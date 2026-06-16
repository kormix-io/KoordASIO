#ifndef TRAYMANAGER_H
#define TRAYMANAGER_H

#include <QObject>
#include <QSystemTrayIcon>
#include <QFileSystemWatcher>

class ConfigModel;
class QWindow;

class TrayManager : public QObject
{
    Q_OBJECT

public:
    TrayManager(ConfigModel *model, QWindow *window, QObject *parent = nullptr);

    void show();
    void setEnabled(bool enabled);

public slots:
    void showWindow();
    void updateTooltip();

private:
    ConfigModel *m_model = nullptr;
    QWindow *m_window = nullptr;
    QSystemTrayIcon m_tray;
    QFileSystemWatcher m_configWatcher;
    bool m_enabled = true;
};

#endif
