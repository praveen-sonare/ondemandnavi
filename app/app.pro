TARGET = navigation
QT = quick qml
PKGCONFIG += qtappfw-navigation

QT += positioning
QT += core
CONFIG += c++11 link_pkgconfig

CONFIG(release, debug|release) {
    QMAKE_POST_LINK = $(STRIP) --strip-unneeded $(TARGET)
}

HEADERS += \
    markermodel.h \
    guidance_module.h \
    file_operation.h

SOURCES += main.cpp \
    file_operation.cpp

RESOURCES += \
    navigation.qrc \
    images/images.qrc

include(app.pri)

DISTFILES +=


