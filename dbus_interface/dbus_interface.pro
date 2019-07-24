QT += dbus
TARGET = dbus_interface
TEMPLATE = lib
CONFIG += staticlib

SOURCES +=
HEADERS += \
    dbus_types.h

XMLSOURCES = \
    org.genivi.navigationcore.xml \
    org.agl.naviapi.xml

gen_adaptor_cpp.input = XMLSOURCES
gen_adaptor_cpp.commands = \
    qdbusxml2cpp -i $$PWD/dbus_types.h -m -a ${QMAKE_FILE_IN_BASE}_adaptor ${QMAKE_FILE_IN}; \
    moc $$OUT_PWD/${QMAKE_FILE_IN_BASE}_adaptor.h -o $$OUT_PWD/${QMAKE_FILE_IN_BASE}_adaptor.moc
gen_adaptor_cpp.output = ${QMAKE_FILE_IN_BASE}_adaptor.cpp
gen_adaptor_cpp.variable_out = SOURCES
gen_adaptor_cpp.clean = ${QMAKE_FILE_IN_BASE}_adaptor.cpp

gen_adaptor_h.input = XMLSOURCES
gen_adaptor_h.commands = @echo Fake making the header for ${QMAKE_FILE_IN}
gen_adaptor_h.depends = ${QMAKE_FILE_IN_BASE}_adaptor.cpp
gen_adaptor_h.output = ${QMAKE_FILE_IN_BASE}_adaptor.h
gen_adaptor_h.clean = ${QMAKE_FILE_IN_BASE}_adaptor.h

gen_interface_cpp.input = XMLSOURCES
gen_interface_cpp.commands = \
    qdbusxml2cpp -i $$PWD/dbus_types.h -m -p ${QMAKE_FILE_IN_BASE}_interface ${QMAKE_FILE_IN}; \
    moc $$OUT_PWD/${QMAKE_FILE_IN_BASE}_interface.h -o $$OUT_PWD/${QMAKE_FILE_IN_BASE}_interface.moc
gen_interface_cpp.output = ${QMAKE_FILE_IN_BASE}_interface.cpp
gen_interface_cpp.variable_out = SOURCES
gen_interface_cpp.clean = ${QMAKE_FILE_IN_BASE}_interface.cpp

gen_interface_h.input = XMLSOURCES
gen_interface_h.commands = @echo Fake making the header for ${QMAKE_FILE_IN}
gen_interface_h.depends = ${QMAKE_FILE_IN_BASE}_interface.cpp
gen_interface_h.output = ${QMAKE_FILE_IN_BASE}_interface.h
gen_interface_h.clean = ${QMAKE_FILE_IN_BASE}_interface.h

QMAKE_EXTRA_COMPILERS += gen_adaptor_cpp gen_adaptor_h gen_interface_cpp gen_interface_h

DISTFILES +=
