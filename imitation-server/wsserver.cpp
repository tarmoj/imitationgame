#include "wsserver.h"
#include "QtWebSockets/qwebsocketserver.h"
#include "QtWebSockets/qwebsocket.h"
#include <QtCore/QDebug>
#include <QDir>


QT_USE_NAMESPACE



WsServer::WsServer(quint16 port, QObject *parent) :
    QObject(parent),
	m_pWebSocketServer(new QWebSocketServer(QStringLiteral("ImitationServer"),
                                            QWebSocketServer::NonSecureMode, this)),
    m_clients()
{
    if (m_pWebSocketServer->listen(QHostAddress::Any, port)) {
        qDebug() << "WsServer listening on port" << port;
        connect(m_pWebSocketServer, &QWebSocketServer::newConnection,
                this, &WsServer::onNewConnection);
        connect(m_pWebSocketServer, &QWebSocketServer::closed, this, &WsServer::closed);
    }
	cs = new CsEngine("../imitation-game.csd");
	cs->start();
	//TODO: set inital value from mainWindow UI
}



WsServer::~WsServer()
{
    m_pWebSocketServer->close();
    qDeleteAll(m_clients.begin(), m_clients.end());
}


void WsServer::onNewConnection()
{
    QWebSocket *pSocket = m_pWebSocketServer->nextPendingConnection();

    connect(pSocket, &QWebSocket::textMessageReceived, this, &WsServer::processTextMessage);
	connect(pSocket, &QWebSocket::binaryMessageReceived, this, &WsServer::processBinaryMessage);
    connect(pSocket, &QWebSocket::disconnected, this, &WsServer::socketDisconnected);

    m_clients << pSocket;

    emit newConnection(m_clients.count());
}



void WsServer::processTextMessage(QString message)
{
    QWebSocket *pClient = qobject_cast<QWebSocket *>(sender());
    if (!pClient) {
        return;
    }
    qDebug()<<message;

	QStringList messageParts = message.split(",");

//	if (messageParts[0]=="pause")
//		setPause();

}

// COMMANDS FROM javascript clientTODO: move to header /
#define NEWSTEP 0
#define NEWNOISE 1
#define NOTEON 11  // syntax of array: [11,<step>,<noise>, {other parameters}]
#define NOTEOFF 10
#define MAXDURATION 10
#define FLUTEISNTRUMENT 10 // instrument number of the flute instrument in csd

// Sea Cs Class Ws alt, window: wsSwever->setVolume


void WsServer::processBinaryMessage(QByteArray message)
{
	QWebSocket *pClient = qobject_cast<QWebSocket *>(sender());
	if (pClient) {
		//pClient->sendBinaryMessage(message);
		qDebug()<<"Binary message: "<<QString::number(message[0])<<QString::number(message[1]);
		QHostAddress senderAddress = pClient->peerAddress();
		if (!peerAdresses.contains(senderAddress)) {
			qDebug()<<"New peer:"<< senderAddress.toString();
			peerAdresses.append(senderAddress);
		}
		int player = peerAdresses.indexOf(senderAddress);
		if (message[0]==NOTEON) {
			QString command;
			float instrno = FLUTEISNTRUMENT+(player+1)/100.0; // player+1 since first player would be .0
			command.sprintf("i %.2f 0 %d %d\n", instrno, MAXDURATION,player ) ;
			qDebug()<<"NOTEON: "<<command;
			//cs->csEvent(command);
		}
		else if (message[0]==NOTEOFF) {
			QString command;
			float instrno = -(FLUTEISNTRUMENT+(player+1)/100.0); // player+1 since first player would be .0
			command.sprintf("i %.2f 0 0\n", instrno) ;
			qDebug()<<"NOTEOFF: "<<command;
			//cs->csEvent(command);
		}

		else if (message[0]==NEWSTEP) {
			qDebug()<<"Player "<<player<<", nw step: "<<(MYFLT)message[1];
			cs->setChannel("step"+QString::number(player),(MYFLT)message[1]);
		}
		else if (message[0]==NEWNOISE) {
			MYFLT noiseLevel = (MYFLT)message[1]/message[2]; // convert to 0..1; array sent as NEWNOISE, noiselevel, MAXLEVEL
			qDebug()<<"Player "<<player<<", nw noisevel: "<<noiseLevel;
			cs->setChannel("noise"+QString::number(player),noiseLevel);
		}

	}
}

void WsServer::socketDisconnected()
{
    QWebSocket *pClient = qobject_cast<QWebSocket *>(sender());
    if (pClient) {
        m_clients.removeAll(pClient);
        emit newConnection(m_clients.count());
        pClient->deleteLater();
	}
}




void WsServer::sendMessage(QWebSocket *socket, QString message )
{
    if (socket == 0)
    {
        return;
    }
    socket->sendTextMessage(message);

}

