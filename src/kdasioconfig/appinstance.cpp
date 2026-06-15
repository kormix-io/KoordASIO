#include "appinstance.h"

#include <QLocalSocket>
#include <QCoreApplication>

namespace {

QString serverNameForAppId(const QString &appId)
{
    return QStringLiteral("KoordASIOControl-") + appId;
}

}

AppInstance::AppInstance(const QString &appId, QObject *parent)
    : QObject(parent)
    , m_serverName(serverNameForAppId(appId))
{
    QLocalSocket probe;
    probe.connectToServer(m_serverName);
    if (probe.waitForConnected(300)) {
        m_isPrimary = false;
        return;
    }

    m_isPrimary = true;
    startServer();
}

bool AppInstance::tryNotifyPrimaryAndExit()
{
    if (m_isPrimary)
        return false;

    QLocalSocket socket;
    socket.connectToServer(m_serverName);
    if (!socket.waitForConnected(500))
        return false;

    socket.write("activate");
    socket.waitForBytesWritten(500);
    return true;
}

void AppInstance::startServer()
{
    QLocalServer::removeServer(m_serverName);
    if (!m_server.listen(m_serverName)) {
        m_isPrimary = false;
        return;
    }

    connect(&m_server, &QLocalServer::newConnection, this, [this]() {
        QLocalSocket *connection = m_server.nextPendingConnection();
        if (!connection)
            return;

        connect(connection, &QLocalSocket::readyRead, this, [this, connection]() {
            if (connection->readAll().contains("activate"))
                emit activateRequested();
            connection->deleteLater();
        });
        connect(connection, &QLocalSocket::disconnected, connection, &QLocalSocket::deleteLater);
    });
}
