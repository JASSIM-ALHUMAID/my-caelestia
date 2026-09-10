#pragma once

#include "configobject.hpp"

namespace caelestia::config {

using Qt::StringLiterals::operator""_s;

class LockConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, recolourLogo, true)
    CONFIG_PROPERTY(bool, minimal, false)
    CONFIG_PROPERTY(bool, pauseMediaOnLock, true)
    CONFIG_PROPERTY(bool, mediaControls, true)
    CONFIG_GLOBAL_PROPERTY(bool, allowScreensaver, false)
    CONFIG_GLOBAL_PROPERTY(bool, enableFprint, true)
    CONFIG_GLOBAL_PROPERTY(int, maxFprintTries, 3)
    CONFIG_PROPERTY(bool, hideNotifs, false)
    CONFIG_PROPERTY(bool, hideWindows, false)
    CONFIG_PROPERTY(qreal, blurred, 1.0)
    // Shape names (see modules/lock/PasswordShapes.qml) the password field picks
    // from at random; empty means the default set
    CONFIG_PROPERTY(QStringList, passwordShapes)
    CONFIG_PROPERTY(QVariantList, leftWidgets,
        {
            vmap({ { u"id"_s, u"weather"_s }, { u"enabled"_s, true } }),
            vmap({ { u"id"_s, u"fetch"_s }, { u"enabled"_s, true } }),
            vmap({ { u"id"_s, u"media"_s }, { u"enabled"_s, true } }),
        })
    CONFIG_PROPERTY(QVariantList, centerWidgets,
        {
            vmap({ { u"id"_s, u"clock"_s }, { u"enabled"_s, true } }),
            vmap({ { u"id"_s, u"date"_s }, { u"enabled"_s, true } }),
            vmap({ { u"id"_s, u"profilePic"_s }, { u"enabled"_s, true } }),
            vmap({ { u"id"_s, u"passwordInput"_s }, { u"enabled"_s, true } }),
            vmap({ { u"id"_s, u"stateMessage"_s }, { u"enabled"_s, true } }),
        })
    CONFIG_PROPERTY(QVariantList, rightWidgets,
        {
            vmap({ { u"id"_s, u"resources"_s }, { u"enabled"_s, true } }),
            vmap({ { u"id"_s, u"notifications"_s }, { u"enabled"_s, true } }),
        })

public:
    explicit LockConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

} // namespace caelestia::config
