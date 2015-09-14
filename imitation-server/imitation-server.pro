#-------------------------------------------------
#
# Project created by QtCreator 2015-03-27T17:29:00
#
#-------------------------------------------------

QT       += core gui websockets

greaterThan(QT_MAJOR_VERSION, 4): QT += widgets

TARGET = imitation-server
TEMPLATE = app

INCLUDEPATH += /usr/local/include/csound

SOURCES += main.cpp\
        imitationwindow.cpp \
    csengine.cpp \
    wsserver.cpp

HEADERS  += imitationwindow.h \
    csengine.h \
    wsserver.h

FORMS    += imitationwindow.ui

unix|win32: LIBS += -lcsnd6 -lcsound64
