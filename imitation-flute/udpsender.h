#ifndef UDPSENDER_H
#define UDPSENDER_H

#include <QObject>
#include <QHostAddress>
#include <QUdpSocket>

class UdpSender : public QObject
{
	Q_OBJECT
public:
	explicit UdpSender(QObject *parent = 0, QHostAddress host=QHostAddress::LocalHost, int port=22023);

	~UdpSender();
signals:

public slots:
	void sendData(QByteArray data);
	void sendNumbersInString(QString message); // separated with commas like '0, 23, 4, 123'
	void setHostAddress(QString address);

private:
	QUdpSocket * mSocket;
	QHostAddress mHost;
	int mPort;
};

#endif // UDPSENDER_H
