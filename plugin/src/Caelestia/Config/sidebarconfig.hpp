#pragma once

#include "configobject.hpp"

#include <qstring.h>

namespace caelestia::config {

using Qt::StringLiterals::operator""_s;

class SidebarConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, enabled, true)
    CONFIG_PROPERTY(int, dragThreshold, 80)
    CONFIG_PROPERTY(QString, edge, u"right"_s)

public:
    explicit SidebarConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

} // namespace caelestia::config
