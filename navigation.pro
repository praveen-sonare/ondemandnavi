CONFIG += ordered
TEMPLATE = subdirs
SUBDIRS = app package

package.depends += app
