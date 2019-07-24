#include"dbus_server.h"
#include <QDebug>

DBus_Server::DBus_Server(QObject *parent) :
  m_serverName("naviapi"),
  m_pathName("org.agl.naviapi"),
  m_objName("/org/agl/naviapi")
{
    initDBus();
    initAPIs(parent);
}

DBus_Server::~DBus_Server(){
    QDBusConnection::sessionBus().unregisterObject(m_objName);
    QDBusConnection::sessionBus().unregisterService(m_pathName);
}

void DBus_Server::initDBus(){

    new NaviapiAdaptor(this);

    if (!QDBusConnection::sessionBus().registerService(m_pathName))
        qDebug() << m_serverName << "registerService() failed";

    if (!QDBusConnection::sessionBus().registerObject(m_objName, this))
        qDebug() << m_serverName << "registerObject() failed";

    QDBusConnection	sessionBus = QDBusConnection::connectToBus(QDBusConnection::SessionBus, m_serverName);
    if (!sessionBus.isConnected()) {
        qDebug() << m_serverName << "connectToBus() failed";
    }

    //for receive dbus signal
    org::agl::naviapi *mInterface;
    mInterface = new org::agl::naviapi(QString(),QString(),QDBusConnection::sessionBus(),this);
    if (!connect(mInterface,SIGNAL(getRouteInfo()),this,SLOT(getRouteInfoSlot()))){
        qDebug() << m_serverName << "sessionBus.connect():getRouteInfoSlot failed";
    }

}

void DBus_Server::initAPIs(QObject *parent){

    if(!QObject::connect(this,SIGNAL(doGetRouteInfo()),
                         parent,SLOT(doGetRouteInfoSlot()))) {
        qDebug() << m_serverName << "cppSIGNAL:doGetRouteInfo to qmlSLOT:doGetRouteInfoSlot connect is failed";
    }

    if(!QObject::connect(parent,SIGNAL(qmlSignalRouteInfo(double,double,double,double)),
                         this,SLOT(sendSignalRouteInfo(double,double,double,double)))) {
        qDebug() << m_serverName << "qmlSIGNAL:qmlSignalRouteInfo to cppSLOT:sendSignalRouteInfo connect is failed";
    }

    if(!QObject::connect(parent,SIGNAL(qmlSignalPosInfo(double,double,double,double)),
                         this,SLOT(sendSignalPosInfo(double,double,double,double)))) {
        qDebug() << m_serverName << "qmlSIGNAL:qmlSignalPosInfo to cppSLOT:sendSignalPosInfo connect is failed";
    }

    if(!QObject::connect(parent,SIGNAL(qmlSignalStopDemo()),
                         this,SLOT(sendSignalStopDemo()))) {
        qDebug() << m_serverName << "qmlSIGNAL:qmlSignalStopDemo to cppSLOT:sendSignalStopDemo connect is failed";
    }

    if(!QObject::connect(parent,SIGNAL(qmlSignalArrvied()),
                         this,SLOT(sendSignalArrvied()))) {
        qDebug() << m_serverName << "qmlSIGNAL:qmlSignalArrvied to cppSLOT:sendSignalArrvied connect is failed";
    }
}

void DBus_Server::getRouteInfoSlot(){
    qDebug() << "call getRouteInfoSlot ";
    emit doGetRouteInfo();
    return;
}

// Signal
void DBus_Server::sendSignalRouteInfo(double srt_lat, double srt_lon, double end_lat, double end_lon){
    qDebug() << "call sendSignalRouteInfo ";
    QDBusMessage message = QDBusMessage::createSignal(m_objName,
                                                     org::agl::naviapi::staticInterfaceName(),
                                                     "signalRouteInfo");
    message << srt_lat << srt_lon << end_lat << end_lon;
    QDBusConnection::sessionBus().send(message);
    return;
}

void DBus_Server::sendSignalPosInfo(double lat, double lon, double drc, double dst){
    QDBusMessage message = QDBusMessage::createSignal(m_objName,
                                                     org::agl::naviapi::staticInterfaceName(),
                                                     "signalPosInfo");
    message << lat << lon << drc << dst;
    QDBusConnection::sessionBus().send(message);
    return;
}

void DBus_Server::sendSignalStopDemo(){
    qDebug() << "call sendSignalStopDemo ";
    QDBusMessage message = QDBusMessage::createSignal(m_objName,
                                                     org::agl::naviapi::staticInterfaceName(),
                                                     "signalStopDemo");
    QDBusConnection::sessionBus().send(message);
    return;
}

void DBus_Server::sendSignalArrvied(){
    qDebug() << "call sendSignalArrvied ";
    QDBusMessage message = QDBusMessage::createSignal(m_objName,
                                                     org::agl::naviapi::staticInterfaceName(),
                                                     "signalArrvied");
    QDBusConnection::sessionBus().send(message);
    return;
}
// Method
