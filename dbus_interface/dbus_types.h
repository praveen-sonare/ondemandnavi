#ifndef DBUS_TYPES_H
#define DBUS_TYPES_H
#include <QtDBus>

#include <QMetaType>
#include <QtCore/QList>
#include <QtCore/QMap>
#include <QtCore/QVariant>
#include <QPair>
#include <QDBusVariant>

// for org.genivi.navigationcore
struct qPositionPairElm{
    uint8_t key;
    QDBusVariant value;
};
Q_DECLARE_METATYPE(qPositionPairElm)

inline QDBusArgument &operator <<(QDBusArgument &argument, const qPositionPairElm &qpositionpairelm)
{
    argument.beginStructure();
    argument << qpositionpairelm.key << qpositionpairelm.value;
    argument.endStructure();
    return argument;
}

inline const QDBusArgument &operator >>(const QDBusArgument &argument, qPositionPairElm &qpositionpairelm)
{
    argument.beginStructure();
    argument >> qpositionpairelm.key;
    argument >> qpositionpairelm.value;
    argument.endStructure();
    return argument;
}

typedef QMap<int32_t,qPositionPairElm> qPosition;
Q_DECLARE_METATYPE(qPosition)

typedef QList<int32_t> qValuesToReturn;
Q_DECLARE_METATYPE(qValuesToReturn)

typedef QList<QMap<int32_t,qPositionPairElm>> qWaypointsList; // aa{i(yv)}
Q_DECLARE_METATYPE(qWaypointsList)

typedef QList<uint32_t> qCalculatedRoutesList; // au

typedef QList<uint32_t> qRoutesList; //au

struct qSessionsListElm{
    uint32_t key;
    QString value;
};
Q_DECLARE_METATYPE(qSessionsListElm)

inline QDBusArgument &operator <<(QDBusArgument &argument, const qSessionsListElm &qsessionslistelm)
{
    argument.beginStructure();
    argument << qsessionslistelm.key << qsessionslistelm.value;
    argument.endStructure();
    return argument;
}

inline const QDBusArgument &operator >>(const QDBusArgument &argument, qSessionsListElm &qsessionslistelm)
{
    argument.beginStructure();
    argument >> qsessionslistelm.key;
    argument >> qsessionslistelm.value;
    argument.endStructure();
    return argument;
}

typedef QList<qSessionsListElm> qSessionsList; // a(us)
Q_DECLARE_METATYPE(qSessionsList)

#endif
