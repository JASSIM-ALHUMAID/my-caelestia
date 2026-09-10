pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import qs.services

Singleton {
    id: root

    property alias enabled: props.enabled

    // The Lua parser rejects the legacy `keyword` command but still replies, so a rejected
    // write is indistinguishable from a successful one. Everything goes through eval.
    function setDynamicConfs(): void {
        Hypr.extras.batchMessage(["eval hl.config({ animations = { enabled = false }, decoration = { shadow = { enabled = false }, blur = { enabled = false }, rounding = 0 }, general = { gaps_in = 0, gaps_out = 0, allow_tearing = true } })"]);
    }

    onEnabledChanged: {
        if (enabled) {
            setDynamicConfs();
            Sounds.play(GlobalConfig.utilities.sounds.serviceOn);
            if (GlobalConfig.utilities.toasts.gameModeChanged)
                Toaster.toast(qsTr("Game mode enabled"), qsTr("Disabled Hyprland animations, blur, gaps and shadows"), "gamepad");
        } else {
            Hypr.extras.message("reload");
            Sounds.play(GlobalConfig.utilities.sounds.serviceOff);
            if (GlobalConfig.utilities.toasts.gameModeChanged)
                Toaster.toast(qsTr("Game mode disabled"), qsTr("Hyprland settings restored"), "gamepad");
        }
    }

    PersistentProperties {
        id: props

        // Not seeded from Hyprland: `descriptions` reports a stale `current` after a reload,
        // so it cannot say whether game mode is really on. Nothing is lost -- game mode does
        // not outlive the shell, and Hyprland has already been restored by the time it starts.
        property bool enabled: false

        reloadableId: "gameMode"
    }

    Connections {
        function onConfigReloaded(): void {
            if (props.enabled)
                root.setDynamicConfs();
        }

        target: Hypr
    }

    IpcHandler {
        function isEnabled(): bool {
            return props.enabled;
        }

        function toggle(): void {
            props.enabled = !props.enabled;
        }

        function enable(): void {
            props.enabled = true;
        }

        function disable(): void {
            props.enabled = false;
        }

        target: "gameMode"
    }
}
