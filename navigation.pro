CONFIG += ordered
TEMPLATE = subdirs
SUBDIRS = dbus_interface \
          app package

package.depends += dbus_interface \
                   app
