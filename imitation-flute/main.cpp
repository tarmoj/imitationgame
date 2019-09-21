#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "csengine.h"
#include <QThread>

#ifdef Q_OS_ANDROID
	#include <QtAndroid>
	#include <QAndroidJniEnvironment>
#endif

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);

#ifdef Q_OS_ANDROID
	//keep screen on:
	QAndroidJniObject activity = QtAndroid::androidActivity();
	if (activity.isValid()) {
		QAndroidJniObject window = activity.callObjectMethod("getWindow", "()Landroid/view/Window;");

		if (window.isValid()) {
			const int FLAG_KEEP_SCREEN_ON = 128;
			window.callMethod<void>("addFlags", "(I)V", FLAG_KEEP_SCREEN_ON);
		}
		QAndroidJniEnvironment env; if (env->ExceptionCheck()) { env->ExceptionClear(); } //Clear any possible pending exceptions.
	}
#endif

	CsEngine * cs = new CsEngine();
	//cs->start();
	// move csound into another thread
	QThread  * csoundThread = new QThread();
	cs = new CsEngine();
	cs->moveToThread(csoundThread);
	QObject::connect(csoundThread, &QThread::finished, cs, &CsEngine::deleteLater);
	QObject::connect(csoundThread, &QThread::finished, csoundThread, &QThread::deleteLater);
	//connect(QApplication::instance(), QApplication::aboutToQuit,cs,&CsEngine::stop );
	QObject::connect(csoundThread, &QThread::started, cs, &CsEngine::play);
	csoundThread->start();


    QQmlApplicationEngine engine;
	engine.rootContext()->setContextProperty("csound", cs); // forward c++ object that can be reached form qml by object name "csound" NB! include <QQmlContext>


    engine.load(QUrl(QStringLiteral("qrc:/main.qml")));
//	cs.open(":/test.csd");
//	cs.csEvent("i 2 0 1");

    return app.exec();
}
