#include "configmodel.h"

#include "toml.h"

#include <QAudioDevice>
#include <QCoreApplication>
#include <QDesktopServices>
#include <QDir>
#include <QFile>
#include <QRegularExpression>
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

// Windows numbers duplicate endpoints into their friendly names — "Speakers (3- USB
// Audio Device)" — and the number changes when the device moves to another USB port.
// Strip the ordinals so a pinned name can be recognized across re-enumerations.
QString stripWindowsDeviceOrdinals(const QString &name)
{
    QString result = name;
    result.remove(QRegularExpression(QStringLiteral("^\\d+ - ")));
    result.replace(QRegularExpression(QStringLiteral("\\(\\d+- ")), QStringLiteral("("));
    return result;
}

// A pinned name that is no longer present would make the driver refuse to load.
// Re-match it to the same device under its new number when that is unambiguous;
// when the device is really gone, clear the pin so the config follows the
// Windows default instead. Returns true if the name changed.
bool healPinnedDevice(QString &name, const QStringList &available)
{
    if (name.isEmpty() || available.isEmpty() || available.contains(name))
        return false;
    const QString stripped = stripWindowsDeviceOrdinals(name);
    QStringList matches;
    for (const QString &candidate : available)
        if (stripWindowsDeviceOrdinals(candidate) == stripped)
            matches << candidate;
    const QString replacement = matches.size() == 1 ? matches.first() : QString();
    qInfo() << "Pinned device" << name << "is gone;"
            << (replacement.isEmpty() ? "following the Windows default" : "re-matched to " + replacement);
    name = replacement;
    return true;
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
        refreshDeviceLists();
        if (healPinnedDevices())
            writeTomlFile();
        emit defaultDevicesChanged();
        emitStatusSummaryChanged();
    });
    connect(m_devices, &QMediaDevices::audioOutputsChanged, this, [this]() {
        refreshDeviceLists();
        if (healPinnedDevices())
            writeTomlFile();
        emit defaultDevicesChanged();
        emitStatusSummaryChanged();
    });
}

QString ConfigModel::defaultInputDevice() const
{
    return QMediaDevices::defaultAudioInput().description();
}

QString ConfigModel::defaultOutputDevice() const
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
    const QString input = !m_inputEnabled ? QStringLiteral("off")
        : elide(m_inputDeviceName.isEmpty() ? defaultInputDevice() : m_inputDeviceName);
    const QString output = elide(m_outputDeviceName.isEmpty() ? defaultOutputDevice() : m_outputDeviceName);
    const QString mode = m_exclusiveMode ? QStringLiteral("Exclusive") : QStringLiteral("Shared");
    return QStringLiteral("Input:   %1\nOutput:  %2\nMode:    %3\nBuffer:  %4 samples")
        .arg(input, output, mode)
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

bool ConfigModel::healPinnedDevices()
{
    bool healed = false;
    if (healPinnedDevice(m_inputDeviceName, m_inputDevices)) {
        healed = true;
        emit inputDeviceChanged();
    }
    if (healPinnedDevice(m_outputDeviceName, m_outputDevices)) {
        healed = true;
        emit outputDeviceChanged();
    }
    return healed;
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
    healPinnedDevices();
    m_loading = false;

    emit bufferSizeChanged();
    emit inputEnabledChanged();
    emit exclusiveModeChanged();
    emit inputDeviceChanged();
    emit outputDeviceChanged();
    emit defaultDevicesChanged();
    emitStatusSummaryChanged();

    // A healed pin (or a config from a version with different semantics, such
    // as a leftover mono-as-stereo channels key) must reach the file, or the
    // driver keeps reading settings the app no longer shows.
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

    // No device key = follow the Windows default. An empty device string is
    // FlexASIO's "input off". A non-empty one is an explicitly pinned device.
    const toml::Value *inputDev = v.find("input.device");
    if (inputDev && inputDev->is<std::string>()) {
        const QString device = QString::fromStdString(inputDev->as<std::string>());
        m_inputEnabled = !device.isEmpty();
        if (m_inputEnabled)
            m_inputDeviceName = device;
    } else {
        m_inputEnabled = true;
        m_inputDeviceName.clear();
    }

    const toml::Value *inputExcl = v.find("input.wasapiExclusiveMode");
    if (inputExcl && inputExcl->is<bool>())
        m_exclusiveMode = inputExcl->as<bool>();

    const toml::Value *outputDev = v.find("output.device");
    if (outputDev && outputDev->is<std::string>())
        m_outputDeviceName = QString::fromStdString(outputDev->as<std::string>());
    else
        m_outputDeviceName.clear();

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
    m_inputDeviceName.clear();
    m_outputDeviceName.clear();
    refreshDeviceLists();
    m_loading = false;

    emit bufferSizeChanged();
    emit inputEnabledChanged();
    emit exclusiveModeChanged();
    emit inputDeviceChanged();
    emit outputDeviceChanged();
    emit defaultDevicesChanged();
    writeTomlFile();
}

void ConfigModel::reloadFromFile()
{
    // The watcher fires for our own saves too; skip those. The file MUST be
    // read in Text mode: writeTomlFile writes in Text mode, so the disk bytes
    // are CRLF while m_lastWritten holds "\n". Comparing raw bytes never
    // matched, which made every save the app itself made trigger a full
    // load() - config parse, COM device enumeration, every signal - and the
    // panel visibly hitched on each settings click.
    QFile file(m_configPath);
    if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
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
    // A pinned device is written by name; following the Windows default writes
    // no device key at all. The empty string is the driver's "input off" switch.
    if (!m_inputEnabled)
        out << "device = \"\"" << "\n";
    else if (!m_inputDeviceName.isEmpty())
        out << "device = \"" << m_inputDeviceName << "\"\n";
    out << "suggestedLatencySeconds = 0.0" << "\n"
        << "wasapiExclusiveMode = " << (m_exclusiveMode ? "true" : "false") << "\n"
        << "\n"
        << "[output]" << "\n";
    if (!m_outputDeviceName.isEmpty())
        out << "device = \"" << m_outputDeviceName << "\"\n";
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
