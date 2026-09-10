pragma Singleton

import QtQuick
import Caelestia.Config
import Quickshell
import Quickshell.Io

// Reads and switches Hyprland's tiling layout. `scrolling` is built into Hyprland (0.51+),
// so all three layouts here are available without any plugin.
//
// The bar writes the same cfgLayout key as Nexus, leaving HyprVarsWriter as the single
// config-file writer. The writer uses `hyprctl eval` for the instant path because the Lua parser
// rejects legacy `keyword` calls while still exiting successfully, which would fail silently.
Singleton {
    id: root

    readonly property var layouts: ["dwindle", "master", "scrolling"]
    property string detectedLayout: ""
    readonly property string current: layouts.includes(GlobalConfig.services.cfgLayout) ? GlobalConfig.services.cfgLayout : detectedLayout

    function displayName(layout: string): string {
        switch (layout) {
        case "dwindle":
            return qsTr("Dwindle");
        case "master":
            return qsTr("Master");
        case "scrolling":
            return qsTr("Scrolling");
        default:
            return layout;
        }
    }

    function iconFor(layout: string): string {
        switch (layout) {
        case "master":
            return "view_sidebar";
        case "scrolling":
            return "view_column";
        default:
            return "dashboard";
        }
    }

    function setLayout(layout: string): void {
        if (!layouts.includes(layout) || layout === current)
            return;

        GlobalConfig.services.cfgLayout = layout;
    }

    function cycle(dir: int): void {
        const idx = layouts.indexOf(current);
        const next = (((idx === -1 ? 0 : idx + dir) % layouts.length) + layouts.length) % layouts.length;
        setLayout(layouts[next]);
    }

    function refresh(): void {
        getLayoutProc.running = true;
    }

    Component.onCompleted: root.refresh()

    Process {
        id: getLayoutProc

        command: ["hyprctl", "getoption", "general:layout", "-j"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const layout = JSON.parse(text)?.str?.trim() ?? "";
                    if (root.layouts.includes(layout))
                        root.detectedLayout = layout;
                } catch (e) {
                    console.warn("HyprLayout: failed to parse hyprctl getoption output:", e);
                }
            }
        }
    }
}
