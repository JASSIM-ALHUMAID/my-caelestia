#pragma once

#include "configobject.hpp"
#include <QQmlEngine>

namespace caelestia::config {

// Which panel a screen edge's hover / inward-drag gesture opens. Several panels can sit on
// the same edge (e.g. launcher, dashboard and dock all live on top or bottom), so the edge
// — not the panel — owns the arbitration. "none" disables that gesture for the edge.
// Valid names: "launcher", "dashboard", "dock", "osd", "session", "none".
class EdgeTriggerConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(QString, hover, u"none"_s)
    CONFIG_PROPERTY(QString, drag, u"none"_s)

public:
    explicit EdgeTriggerConfig(
        const QString& hover = u"none"_s, const QString& drag = u"none"_s, QObject* parent = nullptr)
        : ConfigObject(parent) {
        m_hover = hover;
        m_drag = drag;
    }
};

// Defaults reproduce the historical hardcoded behaviour: the dashboard owns the top edge,
// the launcher is drag-only at the bottom, and the sidebar edges hover the OSD / drag the
// session menu.
class EdgesConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_SUBOBJECT(EdgeTriggerConfig, top)
    CONFIG_SUBOBJECT(EdgeTriggerConfig, bottom)
    CONFIG_SUBOBJECT(EdgeTriggerConfig, left)
    CONFIG_SUBOBJECT(EdgeTriggerConfig, right)

public:
    explicit EdgesConfig(QObject* parent = nullptr)
        : ConfigObject(parent)
        , m_top(new EdgeTriggerConfig(u"dashboard"_s, u"dashboard"_s, this))
        , m_bottom(new EdgeTriggerConfig(u"none"_s, u"launcher"_s, this))
        , m_left(new EdgeTriggerConfig(u"osd"_s, u"session"_s, this))
        , m_right(new EdgeTriggerConfig(u"osd"_s, u"session"_s, this)) {}
};

}
