#include "csengine.h"
#include <QDebug>
#include <QTemporaryFile>


// NB! use DEFINES += USE_DOUBLE


CsEngine::CsEngine()
{
#ifdef FOR_ADNROID
    cs.setOpenSlCallbacks(); // for android audio to work
#endif
    mStop=false;
    cs.SetOption("-odac");
    cs.SetOption("-d");

}

void CsEngine::run() {

//	QString orc =R"(
//			sr = 44100
//			nchnls = 2
//			0dbfs = 1
//			ksmps = 32

//			schedule 1,0,2

//			instr test
//				prints "INSTR TEST"
//				kval chnget "value"
//				;printk2 kval
//				kfreq = 300+400*kval
//				asig vco2 linen(0.5,0.05,p3,0.1), kfreq
//				asig moogvcf asig, 400+600*(1-kval), 0.3+(1-kval)/2
//				outs asig, asig
//			endin)";
//	if (!cs.CompileOrc(orc.toLocal8Bit())) {
//			qDebug()<<"STARTING CSOUND";
//			cs.Start();
//			cs.Perform();
//	}

	if (!open(":/test.csd")) {
		cs.Start();
		cs.Perform();
		while(cs.PerformKsmps()==0 && mStop==false ); // this way cannot deal with channels

	//	//free Csound object
		//cs.Reset(); // is it correct or necessary?

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

    if (!cs.Compile( tempFile->fileName().toLocal8Bit().data()) ){
		//cs.Start();
		//cs.Perform();
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
	cs.SetChannel(channel.toLocal8Bit(), value); // does not work
	//QString command = "chnset "+ QString::number(value) + ",\""+channel+" \"\n";
	//cs.EvalCode(command.toLocal8Bit()); // bad workaround to set channel values...
}

void CsEngine::csEvent(const QString &event_string)
{
	qDebug()<<"CSEVENT";
	QString evalLine = "scoreline_i + {{ " + event_string + "}}";
	//cs.InputMessage("i 1 0 1"); // DOES NOT WORK ON ANDROID???
	//cs.InputMessage(event_string.toLocal8Bit());
	cs.EvalCode(evalLine.toLocal8Bit());
}

void CsEngine::compileOrc(const QString &code)
{
	cs.CompileOrc(code.toLocal8Bit());
}
