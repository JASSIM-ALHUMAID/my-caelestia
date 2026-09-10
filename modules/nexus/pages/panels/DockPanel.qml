pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Dock")
    isSubPage: true

    readonly property list<MenuItem> positionItems: [
        MenuItem { text: qsTr("Top"); property string value: "top" },
        MenuItem { text: qsTr("Bottom"); property string value: "bottom" },
        MenuItem { text: qsTr("Left"); property string value: "left" },
        MenuItem { text: qsTr("Right"); property string value: "right" },
    ]

    readonly property MenuItem activePositionItem: {
        for (const item of root.positionItems)
            if (item.value === Config.dock.position) return item;
        return root.positionItems[0];
    }

    readonly property list<MenuItem> popoutStyleItems: [
        MenuItem { text: qsTr("Hugged"); property string value: "hugged" },
        MenuItem { text: qsTr("Floating"); property string value: "floating" }
    ]

    readonly property MenuItem activePopoutStyleItem: {
        for (const item of root.popoutStyleItems)
            if (item.value === Config.dock.popoutMode) return item;
        return root.popoutStyleItems[0];
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
                checked: Config.dock.enabled
                onToggled: GlobalConfig.dock.enabled = checked
            }

            ToggleRow {
                Layout.fillWidth: true
                text: qsTr("Show on hover")
                subtext: qsTr("Reveal the dock by hovering at the screen edge")
                checked: Config.dock.showOnHover
                onToggled: GlobalConfig.dock.showOnHover = checked
            }

            ToggleRow {
                Layout.fillWidth: true
                text: qsTr("Hide on hover out")
                subtext: qsTr("Dismiss the dock when the mouse leaves its area")
                checked: Config.dock.hideOnHoverOut
                onToggled: GlobalConfig.dock.hideOnHoverOut = checked
            }

            SelectRow {
                Layout.fillWidth: true
                label: qsTr("Position")
                subtext: qsTr("Which screen edge the dock appears on")
                menuItems: root.positionItems
                active: root.activePositionItem
                onSelected: item => GlobalConfig.dock.position = item.value
            }

            StepperRow {
                Layout.fillWidth: true
                label: qsTr("Icon size")
                subtext: qsTr("Size of dock icons in pixels")
                value: Config.dock.iconSize
                from: Config.dock.minIconSize
                to: Config.dock.maxIconSize
                stepSize: 4
                onMoved: v => GlobalConfig.dock.iconSize = v
            }

            StepperRow {
                Layout.fillWidth: true
                label: qsTr("Spacing")
                subtext: qsTr("Gap between dock icons in pixels")
                value: Config.dock.spacing
                from: 0
                to: 32
                stepSize: 1
                onMoved: v => GlobalConfig.dock.spacing = v
            }

            StepperRow {
                Layout.fillWidth: true
                label: qsTr("Edge margin")
                subtext: qsTr("Gap between the dock and its screen edge, in pixels")
                last: true
                value: Config.dock.margin
                from: 0
                to: 64
                stepSize: 2
                onMoved: v => GlobalConfig.dock.margin = v
            }
        }

        // Pinning
        SettingsSection {
            title: qsTr("Pinning")

            ToggleRow {
                Layout.fillWidth: true
                first: true
                text: qsTr("Pinned")
                subtext: qsTr("Keep the dock open and reserve space so windows tile beside it")
                checked: Config.dock.pinned
                onToggled: GlobalConfig.dock.pinned = checked
            }

            ToggleRow {
                Layout.fillWidth: true
                text: qsTr("Show pin button")
                subtext: qsTr("Show a button to pin and unpin the dock")
                checked: Config.dock.showPinButton
                onToggled: GlobalConfig.dock.showPinButton = checked
            }

            ToggleRow {
                Layout.fillWidth: true
                text: qsTr("Keep hidden")
                subtext: qsTr("Reveal only on hover, overriding the pinned state")
                checked: Config.dock.keepHidden
                onToggled: GlobalConfig.dock.keepHidden = checked
            }

            ToggleRow {
                Layout.fillWidth: true
                text: qsTr("Available on fullscreen")
                subtext: qsTr("Allow the dock to appear over a fullscreen window")
                checked: Config.dock.availableOnFullscreen
                onToggled: GlobalConfig.dock.availableOnFullscreen = checked
            }

            ToggleRow {
                Layout.fillWidth: true
                last: true
                text: qsTr("Reveal on empty workspace")
                subtext: qsTr("Show the dock automatically when no windows are open")
                checked: Config.dock.revealOnEmptyWorkspace
                onToggled: GlobalConfig.dock.revealOnEmptyWorkspace = checked
            }
        }

        // Buttons
        SettingsSection {
            title: qsTr("Buttons")

            ToggleRow {
                Layout.fillWidth: true
                first: true
                text: qsTr("Show add button")
                subtext: qsTr("Show a button to add apps from the launcher")
                checked: Config.dock.showAddButton
                onToggled: GlobalConfig.dock.showAddButton = checked
            }

            ToggleRow {
                Layout.fillWidth: true
                text: qsTr("Show edit button")
                subtext: qsTr("Show a button to enter edit mode")
                checked: Config.dock.showEditButton
                onToggled: GlobalConfig.dock.showEditButton = checked
            }

            ToggleRow {
                Layout.fillWidth: true
                last: true
                text: qsTr("Show hover preview")
                subtext: qsTr("Show a window preview card when hovering a dock icon")
                checked: Config.dock.showHoverPopout
                onToggled: GlobalConfig.dock.showHoverPopout = checked
            }
        }

        // Popouts
        SettingsSection {
            title: qsTr("Popouts")

            SelectRow {
                Layout.fillWidth: true
                first: true
                label: qsTr("Popout style")
                subtext: qsTr("How popouts appear relative to the dock")
                menuItems: root.popoutStyleItems
                active: root.activePopoutStyleItem
                onSelected: item => GlobalConfig.dock.popoutMode = item.value
            }

            StepperRow {
                Layout.fillWidth: true
                label: qsTr("Popout gap")
                subtext: qsTr("Distance between a floating popout and the dock")
                value: Config.dock.popoutGap
                from: 0
                to: 64
                stepSize: 2
                onMoved: v => GlobalConfig.dock.popoutGap = v
            }

            StepperRow {
                Layout.fillWidth: true
                last: true
                label: qsTr("Hover grace")
                subtext: qsTr("How long a popout stays open after the cursor leaves, in ms")
                value: Config.dock.hoverGrace
                from: 0
                to: 1000
                stepSize: 25
                onMoved: v => GlobalConfig.dock.hoverGrace = v
            }
        }

        // Behaviour
        SettingsSection {
            title: qsTr("Behaviour")

            ToggleRow {
                Layout.fillWidth: true
                first: true
                text: qsTr("Allow drag-and-drop reorder")
                subtext: qsTr("Reorder pinned dock items by dragging them")
                checked: Config.dock.dragAndDrop
                onToggled: GlobalConfig.dock.dragAndDrop = checked
            }

            ToggleRow {
                Layout.fillWidth: true
                text: qsTr("Wiggle in edit mode")
                subtext: qsTr("Jiggle the icons while edit mode is active")
                checked: Config.dock.wiggleInEditMode
                onToggled: GlobalConfig.dock.wiggleInEditMode = checked
            }

            ToggleRow {
                Layout.fillWidth: true
                text: qsTr("Hide on activate")
                subtext: qsTr("Dismiss the dock after clicking an icon")
                checked: Config.dock.hideOnActivate
                onToggled: GlobalConfig.dock.hideOnActivate = checked
            }

            ToggleRow {
                Layout.fillWidth: true
                text: qsTr("Cycle windows on click")
                subtext: qsTr("Clicking a running app steps through its windows")
                checked: Config.dock.cycleWindowsOnClick
                onToggled: GlobalConfig.dock.cycleWindowsOnClick = checked
            }

            ToggleRow {
                Layout.fillWidth: true
                text: qsTr("Show special workspace apps")
                subtext: qsTr("Include apps running on special workspaces in the dock")
                checked: Config.dock.showSpecialWorkspaceApps
                onToggled: GlobalConfig.dock.showSpecialWorkspaceApps = checked
            }

            ToggleRow {
                Layout.fillWidth: true
                last: true
                text: qsTr("Middle click opens new instance")
                subtext: qsTr("Middle clicking an icon always launches a new window")
                checked: Config.dock.middleClickNewInstance
                onToggled: GlobalConfig.dock.middleClickNewInstance = checked
            }
        }

        // Indicators
        SettingsSection {
            title: qsTr("Indicators")

            ToggleRow {
                Layout.fillWidth: true
                first: true
                text: qsTr("Show running indicators")
                subtext: qsTr("Draw a dot under each running app")
                checked: Config.dock.showRunningIndicators
                onToggled: GlobalConfig.dock.showRunningIndicators = checked
            }

            ToggleRow {
                Layout.fillWidth: true
                text: qsTr("Show separator")
                subtext: qsTr("Divide pinned apps from ones that are merely running")
                checked: Config.dock.showSeparator
                onToggled: GlobalConfig.dock.showSeparator = checked
            }

            StepperRow {
                Layout.fillWidth: true
                last: true
                label: qsTr("Maximum indicator dots")
                subtext: qsTr("Dots drawn per app before they collapse to squares")
                value: Config.dock.maxIndicatorDots
                from: 1
                to: 6
                stepSize: 1
                onMoved: v => GlobalConfig.dock.maxIndicatorDots = v
            }
        }
    }
}
