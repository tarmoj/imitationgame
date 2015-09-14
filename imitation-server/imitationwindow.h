#ifndef IMITATIONWINDOW_H
#define IMITATIONWINDOW_H
//#include "csengine.h"
#include "wsserver.h"

#include <QMainWindow>

namespace Ui {
class ImitationWindow;
}

class ImitationWindow : public QMainWindow
{
	Q_OBJECT

public:
	explicit ImitationWindow(QWidget *parent = 0);
	~ImitationWindow();

public slots:
	void on_volumeSlider_valueChanged(int value);
	void setClientsCount(int clientsCount);

private:
	Ui::ImitationWindow *ui;
	//CsEngine *cs;
	WsServer *wsServer;

};

#endif // IMITATIONWINDOW_H
