#include <QColor>
#include <QDateTime>
#include <QFile>
#include <QImage>
#include <QApplication>
#include <QPalette>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQmlError>
#include <QQuickStyle>
#include <QQuickWindow>
#include <QStandardPaths>
#include <QTextStream>
#include <QThread>
#include <QWindow>

#include <memory>

#include "appinstance.h"
#include "configmodel.h"
#include "traymanager.h"

namespace {

QFile *g_logFile = nullptr;
const QMessageLogContext g_emptyContext;

void logLine(QtMsgType type, const QString &msg, const QMessageLogContext &context = g_emptyContext)
{
    if (!g_logFile)
        return;
    const char *level = "???";
    switch (type) {
    case QtDebugMsg: level = "DBG"; break;
    case QtInfoMsg: level = "INF"; break;
    case QtWarningMsg: level = "WRN"; break;
    case QtCriticalMsg: level = "CRT"; break;
    case QtFatalMsg: level = "FTL"; break;
    }
    QTextStream stream(g_logFile);
    stream << QDateTime::currentDateTime().toString(Qt::ISODate) << ' ' << level << ' '
           << msg;
    if (context.file)
        stream << " (" << context.file << ':' << context.line << ')';
    stream << '\n';
    stream.flush();
    if (type == QtFatalMsg)
        abort();
}

bool initLogFile()
{
    const QString path = QStandardPaths::writableLocation(QStandardPaths::TempLocation)
        + QStringLiteral("/KoordASIOControl.log");
    g_logFile = new QFile(path);
    if (!g_logFile->open(QIODevice::WriteOnly | QIODevice::Append | QIODevice::Text))
        return false;
    logLine(QtInfoMsg, QStringLiteral("--- started --- log: %1").arg(path));
    return true;
}

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

QWindow *findMainWindow(QApplication &app)
{
    for (QWindow *window : app.topLevelWindows()) {
        if (qobject_cast<QQuickWindow *>(window))
            return window;
    }
    return nullptr;
}

void applyDarkPalette(QApplication &app)
{
    const QColor bg(0x31, 0x35, 0x39);
    QPalette palette;
    palette.setColor(QPalette::Window, bg);
    palette.setColor(QPalette::WindowText, QColor(240, 240, 240));
    palette.setColor(QPalette::Base, QColor(0, 0, 0));
    palette.setColor(QPalette::AlternateBase, bg);
    palette.setColor(QPalette::Text, QColor(240, 240, 240));
    palette.setColor(QPalette::Button, bg);
    palette.setColor(QPalette::ButtonText, QColor(240, 240, 240));
    palette.setColor(QPalette::Highlight, QColor(64, 128, 255));
    palette.setColor(QPalette::HighlightedText, QColor(255, 255, 255));
    app.setPalette(palette);
}

}

int main(int argc, char **argv)
{
    QApplication app(argc, argv);
    initLogFile();
    qInstallMessageHandler([](QtMsgType type, const QMessageLogContext &context, const QString &msg) {
        logLine(type, msg, context);
    });
    app.setApplicationName(QStringLiteral("KoordASIO Control"));
    app.setQuitOnLastWindowClosed(false);
    QQuickStyle::setStyle(QStringLiteral("Fusion"));
    applyDarkPalette(app);

    ConfigModel configModel;
    QString screenshotPath;

    if (argc >= 2) {
        const QString arg = argv[1];
        if (arg.startsWith(QStringLiteral("-screenshot="))) {
            screenshotPath = arg.mid(12);
        } else if (!arg.compare(QStringLiteral("-defaults")) || !arg.compare(QStringLiteral("-de"))) {
            configModel.setInstallDefaults(true);
            return 0;
        } else if (!arg.compare(QStringLiteral("-ds"))) {
            configModel.setInstallDefaults(false);
            return 0;
        } else if (arg.startsWith(QStringLiteral("-buffer="))) {
            int bufferSize = 32;
            if (!parseBufferSize(arg.mid(8), bufferSize))
                return 1;
            configModel.setInstallDefaults(true, bufferSize);
            return 0;
        } else if (!arg.compare(QStringLiteral("-exclusive"))) {
            configModel.setInstallDefaults(true);
            return 0;
        } else if (!arg.compare(QStringLiteral("-shared"))) {
            configModel.setInstallDefaults(false);
            return 0;
        }
    }

    std::unique_ptr<AppInstance> instanceGuard;
    if (screenshotPath.isEmpty()) {
        instanceGuard = std::make_unique<AppInstance>(QStringLiteral("KoordASIOControl"));
        if (!instanceGuard->isPrimary()) {
            instanceGuard->tryNotifyPrimaryAndExit();
            return 0;
        }
    }

    QQmlApplicationEngine engine;
    QObject::connect(
        &engine, &QQmlApplicationEngine::warnings,
        &app, [](const QList<QQmlError> &errors) {
            for (const QQmlError &error : errors)
                logLine(QtWarningMsg, error.toString());
        });
    engine.rootContext()->setContextProperty(QStringLiteral("config"), &configModel);
    engine.load(QUrl(QStringLiteral("qrc:/main.qml")));
    if (engine.rootObjects().isEmpty()) {
        logLine(QtCriticalMsg, QStringLiteral("QML root objects empty"));
        return 1;
    }

    logLine(QtInfoMsg, QStringLiteral("QML loaded"));
    configModel.load();
    logLine(QtInfoMsg, QStringLiteral("config loaded"));

    QWindow *mainWindow = findMainWindow(app);
    TrayManager tray(&configModel, mainWindow);
    tray.setEnabled(configModel.systrayEnabled());
    if (screenshotPath.isEmpty())
        tray.show();
    logLine(QtInfoMsg, QStringLiteral("tray shown"));

    QObject::connect(&configModel, &ConfigModel::systrayEnabledChanged, &tray, [&tray, &configModel]() {
        tray.setEnabled(configModel.systrayEnabled());
    });
    QObject::connect(&configModel, &ConfigModel::systrayEnabledChanged, &app, [&app, &configModel]() {
        app.setQuitOnLastWindowClosed(!configModel.systrayEnabled());
    });
    app.setQuitOnLastWindowClosed(!configModel.systrayEnabled());

    if (instanceGuard)
        QObject::connect(instanceGuard.get(), &AppInstance::activateRequested, &tray, &TrayManager::showWindow);

    if (mainWindow)
        mainWindow->show();

    if (!screenshotPath.isEmpty()) {
        for (int i = 0; i < 20; ++i) {
            app.processEvents();
            QThread::msleep(50);
        }
        if (auto *quickWindow = qobject_cast<QQuickWindow *>(mainWindow)) {
            const QImage image = quickWindow->grabWindow();
            if (!image.save(screenshotPath)) {
                logLine(QtCriticalMsg, QStringLiteral("failed to save screenshot: %1").arg(screenshotPath));
                return 1;
            }
            logLine(QtInfoMsg, QStringLiteral("screenshot saved: %1").arg(screenshotPath));
        } else {
            logLine(QtCriticalMsg, QStringLiteral("no QQuickWindow for screenshot"));
            return 1;
        }
        return 0;
    }

    logLine(QtInfoMsg, QStringLiteral("entering event loop"));
    const int code = app.exec();
    logLine(QtInfoMsg, QStringLiteral("event loop exited: %1").arg(code));
    return code;
}
