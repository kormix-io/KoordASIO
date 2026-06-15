#include "traymanager.h"
#include "configmodel.h"

#include <QAction>
#include <QGuiApplication>
#include <QIcon>
#include <QMenu>
#include <QWindow>

TrayManager::TrayManager(ConfigModel *model, QWindow *window, QObject *parent)
    : QObject(parent)
    , m_model(model)
    , m_window(window)
{
    m_tray.setIcon(QIcon(QStringLiteral(":/mainicon.ico")));
    m_tray.setToolTip(QStringLiteral("KoordASIO Control"));

    auto *menu = new QMenu();
    auto *showAction = menu->addAction(QStringLiteral("Open Settings"));
    auto *githubAction = menu->addAction(QStringLiteral("GitHub"));
    menu->addSeparator();
    auto *quitAction = menu->addAction(QStringLiteral("Quit"));

    connect(showAction, &QAction::triggered, this, &TrayManager::showWindow);
    connect(githubAction, &QAction::triggered, m_model, &ConfigModel::openGitHub);
    connect(quitAction, &QAction::triggered, qApp, &QGuiApplication::quit);
    connect(&m_tray, &QSystemTrayIcon::activated, this, [this](QSystemTrayIcon::ActivationReason reason) {
        if (reason == QSystemTrayIcon::Trigger || reason == QSystemTrayIcon::DoubleClick)
            showWindow();
    });

    m_tray.setContextMenu(menu);

    if (m_model) {
        connect(m_model, &ConfigModel::statusSummaryChanged, this, &TrayManager::updateTooltip);
        m_configWatcher.addPath(m_model->configPath());
        connect(&m_configWatcher, &QFileSystemWatcher::fileChanged, m_model, &ConfigModel::reloadFromFile);
    }

    updateTooltip();
}

void TrayManager::show()
{
    m_tray.show();
}

void TrayManager::showWindow()
{
    if (!m_window)
        return;
    m_window->show();
    m_window->raise();
    m_window->requestActivate();
}

void TrayManager::updateTooltip()
{
    if (!m_model)
        return;
    m_tray.setToolTip(QStringLiteral("KoordASIO Control\n%1").arg(m_model->statusSummary()));
}
