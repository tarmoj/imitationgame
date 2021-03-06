#include "csengine.h"
#include <QDebug>


// NB! use DEFINES += USE_DOUBLE


CsEngine::CsEngine(char *csd)
{
    mStop=false;
    m_csd = csd;
    errorValue=0;
}


//CsEngine::~CsEngine()
//{
//	stpo();
//	join();
//	free cs;

//}



Csound *CsEngine::getCsound() {return &cs;}

void CsEngine::run()
{

    //if ( open(m_csd)) {
    if ( cs.Compile(m_csd)) {
		qDebug()<<"Could not open csound file "<<m_csd;
        return;
    }


	cs.Start();
	//CsoundPerformanceThread perfThread(&cs);
	//perfThread.Play();

    // kas siin üldse performance threadi vaja? vt. soundcarpet v CsdPlayerQt
/*
    while (!mStop  && perfThread.GetStatus() == 0 ) {
		usleep(10000);
    }
    qDebug()<<"Stopping thread";
    perfThread.Stop();
    perfThread.Join();
*/

	while(cs.PerformKsmps()==0 && mStop==false ); // this way cannot deal with channels

//	//free Csound object
	cs.Reset(); // is it correct?

    mStop=false; // luba uuesti käivitamine
}

void CsEngine::stop()
{
    // cs.Reset();  // ?kills Csound at all
    mStop = true;

}

QString CsEngine::getErrorString()  // probably not necessry
{
    return errorString;
}

int CsEngine::getErrorValue()
{
    return errorValue;
}


MYFLT CsEngine::getChannel(QString channel)
{
    //qDebug()<<"setChannel "<<channel<<" value: "<<value;
    return cs.GetChannel(channel.toLocal8Bit());
}

void CsEngine::compileOrc(QString code)
{

	//qDebug()<<"Code to compile: "<<code;
	QString message;
	errorValue =  cs.CompileOrc(code.toLocal8Bit());
	if ( errorValue )
		message = "Could not compile the code";
	else
		message = "OK";
	qDebug()<<message;

}

void CsEngine::restart()
{
    stop(); // sets mStop true
    while (mStop) // run sets mStop false again when perftrhead has joined
        usleep(100000);
    start();
}

void CsEngine::setChannel(QString channel, MYFLT value)
{
    //qDebug()<<"setChannel "<<channel<<" value: "<<value;
    cs.SetChannel(channel.toLocal8Bit(), value);
}

void CsEngine::csEvent(QString event_string)
{
	qDebug()<<"MESSAGE IN";
    cs.InputMessage(event_string.toLocal8Bit());
	qDebug()<<"CSOUND DONE";
}
