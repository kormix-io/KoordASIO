#include "configmodel.h"

#include "toml.h"

#include <QAudioDevice>
#include <QCoreApplication>
#include <QDesktopServices>
#include <QDir>
#include <QFile>
#include <QSaveFile>
#include <QStringConverter>
#include <QTextStream>
#include <QUrl>

#include <sstream>

namespace {

QString readAppVersion()
{
#ifdef KOORDASIO_VERSION
    return QStringLiteral(KOORDASIO_VERSION);
#else
    return QStringLiteral("?");
#endif
}

}

ConfigModel::ConfigModel(QObject *parent)
    : QObject(parent)
    , m_devices(new QMediaDevices(this))
    , m_configPath(QDir::homePath() + QStringLiteral("/.KoordASIO.toml"))
    , m_version(readAppVersion())
    , m_settings(QStringLiteral("kormix"), QStringLiteral("KoordASIO"))
{
    m_systrayEnabled = m_settings.value(QStringLiteral("systrayEnabled"), true).toBool();
    connect(m_devices, &QMediaDevices::audioInputsChanged, this, [this]() {
        emit inputDeviceChanged();
        emitStatusSummaryChanged();
    });
    connect(m_devices, &QMediaDevices::audioOutputsChanged, this, [this]() {
        emit outputDeviceChanged();
        emitStatusSummaryChanged();
    });
}

// The config never names devices: the driver follows the Windows default
// devices, the way a configless FlexASIO does. Pinning a name broke the driver
// outright whenever Windows renumbered an endpoint ("Speakers (3- USB Audio
// Device)" coming back as "(4- ...)" after a port change). These getters only
// feed the UI, so the user can see where audio will go.
QString ConfigModel::inputDevice() const
{
    return QMediaDevices::defaultAudioInput().description();
}

QString ConfigModel::outputDevice() const
{
    return QMediaDevices::defaultAudioOutput().description();
}

QStringList ConfigModel::bufferSizeChoices() const
{
    QStringList choices;
    for (int size : m_bufferSizes)
        choices << QString::number(size);
    return choices;
}

QString ConfigModel::statusSummary() const
{
    // One setting per line, label and value aligned. The Windows shell draws this
    // itself and caps it at 127 characters, so elide long device names rather
    // than risk losing whole lines off the end.
    const auto elide = [](const QString &name) {
        const int limit = 26;
        return name.length() > limit ? name.left(limit - 1) + QChar(0x2026) : name;
    };
    const QString input = m_inputEnabled ? elide(inputDevice()) : QStringLiteral("off");
    const QString mode = m_exclusiveMode ? QStringLiteral("Exclusive") : QStringLiteral("Shared");
    return QStringLiteral("Input:   %1\nOutput:  %2\nMode:    %3\nBuffer:  %4 samples")
        .arg(input, elide(outputDevice()), mode)
        .arg(bufferSize());
}

int ConfigModel::bufferSizeToIndex(int samples) const
{
    const int index = m_bufferSizes.indexOf(samples);
    return index >= 0 ? index : 0;
}

void ConfigModel::load()
{
    m_loading = true;

    QFile configFile(m_configPath);
    if (!configFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
        setInstallDefaults(false, 128);
        m_loading = false;
        return;
    }

    const QByteArray configData = configFile.readAll();
    configFile.close();
    std::istringstream stream(configData.constData());
    const toml::ParseResult pr = toml::parse(stream);
    if (!pr.valid()) {
        setInstallDefaults(false, 128);
        m_loading = false;
        return;
    }

    applyTomlValues(pr.value);
    m_loading = false;

    emit bufferSizeChanged();
    emit inputEnabledChanged();
    emit inputStereoEmulationChanged();
    emit outputStereoEmulationChanged();
    emit exclusiveModeChanged();
    emit inputDeviceChanged();
    emit outputDeviceChanged();
    emitStatusSummaryChanged();

    // Configs written by older versions pin device names, which the driver
    // fails on once Windows renumbers an endpoint. Rewriting in the canonical
    // keyless form heals them the moment this app runs.
    if (tomlText().toUtf8() != configData)
        writeTomlFile();
}

void ConfigModel::applyTomlValues(const toml::Value &v)
{
    const toml::Value *bss = v.find("bufferSizeSamples");
    if (bss && bss->is<int>())
        m_bufferSizeIndex = bufferSizeToIndex(bss->as<int>());
    else
        m_bufferSizeIndex = bufferSizeToIndex(64);

    // An empty device string is FlexASIO's "input off"; any other value —
    // including a pinned name from an older version — means input is on.
    const toml::Value *inputDev = v.find("input.device");
    m_inputEnabled = !(inputDev && inputDev->is<std::string>() && inputDev->as<std::string>().empty());

    const toml::Value *inputChannels = v.find("input.channels");
    m_inputStereoEmulation = inputChannels && inputChannels->is<int>() && inputChannels->as<int>() == 2;

    const toml::Value *inputExcl = v.find("input.wasapiExclusiveMode");
    if (inputExcl && inputExcl->is<bool>())
        m_exclusiveMode = inputExcl->as<bool>();

    const toml::Value *outputChannels = v.find("output.channels");
    m_outputStereoEmulation = outputChannels && outputChannels->is<int>() && outputChannels->as<int>() == 2;

    const toml::Value *outputExcl = v.find("output.wasapiExclusiveMode");
    if (outputExcl && outputExcl->is<bool>())
        m_exclusiveMode = outputExcl->as<bool>();
}

bool ConfigModel::hasStoredConfig() const
{
    QFile configFile(m_configPath);
    if (!configFile.open(QIODevice::ReadOnly | QIODevice::Text))
        return false;
    const QByteArray configData = configFile.readAll();
    configFile.close();
    if (configData.isEmpty())
        return false;

    std::istringstream stream(configData.constData());
    return toml::parse(stream).valid();
}

void ConfigModel::setDefaults()
{
    // Shared mode accepts any host sample rate and coexists with other
    // applications; Exclusive is the opt-in for latency chasers. An Exclusive
    // default made the driver fail to load in hosts running at a rate the
    // device does not do natively (issue #16).
    setInstallDefaults(false, 128);
}

void ConfigModel::setInstallDefaults(bool exclusive, int bufferSizeSamples)
{
    m_loading = true;
    m_bufferSizeIndex = bufferSizeToIndex(bufferSizeSamples);
    m_exclusiveMode = exclusive;
    m_inputEnabled = true;
    m_inputStereoEmulation = false;
    m_outputStereoEmulation = false;
    m_loading = false;

    emit bufferSizeChanged();
    emit inputEnabledChanged();
    emit inputStereoEmulationChanged();
    emit outputStereoEmulationChanged();
    emit exclusiveModeChanged();
    emit inputDeviceChanged();
    emit outputDeviceChanged();
    writeTomlFile();
}

void ConfigModel::reloadFromFile()
{
    // The watcher fires for our own saves too; skip those.
    QFile file(m_configPath);
    if (file.open(QIODevice::ReadOnly)) {
        const QByteArray current = file.readAll();
        file.close();
        if (current == m_lastWritten)
            return;
    }
    load();
}

QString ConfigModel::tomlText() const
{
    QString text;
    QTextStream out(&text);
    out << "backend = \"Windows WASAPI\"" << "\n"
        << "bufferSizeSamples = " << bufferSize() << "\n"
        << "\n"
        << "[input]" << "\n";
    // No device key: the driver uses the Windows default device. The empty
    // string is the driver's "input off" switch.
    if (!m_inputEnabled)
        out << "device = \"\"" << "\n";
    if (m_inputEnabled && m_inputStereoEmulation)
        out << "channels = 2" << "\n";
    out << "suggestedLatencySeconds = 0.0" << "\n"
        << "wasapiExclusiveMode = " << (m_exclusiveMode ? "true" : "false") << "\n"
        << "\n"
        << "[output]" << "\n";
    if (m_outputStereoEmulation)
        out << "channels = 2" << "\n";
    out << "suggestedLatencySeconds = 0.0" << "\n"
        << "wasapiExclusiveMode = " << (m_exclusiveMode ? "true" : "false") << "\n";
    out.flush();
    return text;
}

void ConfigModel::writeTomlFile()
{
    if (m_loading)
        return;

    QSaveFile file(m_configPath);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text))
        return;
    // Remembered so the file watcher can tell our own writes from an external
    // edit; reloading our own write would re-derive state we already hold.
    m_lastWritten = tomlText().toUtf8();
    file.write(m_lastWritten);
    file.commit();
    emitStatusSummaryChanged();
}

void ConfigModel::emitStatusSummaryChanged()
{
    emit statusSummaryChanged();
}

void ConfigModel::setInputEnabled(bool enabled)
{
    if (m_inputEnabled == enabled)
        return;
    m_inputEnabled = enabled;
    emit inputEnabledChanged();
    writeTomlFile();
}

void ConfigModel::setInputStereoEmulation(bool enabled)
{
    if (m_inputStereoEmulation == enabled)
        return;
    m_inputStereoEmulation = enabled;
    emit inputStereoEmulationChanged();
    writeTomlFile();
}

void ConfigModel::setOutputStereoEmulation(bool enabled)
{
    if (m_outputStereoEmulation == enabled)
        return;
    m_outputStereoEmulation = enabled;
    emit outputStereoEmulationChanged();
    writeTomlFile();
}

void ConfigModel::setExclusiveMode(bool exclusive)
{
    if (m_exclusiveMode == exclusive)
        return;
    m_exclusiveMode = exclusive;
    emit exclusiveModeChanged();
    writeTomlFile();
}

void ConfigModel::setBufferSizeIndex(int index)
{
    if (index < 0 || index >= m_bufferSizes.size() || m_bufferSizeIndex == index)
        return;
    m_bufferSizeIndex = index;
    emit bufferSizeChanged();
    writeTomlFile();
}

void ConfigModel::setSystrayEnabled(bool enabled)
{
    if (m_systrayEnabled == enabled)
        return;
    m_systrayEnabled = enabled;
    m_settings.setValue(QStringLiteral("systrayEnabled"), enabled);
    emit systrayEnabledChanged();
}

void ConfigModel::openInputSettings()
{
    if (m_mmcplProc)
        m_mmcplProc->kill();
    m_mmcplProc = new QProcess(this);
    m_mmcplProc->start(QStringLiteral("control"), QStringList() << m_inputAudioSettingsPath);
}

void ConfigModel::openOutputSettings()
{
    if (m_mmcplProc)
        m_mmcplProc->kill();
    m_mmcplProc = new QProcess(this);
    m_mmcplProc->start(QStringLiteral("control"), QStringList() << m_outputAudioSettingsPath);
}

void ConfigModel::openGitHub()
{
    QDesktopServices::openUrl(QUrl(QStringLiteral("https://github.com/kormix-io/KoordASIO")));
}

void ConfigModel::openReleases()
{
    QDesktopServices::openUrl(QUrl(QStringLiteral("https://github.com/kormix-io/KoordASIO/releases")));
}

void ConfigModel::openWebsite()
{
    QDesktopServices::openUrl(QUrl(QStringLiteral("https://kormix-io.github.io/KoordASIO/")));
}
