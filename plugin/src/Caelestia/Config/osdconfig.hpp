#pragma once

#include "configobject.hpp"

namespace caelestia::config {

class OsdConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, enabled, true)
    // Per-panel opt-out for the edge hover gesture, matching launcher/dashboard/dock. Defaults
    // on because hover has always been the OSD's reveal.
    CONFIG_PROPERTY(bool, showOnHover, true)
    CONFIG_PROPERTY(int, hideDelay, 2000)
    CONFIG_PROPERTY(bool, enableBrightness, true)
    CONFIG_PROPERTY(bool, enableMicrophone, false)
    CONFIG_PROPERTY(QString, position, u"left"_s)

public:
    explicit OsdConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

} // namespace caelestia::config
