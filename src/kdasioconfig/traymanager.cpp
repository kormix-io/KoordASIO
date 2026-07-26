#include "traymanager.h"
#include "configmodel.h"

#include <QAction>
#include <QFile>
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
        connect(&m_configWatcher, &QFileSystemWatcher::fileChanged, this, [this](const QString &path) {
            m_model->reloadFromFile();
            // QSaveFile commits by renaming over the target, which drops the
            // watch, so re-arm it or only the first edit is ever noticed.
            if (!m_configWatcher.files().contains(path) && QFile::exists(path))
                m_configWatcher.addPath(path);
        });
    }

    updateTooltip();
}

void TrayManager::show()
{
    if (m_enabled)
        m_tray.show();
}

void TrayManager::setEnabled(bool enabled)
{
    if (m_enabled == enabled)
        return;
    m_enabled = enabled;
    if (enabled)
        m_tray.show();
    else
        m_tray.hide();
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
    // Kept short: the shell's 127-character cap has to cover the summary too.
    m_tray.setToolTip(QStringLiteral("KoordASIO\n%1").arg(m_model->statusSummary()));
}
