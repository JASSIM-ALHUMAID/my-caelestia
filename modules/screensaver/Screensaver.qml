pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Wayland
import Caelestia.Config
import qs.services
import qs.modules.screensaver.effects

Singleton {
    id: root

    readonly property bool idleAllowed: !GlobalConfig.general.idle.inhibitWhenAudio || !Audio.hasActiveAudio
    property bool active: false
    property string pickedEffectId: ""
    readonly property bool showingOnLockScreen: root.active && Visibilities.sessionLocked && GlobalConfig.lock.allowScreensaver
    readonly property string effectiveEffectId: GlobalConfig.general.screensaver.randomEffects ? (root.pickedEffectId || GlobalConfig.general.screensaver.effect) : GlobalConfig.general.screensaver.effect
    readonly property var effects: registry.all

    function show(): void {
        if (Visibilities.sessionLocked && !GlobalConfig.lock.allowScreensaver)
            return;

        if (GlobalConfig.general.screensaver.randomEffects) {
            const available = registry.all.filter(effect => effect.id !== "video" || GlobalConfig.general.screensaver.videoPath.length > 0);
            const pick = available[Math.floor(Math.random() * available.length)];
            root.pickedEffectId = pick.id;
        }
        root.active = true;
    }

    function hide(): void {
        root.active = false;
    }

    function preview(): void {
        root.show();
        previewTimer.start();
    }

    Effects {
        id: registry
    }

    Timer {
        id: previewTimer

        interval: 8000

        onTriggered: root.hide()
    }

    IdleMonitor {
        enabled: root.idleAllowed && GlobalConfig.general.screensaver.enabled && GlobalConfig.general.screensaver.timeout > 0
        timeout: GlobalConfig.general.screensaver.timeout

        onIsIdleChanged: {
            if (isIdle)
                root.show();
            else
                root.hide();
        }
    }

    Connections {
        function onSessionLockedChanged(): void {
            if (!Visibilities.sessionLocked || !GlobalConfig.lock.allowScreensaver)
                root.hide();
        }

        target: Visibilities
    }

    Connections {
        function onEnabledChanged(): void {
            if (!GlobalConfig.general.screensaver.enabled)
                root.hide();
        }

        target: GlobalConfig.general.screensaver
    }

    Connections {
        function onAllowScreensaverChanged(): void {
            if (Visibilities.sessionLocked && !GlobalConfig.lock.allowScreensaver)
                root.hide();
        }

        target: GlobalConfig.lock
    }

    Variants {
        model: Screens.screens

        ScreensaverSurface {
            required property ShellScreen modelData

            screen: modelData
            active: root.active
            effectId: root.effectiveEffectId
        }
    }
}
