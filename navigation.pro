CONFIG += ordered
TEMPLATE = subdirs
SUBDIRS = dbus_interface \
          app package

equals(DEFINES, "DESKTOP"){
    SUBDIRS -= package
}

package.depends += dbus_interface \
                   app
