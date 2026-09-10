pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils
import qs.modules.launcher.services
import qs.modules.nexus.common
import "../../../../services/HyprSchema.js" as Schema

// Hyprland variables -- everything that is a key in ~/.local/share/caelestia/hypr/variables.lua.
// The numeric/boolean/string rows come from HyprSchema.VAR_SECTIONS; Cursor and Apps stay
// hand-written because they populate their options from the system (installed cursor themes,
// DesktopEntries) rather than from the schema.
PageBase {
    id: root

    property list<string> cursorThemeNames: []

    // Keyed by appKinds[].kind. A binding rather than an imperative rebuild so it also tracks
    // launcher.hiddenApps and the current selection, not just the entry index.
    readonly property var appLists: {
        const lists = ({});
        for (const kind of root.appKinds)
            lists[kind.kind] = root.appsForKind(kind);
        return lists;
    }

    readonly property var appKinds: [
        { kind: "terminal", categories: ["TerminalEmulator"], overrides: ["foot", "kitty", "wezterm", "alacritty", "ghostty", "contour"], configKey: "appTerminal", defaultId: "foot", label: qsTr("Terminal"), subtext: qsTr("Default terminal emulator"), icon: "terminal" },
        { kind: "browser", categories: ["WebBrowser"], overrides: ["firefox", "chromium", "google-chrome", "brave", "vivaldi"], configKey: "appBrowser", defaultId: "firefox", label: qsTr("Browser"), subtext: qsTr("Default web browser"), icon: "language" },
        { kind: "editor", categories: ["TextEditor", "IDE"], overrides: ["codium", "zeditor", "kate", "sublime-text", "nvim-qt"], configKey: "appEditor", defaultId: "codium", label: qsTr("Editor"), subtext: qsTr("Default text editor"), icon: "code" },
        { kind: "fileExplorer", categories: ["FileManager"], overrides: ["thunar", "nautilus", "dolphin", "nemo", "pcmanfm"], configKey: "appFileExplorer", defaultId: "thunar", label: qsTr("File explorer"), subtext: qsTr("Default file manager"), icon: "folder" },
        { kind: "audioSettings", categories: ["Audio"], excludeCategories: ["Player", "Recorder", "Video"], overrides: ["org.pulseaudio.pavucontrol", "pavucontrol", "pulsemixer", "helvum", "qpwgraph"], configKey: "appAudioSettings", defaultId: "pavucontrol", label: qsTr("Audio settings"), subtext: qsTr("Audio control application"), icon: "volume_up" }
    ]

    function appsForKind(kind: var): list<var> {
        const all = DesktopEntries.applications.values;
        const byId = ({});

        const add = (entry, force) => {
            if (!entry || byId[entry.id])
                return;
            if (!force && (entry.noDisplay || Strings.testRegexList(GlobalConfig.launcher.hiddenApps, entry.id)))
                return;
            byId[entry.id] = {
                id: entry.id,
                name: entry.name,
                iconSource: Quickshell.iconPath(entry.icon, "image-missing"),
                entry: entry
            };
        };

        // A category match alone is too coarse for some kinds -- "Audio" also covers players --
        // so a kind may veto entries carrying an excluded category.
        const excluded = kind.excludeCategories ?? [];
        for (const a of all)
            if (a.categories?.some(c => kind.categories.includes(c)) && !a.categories.some(c => excluded.includes(c)))
                add(a, false);

        // Well-known apps whose entry may lack the expected category. The stored value is a bare
        // entry id, but tolerate an id suffix or an exec name so hand-written config still resolves.
        const lookup = key => key ? all.find(a => a.id === key || a.id.endsWith(`.${key}`) || a.execString === key) : null;
        for (const override of kind.overrides)
            add(lookup(override), false);

        // The current selection is always listed, even if hidden, so the row can show its name
        add(lookup(GlobalConfig.services[kind.configKey]), true);

        return Object.values(byId).sort((a, b) => a.name.localeCompare(b.name) || a.id.localeCompare(b.id));
    }

    title: qsTr("Variables")
    isSubPage: true

    // isModified is a method, which a binding can't depend on. Reading the property first
    // registers it with the enclosing binding, so the reset affordance re-evaluates whenever
    // the value changes -- including when resetOption writes the default back.
    function isModified(key: string): bool {
        GlobalConfig.services[key];
        return GlobalConfig.services.isModified(key);
    }

    // Schema-derived, so it can't drift from the rows on screen the way the old hand-written
    // list did. The app and cursor keys aren't in the schema, hence the concat.
    readonly property list<string> resetKeys: Schema.allKeys(Schema.VAR_SECTIONS).concat(["cursorTheme", "cursorSize", "appTerminal", "appBrowser", "appEditor", "appFileExplorer", "appAudioSettings"])

    function resetAll(): void {
        for (const key of root.resetKeys)
            GlobalConfig.services.resetOption(key);
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Reset all button. Resetting every variable can't be undone, so it takes two clicks --
        // the second one has to land while the button is still asking.
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.extraSmall

            Item {
                Layout.fillWidth: true
            }

            IconTextButton {
                id: resetAllButton

                property bool confirming: false

                icon: confirming ? "warning" : "restart_alt"
                text: confirming ? qsTr("Reset everything?") : qsTr("Reset all to defaults")
                type: IconTextButton.Tonal
                onClicked: {
                    if (confirming) {
                        confirming = false;
                        confirmTimeout.stop();
                        root.resetAll();
                    } else {
                        confirming = true;
                        confirmTimeout.restart();
                    }
                }

                Timer {
                    id: confirmTimeout

                    interval: 4000
                    onTriggered: resetAllButton.confirming = false
                }
            }
        }

        // Discover installed cursor themes. Re-runs whenever the page is shown so a theme
        // installed since the shell started still turns up.
        Process {
            id: cursorDiscovery

            running: true
            command: ["sh", "-c", "for dir in /usr/share/icons/* ~/.local/share/icons/*; do [ -d \"$dir/cursors\" ] && basename \"$dir\"; done | sort -u"]
            stdout: StdioCollector {
                onStreamFinished: {
                    const themes = text.trim().split("\n").filter(t => t.length > 0);
                    root.cursorThemeNames = themes;
                }
            }
        }

        Connections {
            target: root

            function onVisibleChanged(): void {
                if (root.visible && !cursorDiscovery.running)
                    cursorDiscovery.running = true;
            }
        }

        HyprSectionList {
            sections: Schema.VAR_SECTIONS
        }

        // Cursor
        CollapsibleSection {
            Layout.fillWidth: true
            title: qsTr("Cursor")
            showBackground: false

            Variants {
                id: cursorThemeVariants

                model: root.cursorThemeNames

                MenuItem {
                    required property string modelData

                    text: modelData
                    icon: modelData === GlobalConfig.services.cursorTheme ? "check" : ""
                    activeIcon: "mouse"
                }
            }

            SelectRow {
                Layout.fillWidth: true
                first: true
                label: qsTr("Cursor theme")
                subtext: qsTr("Pointer appearance across the desktop")
                menuOnTop: true
                menuItems: cursorThemeVariants.instances
                active: menuItems.find(i => i.text === GlobalConfig.services.cursorTheme) ?? null
                fallbackIcon: "mouse"
                fallbackText: GlobalConfig.services.cursorTheme || qsTr("None")
                onSelected: item => GlobalConfig.services.cursorTheme = item.text
            }

            StepperRow {
                Layout.fillWidth: true
                last: true
                label: qsTr("Cursor size")
                subtext: qsTr("Pointer size in pixels")
                value: GlobalConfig.services.cursorSize
                from: 8
                to: 48
                stepSize: 2
                resetIcon: root.isModified("cursorSize") ? "restart_alt" : ""
                onMoved: v => GlobalConfig.services.cursorSize = v
                onResetRequested: GlobalConfig.services.resetOption("cursorSize")
            }
        }

        // Apps
        CollapsibleSection {
            Layout.fillWidth: true
            title: qsTr("Apps")
            showBackground: false

            Repeater {
                model: root.appKinds

                RowLayout {
                    id: appRow

                    required property int index
                    required property var modelData

                    readonly property var apps: root.appLists[modelData.kind] ?? []
                    readonly property string currentId: GlobalConfig.services[modelData.configKey]

                    // Tolerates a legacy value stored as a bare name (e.g. "wezterm" for
                    // org.wezfurlong.wezterm) so the row still shows the right app
                    readonly property var current: apps.find(a => a.id === appRow.currentId) ?? apps.find(a => a.id.endsWith(`.${appRow.currentId}`)) ?? null

                    Layout.fillWidth: true
                    spacing: 0

                    Variants {
                        id: appVariants

                        model: appRow.apps

                        MenuItem {
                            required property var modelData

                            readonly property string appId: modelData.id

                            text: modelData.name
                            iconSource: modelData.iconSource
                            activeIcon: appRow.modelData.icon
                            trailingIcon: modelData.id === appRow.current?.id ? "check" : ""
                        }
                    }

                    SelectRow {
                        Layout.fillWidth: true
                        first: appRow.index === 0
                        last: appRow.index === root.appKinds.length - 1
                        label: appRow.modelData.label
                        subtext: appRow.modelData.subtext
                        menuOnTop: true
                        menuItems: appVariants.instances
                        active: menuItems.find(i => i.appId === appRow.current?.id) ?? null
                        fallbackIcon: appRow.modelData.icon
                        fallbackText: appRow.currentId
                        fallbackIconSource: appRow.current?.iconSource ?? ""
                        onSelected: item => GlobalConfig.services.setOption(appRow.modelData.configKey, item.appId)
                    }

                    IconButton {
                        icon: "play_arrow"
                        type: IconButton.Text
                        onClicked: {
                            const entry = appRow.current?.entry;
                            if (entry)
                                Apps.launch(entry);
                        }
                    }
                }
            }
        }
    }
}
