#include "wsserver.h"
#include "QtWebSockets/qwebsocketserver.h"
#include "QtWebSockets/qwebsocket.h"
#include <QtCore/QDebug>
#include <QDir>

//TEST for sending OSC
#include <lo/lo.h>


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

	// UDP server to receive messages from android apps
	udpSocket = new QUdpSocket(this);
	udpSocket->bind(QHostAddress::Any, port+1);
	qDebug()<<"Listening for UDP messages on port "<<port+1;
	connect(udpSocket, SIGNAL(readyRead()), this, SLOT(readUdp()));

	//TEST
	target = lo_address_new("localhost", "8008") ;
}



WsServer::~WsServer()
{
    m_pWebSocketServer->close();
    qDeleteAll(m_clients.begin(), m_clients.end());
}

void WsServer::readUdp()
{
	QByteArray message;
	QHostAddress senderAddress;
	quint16 senderPort;

	message.resize(udpSocket->pendingDatagramSize());

	udpSocket->readDatagram(message.data(), message.size(), &senderAddress, &senderPort);

	if (!peerAdresses.contains(senderAddress)) {
		qDebug()<<"New peer:"<< senderAddress.toString();
		peerAdresses.append(senderAddress);
	}
	int player = peerAdresses.indexOf(senderAddress);
	if (message[0]==NOTEON) {
		QString command;
		float instrno = FLUTEISNTRUMENT+(player+1)/100.0; // player+1 since first player would be .0
		command.sprintf("i %.2f 0 -1 %d", instrno, player ) ;
		qDebug()<<"NOTEON: "<<command;
		cs->csEvent(command);

		lo_send(target, "/event", "iif", NOTEON,player, instrno);
	}
	else if (message[0]==NOTEOFF) {
		QString command;
		float instrno = -(FLUTEISNTRUMENT+(player+1)/100.0); // player+1 since first player would be .0
		command.sprintf("i %.2f 0 0.1", instrno) ;
		qDebug()<<"NOTEOFF: "<<command;
		cs->csEvent(command);

		lo_send(target, "/event", "iif", NOTEOFF,player, instrno); // since csEvent has sometimes lag
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
	else if (message[0]==NEWNOISE) {
		MYFLT noiseLevel = (MYFLT)message[1]/message[2]; // convert to 0..1; array sent as NEWNOISE, noiselevel, MAXLEVEL
		qDebug()<<"Player "<<player<<", nw noisevel: "<<noiseLevel;
		cs->setChannel("noise"+QString::number(player),noiseLevel);
	}

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



void WsServer::processTextMessage(QString message) // message must be an array of numbers (8bit), separated with colons
{
    QWebSocket *pClient = qobject_cast<QWebSocket *>(sender());
    if (!pClient) {
        return;
    }
    qDebug()<<message;
	QByteArray data;
	bool allFine = true;
	quint8 byte = 0;
	QStringList messageParts = message.split(",");
	foreach (QString number, messageParts) {
		bool ok;
		byte = (quint8)number.toUShort(&ok);
		qDebug()<<byte;
		if (ok)
			data.append(byte);
		else {
			qDebug()<<"Conversion failed!";
			allFine = false;
		}

	}
	if (allFine)
		processBinaryMessage(data);

}


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
			if (message.length()>2 && message[1]==100) { // test call, take player from array
				player = message[2];
			}
			float instrno = FLUTEISNTRUMENT+(player+1)/100.0; // player+1 since first player would be .0

			// float pan = message[1]/100.0; // pan from channel
			command.sprintf("i %.2f 0 %d %d", instrno, -1,player ) ;
			qDebug()<<"NOTEON: "<<command;
			//cs->csEvent(command); // lag!
			lo_send(target, "/event", "iif", NOTEON,player, instrno); // since csEvent has sometimes lag
		}
		else if (message[0]==NOTEOFF) {
			if (message.length()>2 && message[1]==100) { // test call, take player from array
				player = message[2];
			}
			QString command;
			float instrno = -(FLUTEISNTRUMENT+(player+1)/100.0); // player+1 since first player would be .0
			command.sprintf("i %.2f 0 0.1", instrno) ;
			qDebug()<<"NOTEOFF: "<<command;
			//cs->csEvent(command); // lag!
			lo_send(target, "/event", "iif", NOTEOFF,player, instrno); // since csEvent has sometimes lag
		}

		else if (message[0]==NEWSTEP) {
			if (message.length()>3 && message[2]==100) { // test call, take player from array
				player = message[3];
			}
			qDebug()<<"Player "<<player<<", new step: "<<(MYFLT)message[1];
			cs->setChannel("step"+QString::number(player),(MYFLT)message[1]);
		}
		else if (message[0]==NEWNOISE) {
			if (message.length()>4 && message[3]==100) { // test call, take player from array
				player = message[4];
			}
			MYFLT noiseLevel = (MYFLT)message[1]/message[2]; // convert to 0..1; array sent as NEWNOISE, noiselevel, MAXLEVEL
			qDebug()<<"Player "<<player<<", new noisevel: "<<noiseLevel;
			cs->setChannel("noise"+QString::number(player),noiseLevel);
		}
		else if (message[0]==NEWVIBRATO) {
			MYFLT vibrato = (MYFLT)message[1]/10; // vibrato sent as 0..10
			qDebug()<<"Player "<<player<<", new vibrato level: "<<vibrato;
			cs->setChannel("vibrato"+QString::number(player),vibrato);
		}
		else if (message[0]==NEWPAN) {
			if (message.length()>3 && message[2]==100) { // test call, take player from array
				player = message[3];
			}
			MYFLT pan = (MYFLT)message[1]/10; // pan sent as 0..10
			qDebug()<<"Player "<<player<<", new pan: "<<pan;
			cs->setChannel("pan"+QString::number(player),pan);
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

void WsServer::setVolume(double volume)
{
	cs->setChannel("volume",(MYFLT)volume);
}

