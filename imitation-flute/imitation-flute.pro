TEMPLATE = app

QT += qml quick widgets websockets

SOURCES += main.cpp \
    csengine.cpp

RESOURCES += qml.qrc

CONFIG += c++11


# Additional import path used to resolve QML modules in Qt Creator's code model
QML_IMPORT_PATH =

# Default rules for deployment.
include(deployment.pri)

HEADERS += \
    csengine.h

INCLUDEPATH += /usr/local/include/csound/


android {
  QT += androidextras
  INCLUDEPATH += /home/tarmo/src/csound6-git/Android/CsoundAndroid/jni/	 #TODO: should have an extra varaible, not hardcoded personal library
  HEADERS += AndroidCsound.hpp
  LIBS +=  -L/home/tarmo/src/csound-android-6.12.0/CsoundForAndroid/CsoundAndroid/src/main/jniLibs/armeabi-v7a/ -lcsoundandroid -lsndfile -lc++_shared -loboe
}

linux:!android {
  LIBS += -lcsound64 -lsndfile
}

DISTFILES += \
    android/AndroidManifest.xml \
    android/res/values/libs.xml \
    android/build.gradle \
    android/AndroidManifest.xml \
    android/gradle/wrapper/gradle-wrapper.jar \
    android/gradlew \
    android/res/values/libs.xml \
    android/build.gradle \
    android/gradle/wrapper/gradle-wrapper.properties \
    android/gradlew.bat

ANDROID_PACKAGE_SOURCE_DIR = $$PWD/android

contains(ANDROID_TARGET_ARCH,armeabi-v7a) {
    ANDROID_EXTRA_LIBS = \
        /home/tarmo/tarmo/csound/imitation-game/imitation-flute/../../../../src/csound-android-6.12.0/CsoundForAndroid/CsoundAndroid/src/main/jniLibs/armeabi-v7a/libc++_shared.so \
        /home/tarmo/tarmo/csound/imitation-game/imitation-flute/../../../../src/csound-android-6.12.0/CsoundForAndroid/CsoundAndroid/src/main/jniLibs/armeabi-v7a/libcsoundandroid.so \
        /home/tarmo/tarmo/csound/imitation-game/imitation-flute/../../../../src/csound-android-6.12.0/CsoundForAndroid/CsoundAndroid/src/main/jniLibs/armeabi-v7a/libsndfile.so \
        $$PWD/../../../../src/csound-android-6.12.0/CsoundForAndroid/CsoundAndroid/src/main/jniLibs/armeabi-v7a/liboboe.so
}

