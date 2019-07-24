#include "dbus_server_navigationcore.h"
#include <QDebug>
#include <QDBusVariant>
#include <QDBusConnectionInterface>
#include <QGeoCoordinate>

dbus_server_navigationcore::dbus_server_navigationcore(QObject *parent) :
    m_pathName("org.agl.naviapi"),
    m_objName("/org/genivi/navicore"),
    m_serverName("mapmatchedposition"),
    m_object(parent)
{
	setupDBus();
    setupApi();
}

dbus_server_navigationcore::~dbus_server_navigationcore(){
    QDBusConnection::sessionBus().unregisterObject(m_objName);
}

void dbus_server_navigationcore::setupDBus()
{
    qDBusRegisterMetaType<qPositionPairElm>();
    qDBusRegisterMetaType<qPosition>();
    qDBusRegisterMetaType<qValuesToReturn>();
    qDBusRegisterMetaType<qWaypointsList>();
    qDBusRegisterMetaType<qSessionsListElm>();
    qDBusRegisterMetaType<qSessionsList>();


    if (!QDBusConnection::sessionBus().registerService(m_pathName))
        qDebug() << m_serverName << "registerService() failed";

    if (!QDBusConnection::sessionBus().registerObject(m_objName, this))
        qDebug() << m_serverName << "registerObject() failed";

    new MapMatchedPositionAdaptor(this);
    new RoutingAdaptor(this);
    new SessionAdaptor(this);
}

void dbus_server_navigationcore::setupApi(){

    if(!QObject::connect(this,SIGNAL(doPauseSimulation()),
                         m_object,SLOT(doPauseSimulationSlot()))) {
        qDebug() << m_serverName << "cppSIGNAL:doPauseSimulation to qmlSLOT:doPauseSimulationSlot connect is failed";
    }

}

// Method
qPosition dbus_server_navigationcore::GetPosition(const qValuesToReturn &valuesToReturn){
    double Latitude =0;
    double Longitude =0;
    qPosition result;
    qPositionPairElm Pair_1,Pair_2;
    QVariant m_Variant = m_object->property("currentpostion");
    if(m_Variant.canConvert<QGeoCoordinate>()){
            QGeoCoordinate coordinate = m_Variant.value<QGeoCoordinate>();
            Latitude = coordinate.latitude();
            Longitude = coordinate.longitude();
    }

    for(int i = 0; i < valuesToReturn.size(); i++){
        switch(valuesToReturn[i]){
            case 160:
                Pair_1.key = 160;
                Pair_1.value = QDBusVariant(Latitude);
                result.insert(160,Pair_1);
                break;
            case 161:
                Pair_2.key = 161;
                Pair_2.value = QDBusVariant(Longitude);
                result.insert(161,Pair_2);
                break;
            default:
                break;
        }
    }
    return result;
}

void dbus_server_navigationcore::PauseSimulation(uint sessionHandle){
    qDebug() << m_serverName << sessionHandle << "call PauseSimulation";
    emit doPauseSimulation();
    return;
}

void dbus_server_navigationcore::SetSimulationMode(uint sessionHandle, bool activate){
    qDebug() << m_serverName << sessionHandle << activate << "call SetSimulationMode";
    return;
}

void dbus_server_navigationcore::CalculateRoute(uint sessionHandle, uint routeHandle){
    qDebug() << m_objName << sessionHandle << routeHandle << "call dbus_server_routing";
    return;
}

void dbus_server_navigationcore::CancelRouteCalculation(uint sessionHandle, uint routeHandle){
    qDebug() << m_objName << sessionHandle << routeHandle << "call CancelRouteCalculation";
    return;
}

uint dbus_server_navigationcore::CreateRoute(uint sessionHandle){
    qDebug() << m_objName << sessionHandle << "call CreateRoute";
    QVariant returnvalue;
    uint result;

    // call qml function
    if(!QMetaObject::invokeMethod(m_object,"doGetAllRoutesSlot",Q_RETURN_ARG(QVariant, returnvalue)))
        qDebug() << m_objName << "invokeMethod doGetAllRoutesSlot failed.";

    // we only manage 1 route for now
    result = (uint)returnvalue.toInt();
    return result;
}

qRoutesList dbus_server_navigationcore::GetAllRoutes(){
    qDebug() << m_objName << "call GetAllRoutes";
    QVariant returnvalue;
    qRoutesList result;

    // call qml function
    if(!QMetaObject::invokeMethod(m_object,"doGetAllRoutesSlot",Q_RETURN_ARG(QVariant, returnvalue)))
        qDebug() << m_objName << "invokeMethod doGetAllRoutesSlot failed.";

    // we only manage 1 route for now
    int ret = returnvalue.toInt();
    if(ret == 1){
        result.append(ret);
    }
    return result;
}

void dbus_server_navigationcore::SetWaypoints(uint sessionHandle, uint routeHandle, bool startFromCurrentPosition, qWaypointsList waypointsList){
    qDebug() << m_objName << sessionHandle << routeHandle << startFromCurrentPosition << "call SetWaypoints";
    double Latitude =0;
    double Longitude =0;

    // analize waypointlist only manage 1 waypoint
    for(int i = 0; i < 1; i++){
        QMap<int32_t,qPositionPairElm>::const_iterator itr = waypointsList[i].constBegin();
        while(itr != waypointsList[i].constEnd()){
            switch(itr.key()){
                case 160:
                    Latitude = itr.value().value.variant().toDouble();
                    itr++;
                    break;
                case 161:
                    Longitude = itr.value().value.variant().toDouble();
                    itr++;
                    break;
                default:
                    break;
            }
        }
    }

    // call qml function
    if(!QMetaObject::invokeMethod(m_object,"doSetWaypointsSlot",Q_ARG(QVariant, Latitude),Q_ARG(QVariant, Longitude),Q_ARG(QVariant, startFromCurrentPosition)))
        qDebug() << m_objName << "invokeMethod doSetWaypointsSlot failed.";

    return;
}

qSessionsList dbus_server_navigationcore::GetAllSessions(){
    qDebug() << m_objName << "call GetAllSessions";
    qSessionsList result;
    qSessionsListElm element;
    element.key = 1;
    element.value = "dummy";
    result.append(element);
    return result;
}

