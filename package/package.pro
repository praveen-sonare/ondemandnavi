TEMPLATE = aux

scripts.path = /usr/bin
scripts.files += $$_PRO_FILE_PWD_/flite $$_PRO_FILE_PWD_/jtalk
scripts.CONFIG = executable

icon.path = /usr/share/icons/hicolor/scalable
icon.files += $$_PRO_FILE_PWD_/navigation.svg
icon.CONFIG = no_check_exist

desktop.path = /usr/share/applications
desktop.files = $$_PRO_FILE_PWD_/navigation.desktop
desktop.CONFIG = no_check_exist

INSTALLS += scripts desktop icon
