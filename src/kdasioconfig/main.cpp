#include <QColor>
#include <QGuiApplication>
#include <QPalette>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QQuickWindow>
#include <QWindow>

#include "appinstance.h"
#include "configmodel.h"
#include "traymanager.h"

namespace {

bool parseBufferSize(const QString &value, int &bufferSize)
{
    bool ok = false;
    const int parsed = value.toInt(&ok);
    if (!ok)
        return false;
    const QList<int> allowed = {32, 64, 128, 256, 512, 1024, 2048};
    if (!allowed.contains(parsed))
        return false;
    bufferSize = parsed;
    return true;
}

QWindow *findMainWindow(QGuiApplication &app)
{
    for (QWindow *window : app.topLevelWindows()) {
        if (qobject_cast<QQuickWindow *>(window))
            return window;
    }
    return nullptr;
}

void applyDarkPalette(QGuiApplication &app)
{
    QPalette palette;
    palette.setColor(QPalette::Window, QColor(30, 30, 30));
    palette.setColor(QPalette::WindowText, QColor(240, 240, 240));
    palette.setColor(QPalette::Base, QColor(25, 25, 25));
    palette.setColor(QPalette::AlternateBase, QColor(35, 35, 35));
    palette.setColor(QPalette::Text, QColor(240, 240, 240));
    palette.setColor(QPalette::Button, QColor(45, 45, 45));
    palette.setColor(QPalette::ButtonText, QColor(240, 240, 240));
    palette.setColor(QPalette::Highlight, QColor(64, 128, 255));
    palette.setColor(QPalette::HighlightedText, QColor(255, 255, 255));
    app.setPalette(palette);
}

}

int main(int argc, char **argv)
{
    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("KoordASIO Control"));
    app.setQuitOnLastWindowClosed(false);
    QQuickStyle::setStyle(QStringLiteral("Fusion"));
    applyDarkPalette(app);

    ConfigModel configModel;

    if (argc >= 2) {
        const QString arg = argv[1];
        if (!arg.compare(QStringLiteral("-defaults")) || !arg.compare(QStringLiteral("-de"))) {
            configModel.setInstallDefaults(true);
            return 0;
        }
        if (!arg.compare(QStringLiteral("-ds"))) {
            configModel.setInstallDefaults(false);
            return 0;
        }
        if (arg.startsWith(QStringLiteral("-buffer="))) {
            int bufferSize = 32;
            if (!parseBufferSize(arg.mid(8), bufferSize))
                return 1;
            configModel.setInstallDefaults(true, bufferSize);
            return 0;
        }
        if (!arg.compare(QStringLiteral("-exclusive"))) {
            configModel.setInstallDefaults(true);
            return 0;
        }
        if (!arg.compare(QStringLiteral("-shared"))) {
            configModel.setInstallDefaults(false);
            return 0;
        }
    }

    AppInstance instanceGuard(QStringLiteral("KoordASIOControl"));
    if (!instanceGuard.isPrimary()) {
        instanceGuard.tryNotifyPrimaryAndExit();
        return 0;
    }

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(QStringLiteral("config"), &configModel);
    engine.load(QUrl(QStringLiteral("qrc:/main.qml")));
    if (engine.rootObjects().isEmpty())
        return 1;

    configModel.load();

    QWindow *mainWindow = findMainWindow(app);
    TrayManager tray(&configModel, mainWindow);
    tray.show();

    QObject::connect(&instanceGuard, &AppInstance::activateRequested, &tray, &TrayManager::showWindow);

    if (mainWindow)
        mainWindow->show();

    return app.exec();
}
