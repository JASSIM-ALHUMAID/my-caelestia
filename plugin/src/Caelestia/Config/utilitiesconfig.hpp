#pragma once

#include "configobject.hpp"

#include <qstring.h>
#include <qvariant.h>

namespace caelestia::config {

using Qt::StringLiterals::operator""_s;

class UtilitiesToasts : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(QString, fullscreen, u"off"_s)
    CONFIG_GLOBAL_PROPERTY(bool, configLoaded, true)
    CONFIG_GLOBAL_PROPERTY(bool, chargingChanged, true)
    CONFIG_GLOBAL_PROPERTY(bool, gameModeChanged, true)
    CONFIG_GLOBAL_PROPERTY(bool, dndChanged, true)
    CONFIG_GLOBAL_PROPERTY(bool, audioOutputChanged, true)
    CONFIG_GLOBAL_PROPERTY(bool, audioInputChanged, true)
    CONFIG_GLOBAL_PROPERTY(bool, capsLockChanged, true)
    CONFIG_GLOBAL_PROPERTY(bool, numLockChanged, true)
    CONFIG_GLOBAL_PROPERTY(bool, kbLayoutChanged, true)
    CONFIG_GLOBAL_PROPERTY(bool, kbLimit, true)
    CONFIG_GLOBAL_PROPERTY(bool, vpnChanged, true)
    CONFIG_GLOBAL_PROPERTY(bool, hyprsunsetChanged, true)
    CONFIG_GLOBAL_PROPERTY(bool, nowPlaying, false)

public:
    explicit UtilitiesToasts(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class UtilitiesSounds : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    // Master switch for ambient event sounds, off so an install never starts making noise on its
    // own. The names below are pre-filled with XDG sound-theme names so flipping this on gives a
    // working set; clear an individual one to silence just that event. A value containing `/` is
    // treated as a path to a sound file instead of a theme name.
    CONFIG_GLOBAL_PROPERTY(bool, enabled, false)
    CONFIG_GLOBAL_PROPERTY(QString, chargerPlugged, u"power-plug"_s)
    CONFIG_GLOBAL_PROPERTY(QString, chargerUnplugged, u"power-unplug"_s)
    CONFIG_GLOBAL_PROPERTY(QString, serviceOn, u"device-added"_s)
    CONFIG_GLOBAL_PROPERTY(QString, serviceOff, u"device-removed"_s)
    CONFIG_GLOBAL_PROPERTY(QString, startup, u"service-login"_s)
    CONFIG_GLOBAL_PROPERTY(QString, volumeChange, u"audio-volume-change"_s)
    // No conventional sound exists for a brightness step, so this is silent unless set.
    CONFIG_GLOBAL_PROPERTY(QString, brightnessChange, "")
    // Volume and brightness fire per scroll tick; without a floor this spawns dozens of
    // canberra processes a second.
    CONFIG_GLOBAL_PROPERTY(int, throttleMs, 150)

public:
    explicit UtilitiesSounds(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class UtilitiesVpn : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_GLOBAL_PROPERTY(bool, enabled, false)
    CONFIG_GLOBAL_PROPERTY(QVariantList, provider)

public:
    explicit UtilitiesVpn(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class UtilitiesHyprsunset : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_GLOBAL_PROPERTY(bool, enabled, false)
    CONFIG_GLOBAL_PROPERTY(bool, automatic, false)
    CONFIG_GLOBAL_PROPERTY(QString, from, u"19:00"_s)
    CONFIG_GLOBAL_PROPERTY(QString, to, u"06:30"_s)
    CONFIG_GLOBAL_PROPERTY(int, temperature, 4500)
    CONFIG_GLOBAL_PROPERTY(int, gamma, 100)

public:
    explicit UtilitiesHyprsunset(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class UtilitiesConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, enabled, true)
    CONFIG_PROPERTY(int, maxToasts, 4)
    CONFIG_SUBOBJECT(UtilitiesToasts, toasts)
    CONFIG_SUBOBJECT(UtilitiesSounds, sounds)
    CONFIG_SUBOBJECT(UtilitiesVpn, vpn)
    CONFIG_SUBOBJECT(UtilitiesHyprsunset, hyprsunset)
    CONFIG_PROPERTY(QVariantList, quickToggles,
        {
            vmap({ { u"id"_s, u"wifi"_s }, { u"enabled"_s, true } }),
            vmap({ { u"id"_s, u"bluetooth"_s }, { u"enabled"_s, true } }),
            vmap({ { u"id"_s, u"mic"_s }, { u"enabled"_s, true } }),
            vmap({ { u"id"_s, u"settings"_s }, { u"enabled"_s, true } }),
            vmap({ { u"id"_s, u"gameMode"_s }, { u"enabled"_s, true } }),
            vmap({ { u"id"_s, u"dnd"_s }, { u"enabled"_s, true } }),
            vmap({ { u"id"_s, u"hyprsunset"_s }, { u"enabled"_s, true } }),
            vmap({ { u"id"_s, u"vpn"_s }, { u"enabled"_s, false } }),
        })

public:
    explicit UtilitiesConfig(QObject* parent = nullptr)
        : ConfigObject(parent)
        , m_toasts(new UtilitiesToasts(this))
        , m_sounds(new UtilitiesSounds(this))
        , m_vpn(new UtilitiesVpn(this))
        , m_hyprsunset(new UtilitiesHyprsunset(this)) {}
};

} // namespace caelestia::config
