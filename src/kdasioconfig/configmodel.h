#ifndef CONFIGMODEL_H
#define CONFIGMODEL_H

#include <QObject>
#include <QMediaDevices>
#include <QProcess>
#include <QStringList>

#include "toml.h"

class ConfigModel : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QStringList inputDevices READ inputDevices NOTIFY inputDevicesChanged)
    Q_PROPERTY(QStringList outputDevices READ outputDevices NOTIFY outputDevicesChanged)
    Q_PROPERTY(QString inputDevice READ inputDevice WRITE setInputDevice NOTIFY inputDeviceChanged)
    Q_PROPERTY(QString outputDevice READ outputDevice WRITE setOutputDevice NOTIFY outputDeviceChanged)
    Q_PROPERTY(bool inputEnabled READ inputEnabled WRITE setInputEnabled NOTIFY inputEnabledChanged)
    Q_PROPERTY(bool inputStereoEmulation READ inputStereoEmulation WRITE setInputStereoEmulation NOTIFY inputStereoEmulationChanged)
    Q_PROPERTY(bool outputStereoEmulation READ outputStereoEmulation WRITE setOutputStereoEmulation NOTIFY outputStereoEmulationChanged)
    Q_PROPERTY(bool exclusiveMode READ exclusiveMode WRITE setExclusiveMode NOTIFY exclusiveModeChanged)
    Q_PROPERTY(int bufferSizeIndex READ bufferSizeIndex WRITE setBufferSizeIndex NOTIFY bufferSizeChanged)
    Q_PROPERTY(int bufferSize READ bufferSize NOTIFY bufferSizeChanged)
    Q_PROPERTY(QStringList bufferSizeChoices READ bufferSizeChoices CONSTANT)
    Q_PROPERTY(QString version READ version CONSTANT)
    Q_PROPERTY(QString configPath READ configPath CONSTANT)
    Q_PROPERTY(QString statusSummary READ statusSummary NOTIFY statusSummaryChanged)

public:
    explicit ConfigModel(QObject *parent = nullptr);

    QStringList inputDevices() const { return m_inputDevices; }
    QStringList outputDevices() const { return m_outputDevices; }
    QString inputDevice() const { return m_inputDeviceName; }
    QString outputDevice() const { return m_outputDeviceName; }
    bool inputEnabled() const { return m_inputEnabled; }
    bool inputStereoEmulation() const { return m_inputStereoEmulation; }
    bool outputStereoEmulation() const { return m_outputStereoEmulation; }
    bool exclusiveMode() const { return m_exclusiveMode; }
    int bufferSizeIndex() const { return m_bufferSizeIndex; }
    int bufferSize() const { return m_bufferSizes.value(m_bufferSizeIndex, 32); }
    QStringList bufferSizeChoices() const;
    QString version() const { return m_version; }
    QString configPath() const { return m_configPath; }
    QString statusSummary() const;

    void setInputDevice(const QString &name);
    void setOutputDevice(const QString &name);
    void setInputEnabled(bool enabled);
    void setInputStereoEmulation(bool enabled);
    void setOutputStereoEmulation(bool enabled);
    void setExclusiveMode(bool exclusive);
    void setBufferSizeIndex(int index);

    Q_INVOKABLE void load();
    Q_INVOKABLE void setDefaults();
    Q_INVOKABLE void setInstallDefaults(bool exclusive, int bufferSizeSamples = 32);
    Q_INVOKABLE void openInputSettings();
    Q_INVOKABLE void openOutputSettings();
    Q_INVOKABLE void openGitHub();
    Q_INVOKABLE void openReleases();
    Q_INVOKABLE void reloadFromFile();

signals:
    void inputDevicesChanged();
    void outputDevicesChanged();
    void inputDeviceChanged();
    void outputDeviceChanged();
    void inputEnabledChanged();
    void inputStereoEmulationChanged();
    void outputStereoEmulationChanged();
    void exclusiveModeChanged();
    void bufferSizeChanged();
    void statusSummaryChanged();

private:
    void refreshDeviceLists();
    void writeTomlFile();
    void applyTomlValues(const toml::Value &v);
    void emitStatusSummaryChanged();
    int bufferSizeToIndex(int samples) const;

    QMediaDevices *m_devices = nullptr;
    QProcess *m_mmcplProc = nullptr;
    QString m_inputDeviceName;
    QString m_outputDeviceName;
    QStringList m_inputDevices;
    QStringList m_outputDevices;
    QString m_configPath;
    QString m_version;
    QString m_inputAudioSettingsPath = QStringLiteral("mmsys.cpl,,1");
    QString m_outputAudioSettingsPath = QStringLiteral("mmsys.cpl");
    QList<int> m_bufferSizes = {32, 64, 128, 256, 512, 1024, 2048};
    int m_bufferSizeIndex = 0;
    bool m_exclusiveMode = false;
    bool m_inputEnabled = true;
    bool m_inputStereoEmulation = false;
    bool m_outputStereoEmulation = false;
    bool m_loading = false;
};

#endif
