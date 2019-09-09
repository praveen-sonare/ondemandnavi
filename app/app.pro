TARGET = navigation
QT = quick qml aglextras
PKGCONFIG += qlibhomescreen qlibwindowmanager

equals(DEFINES, "DESKTOP"){
    QT -= aglextras
    PKGCONFIG -= qlibhomescreen qlibwindowmanager
}

QT += positioning
QT += dbus
QT += core
CONFIG += c++11 link_pkgconfig

HEADERS += \
    markermodel.h \
    dbus_server.h \
    guidance_module.h \
    file_operation.h \
    dbus_server_navigationcore.h

SOURCES += main.cpp \
    dbus_server.cpp \
    file_operation.cpp \
    dbus_server_navigationcore.cpp

RESOURCES += \
    navigation.qrc \
    images/images.qrc

ENABLE_OSM = $$ENABLE_OSM

equals(ENABLE_OSM, 1) {
    DEFINES += ENABLE_OSM
    RESOURCES += openstreetmaps/openstreetmaps.qrc
} else {
    RESOURCES += mapbox/mapbox.qrc
}

LIBS += $$OUT_PWD/../dbus_interface/libdbus_interface.a
INCLUDEPATH += $$OUT_PWD/../dbus_interface

include(app.pri)

DISTFILES +=

