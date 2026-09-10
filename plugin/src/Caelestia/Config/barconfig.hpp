#pragma once

#include "configobject.hpp"

#include <qstring.h>
#include <qstringlist.h>
#include <qvariant.h>

namespace caelestia::config {

using Qt::StringLiterals::operator""_s;

class BarScrollActions : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, workspaces, true)
    CONFIG_PROPERTY(bool, volume, true)
    CONFIG_PROPERTY(bool, brightness, true)

public:
    explicit BarScrollActions(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class BarPopouts : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, activeWindow, true)
    CONFIG_PROPERTY(bool, tray, true)
    CONFIG_PROPERTY(bool, statusIcons, true)
    // "hugged" | "floating" - how popouts appear relative to the bar
    CONFIG_PROPERTY(QString, mode, u"hugged"_s)
    // Distance in px between a floating popout and the bar. Ignored in hugged mode.
    CONFIG_PROPERTY(int, gap, 12)
    // How long in ms a popout lingers after the cursor leaves, so it can be moved onto.
    CONFIG_PROPERTY(int, hoverGrace, 200)

public:
    explicit BarPopouts(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class BarWorkspaces : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(int, shown, 5)
    CONFIG_PROPERTY(bool, activeIndicator, true)
    CONFIG_PROPERTY(bool, occupiedBg, false)
    CONFIG_PROPERTY(bool, showWindows, true)
    CONFIG_PROPERTY(bool, showWindowsOnActive, true)
    CONFIG_PROPERTY(bool, showWindowsOnSpecialWorkspaces, true)
    CONFIG_PROPERTY(int, maxWindowIcons, 5)
    // Gap between the window icons stacked on a single workspace
    CONFIG_PROPERTY(int, windowIconSpacing, 0)
    CONFIG_PROPERTY(bool, activeTrail, false)
    CONFIG_PROPERTY(bool, numbered, false)
    CONFIG_PROPERTY(bool, appIcons, false)
    CONFIG_PROPERTY(bool, useIcon, false)
    CONFIG_PROPERTY(QString, label, u"  "_s)
    CONFIG_PROPERTY(QString, occupiedLabel, u"󰮯"_s)
    CONFIG_PROPERTY(QString, activeLabel, u"󰮯"_s)
    CONFIG_PROPERTY(QString, capitalisation, u"preserve"_s)

public:
    explicit BarWorkspaces(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class BarActiveWindow : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, compact, false)
    CONFIG_PROPERTY(bool, inverted, false)
    CONFIG_PROPERTY(bool, showOnHover, true)

public:
    explicit BarActiveWindow(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class BarTray : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, background, false)
    CONFIG_PROPERTY(bool, recolour, false)
    CONFIG_PROPERTY(bool, compact, false)

public:
    explicit BarTray(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class BarStatus : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, showAudio, false)
    CONFIG_PROPERTY(bool, showMicrophone, false)
    CONFIG_PROPERTY(bool, showKbLayout, false)
    CONFIG_PROPERTY(bool, showNetwork, true)
    CONFIG_PROPERTY(bool, showWifi, true)
    CONFIG_PROPERTY(bool, showBluetooth, true)
    CONFIG_PROPERTY(bool, showBattery, true)
    CONFIG_PROPERTY(bool, showBatteryPercentage, false)
    CONFIG_PROPERTY(bool, showLockStatus, true)

public:
    explicit BarStatus(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class BarClock : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, background, false)
    CONFIG_PROPERTY(bool, showDate, false)
    CONFIG_PROPERTY(bool, showIcon, true)

public:
    explicit BarClock(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class BarDock : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    // "left" | "right" | "top" | "bottom" — side of each icon the active dot sits on
    CONFIG_PROPERTY(QString, activeIndicatorPosition, u"left"_s)
    CONFIG_PROPERTY(int, iconSize, 30)
    CONFIG_PROPERTY(int, indicatorGap, 12)
    // Follow an open special workspace instead of the underlying regular workspace.
    CONFIG_PROPERTY(bool, showSpecialWorkspaceApps, false)

public:
    explicit BarDock(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

// What the bar does when its entries no longer fit along the screen edge. Without this the
// entries simply run past the end of the bar and get clipped by the wrapper, because Qt Quick
// Layouts fix a non-filling item's size to its preferred size.
class BarOverflow : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    // "none"   — let entries overflow (previous behaviour)
    // "cap"    — shrink the greedy entries (workspace window icons, dock icons, tray icons)
    // "popout" — move self-contained entries into a "⋯" popout, then cap whatever is left
    CONFIG_PROPERTY(QString, mode, u"cap"_s)
    // Floors the cap will not shrink an entry below
    CONFIG_PROPERTY(int, minWindowIcons, 1)
    CONFIG_PROPERTY(int, minDockIcons, 2)
    CONFIG_PROPERTY(int, minTrayIcons, 2)
    // Draw a "+N" chip on dock/tray entries that were truncated
    CONFIG_PROPERTY(bool, showCount, true)
    CONFIG_PROPERTY(QString, icon, u"more_horiz"_s)

public:
    explicit BarOverflow(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class BarVisualiserConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(int, bars, 5)
    // Perpendicular dimension of each bar (width along the bar edge)
    CONFIG_PROPERTY(int, barWidth, 8)
    // Maximum distance bars extend from the bar edge
    CONFIG_PROPERTY(int, barLength, 40)
    CONFIG_PROPERTY(int, barRounding, 8)
    CONFIG_PROPERTY(int, barAmplitude, 100)
    CONFIG_PROPERTY(int, barSpacing, 2)
    // "solid", "gradient", "rainbow", "custom_solid", "custom_gradient"
    CONFIG_PROPERTY(QString, barColorMode, u"solid"_s)
    // Hex colour for custom modes (#RRGGBB)
    CONFIG_PROPERTY(QString, barCustomColor, u""_s)
    CONFIG_PROPERTY(QString, barCustomColor2, u""_s)
    CONFIG_PROPERTY(QString, fillMode, u"outward"_s)
    CONFIG_PROPERTY(bool, beatPulse, false)
    // Amplitude multiplier on each beat (e.g. 0.5 = 50 % boost)
    CONFIG_PROPERTY(qreal, beatPulseAmount, 0.5)
    // Per-bar frequency tilt; replaces GlobalConfig.services.visualiserTilt
    CONFIG_PROPERTY(qreal, tilt, 0.0)
    // Bar rise/fall smoothing time constant in ms (default 50 = 0.05s)
    CONFIG_PROPERTY(int, smoothing, 50)
    // Beat-pulse decay time constant in ms (default 100 = 0.1s)
    CONFIG_PROPERTY(int, beatDecay, 100)
    CONFIG_PROPERTY(QString, clickAction, u"none"_s)
    CONFIG_PROPERTY(QString, silenceBehavior, u"flat"_s)

public:
    explicit BarVisualiserConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

// Per-edge bar configuration. One instance per screen edge (left/right/top/bottom);
// the edge is implied by which container slot it lives in, so there is no `edge` here.
class BarEdgeConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, enabled, true)
    CONFIG_PROPERTY(bool, persistent, true)
    CONFIG_PROPERTY(bool, showOnHover, true)
    CONFIG_PROPERTY(bool, hideOnHoverOut, true)
    CONFIG_PROPERTY(bool, revealOnEmptyWorkspace, false)
    // Draw over windows instead of reserving an exclusive zone for the bar.
    CONFIG_PROPERTY(bool, floating, false)
    CONFIG_PROPERTY(int, dragThreshold, 20)
    // Stacking order among the bars on a screen; higher sits on top where bars meet at a corner.
    CONFIG_PROPERTY(int, zIndex, 0)
    // Extra padding at the bar's start edge (top for left/right, left for top/bottom)
    // to create visual space from adjacent bars at the corner.
    CONFIG_PROPERTY(int, startCornerPadding, 0)
    // Extra padding at the bar's end edge (bottom for left/right, right for top/bottom).
    CONFIG_PROPERTY(int, endCornerPadding, 0)
    CONFIG_SUBOBJECT(BarScrollActions, scrollActions)
    CONFIG_SUBOBJECT(BarPopouts, popouts)
    CONFIG_SUBOBJECT(BarWorkspaces, workspaces)
    CONFIG_SUBOBJECT(BarActiveWindow, activeWindow)
    CONFIG_SUBOBJECT(BarTray, tray)
    CONFIG_SUBOBJECT(BarStatus, status)
    CONFIG_SUBOBJECT(BarClock, clock)
    CONFIG_SUBOBJECT(BarDock, dock)
    CONFIG_SUBOBJECT(BarVisualiserConfig, visualiser)
    CONFIG_SUBOBJECT(BarOverflow, overflow)
    CONFIG_PROPERTY(QVariantList, entries,
        {
            vmap({ { u"id"_s, u"logo"_s }, { u"enabled"_s, true } }),
            vmap({ { u"id"_s, u"workspaces"_s }, { u"enabled"_s, true } }),
            vmap({ { u"id"_s, u"spacer"_s }, { u"enabled"_s, true } }),
            vmap({ { u"id"_s, u"activeWindow"_s }, { u"enabled"_s, true } }),
            vmap({ { u"id"_s, u"spacer"_s }, { u"enabled"_s, true } }),
            vmap({ { u"id"_s, u"tray"_s }, { u"enabled"_s, true } }),
            vmap({ { u"id"_s, u"clock"_s }, { u"enabled"_s, true } }),
            vmap({ { u"id"_s, u"statusIcons"_s }, { u"enabled"_s, true } }),
            vmap({ { u"id"_s, u"power"_s }, { u"enabled"_s, true } }),
            vmap({ { u"id"_s, u"visualiser"_s }, { u"enabled"_s, false } }),
            vmap({ { u"id"_s, u"barPin"_s }, { u"enabled"_s, false } }),
        })
    CONFIG_PROPERTY(QStringList, excludedScreens)

public:
    // `defaultEnabled` lets the container default one edge on (left) and the rest off without
    // routing through the setter (which would mark `enabled` as user-loaded and serialize it).
    explicit BarEdgeConfig(bool defaultEnabled = true, QObject* parent = nullptr)
        : ConfigObject(parent)
        , m_scrollActions(new BarScrollActions(this))
        , m_popouts(new BarPopouts(this))
        , m_workspaces(new BarWorkspaces(this))
        , m_activeWindow(new BarActiveWindow(this))
        , m_tray(new BarTray(this))
        , m_status(new BarStatus(this))
        , m_clock(new BarClock(this))
        , m_dock(new BarDock(this))
        , m_visualiser(new BarVisualiserConfig(this))
        , m_overflow(new BarOverflow(this)) {
        m_enabled = defaultEnabled;
    }
};

// Container for the four per-edge bars plus the genuinely-global bar settings (shared lookup
// tables / behaviours that aren't per-bar). Keeps the name `BarConfig` so `Config.bar` resolves.
class BarConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_SUBOBJECT(BarEdgeConfig, left)
    CONFIG_SUBOBJECT(BarEdgeConfig, right)
    CONFIG_SUBOBJECT(BarEdgeConfig, top)
    CONFIG_SUBOBJECT(BarEdgeConfig, bottom)

    // Shared-once globals, hoisted out of the per-edge workspaces/tray subobjects.
    CONFIG_GLOBAL_PROPERTY(bool, perMonitorWorkspaces, true)
    CONFIG_GLOBAL_PROPERTY(QVariantList, specialWorkspaceIcons)
    CONFIG_GLOBAL_PROPERTY(QVariantList, windowIcons,
        { vmap({
            { u"regex"_s, u"steam(_app_(default|[0-9]+))?"_s },
            { u"icon"_s, u"sports_esports"_s },
        }) })
    CONFIG_GLOBAL_PROPERTY(QVariantList, trayIconSubs)
    CONFIG_GLOBAL_PROPERTY(QStringList, trayHiddenIcons)

public:
    explicit BarConfig(QObject* parent = nullptr)
        : ConfigObject(parent)
        , m_left(new BarEdgeConfig(true, this))
        , m_right(new BarEdgeConfig(false, this))
        , m_top(new BarEdgeConfig(false, this))
        , m_bottom(new BarEdgeConfig(false, this)) {}
};

} // namespace caelestia::config
