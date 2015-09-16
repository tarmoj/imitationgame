#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "udpsender.h"

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);

	UdpSender udpSender;

    QQmlApplicationEngine engine;
	//bind object before load
	engine.rootContext()->setContextProperty("udpSender", &udpSender); // forward c++ object that can be reached form qml by object name "udpSender" NB! include <QQmlContext>

    engine.load(QUrl(QStringLiteral("qrc:/main.qml")));

	//test
//	QByteArray data;
//	data.append(1);data.append(3);
//	udpSender.sendData(data);


    return app.exec();
}
