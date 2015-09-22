#ifndef WSSERVER_H
#define WSSERVER_H
#include "csengine.h"

#include <QObject>
#include <QtCore/QList>
#include <QtCore/QByteArray>
#include <QtCore/QHash>
#include <QHostAddress>
#include <QUdpSocket>

//test
#include <lo/lo.h>

QT_FORWARD_DECLARE_CLASS(QWebSocketServer)
QT_FORWARD_DECLARE_CLASS(QWebSocket)


// COMMANDS sent FROM javascript or android client
#define NEWSTEP 100
#define NEWNOISE 101
#define NEWVIBRATO 102
#define NEWPAN 103
#define NOTEON 11  // syntax of array: [11,<step>,<noise>, {other parameters}]
#define NOTEOFF 10
#define MAXDURATION 10
#define FLUTEISNTRUMENT 10 // instrument number of the flute instrument in csd


class WsServer : public QObject
{
    Q_OBJECT
public:
    explicit WsServer(quint16 port, QObject *parent = NULL);
    ~WsServer();

	void sendMessage(QWebSocket *socket, QString message);
	void setVolume(double volume);

Q_SIGNALS:
    void closed();
    void newConnection(int connectionsCount);
    void newEvent(QString eventString);


private Q_SLOTS:
    void onNewConnection();
    void processTextMessage(QString message);
	void processBinaryMessage(QByteArray message);
    void socketDisconnected();
	void readUdp();


private:
    QWebSocketServer *m_pWebSocketServer;
    QList<QWebSocket *> m_clients;
	QList <QHostAddress> peerAdresses;
	CsEngine *cs;
	QUdpSocket *udpSocket;
	lo_address target;

};



#endif // WSSERVER_H
