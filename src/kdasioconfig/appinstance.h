#ifndef APPINSTANCE_H
#define APPINSTANCE_H

#include <QObject>
#include <QLocalServer>
#include <QString>

// Single-instance guard using Qt's QLocalServer/QLocalSocket (no third-party deps).
class AppInstance : public QObject
{
    Q_OBJECT

public:
    explicit AppInstance(const QString &appId, QObject *parent = nullptr);

    bool isPrimary() const { return m_isPrimary; }
    bool tryNotifyPrimaryAndExit();

signals:
    void activateRequested();

private:
    void startServer();

    QString m_serverName;
    QLocalServer m_server;
    bool m_isPrimary = false;
};

#endif
