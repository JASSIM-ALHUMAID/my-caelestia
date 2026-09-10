pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Launcher")
    isSubPage: true

    readonly property bool floating: Config.launcher.mode === "floating"

    readonly property list<MenuItem> positionItems: [
        MenuItem { text: qsTr("Top"); property string value: "top" },
        MenuItem { text: qsTr("Bottom"); property string value: "bottom" },
        MenuItem { text: qsTr("Left"); property string value: "left" },
        MenuItem { text: qsTr("Right"); property string value: "right" },
        MenuItem { text: qsTr("Center"); property string value: "center" },
    ]

    // "Center" only means anything while floating (there's no edge to hug), so docked mode
    // never offers it. var, not list<MenuItem>, matching EdgeConflictPage's itemsFor() — a
    // filtered list is a plain JS array, not the literal-of-components form list<T> expects.
    readonly property var visiblePositionItems: root.floating ? root.positionItems : root.positionItems.filter(item => item.value !== "center")

    readonly property MenuItem activePositionItem: {
        for (const item of root.visiblePositionItems)
            if (item.value === Config.launcher.position) return item;
        return root.visiblePositionItems[0];
    }

    readonly property list<MenuItem> modeItems: [
        MenuItem { text: qsTr("Docked"); property string value: "docked" },
        MenuItem { text: qsTr("Floating"); property string value: "floating" },
    ]

    readonly property MenuItem activeModeItem: {
        for (const item of root.modeItems)
            if (item.value === Config.launcher.mode) return item;
        return root.modeItems[0];
    }

    readonly property list<MenuItem> appLayoutItems: [
        MenuItem { text: qsTr("List"); property string value: "list" },
        MenuItem { text: qsTr("Grid"); property string value: "grid" },
    ]

    readonly property MenuItem activeAppLayoutItem: {
        for (const item of root.appLayoutItems)
            if (item.value === Config.launcher.appLayout) return item;
        return root.appLayoutItems[0];
    }

    // Switching back to docked while parked on "center" would otherwise leave the stored
    // position disagreeing with what Wrapper.qml actually renders (it coerces docked+center
    // to bottom purely visually) — write the real edge back so the config stays truthful.
    onFloatingChanged: {
        if (!floating && Config.launcher.position === "center")
            GlobalConfig.launcher.position = "bottom";
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // General
        SettingsSection {
            first: true
            expanded: true
            title: qsTr("General")

            ToggleRow {
                Layout.fillWidth: true
                first: true
                text: qsTr("Enabled")
                checked: Config.launcher.enabled
                onToggled: GlobalConfig.launcher.enabled = checked
            }

            ToggleRow {
                Layout.fillWidth: true
                last: true
                text: qsTr("Show on hover")
                subtext: qsTr("Reveal when the cursor reaches the screen edge")
                checked: Config.launcher.showOnHover
                onToggled: GlobalConfig.launcher.showOnHover = checked
            }
        }

        // Display
        SettingsSection {
            title: qsTr("Display")

            SelectRow {
                Layout.fillWidth: true
                first: true
                label: qsTr("Position")
                subtext: qsTr("Which screen edge the launcher appears on")
                menuItems: root.visiblePositionItems
                active: root.activePositionItem
                onSelected: item => GlobalConfig.launcher.position = item.value
            }

            SelectRow {
                Layout.fillWidth: true
                label: qsTr("Mode")
                subtext: qsTr("Hug a screen edge, or float free of it")
                menuItems: root.modeItems
                active: root.activeModeItem
                onSelected: item => GlobalConfig.launcher.mode = item.value
            }

            StepperRow {
                id: gapRow

                Layout.fillWidth: true
                label: qsTr("Edge gap")
                subtext: qsTr("Distance between the launcher and the screen edge")
                visible: root.floating
                value: Config.launcher.gap
                from: 0
                to: 120
                stepSize: 4
                onMoved: v => GlobalConfig.launcher.gap = v
            }

            StepperRow {
                Layout.fillWidth: true
                label: qsTr("Max items shown")
                value: Config.launcher.maxShown
                from: 1
                to: 20
                stepSize: 1
                onMoved: v => GlobalConfig.launcher.maxShown = v
            }

            StepperRow {
                Layout.fillWidth: true
                label: qsTr("Max wallpapers")
                value: Config.launcher.maxWallpapers
                from: 1
                to: 30
                stepSize: 1
                onMoved: v => GlobalConfig.launcher.maxWallpapers = v
            }

            StepperRow {
                Layout.fillWidth: true
                label: qsTr("Drag threshold")
                subtext: qsTr("Pixels dragged before the launcher opens")
                value: Config.launcher.dragThreshold
                from: 0
                to: 200
                stepSize: 5
                onMoved: v => GlobalConfig.launcher.dragThreshold = v
            }

            SelectRow {
                Layout.fillWidth: true
                label: qsTr("App layout")
                subtext: qsTr("Show results as a list or a tiled grid")
                menuItems: root.appLayoutItems
                active: root.activeAppLayoutItem
                onSelected: item => GlobalConfig.launcher.appLayout = item.value
            }

            StepperRow {
                Layout.fillWidth: true
                label: qsTr("Grid columns")
                visible: Config.launcher.appLayout === "grid"
                value: Config.launcher.gridColumns
                from: 2
                to: 8
                stepSize: 1
                onMoved: v => GlobalConfig.launcher.gridColumns = v
            }

            StepperRow {
                Layout.fillWidth: true
                last: true
                label: qsTr("Icon size")
                subtext: qsTr("Multiplier applied to app icons in both layouts")
                value: Tokens.sizes.launcher.iconScale
                from: 0.5
                to: 2
                stepSize: 0.1
                onMoved: v => TokenConfig.sizes.launcher.iconScale = v
            }
        }

        // Behaviour
        SettingsSection {
            title: qsTr("Behaviour")

            ToggleRow {
                Layout.fillWidth: true
                first: true
                text: qsTr("Vim keybinds")
                subtext: qsTr("Navigate results with Ctrl+hjkl")
                checked: GlobalConfig.launcher.vimKeybinds
                onToggled: GlobalConfig.launcher.vimKeybinds = checked
            }

            ToggleRow {
                Layout.fillWidth: true
                text: qsTr("Enable dangerous actions")
                subtext: qsTr("Allow actions that shut down or log out")
                checked: GlobalConfig.launcher.enableDangerousActions
                onToggled: GlobalConfig.launcher.enableDangerousActions = checked
            }

            ToggleRow {
                Layout.fillWidth: true
                last: true
                text: qsTr("Show on fullscreen")
                subtext: qsTr("Keep the launcher visible when a fullscreen window is active")
                checked: Config.launcher.fullscreen !== "off"
                onToggled: GlobalConfig.launcher.fullscreen = checked ? "on" : "off"
            }
        }

        // Prefixes
        SettingsSection {
            title: qsTr("Prefixes")

            TextFieldRow {
                Layout.fillWidth: true
                Layout.topMargin: Tokens.padding.small
                label: qsTr("Action prefix")
                placeholder: qsTr(">")
                text: GlobalConfig.launcher.actionPrefix
                onTextModified: t => GlobalConfig.launcher.actionPrefix = t
            }

            TextFieldRow {
                Layout.fillWidth: true
                label: qsTr("Special prefix")
                placeholder: qsTr("@")
                text: GlobalConfig.launcher.specialPrefix
                onTextModified: t => GlobalConfig.launcher.specialPrefix = t
            }
        }

        // Fuzzy search
        SettingsSection {
            title: qsTr("Fuzzy search")

            ToggleRow {
                Layout.fillWidth: true
                first: true
                text: qsTr("Apps")
                checked: GlobalConfig.launcher.useFuzzy.apps
                onToggled: GlobalConfig.launcher.useFuzzy.apps = checked
            }

            ToggleRow {
                Layout.fillWidth: true
                text: qsTr("Actions")
                checked: GlobalConfig.launcher.useFuzzy.actions
                onToggled: GlobalConfig.launcher.useFuzzy.actions = checked
            }

            ToggleRow {
                Layout.fillWidth: true
                text: qsTr("Schemes")
                checked: GlobalConfig.launcher.useFuzzy.schemes
                onToggled: GlobalConfig.launcher.useFuzzy.schemes = checked
            }

            ToggleRow {
                Layout.fillWidth: true
                text: qsTr("Variants")
                checked: GlobalConfig.launcher.useFuzzy.variants
                onToggled: GlobalConfig.launcher.useFuzzy.variants = checked
            }

            ToggleRow {
                Layout.fillWidth: true
                last: true
                text: qsTr("Wallpapers")
                checked: GlobalConfig.launcher.useFuzzy.wallpapers
                onToggled: GlobalConfig.launcher.useFuzzy.wallpapers = checked
            }
        }
    }
}
