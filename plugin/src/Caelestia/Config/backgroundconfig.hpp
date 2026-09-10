#pragma once

#include "configobject.hpp"

#include <qcolor.h>
#include <qstring.h>

namespace caelestia::config {

class DesktopClockBackground : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, enabled, false)
    CONFIG_PROPERTY(qreal, opacity, 0.7)
    CONFIG_PROPERTY(bool, blur, true)

public:
    explicit DesktopClockBackground(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class DesktopClockShadow : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, enabled, true)
    CONFIG_PROPERTY(qreal, opacity, 0.7)
    CONFIG_PROPERTY(qreal, blur, 0.4)

public:
    explicit DesktopClockShadow(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class DesktopClock : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, enabled, false)
    CONFIG_PROPERTY(qreal, scale, 1.0)
    CONFIG_PROPERTY(QString, position, QStringLiteral("bottom-right"))
    CONFIG_PROPERTY(bool, invertColors, false)
    CONFIG_PROPERTY(bool, hoverEnabled, true)
    CONFIG_PROPERTY(qreal, hoverScale, 1.1)
    CONFIG_PROPERTY(QString, clickAction, QStringLiteral("nexus"))
    CONFIG_SUBOBJECT(DesktopClockBackground, background)
    CONFIG_SUBOBJECT(DesktopClockShadow, shadow)

public:
    explicit DesktopClock(QObject* parent = nullptr)
        : ConfigObject(parent)
        , m_background(new DesktopClockBackground(this))
        , m_shadow(new DesktopClockShadow(this)) {}
};

class DesktopBatteryBackground : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, enabled, false)
    CONFIG_PROPERTY(qreal, opacity, 0.7)
    CONFIG_PROPERTY(bool, blur, true)

public:
    explicit DesktopBatteryBackground(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class DesktopBatteryShadow : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, enabled, true)
    CONFIG_PROPERTY(qreal, opacity, 0.7)
    CONFIG_PROPERTY(qreal, blur, 0.4)

public:
    explicit DesktopBatteryShadow(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class DesktopBattery : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, enabled, false)
    CONFIG_PROPERTY(qreal, scale, 1.0)
    CONFIG_PROPERTY(QString, position, QStringLiteral("bottom-right"))
    CONFIG_PROPERTY(int, style, 0)
    CONFIG_PROPERTY(bool, invertColors, false)
    CONFIG_PROPERTY(bool, hoverEnabled, true)
    CONFIG_PROPERTY(qreal, hoverScale, 1.1)
    CONFIG_PROPERTY(QString, clickAction, QStringLiteral("nexus/battery"))
    CONFIG_PROPERTY(bool, wavy, false)
    CONFIG_PROPERTY(int, waveStyle, 0)
    CONFIG_PROPERTY(bool, waveOnlyWhenCharging, true)
    CONFIG_PROPERTY(bool, chargingBoltPulse, false)
    CONFIG_PROPERTY(int, chargingBoltPulseStrength, 1)
    CONFIG_PROPERTY(bool, chargingEnergisedWave, false)
    CONFIG_PROPERTY(bool, chargingGlow, false)
    CONFIG_PROPERTY(bool, chargingBubbles, false)
    CONFIG_PROPERTY(bool, chargingRandom, false)
    CONFIG_PROPERTY(int, chargingRandomTrigger, 2)
    CONFIG_PROPERTY(int, chargingRandomInterval, 30)
    CONFIG_SUBOBJECT(DesktopBatteryBackground, background)
    CONFIG_SUBOBJECT(DesktopBatteryShadow, shadow)

public:
    explicit DesktopBattery(QObject* parent = nullptr)
        : ConfigObject(parent)
        , m_background(new DesktopBatteryBackground(this))
        , m_shadow(new DesktopBatteryShadow(this)) {}
};

class BackgroundVisualiser : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, enabled, false)
    CONFIG_PROPERTY(bool, autoHide, true)
    CONFIG_PROPERTY(bool, blur, false)
    // "bars" | "waveform" | "sine" | "outline"
    CONFIG_PROPERTY(QString, style, QStringLiteral("bars"))
    CONFIG_PROPERTY(int, thickness, 6)
    // Total fraction of the edge left empty at its centre. The renderer clamps this to [0, 0.8].
    CONFIG_PROPERTY(qreal, centerGap, 0.2)
    CONFIG_PROPERTY(qreal, rounding, 1)
    CONFIG_PROPERTY(qreal, spacing, 1)
    // "bottom" | "top" | "left" | "right" - which screen edge the bars grow from
    CONFIG_PROPERTY(QString, position, QStringLiteral("bottom"))
    // Fraction of the screen's extent (height for top/bottom, width for left/right) the bars
    // may reach at full amplitude
    CONFIG_PROPERTY(qreal, reach, 0.4)
    // "none" disables clicks; "nexus" opens the hub, "nexus/<page>" a specific page
    CONFIG_PROPERTY(QString, clickAction, QStringLiteral("nexus"))

public:
    explicit BackgroundVisualiser(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class BackgroundVideoProgress : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, enabled, false)
    // "bottom" | "top" | "left" | "right" - the screen edge carrying the progress bar
    CONFIG_PROPERTY(QString, position, QStringLiteral("bottom"))
    // "straight" | "wavy" - the visual style of the completed portion
    CONFIG_PROPERTY(QString, style, QStringLiteral("straight"))
    CONFIG_PROPERTY(int, thickness, 6)

public:
    explicit BackgroundVideoProgress(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class BackgroundConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, enabled, true)
    CONFIG_PROPERTY(bool, wallpaperEnabled, true)
    CONFIG_PROPERTY(bool, videoAudio, false)
    CONFIG_PROPERTY(bool, pauseAudioWhenOtherPlaying, false)
    CONFIG_PROPERTY(QString, transitionType, QStringLiteral("fade"))
    CONFIG_PROPERTY(QString, fillMode, QStringLiteral("cover"))
    CONFIG_PROPERTY(int, transitionDuration, 1000)
    CONFIG_PROPERTY(int, transitionWaveCount, 3)
    CONFIG_PROPERTY(int, transitionStripeCount, 0)
    CONFIG_PROPERTY(int, transitionHoneycombSize, 1)
    CONFIG_PROPERTY(QString, transitionInterrupt, QStringLiteral("freeze"))
    CONFIG_PROPERTY(QString, transitionInterruptReplay, QStringLiteral("same"))
    // Either a named preset ("inOutCubic", "outCubic", "outExpo", "linear", "inCubic"), the
    // name of an appearance.curves token ("standard", "emphasized", ...), or "custom" to use
    // transitionCurve below.
    CONFIG_PROPERTY(QString, transitionEasing, QStringLiteral("inOutCubic"))
    // Cubic bezier segments in the same layout as appearance.curves: c1x, c1y, c2x, c2y, endX,
    // endY. Kept separate from the UI motion tokens so tuning a wallpaper fade can't change
    // how every menu and panel animates.
    CONFIG_PROPERTY(QList<qreal>, transitionCurve, (QList<qreal> { 0.65, 0.05, 0.36, 1, 1, 1 }))
    CONFIG_PROPERTY(QColor, fillColor, QColor(0, 0, 0))
    CONFIG_PROPERTY(bool, rotationEnabled, false)
    CONFIG_PROPERTY(int, rotationIntervalMinutes, 60)
    CONFIG_PROPERTY(QString, advanceOrder, QStringLiteral("random"))
    CONFIG_PROPERTY(QString, advancePool, QStringLiteral("all"))
    CONFIG_PROPERTY(int, videoLoops, 0)
    CONFIG_PROPERTY(bool, videoPlayToEnd, false)
    CONFIG_PROPERTY(int, videoSeekStepSeconds, 10)
    CONFIG_SUBOBJECT(DesktopClock, desktopClock)
    CONFIG_SUBOBJECT(DesktopBattery, desktopBattery)
    CONFIG_SUBOBJECT(BackgroundVisualiser, visualiser)
    CONFIG_SUBOBJECT(BackgroundVideoProgress, videoProgress)

public:
    explicit BackgroundConfig(QObject* parent = nullptr)
        : ConfigObject(parent)
        , m_desktopClock(new DesktopClock(this))
        , m_desktopBattery(new DesktopBattery(this))
        , m_visualiser(new BackgroundVisualiser(this))
        , m_videoProgress(new BackgroundVideoProgress(this)) {}
};

} // namespace caelestia::config
