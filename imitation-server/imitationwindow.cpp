#include "imitationwindow.h"
#include "ui_imitationwindow.h"

ImitationWindow::ImitationWindow(QWidget *parent) :
	QMainWindow(parent),
	ui(new Ui::ImitationWindow)
{
	ui->setupUi(this);
	wsServer = new WsServer(22022);
//	cs = new CsEngine("../imitation-game.csd");
//	cs->start();
//	cs->setChannel("volume",(MYFLT)ui->volumeSlider->value()/100); // send initial value
	connect(wsServer, SIGNAL(newConnection(int)), this, SLOT(setClientsCount(int)));
//	connect(wsServer, SIGNAL(newEvent(QString)),cs,SLOT(csEvent(QString))  );
}

ImitationWindow::~ImitationWindow()
{
	delete ui;
}

void ImitationWindow::setClientsCount(int clientsCount)
{
	ui->clientsCountLabel->setText(QString::number(clientsCount));
}


void ImitationWindow::on_volumeSlider_valueChanged(int value)
{
	//cs->setChannel("volume",(MYFLT) value/100.0);
}
