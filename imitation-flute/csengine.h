#ifndef CSENGINE_H
#define CSENGINE_H

#include <QThread>
#ifdef Q_OS_ANDROID
    #include "AndroidCsound.hpp"
#else
    #include <csound.hpp>
#endif


class CsEngine : public QThread
{
    Q_OBJECT
private:
    bool mStop;
#ifdef Q_OS_ANDROID
    AndroidCsound cs;
#else
    Csound cs;
#endif

public:
    explicit CsEngine();
	//~CsEngine();
    void run();
    int open(QString csd);
    Q_INVOKABLE void stop();
    Q_INVOKABLE void setChannel(const QString &channel, MYFLT value);
    Q_INVOKABLE void csEvent(const QString &event_string);
	Q_INVOKABLE void compileOrc(const QString &code);
	//Q_INVOKABLE double getChannel(const char *channel);

};

#endif // CSENGINE_H
