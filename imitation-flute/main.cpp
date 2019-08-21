#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "csengine.h"
#include <QThread>

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);

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
