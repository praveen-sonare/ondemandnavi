#ifndef DBUS_SERVER_NAVIGATIONCORE_H
#define DBUS_SERVER_NAVIGATIONCORE_H

#include <QtDBus/QDBusConnection>
#include <QtCore/QObject>
#include <QtDBus/QtDBus>

#include "org.genivi.navigationcore_adaptor.h"
#include "org.genivi.navigationcore_interface.h"

class dbus_server_navigationcore : public QObject
{
	Q_OBJECT

    QString	m_pathName;
    QString	m_objName;
	QString m_serverName;
    QObject *m_object;

public:
    dbus_server_navigationcore(QObject *parent = 0);
    ~dbus_server_navigationcore();

public slots:
	// mapmatchedposition
    qPosition GetPosition(const qValuesToReturn &valuesToReturn);
    void PauseSimulation(uint sessionHandle);
    void SetSimulationMode(uint sessionHandle, bool activate);
	// routing
    void CalculateRoute(uint sessionHandle, uint routeHandle);
    void CancelRouteCalculation(uint sessionHandle, uint routeHandle);
    uint CreateRoute(uint sessionHandle);
    qRoutesList GetAllRoutes();
    void SetWaypoints(uint sessionHandle, uint routeHandle, bool startFromCurrentPosition, qWaypointsList waypointsList);
    // session
    qSessionsList GetAllSessions();

signals:
    void doPauseSimulation();

private:
	void setupDBus();
    void setupApi();

};

#endif // DBUS_SERVER_NAVIGATIONCORE_H

