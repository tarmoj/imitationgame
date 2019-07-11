#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "csengine.h"

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);

	CsEngine cs;
	cs.start();
    QQmlApplicationEngine engine;
	engine.rootContext()->setContextProperty("csound", &cs); // forward c++ object that can be reached form qml by object name "csound" NB! include <QQmlContext>


    engine.load(QUrl(QStringLiteral("qrc:/main.qml")));
//	cs.open(":/test.csd");
//	cs.csEvent("i 2 0 1");

    return app.exec();
}
