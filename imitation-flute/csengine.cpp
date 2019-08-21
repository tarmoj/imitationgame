#include "csengine.h"
#include <QDebug>
#include <QTemporaryFile>
#include <QCoreApplication>


// NB! use DEFINES += USE_DOUBLE


CsEngine::CsEngine(QObject *parent) : QObject(parent)
{
#ifdef Q_OS_ANDROID
	cs = new AndroidCsound();
	cs->setOpenSlCallbacks(); // for android audio to work
# else
	cs = new Csound();
#endif
    mStop=false;
	cs->SetOption("-odac");
	cs->SetOption("-d");

}

CsEngine::~CsEngine()
{
	stop(); // this is mess
}

void CsEngine::play() {

	if (!open(":/test.csd")) {
		cs->Start();
		cs->Perform();
		while(cs->PerformKsmps()==0 && mStop==false ) {
			QCoreApplication::processEvents(); // probably bad solution but works. otherwise other slots will never be called
		}

	//	//free Csound object
		//cs->Reset(); // is it correct or necessary?
		cs->Stop();
		//delete cs;
		mStop = false;

		qDebug()<<"END PERFORMANCE";
		mStop=false; // luba uuesti käivitamine
	}
}

int CsEngine::open(QString csd)
{

    QTemporaryFile *tempFile = QTemporaryFile::createNativeFile(csd); //TODO: checi if not 0
//    if (tempFile.open()) {
//        tempFile.write(file.readAll());
//    }

    qDebug()<<tempFile->readAll();

	if (!cs->Compile( tempFile->fileName().toLocal8Bit().data()) ){
        return 0;
    } else {
        qDebug()<<"Could not open csound file: "<<csd;
        return -1;
    }
}

void CsEngine::stop()
{
	mStop = true;
}


void CsEngine::setChannel(const QString &channel, MYFLT value)
{
	qDebug()<<"setChannel "<<channel<<" value: "<<value;
	cs->SetChannel(channel.toLocal8Bit(), value); // does not work
	//QString command = "chnset "+ QString::number(value) + ",\""+channel+" \"\n";
	//cs->EvalCode(command.toLocal8Bit()); // bad workaround to set channel values...
}

void CsEngine::csEvent(const QString &event_string)
{
	qDebug()<<"CSEVENT";
	QString evalLine = "scoreline_i + {{ " + event_string + "}}";
	//cs->InputMessage("i 1 0 1"); // DOES NOT WORK ON ANDROID???
	cs->InputMessage(event_string.toLocal8Bit());
	//cs->EvalCode(evalLine.toLocal8Bit());
}

void CsEngine::compileOrc(const QString &code)
{
	cs->CompileOrc(code.toLocal8Bit());
}
