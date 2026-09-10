pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components.controls
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Notifications")
    isSubPage: true

    readonly property list<MenuItem> popoutStyleItems: [
        MenuItem { text: qsTr("Hugged"); property string value: "hugged" },
        MenuItem { text: qsTr("Floating"); property string value: "floating" }
    ]

    readonly property MenuItem activePopoutStyleItem: {
        for (const item of root.popoutStyleItems)
            if (item.value === Config.notifs.popoutMode) return item;
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
                text: qsTr("Expire")
                subtext: qsTr("Auto-dismiss notifications after timeout")
                checked: Config.notifs.expire
                onToggled: GlobalConfig.notifs.expire = checked
            }

            ToggleRow {
                Layout.fillWidth: true
                text: qsTr("Action on click")
                subtext: qsTr("Invoke the first action when clicking a notification")
                checked: Config.notifs.actionOnClick
                onToggled: GlobalConfig.notifs.actionOnClick = checked
            }

            ToggleRow {
                Layout.fillWidth: true
                last: true
                text: qsTr("Open expanded")
                subtext: qsTr("Show full notification body by default")
                checked: Config.notifs.openExpanded
                onToggled: GlobalConfig.notifs.openExpanded = checked
            }
        }

        // Timeouts
        SettingsSection {
            title: qsTr("Timeouts")

            StepperRow {
                Layout.fillWidth: true
                first: true
                label: qsTr("Default expire")
                subtext: qsTr("Milliseconds before notification auto-dismisses")
                value: Config.notifs.defaultExpireTimeout
                from: 1000
                to: 30000
                stepSize: 500
                onMoved: v => GlobalConfig.notifs.defaultExpireTimeout = v
            }

            StepperRow {
                Layout.fillWidth: true
                last: true
                label: qsTr("Fullscreen expire")
                subtext: qsTr("Faster timeout when a window is fullscreen")
                value: Config.notifs.fullscreenExpireTimeout
                from: 500
                to: 10000
                stepSize: 250
                onMoved: v => GlobalConfig.notifs.fullscreenExpireTimeout = v
            }
        }

        // Popouts
        SettingsSection {
            title: qsTr("Popouts")

            SelectRow {
                Layout.fillWidth: true
                first: true
                label: qsTr("Popout style")
                subtext: qsTr("How the notification list appears relative to the screen edge")
                menuItems: root.popoutStyleItems
                active: root.activePopoutStyleItem
                onSelected: item => GlobalConfig.notifs.popoutMode = item.value
            }

            StepperRow {
                Layout.fillWidth: true
                visible: Config.notifs.popoutMode === "floating"
                label: qsTr("Popout gap")
                subtext: qsTr("Distance between a floating popout and the screen edge")
                value: Config.notifs.popoutGap
                from: 0
                to: 64
                stepSize: 2
                onMoved: v => GlobalConfig.notifs.popoutGap = v
            }

            StepperRow {
                Layout.fillWidth: true
                last: true
                label: qsTr("Hover grace")
                subtext: qsTr("How long to wait before restarting auto-expire after cursor leaves, in ms")
                value: Config.notifs.hoverGrace
                from: 0
                to: 1000
                stepSize: 25
                onMoved: v => GlobalConfig.notifs.hoverGrace = v
            }
        }

        // Interaction
        SettingsSection {
            title: qsTr("Interaction")

            StepperRow {
                Layout.fillWidth: true
                first: true
                label: qsTr("Clear threshold")
                subtext: qsTr("Fraction of width to swipe for dismissal")
                value: Math.round(Config.notifs.clearThreshold * 100)
                from: 10
                to: 90
                stepSize: 5
                onMoved: v => GlobalConfig.notifs.clearThreshold = v / 100
            }

            StepperRow {
                Layout.fillWidth: true
                last: true
                label: qsTr("Expand threshold")
                subtext: qsTr("Vertical drag distance in px to expand/collapse")
                value: Config.notifs.expandThreshold
                from: 5
                to: 50
                stepSize: 5
                onMoved: v => GlobalConfig.notifs.expandThreshold = v
            }
        }
    }
}
