#pragma once

#include "configobject.hpp"

#include <qstring.h>

namespace caelestia::config {

class NotifsConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_GLOBAL_PROPERTY(bool, expire, true)
    CONFIG_GLOBAL_PROPERTY(QString, fullscreen, QStringLiteral("on"))
    CONFIG_GLOBAL_PROPERTY(int, defaultExpireTimeout, 5000)
    CONFIG_GLOBAL_PROPERTY(int, fullscreenExpireTimeout, 2000)
    CONFIG_PROPERTY(qreal, clearThreshold, 0.3)
    CONFIG_PROPERTY(int, expandThreshold, 20)
    CONFIG_GLOBAL_PROPERTY(bool, actionOnClick, false)
    CONFIG_PROPERTY(int, groupPreviewNum, 3)
    CONFIG_PROPERTY(bool, openExpanded, false)
    // "hugged" | "floating" - how the popup list appears relative to the screen edge
    CONFIG_PROPERTY(QString, popoutMode, u"hugged"_s)
    // Distance in px between a floating popup and the screen edge. Ignored in hugged mode.
    CONFIG_PROPERTY(int, popoutGap, 12)
    // How long in ms to wait after cursor leaves before restarting auto-expire timers.
    CONFIG_PROPERTY(int, hoverGrace, 200)

public:
    explicit NotifsConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

} // namespace caelestia::config
