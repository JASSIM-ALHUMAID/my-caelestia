pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components.controls
import qs.modules.nexus
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Taskbar")
    isSubPage: true

    readonly property string edge: root.nState.selectedEdge

    readonly property list<MenuItem> edgeItems: [
        MenuItem { text: qsTr("Left"); property string value: "left" },
        MenuItem { text: qsTr("Right"); property string value: "right" },
        MenuItem { text: qsTr("Top"); property string value: "top" },
        MenuItem { text: qsTr("Bottom"); property string value: "bottom" },
    ]

    readonly property MenuItem activeEdgeItem: {
        for (const item of root.edgeItems)
            if (item.value === root.edge) return item;
        return root.edgeItems[0];
    }

    readonly property list<MenuItem> popoutStyleItems: [
        MenuItem { text: qsTr("Hugged"); property string value: "hugged" },
        MenuItem { text: qsTr("Floating"); property string value: "floating" }
    ]

    readonly property list<MenuItem> overflowModeItems: [
        MenuItem { text: qsTr("Cap entries"); property string value: "cap" },
        MenuItem { text: qsTr("Overflow popout"); property string value: "popout" },
        MenuItem { text: qsTr("Do nothing"); property string value: "none" }
    ]

    readonly property MenuItem activeOverflowModeItem: {
        for (const item of root.overflowModeItems)
            if (item.value === Config.bar[root.edge].overflow.mode) return item;
        return root.overflowModeItems[0];
    }

    readonly property MenuItem activePopoutStyleItem: {
        for (const item of root.popoutStyleItems)
            if (item.value === Config.bar[root.edge].popouts.mode) return item;
        return root.popoutStyleItems[0];
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Edge selector
        SettingsSection {
            first: true
            expanded: true
            title: qsTr("Edge")

            SelectRow {
                Layout.fillWidth: true
                first: true
                last: true
                label: qsTr("Selected edge")
                subtext: qsTr("Which screen edge to configure")
                menuItems: root.edgeItems
                active: root.activeEdgeItem
                onSelected: item => root.nState.selectedEdge = item.value
            }
        }

        // Behaviour
        SettingsSection {
            title: qsTr("Behaviour")

            ToggleRow {
                Layout.fillWidth: true
                first: true
                text: qsTr("Enabled")
                subtext: qsTr("Show this bar on the selected edge")
                checked: Config.bar[root.edge].enabled
                onToggled: GlobalConfig.bar[root.edge].enabled = checked
            }

            ToggleRow {
                Layout.fillWidth: true
                text: qsTr("Persistent")
                subtext: qsTr("Keep the bar visible at all times")
                checked: Config.bar[root.edge].persistent
                onToggled: GlobalConfig.bar[root.edge].persistent = checked
            }

            ToggleRow {
                Layout.fillWidth: true
                text: qsTr("Show on hover")
                subtext: qsTr("Reveal the bar when the cursor reaches the screen edge")
                checked: Config.bar[root.edge].showOnHover
                onToggled: GlobalConfig.bar[root.edge].showOnHover = checked
            }

            ToggleRow {
                Layout.fillWidth: true
                text: qsTr("Floating")
                subtext: qsTr("Draw over windows instead of reserving space for the bar")
                checked: Config.bar[root.edge].floating
                onToggled: GlobalConfig.bar[root.edge].floating = checked
            }

            ToggleRow {
                Layout.fillWidth: true
                text: qsTr("Hide on hover out")
                subtext: qsTr("Dismiss the bar when the mouse leaves its area")
                checked: Config.bar[root.edge].hideOnHoverOut
                onToggled: GlobalConfig.bar[root.edge].hideOnHoverOut = checked
            }

            ToggleRow {
                Layout.fillWidth: true
                text: qsTr("Reveal on empty workspace")
                subtext: qsTr("Show the bar automatically when no windows are open")
                checked: Config.bar[root.edge].revealOnEmptyWorkspace
                onToggled: GlobalConfig.bar[root.edge].revealOnEmptyWorkspace = checked
            }

            StepperRow {
                Layout.fillWidth: true
                label: qsTr("Drag threshold")
                subtext: qsTr("Pixels dragged before the bar reveals")
                value: Config.bar[root.edge].dragThreshold
                from: 0
                to: 200
                stepSize: 5
                onMoved: v => GlobalConfig.bar[root.edge].dragThreshold = v
            }

            StepperRow {
                Layout.fillWidth: true
                label: qsTr("Start corner padding")
                subtext: qsTr("Extra padding at the bar's start edge (top for left/right bars, left for top/bottom bars)")
                value: Config.bar[root.edge].startCornerPadding
                from: 0
                to: 100
                stepSize: 5
                onMoved: v => GlobalConfig.bar[root.edge].startCornerPadding = v
            }

            StepperRow {
                Layout.fillWidth: true
                last: true
                label: qsTr("End corner padding")
                subtext: qsTr("Extra padding at the bar's end edge (bottom for left/right bars, right for top/bottom bars)")
                value: Config.bar[root.edge].endCornerPadding
                from: 0
                to: 100
                stepSize: 5
                onMoved: v => GlobalConfig.bar[root.edge].endCornerPadding = v
            }
        }

        // Components
        SettingsSection {
            title: qsTr("Components")

            NavRow {
                first: true
                icon: "workspaces"
                label: qsTr("Workspaces")
                status: qsTr("Indicators, window icons")
                onClicked: root.nState.openSubPage(PageCompRegistry.panelsSubPages.barWorkspaces)
            }

            NavRow {
                icon: "web_asset"
                label: qsTr("Active window")
                status: qsTr("Title display, popout")
                onClicked: root.nState.openSubPage(PageCompRegistry.panelsSubPages.barActiveWindow)
            }

            NavRow {
                icon: "widgets"
                label: qsTr("Tray")
                status: qsTr("System tray icons")
                onClicked: root.nState.openSubPage(PageCompRegistry.panelsSubPages.barTray)
            }

            NavRow {
                icon: "signal_cellular_alt"
                label: qsTr("Status icons")
                status: qsTr("Visible indicators")
                onClicked: root.nState.openSubPage(PageCompRegistry.panelsSubPages.barStatusIcons)
            }

            NavRow {
                icon: "schedule"
                label: qsTr("Clock")
                status: qsTr("Date, icon, background")
                onClicked: root.nState.openSubPage(PageCompRegistry.panelsSubPages.barClock)
            }

            NavRow {
                icon: "dock_to_bottom"
                label: qsTr("Dock")
                status: qsTr("Icon size, indicator position")
                onClicked: root.nState.openSubPage(PageCompRegistry.panelsSubPages.barDock)
            }

            NavRow {
                icon: "graphic_eq"
                label: qsTr("Visualiser")
                status: qsTr("Cava sound visualiser bars")
                onClicked: root.nState.openSubPage(PageCompRegistry.panelsSubPages.barVisualiser)
            }

            NavRow {
                last: true
                icon: "reorder"
                label: qsTr("Bar entries")
                status: qsTr("Order, visibility, logo variant")
                onClicked: root.nState.openSubPage(PageCompRegistry.panelsSubPages.barEntries)
            }
        }

        // Scroll actions
        SettingsSection {
            title: qsTr("Scroll actions")

            ToggleRow {
                Layout.fillWidth: true
                first: true
                text: qsTr("Workspaces")
                subtext: qsTr("Scroll over the workspace indicator to switch workspaces")
                checked: Config.bar[root.edge].scrollActions.workspaces
                onToggled: GlobalConfig.bar[root.edge].scrollActions.workspaces = checked
            }

            ToggleRow {
                Layout.fillWidth: true
                text: qsTr("Volume")
                subtext: qsTr("Scroll on the top half of the bar to adjust volume")
                checked: Config.bar[root.edge].scrollActions.volume
                onToggled: GlobalConfig.bar[root.edge].scrollActions.volume = checked
            }

            ToggleRow {
                Layout.fillWidth: true
                last: true
                text: qsTr("Brightness")
                subtext: qsTr("Scroll on the bottom half of the bar to adjust brightness")
                checked: Config.bar[root.edge].scrollActions.brightness
                onToggled: GlobalConfig.bar[root.edge].scrollActions.brightness = checked
            }
        }

        // Popouts
        SettingsSection {
            title: qsTr("Popouts")

            SelectRow {
                Layout.fillWidth: true
                first: true
                label: qsTr("Popout style")
                subtext: qsTr("How popouts appear relative to the bar")
                menuItems: root.popoutStyleItems
                active: root.activePopoutStyleItem
                onSelected: item => GlobalConfig.bar[root.edge].popouts.mode = item.value
            }

            StepperRow {
                Layout.fillWidth: true
                label: qsTr("Popout gap")
                subtext: qsTr("Distance between a floating popout and the bar")
                value: Config.bar[root.edge].popouts.gap
                from: 0
                to: 64
                stepSize: 2
                onMoved: v => GlobalConfig.bar[root.edge].popouts.gap = v
            }

            StepperRow {
                Layout.fillWidth: true
                last: true
                label: qsTr("Hover grace")
                subtext: qsTr("How long a popout stays open after the cursor leaves, in ms")
                value: Config.bar[root.edge].popouts.hoverGrace
                from: 0
                to: 1000
                stepSize: 25
                onMoved: v => GlobalConfig.bar[root.edge].popouts.hoverGrace = v
            }
        }

        // Overflow
        SettingsSection {
            title: qsTr("Overflow")

            SelectRow {
                Layout.fillWidth: true
                first: true
                label: qsTr("When entries don't fit")
                subtext: qsTr("Cap shrinks the busy entries; popout moves what it can into a ⋯ menu, then caps the rest")
                menuItems: root.overflowModeItems
                active: root.activeOverflowModeItem
                onSelected: item => GlobalConfig.bar[root.edge].overflow.mode = item.value
            }

            ToggleRow {
                Layout.fillWidth: true
                text: qsTr("Show hidden count")
                subtext: qsTr("Draw a \"+N\" chip on the tray and dock when icons were dropped")
                checked: Config.bar[root.edge].overflow.showCount
                onToggled: GlobalConfig.bar[root.edge].overflow.showCount = checked
            }

            StepperRow {
                Layout.fillWidth: true
                label: qsTr("Minimum window icons")
                subtext: qsTr("Window icons per workspace the cap will not go below")
                value: Config.bar[root.edge].overflow.minWindowIcons
                from: 1
                to: 10
                stepSize: 1
                onMoved: v => GlobalConfig.bar[root.edge].overflow.minWindowIcons = v
            }

            StepperRow {
                Layout.fillWidth: true
                label: qsTr("Minimum dock icons")
                subtext: qsTr("App icons the dock cap will not go below")
                value: Config.bar[root.edge].overflow.minDockIcons
                from: 1
                to: 20
                stepSize: 1
                onMoved: v => GlobalConfig.bar[root.edge].overflow.minDockIcons = v
            }

            StepperRow {
                Layout.fillWidth: true
                last: true
                label: qsTr("Minimum tray icons")
                subtext: qsTr("Tray icons the cap will not go below")
                value: Config.bar[root.edge].overflow.minTrayIcons
                from: 1
                to: 20
                stepSize: 1
                onMoved: v => GlobalConfig.bar[root.edge].overflow.minTrayIcons = v
            }
        }
    }
}
