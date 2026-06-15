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
{
    connect(m_devices, &QMediaDevices::audioInputsChanged, this, [this]() {
        refreshDeviceLists();
        writeTomlFile();
    });
    connect(m_devices, &QMediaDevices::audioOutputsChanged, this, [this]() {
        refreshDeviceLists();
        writeTomlFile();
    });
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
    const QString input = m_inputEnabled ? m_inputDeviceName : QStringLiteral("off");
    const QString mode = m_exclusiveMode ? QStringLiteral("Exclusive") : QStringLiteral("Shared");
    return QStringLiteral("In: %1 | Out: %2 | %3 | %4 samples")
        .arg(input, m_outputDeviceName, mode)
        .arg(bufferSize());
}

void ConfigModel::refreshDeviceLists()
{
    QStringList inputs;
    for (const QAudioDevice &device : m_devices->audioInputs())
        inputs << device.description();

    QStringList outputs;
    for (const QAudioDevice &device : m_devices->audioOutputs())
        outputs << device.description();

    if (inputs == m_inputDevices && outputs == m_outputDevices)
        return;

    m_inputDevices = inputs;
    m_outputDevices = outputs;
    emit inputDevicesChanged();
    emit outputDevicesChanged();
}

int ConfigModel::bufferSizeToIndex(int samples) const
{
    const int index = m_bufferSizes.indexOf(samples);
    return index >= 0 ? index : 0;
}

void ConfigModel::load()
{
    m_loading = true;
    refreshDeviceLists();

    QFile configFile(m_configPath);
    if (!configFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
        setInstallDefaults(true, 32);
        m_loading = false;
        return;
    }

    const QByteArray configData = configFile.readAll();
    configFile.close();
    std::istringstream stream(configData.constData());
    const toml::ParseResult pr = toml::parse(stream);
    if (!pr.valid()) {
        setInstallDefaults(true, 32);
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
}

void ConfigModel::applyTomlValues(const toml::Value &v)
{
    const toml::Value *bss = v.find("bufferSizeSamples");
    if (bss && bss->is<int>())
        m_bufferSizeIndex = bufferSizeToIndex(bss->as<int>());
    else
        m_bufferSizeIndex = bufferSizeToIndex(64);

    const toml::Value *inputDev = v.find("input.device");
    if (inputDev && inputDev->is<std::string>()) {
        const QString device = QString::fromStdString(inputDev->as<std::string>());
        m_inputEnabled = !device.isEmpty();
        m_inputDeviceName = m_inputEnabled ? device : QString();
    } else {
        m_inputEnabled = true;
        m_inputDeviceName = QMediaDevices::defaultAudioInput().description();
    }

    const toml::Value *inputChannels = v.find("input.channels");
    m_inputStereoEmulation = inputChannels && inputChannels->is<int>() && inputChannels->as<int>() == 2;

    const toml::Value *inputExcl = v.find("input.wasapiExclusiveMode");
    if (inputExcl && inputExcl->is<bool>())
        m_exclusiveMode = inputExcl->as<bool>();

    const toml::Value *outputDev = v.find("output.device");
    if (outputDev && outputDev->is<std::string>())
        m_outputDeviceName = QString::fromStdString(outputDev->as<std::string>());
    else
        m_outputDeviceName = QMediaDevices::defaultAudioOutput().description();

    const toml::Value *outputChannels = v.find("output.channels");
    m_outputStereoEmulation = outputChannels && outputChannels->is<int>() && outputChannels->as<int>() == 2;

    const toml::Value *outputExcl = v.find("output.wasapiExclusiveMode");
    if (outputExcl && outputExcl->is<bool>())
        m_exclusiveMode = outputExcl->as<bool>();
}

void ConfigModel::setDefaults()
{
    setInstallDefaults(true, 32);
}

void ConfigModel::setInstallDefaults(bool exclusive, int bufferSizeSamples)
{
    m_loading = true;
    m_bufferSizeIndex = bufferSizeToIndex(bufferSizeSamples);
    m_exclusiveMode = exclusive;
    m_inputEnabled = true;
    m_inputStereoEmulation = false;
    m_outputStereoEmulation = false;
    m_inputDeviceName = QMediaDevices::defaultAudioInput().description();
    m_outputDeviceName = QMediaDevices::defaultAudioOutput().description();
    refreshDeviceLists();
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
    load();
}

void ConfigModel::writeTomlFile()
{
    if (m_loading)
        return;

    QSaveFile file(m_configPath);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text))
        return;

    QTextStream out(&file);
    out.setEncoding(QStringConverter::Utf8);
    out << "backend = \"Windows WASAPI\"" << "\n"
        << "bufferSizeSamples = " << bufferSize() << "\n"
        << "\n"
        << "[input]" << "\n"
        << "device = \"" << (m_inputEnabled ? m_inputDeviceName : QString()) << "\"\n";
    if (m_inputEnabled && m_inputStereoEmulation)
        out << "channels = 2" << "\n";
    out << "suggestedLatencySeconds = 0.0" << "\n"
        << "wasapiExclusiveMode = " << (m_exclusiveMode ? "true" : "false") << "\n"
        << "\n"
        << "[output]" << "\n"
        << "device = \"" << m_outputDeviceName << "\"\n";
    if (m_outputStereoEmulation)
        out << "channels = 2" << "\n";
    out << "suggestedLatencySeconds = 0.0" << "\n"
        << "wasapiExclusiveMode = " << (m_exclusiveMode ? "true" : "false") << "\n";
    file.commit();
    emitStatusSummaryChanged();
}

void ConfigModel::emitStatusSummaryChanged()
{
    emit statusSummaryChanged();
}

void ConfigModel::setInputDevice(const QString &name)
{
    if (m_inputDeviceName == name)
        return;
    m_inputDeviceName = name;
    emit inputDeviceChanged();
    writeTomlFile();
}

void ConfigModel::setOutputDevice(const QString &name)
{
    if (m_outputDeviceName == name)
        return;
    m_outputDeviceName = name;
    emit outputDeviceChanged();
    writeTomlFile();
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
