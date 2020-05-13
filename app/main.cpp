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

	app.setDesktopFileName(graphic_role);

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
	MarkerModel model;
	context->setContextProperty("markerModel", &model);

	Guidance_Module guidance;
	context->setContextProperty("guidanceModule", &guidance);

	engine.load(QUrl(QStringLiteral("qrc:/navigation.qml")));

	return app.exec();
}

