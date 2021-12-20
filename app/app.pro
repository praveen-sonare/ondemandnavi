TEMPLATE = app
TARGET = navigation
QT = core qml quick positioning
CONFIG += c++11 link_pkgconfig

PKGCONFIG += qtappfw-navigation

HEADERS += \
    markermodel.h \
    guidance_module.h \
    file_operation.h

SOURCES += \
    main.cpp \
    file_operation.cpp

RESOURCES += \
    navigation.qrc \
    images/images.qrc

target.path = /usr/bin
target.files += $${OUT_PWD}/$${TARGET}
target.CONFIG = no_check_exist executable

INSTALLS += target




