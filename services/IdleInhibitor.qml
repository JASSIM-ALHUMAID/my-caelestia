pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Caelestia.Config
import qs.services

Singleton {
    id: root

    property alias enabled: props.enabled
    readonly property alias enabledSince: props.enabledSince

    onEnabledChanged: {
        if (enabled) {
            props.enabledSince = new Date();
            Sounds.play(GlobalConfig.utilities.sounds.serviceOn);
        } else {
            Sounds.play(GlobalConfig.utilities.sounds.serviceOff);
        }
    }

    PersistentProperties {
        id: props

        property bool enabled
        property date enabledSince

        reloadableId: "idleInhibitor"
    }

    IdleInhibitor {
        enabled: props.enabled
        window: PanelWindow {
            implicitWidth: 0
            implicitHeight: 0
            color: "transparent"
            mask: Region {}
        }
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

        target: "idleInhibitor"
    }
}
