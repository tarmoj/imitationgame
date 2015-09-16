#include "udpsender.h"
#include <QStringList>

UdpSender::UdpSender(QObject *parent, QHostAddress host, int port) : QObject(parent)
{
	mSocket = new QUdpSocket(this);
	mHost = host;
	mPort = port;
	//socket->bind(host, port);
}

UdpSender::~UdpSender()
{

}

void UdpSender::sendData(QByteArray data)
{
	qDebug()<<"sending"<<data.length()<<" bytes";
	mSocket->writeDatagram(data, mHost, mPort);
}

void UdpSender::sendNumbersInString(QString message)
{
	QByteArray data;
	QStringList numbers = message.split(",");
	foreach (QString number, numbers) {
		quint8 byte = (quint8)number.toInt();
		data.append(byte);
	}
	sendData(data);
}

