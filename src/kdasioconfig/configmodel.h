#ifndef CONFIGMODEL_H
#define CONFIGMODEL_H

#include <QObject>
#include <QMediaDevices>
#include <QProcess>
#include <QSettings>
#include <QStringList>

#include "toml.h"

class ConfigModel : public QObject
{
    Q_OBJECT
    // inputDevice/outputDevice are the PINNED device names; empty means "follow
    // the Windows default", which writes no device key - the robust state, since
    // a pinned name goes stale when Windows renumbers endpoints. The default*
    // properties expose what the Windows default currently resolves to, for
    // display in the dropdown's first entry.
    Q_PROPERTY(QStringList inputDevices READ inputDevices NOTIFY inputDevicesChanged)
    Q_PROPERTY(QStringList outputDevices READ outputDevices NOTIFY outputDevicesChanged)
    Q_PROPERTY(QString inputDevice READ inputDevice WRITE setInputDevice NOTIFY inputDeviceChanged)
    Q_PROPERTY(QString outputDevice READ outputDevice WRITE setOutputDevice NOTIFY outputDeviceChanged)
    Q_PROPERTY(QString defaultInputDevice READ defaultInputDevice NOTIFY defaultDevicesChanged)
    Q_PROPERTY(QString defaultOutputDevice READ defaultOutputDevice NOTIFY defaultDevicesChanged)
    Q_PROPERTY(bool inputEnabled READ inputEnabled WRITE setInputEnabled NOTIFY inputEnabledChanged)
    Q_PROPERTY(bool exclusiveMode READ exclusiveMode WRITE setExclusiveMode NOTIFY exclusiveModeChanged)
    Q_PROPERTY(int bufferSizeIndex READ bufferSizeIndex WRITE setBufferSizeIndex NOTIFY bufferSizeChanged)
    Q_PROPERTY(int bufferSize READ bufferSize NOTIFY bufferSizeChanged)
    Q_PROPERTY(QStringList bufferSizeChoices READ bufferSizeChoices CONSTANT)
    Q_PROPERTY(QString version READ version CONSTANT)
    Q_PROPERTY(QString configPath READ configPath CONSTANT)
    Q_PROPERTY(QString statusSummary READ statusSummary NOTIFY statusSummaryChanged)
    Q_PROPERTY(bool systrayEnabled READ systrayEnabled WRITE setSystrayEnabled NOTIFY systrayEnabledChanged)

public:
    explicit ConfigModel(QObject *parent = nullptr);

    QStringList inputDevices() const { return m_inputDevices; }
    QStringList outputDevices() const { return m_outputDevices; }
    QString inputDevice() const { return m_inputDeviceName; }
    QString outputDevice() const { return m_outputDeviceName; }
    QString defaultInputDevice() const;
    QString defaultOutputDevice() const;
    bool inputEnabled() const { return m_inputEnabled; }
    bool exclusiveMode() const { return m_exclusiveMode; }
    int bufferSizeIndex() const { return m_bufferSizeIndex; }
    int bufferSize() const { return m_bufferSizes.value(m_bufferSizeIndex, 32); }
    QStringList bufferSizeChoices() const;
    QString version() const { return m_version; }
    QString configPath() const { return m_configPath; }
    QString statusSummary() const;
    bool systrayEnabled() const { return m_systrayEnabled; }

    void setInputDevice(const QString &name);
    void setOutputDevice(const QString &name);
    void setInputEnabled(bool enabled);
    void setExclusiveMode(bool exclusive);
    void setBufferSizeIndex(int index);
    void setSystrayEnabled(bool enabled);

    Q_INVOKABLE void load();
    Q_INVOKABLE bool hasStoredConfig() const;
    Q_INVOKABLE void setDefaults();
    Q_INVOKABLE void setInstallDefaults(bool exclusive, int bufferSizeSamples = 128);
    Q_INVOKABLE void openInputSettings();
    Q_INVOKABLE void openOutputSettings();
    Q_INVOKABLE void openGitHub();
    Q_INVOKABLE void openReleases();
    Q_INVOKABLE void openWebsite();
    Q_INVOKABLE void reloadFromFile();

signals:
    void inputDevicesChanged();
    void outputDevicesChanged();
    void inputDeviceChanged();
    void outputDeviceChanged();
    void defaultDevicesChanged();
    void inputEnabledChanged();
    void exclusiveModeChanged();
    void bufferSizeChanged();
    void statusSummaryChanged();
    void systrayEnabledChanged();

private:
    QString tomlText() const;
    void writeTomlFile();
    void applyTomlValues(const toml::Value &v);
    void refreshDeviceLists();
    bool healPinnedDevices();
    void emitStatusSummaryChanged();
    int bufferSizeToIndex(int samples) const;

    QMediaDevices *m_devices = nullptr;
    QProcess *m_mmcplProc = nullptr;
    QString m_inputDeviceName;   // empty = follow the Windows default
    QString m_outputDeviceName;  // empty = follow the Windows default
    QStringList m_inputDevices;
    QStringList m_outputDevices;
    QString m_configPath;
    QString m_version;
    QByteArray m_lastWritten;
    QString m_inputAudioSettingsPath = QStringLiteral("mmsys.cpl,,1");
    QString m_outputAudioSettingsPath = QStringLiteral("mmsys.cpl");
    QList<int> m_bufferSizes = {32, 64, 128, 256, 512, 1024, 2048};
    int m_bufferSizeIndex = 0;
    bool m_exclusiveMode = false;
    bool m_inputEnabled = true;
    bool m_loading = false;
    bool m_systrayEnabled = true;
    QSettings m_settings;
};

#endif
