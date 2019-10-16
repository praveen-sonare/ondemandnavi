#ifndef DBUS_SERVER_H
#define DBUS_SERVER_H
#include "org.agl.naviapi_interface.h"
#include "org.agl.naviapi_adaptor.h"
#include <QtQml/QQmlApplicationEngine>

class DBus_Server : public QObject{

    Q_OBJECT

    QString m_serverName;
    QString m_pathName;
    QString m_objName;

public:
    DBus_Server(QObject *parent = nullptr);
    ~DBus_Server();

private:
    void initDBus();
    void initAPIs(QObject*);

signals:
    void doGetRouteInfo();

public slots:
    void getRouteInfoSlot();
    void sendSignalRouteInfo(double srt_lat,double srt_lon,double end_lat,double end_lon);
    void sendSignalPosInfo(double lat,double lon,double drc,double dst);
};
#endif // DBUS_SERVER_H
