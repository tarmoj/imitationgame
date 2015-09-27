TEMPLATE = app

QT += qml quick widgets network

SOURCES += main.cpp \
    csengine.cpp

RESOURCES += qml.qrc

CONFIG += c++11

# Additional import path used to resolve QML modules in Qt Creator's code model
QML_IMPORT_PATH =

# Default rules for deployment.
include(deployment.pri)

INCLUDEPATH += /usr/local/include/csound/ /home/tarmo/src/csound-android-6.05.0/CsoundAndroid/jni/

HEADERS += \
    csengine.h

DISTFILES += \
    android/AndroidManifest.xml \
    android/res/values/libs.xml \
    android/build.gradle

ANDROID_PACKAGE_SOURCE_DIR = $$PWD/android

android {

	LIBS += -L/home/tarmo/src/csound-android-6.05.0/CsoundAndroid/libs/armeabi-v7a/ -lcsoundandroid -lsndfile

#HEADERS += AndroidCsound.hpp # this is probably not necessary

DEFINES += FOR_ADNROID



} else: win32|unix {

LIBS += -lcsound64 -lsndfile

DEFINES += FOR_DESKTOP

}

contains(ANDROID_TARGET_ARCH,armeabi-v7a) {
    ANDROID_EXTRA_LIBS = \
		$$PWD/../../../../src/csound-android-6.05.0/CsoundAndroid/libs/armeabi-v7a/libsndfile.so \
		$$PWD/../../../../src/csound-android-6.05.0/CsoundAndroid/libs/armeabi-v7a/libcsoundandroid.so
}
