/*
 * Copyright (C) 2016 The Qt Company Ltd.
 * Copyright (C) 2019 Konsulko Group
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *	  http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#ifdef DESKTOP
#define USE_QTAGLEXTRAS		0
#define USE_QLIBWINDOWMANAGER	0
#else
#define USE_QTAGLEXTRAS		0
#define USE_QLIBWINDOWMANAGER	1
#endif

#if USE_QTAGLEXTRAS
#include <QtAGLExtras/AGLApplication>
#elif USE_QLIBWINDOWMANAGER
#include <qlibwindowmanager.h>
#include <qlibhomescreen.h>
#include <string>
#endif
#include <QtCore/QDebug>
#include <QtCore/QCommandLineParser>
#include <QtCore/QUrlQuery>
#include <QtCore/QSettings>
#include <QtGui/QGuiApplication>
#include <QtQml/QQmlApplicationEngine>
#include <QtQml/QQmlContext>
#include <QtQuickControls2/QQuickStyle>
#include <QQuickWindow>
#include <QtDBus/QDBusConnection>
#include "markermodel.h"
#include "dbus_server.h"
#include "dbus_server_navigationcore.h"
#include "guidance_module.h"
#include "file_operation.h"

int main(int argc, char *argv[])
{
	
	// for dbusIF
	if (!QDBusConnection::sessionBus().isConnected()) {
		qWarning("Cannot connect to the D-Bus session bus.\n"
			 "Please check your system settings and try again.\n");
		return 1;
	}
	
#if USE_QTAGLEXTRAS
	AGLApplication app(argc, argv);
	app.setApplicationName("navigation");
	app.setupApplicationRole("navigation");
 	app.load(QUrl(QStringLiteral("qrc:/navigation.qml")));
	
#elif USE_QLIBWINDOWMANAGER
	QGuiApplication app(argc, argv);
	QString graphic_role = QString("navigation");
	int port = 1700;
	QString token = "hello";
	QCoreApplication::setOrganizationDomain("LinuxFoundation");
	QCoreApplication::setOrganizationName("AutomotiveGradeLinux");
	QCoreApplication::setApplicationName(graphic_role);
	QCoreApplication::setApplicationVersion("0.1.0");
	QCommandLineParser parser;
	parser.addPositionalArgument("port", app.translate("main", "port for binding"));
	parser.addPositionalArgument("secret", app.translate("main", "secret for binding"));
	parser.addHelpOption();
	parser.addVersionOption();
	parser.process(app);
	QStringList positionalArguments = parser.positionalArguments();
	if (positionalArguments.length() == 2) {
		port = positionalArguments.takeFirst().toInt();
		token = positionalArguments.takeFirst();
	}
	fprintf(stderr, "[navigation] app_name: %s, port: %d, token: %s.\n",
		graphic_role.toStdString().c_str(),
		port,
		token.toStdString().c_str());

	// QLibWM
	QLibWindowmanager* qwmHandler = new QLibWindowmanager();
	int res;
	if((res = qwmHandler->init(port,token)) != 0){
		fprintf(stderr, "[navigation] init qlibwm err(%d)\n", res);
		return -1;
	}
	if((res = qwmHandler->requestSurface(graphic_role)) != 0) {
		fprintf(stderr, "[navigation] request surface err(%d)\n", res);
		return -1;
	}
	qwmHandler->set_event_handler(QLibWindowmanager::Event_SyncDraw,
				      [qwmHandler, &graphic_role](json_object *object) {
					      qwmHandler->endDraw(graphic_role);
				      });

	// QLibHS
	QLibHomeScreen* qhsHandler = new QLibHomeScreen();
	qhsHandler->init(port, token.toStdString().c_str());
	qhsHandler->set_event_handler(QLibHomeScreen::Event_ShowWindow,
				      [qwmHandler, &graphic_role](json_object *object){
					      qDebug("Surface %s got showWindow\n", graphic_role.toStdString().c_str());
					      qwmHandler->activateWindow(graphic_role);
				      });
	// Load qml
	QQmlApplicationEngine engine;

	MarkerModel model;
	engine.rootContext()->setContextProperty("markerModel", &model);

	Guidance_Module guidance;
	engine.rootContext()->setContextProperty("guidanceModule", &guidance);

	File_Operation file;
	engine.rootContext()->setContextProperty("fileOperation", &file);

	engine.load(QUrl(QStringLiteral("qrc:/navigation.qml")));
 	QObject *root = engine.rootObjects().first();
	QQuickWindow *window = qobject_cast<QQuickWindow *>(root);
	QObject::connect(window, SIGNAL(frameSwapped()), qwmHandler, SLOT(slotActivateSurface()));
	QObject *map = engine.rootObjects().first()->findChild<QObject*>("map");
	DBus_Server dbus(map);
	dbus_server_navigationcore dbus_navigationcore(map);

#else	// for only libwindowmanager
	QGuiApplication app(argc, argv);
	app.setApplicationName("navigation");

	// Load qml
	QQmlApplicationEngine engine;

	MarkerModel model;
	engine.rootContext()->setContextProperty("markerModel", &model);

	Guidance_Module guidance;
	engine.rootContext()->setContextProperty("guidanceModule", &guidance);

	File_Operation file;
	engine.rootContext()->setContextProperty("fileOperation", &file);

	engine.load(QUrl(QStringLiteral("qrc:/navigation.qml")));
	QObject *map = engine.rootObjects().first()->findChild<QObject*>("map");
	DBus_Server dbus(map);
	dbus_server_navigationcore dbus_navigationcore(map);

#endif
	
	return app.exec();
}

