#pragma once

#include "configobject.hpp"

#include <qstring.h>
#include <qvariant.h>

namespace caelestia::config {

using Qt::StringLiterals::operator""_s;

class ServiceConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_GLOBAL_PROPERTY(QString, weatherLocation)
    // Guess based on locale
    CONFIG_GLOBAL_PROPERTY(bool, useFahrenheit,
        QLocale().measurementSystem() == QLocale::ImperialUSSystem ||
            QLocale().measurementSystem() == QLocale::ImperialUKSystem)
    // This is always false by default cause apparently even imperial system users don't use it for perf temps?
    CONFIG_GLOBAL_PROPERTY(bool, useFahrenheitPerformance, false)
    // Attempt to guess based on locale
    CONFIG_GLOBAL_PROPERTY(
        bool, useTwelveHourClock, QLocale().timeFormat(QLocale::ShortFormat).toLower().contains(u"a"_s))
    CONFIG_GLOBAL_PROPERTY(QString, gpuType)
    CONFIG_GLOBAL_PROPERTY(int, visualiserBars, 60)
    // Frequency tilt applied to cava output before display. 0 = flat, >0 boosts highs, <0 boosts lows.
    // Recommended range -1.0..1.0; the top bar's amplitude is multiplied by (1 + tilt).
    CONFIG_GLOBAL_PROPERTY(qreal, visualiserTilt, 0.0)
    CONFIG_GLOBAL_PROPERTY(qreal, audioIncrement, 0.1)
    CONFIG_GLOBAL_PROPERTY(qreal, brightnessIncrement, 0.1)
    CONFIG_GLOBAL_PROPERTY(qreal, maxVolume, 1.0)
    // Countdown timer. `timerDefaultDuration` is in seconds; `timerPresets` are minute counts shown
    // in the timer popout. `timerSound` is a freedesktop sound name played via canberra-gtk-play.
    CONFIG_GLOBAL_PROPERTY(int, timerDefaultDuration, 300)
    CONFIG_GLOBAL_PROPERTY(QVariantList, timerPresets, { 1, 5, 10, 15, 25, 45, 60 })
    CONFIG_GLOBAL_PROPERTY(bool, timerSoundEnabled, true)
    CONFIG_GLOBAL_PROPERTY(QString, timerSound, u"complete"_s)

    CONFIG_GLOBAL_PROPERTY(bool, smartScheme, true)
    CONFIG_GLOBAL_PROPERTY(QString, modeOverride, "")
    CONFIG_GLOBAL_PROPERTY(QString, defaultPlayer, u"Spotify"_s)
    CONFIG_GLOBAL_PROPERTY(QVariantList, playerAliases,
        { vmap({ { u"from"_s, u"com.github.th_ch.youtube_music"_s }, { u"to"_s, u"YT Music"_s } }) })
    CONFIG_GLOBAL_PROPERTY(QString, lyricsBackend, u"Auto"_s)
    CONFIG_GLOBAL_PROPERTY(QString, cursorTheme, u"ArcAurora-cursors"_s)
    CONFIG_GLOBAL_PROPERTY(int, cursorSize, 22)
    CONFIG_GLOBAL_PROPERTY(int, workspaceGaps, 20)
    CONFIG_GLOBAL_PROPERTY(int, windowGapsIn, 5)
    CONFIG_GLOBAL_PROPERTY(int, windowGapsOut, 10)
    CONFIG_GLOBAL_PROPERTY(int, singleWindowGapsOut, 20)

    // Blur
    CONFIG_GLOBAL_PROPERTY(bool, blurEnabled, true)
    CONFIG_GLOBAL_PROPERTY(int, blurSize, 8)
    CONFIG_GLOBAL_PROPERTY(int, blurPasses, 2)
    CONFIG_GLOBAL_PROPERTY(bool, blurSpecialWs, false)
    CONFIG_GLOBAL_PROPERTY(bool, blurPopups, true)
    CONFIG_GLOBAL_PROPERTY(bool, blurInputMethods, true)
    CONFIG_GLOBAL_PROPERTY(bool, blurXray, false)
    // Shadow
    CONFIG_GLOBAL_PROPERTY(bool, shadowEnabled, true)
    CONFIG_GLOBAL_PROPERTY(int, shadowRange, 15)
    CONFIG_GLOBAL_PROPERTY(int, shadowRenderPower, 4)
    // Window
    CONFIG_GLOBAL_PROPERTY(qreal, windowOpacity, 0.95)
    CONFIG_GLOBAL_PROPERTY(int, windowRounding, 15)
    CONFIG_GLOBAL_PROPERTY(int, windowBorderSize, 1)

    // Misc Hyprland vars
    CONFIG_GLOBAL_PROPERTY(QString, sleepGestureCmd, u"systemctl suspend-then-hibernate"_s)

    // hypr-user.lua config. These are not variables.lua keys -- they're written into
    // hypr-vars.lua under a `cfg` prefix (upstream's convention for non-plain vars, cf. `kb*`)
    // and read back by hypr-user.lua, which is sourced last and so overrides hyprland/*.lua.
    //
    // The defaults are the values hypr-user.lua shipped with, not Hyprland's or upstream
    // caelestia's. These keys exist only for this surface, and a settings page that opens
    // showing "dwindle" while the session is actually scrolling would be a lie -- an untouched
    // config has to round-trip to exactly what it already had.
    CONFIG_GLOBAL_PROPERTY(QString, cfgLayout, u"scrolling"_s)
    CONFIG_GLOBAL_PROPERTY(qreal, cfgColumnWidth, 0.85)
    CONFIG_GLOBAL_PROPERTY(QString, cfgExplicitColumnWidths, u"0.35, 0.5, 0.65, 0.95, 1.0"_s)
    CONFIG_GLOBAL_PROPERTY(QString, cfgKbLayout, u"us,ara"_s)
    CONFIG_GLOBAL_PROPERTY(QString, cfgKbVariant, "")
    CONFIG_GLOBAL_PROPERTY(QString, cfgKbOptions, u"grp:win_space_toggle, ctrl:nocaps"_s)
    CONFIG_GLOBAL_PROPERTY(qreal, cfgSensitivity, 0.3)
    CONFIG_GLOBAL_PROPERTY(QString, cfgAccelProfile, u"flat"_s)
    CONFIG_GLOBAL_PROPERTY(bool, cfgAnimationsEnabled, true)
    CONFIG_GLOBAL_PROPERTY(int, cfgSwipeDistance, 500)
    CONFIG_GLOBAL_PROPERTY(qreal, cfgSwipeCancelRatio, 0.15)
    CONFIG_GLOBAL_PROPERTY(int, cfgSwipeMinSpeed, 5)
    CONFIG_GLOBAL_PROPERTY(bool, cfgSwipeDirectionLock, true)
    CONFIG_GLOBAL_PROPERTY(bool, cfgSwipeCreateNew, true)

    // Hyprland keybinds (the `kb*` keys of variables.lua, consumed by hypr/hyprland/keybinds.lua).
    //
    // Unlike the `cfg*` block above, these are real upstream keys, so the defaults here are
    // upstream's verbatim -- that's what "unmodified" has to mean for the reset affordance.
    //
    // The value is a Hyprland lua key combo: modifiers (SUPER/CTRL/ALT/SHIFT, exact case) and a
    // keysym joined by " + ". `mouse:NNN`, `mouse_up`/`mouse_down` and bare keysyms are also legal.
    // The four kbMoveWinToWs/kbGoToWs* keys are a modifier *prefix* with no key -- keybinds.lua
    // appends " + <digit>" for workspaces 1-10. There is no form that disables a bind; an empty
    // string is a config error, not an unbind.

    // Workspaces
    CONFIG_GLOBAL_PROPERTY(QString, kbMoveWinToWs, u"SUPER + ALT"_s)
    CONFIG_GLOBAL_PROPERTY(QString, kbMoveWinToWsGroup, u"CTRL + SUPER + ALT"_s)
    CONFIG_GLOBAL_PROPERTY(QString, kbGoToWs, u"SUPER"_s)
    CONFIG_GLOBAL_PROPERTY(QString, kbGoToWsGroup, u"CTRL + SUPER"_s)
    CONFIG_GLOBAL_PROPERTY(QString, kbNextWs, u"CTRL + SUPER + Right"_s)
    CONFIG_GLOBAL_PROPERTY(QString, kbPrevWs, u"CTRL + SUPER + Left"_s)
    // Window group
    CONFIG_GLOBAL_PROPERTY(QString, kbWindowGroupCycleNext, u"ALT + TAB"_s)
    CONFIG_GLOBAL_PROPERTY(QString, kbWindowGroupCyclePrev, u"SHIFT + ALT + TAB"_s)
    CONFIG_GLOBAL_PROPERTY(QString, kbUngroup, u"SUPER + U"_s)
    CONFIG_GLOBAL_PROPERTY(QString, kbToggleGroup, u"SUPER + Comma"_s)
    // Window
    CONFIG_GLOBAL_PROPERTY(QString, kbMoveWindow, u"SUPER + Z"_s)
    CONFIG_GLOBAL_PROPERTY(QString, kbResizeWindow, u"SUPER + X"_s)
    CONFIG_GLOBAL_PROPERTY(QString, kbWindowPip, u"SUPER + ALT + backslash"_s)
    CONFIG_GLOBAL_PROPERTY(QString, kbPinWindow, u"SUPER + P"_s)
    CONFIG_GLOBAL_PROPERTY(QString, kbWindowFullscreen, u"SUPER + F"_s)
    CONFIG_GLOBAL_PROPERTY(QString, kbWindowBorderedFullscreen, u"SUPER + ALT + F"_s)
    CONFIG_GLOBAL_PROPERTY(QString, kbToggleWindowFloating, u"SUPER + ALT + space"_s)
    CONFIG_GLOBAL_PROPERTY(QString, kbCloseWindow, u"SUPER + Q"_s)
    // Special workspaces
    CONFIG_GLOBAL_PROPERTY(QString, kbSpecialWs, u"SUPER + S"_s)
    CONFIG_GLOBAL_PROPERTY(QString, kbSystemMonitorWs, u"CTRL + SHIFT + Escape"_s)
    CONFIG_GLOBAL_PROPERTY(QString, kbMusicWs, u"SUPER + M"_s)
    CONFIG_GLOBAL_PROPERTY(QString, kbCommunicationWs, u"SUPER + D"_s)
    CONFIG_GLOBAL_PROPERTY(QString, kbTodoWs, u"SUPER + R"_s)
    // Apps
    CONFIG_GLOBAL_PROPERTY(QString, kbTerminal, u"SUPER + T"_s)
    CONFIG_GLOBAL_PROPERTY(QString, kbBrowser, u"SUPER + W"_s)
    CONFIG_GLOBAL_PROPERTY(QString, kbEditor, u"SUPER + C"_s)
    CONFIG_GLOBAL_PROPERTY(QString, kbFileExplorer, u"SUPER + E"_s)
    // Misc
    CONFIG_GLOBAL_PROPERTY(QString, kbSession, u"CTRL + ALT + Delete"_s)
    CONFIG_GLOBAL_PROPERTY(QString, kbShowSidebar, u"SUPER + N"_s)
    CONFIG_GLOBAL_PROPERTY(QString, kbClearNotifs, u"CTRL + ALT + C"_s)
    CONFIG_GLOBAL_PROPERTY(QString, kbShowPanels, u"SUPER + K"_s)
    CONFIG_GLOBAL_PROPERTY(QString, kbLock, u"SUPER + L"_s)
    CONFIG_GLOBAL_PROPERTY(QString, kbRestoreLock, u"SUPER + ALT + L"_s)

    // Apps
    CONFIG_GLOBAL_PROPERTY(QString, appTerminal, u"foot"_s)
    CONFIG_GLOBAL_PROPERTY(QString, appBrowser, u"firefox"_s)
    CONFIG_GLOBAL_PROPERTY(QString, appEditor, u"codium"_s)
    CONFIG_GLOBAL_PROPERTY(QString, appFileExplorer, u"thunar"_s)
    CONFIG_GLOBAL_PROPERTY(QString, appAudioSettings, u"pavucontrol"_s)

    // Touchpad
    CONFIG_GLOBAL_PROPERTY(bool, touchpadDisableTyping, true)
    CONFIG_GLOBAL_PROPERTY(qreal, touchpadScrollFactor, 0.3)
    CONFIG_GLOBAL_PROPERTY(int, gestureFingers, 3)
    CONFIG_GLOBAL_PROPERTY(int, workspaceSwipeFingers, 4)
    CONFIG_GLOBAL_PROPERTY(int, gestureFingersMore, 4)

public:
    explicit ServiceConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

} // namespace caelestia::config
