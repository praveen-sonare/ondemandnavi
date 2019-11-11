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

#include <qlibwindowmanager.h>
#include <qlibhomescreen.h>
#include <string>
#include <QtCore/QDebug>
#include <QtCore/QCommandLineParser>
#include <QtCore/QUrlQuery>
#include <QtCore/QSettings>
#include <QtGui/QGuiApplication>
#include <QtQml/QQmlApplicationEngine>
#include <QtQml/QQmlContext>
#include <QtQuickControls2/QQuickStyle>
#include <QQuickWindow>
#include <navigation.h>
#include "markermodel.h"
#include "guidance_module.h"
#include "file_operation.h"

int main(int argc, char *argv[])
{
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

	// Load qml
	QQmlApplicationEngine engine;
	QQmlContext *context = engine.rootContext();

	File_Operation file;
	context->setContextProperty("fileOperation", &file);

	QStringList positionalArguments = parser.positionalArguments();
	if (positionalArguments.length() == 2) {
		port = positionalArguments.takeFirst().toInt();
		token = positionalArguments.takeFirst();
		QUrl bindingAddress;
		bindingAddress.setScheme(QStringLiteral("ws"));
		bindingAddress.setHost(QStringLiteral("localhost"));
		bindingAddress.setPort(port);
		bindingAddress.setPath(QStringLiteral("/api"));
		QUrlQuery query;
		query.addQueryItem(QStringLiteral("token"), token);
		bindingAddress.setQuery(query);

		Navigation *navigation = new Navigation(bindingAddress, context);
		context->setContextProperty("navigation", navigation);
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

	MarkerModel model;
	context->setContextProperty("markerModel", &model);

	Guidance_Module guidance;
	context->setContextProperty("guidanceModule", &guidance);

	engine.load(QUrl(QStringLiteral("qrc:/navigation.qml")));
 	QObject *root = engine.rootObjects().first();
	QQuickWindow *window = qobject_cast<QQuickWindow *>(root);
	QObject::connect(window, SIGNAL(frameSwapped()), qwmHandler, SLOT(slotActivateSurface()));

	return app.exec();
}

