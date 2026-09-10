pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Dashboard")
    isSubPage: true

    readonly property list<MenuItem> positionItems: [
        MenuItem { text: qsTr("Top"); property string value: "top" },
        MenuItem { text: qsTr("Bottom"); property string value: "bottom" },
    ]

    readonly property MenuItem activePositionItem: {
        for (const item of root.positionItems)
            if (item.value === Config.dashboard.position) return item;
        return root.positionItems[0];
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
                checked: Config.dashboard.enabled
                onToggled: GlobalConfig.dashboard.enabled = checked
            }

            ToggleRow {
                Layout.fillWidth: true
                text: qsTr("Show on hover")
                subtext: qsTr("Reveal when the cursor reaches the screen edge")
                checked: Config.dashboard.showOnHover
                onToggled: GlobalConfig.dashboard.showOnHover = checked
            }

            ToggleRow {
                Layout.fillWidth: true
                text: qsTr("Show on fullscreen")
                subtext: qsTr("Keep the dashboard visible when a fullscreen window is active")
                checked: Config.dashboard.fullscreen !== "off"
                onToggled: GlobalConfig.dashboard.fullscreen = checked ? "on" : "off"
            }

            SelectRow {
                Layout.fillWidth: true
                last: true
                label: qsTr("Position")
                subtext: qsTr("Which screen edge the dashboard appears on")
                menuItems: root.positionItems
                active: root.activePositionItem
                onSelected: item => GlobalConfig.dashboard.position = item.value
            }
        }

        // Tabs
        SettingsSection {
            title: qsTr("Tabs")

            ToggleRow {
                Layout.fillWidth: true
                first: true
                text: qsTr("Dashboard")
                checked: Config.dashboard.showDashboard
                onToggled: GlobalConfig.dashboard.showDashboard = checked
            }

            ToggleRow {
                Layout.fillWidth: true
                text: qsTr("Media")
                checked: Config.dashboard.showMedia
                onToggled: GlobalConfig.dashboard.showMedia = checked
            }

            ToggleRow {
                Layout.fillWidth: true
                text: qsTr("Performance")
                checked: Config.dashboard.showPerformance
                onToggled: GlobalConfig.dashboard.showPerformance = checked
            }

            ToggleRow {
                Layout.fillWidth: true
                last: true
                text: qsTr("Weather")
                checked: Config.dashboard.showWeather
                onToggled: GlobalConfig.dashboard.showWeather = checked
            }
        }

        // Performance widgets
        SettingsSection {
            title: qsTr("Performance widgets")

            ToggleRow {
                Layout.fillWidth: true
                first: true
                text: qsTr("Battery")
                checked: Config.dashboard.performance.showBattery
                onToggled: GlobalConfig.dashboard.performance.showBattery = checked
            }

            ToggleRow {
                Layout.fillWidth: true
                text: qsTr("GPU")
                checked: Config.dashboard.performance.showGpu
                onToggled: GlobalConfig.dashboard.performance.showGpu = checked
            }

            ToggleRow {
                Layout.fillWidth: true
                text: qsTr("CPU")
                checked: Config.dashboard.performance.showCpu
                onToggled: GlobalConfig.dashboard.performance.showCpu = checked
            }

            ToggleRow {
                Layout.fillWidth: true
                text: qsTr("Memory")
                checked: Config.dashboard.performance.showMemory
                onToggled: GlobalConfig.dashboard.performance.showMemory = checked
            }

            ToggleRow {
                Layout.fillWidth: true
                text: qsTr("Storage")
                checked: Config.dashboard.performance.showStorage
                onToggled: GlobalConfig.dashboard.performance.showStorage = checked
            }

            ToggleRow {
                Layout.fillWidth: true
                last: true
                text: qsTr("Network")
                checked: Config.dashboard.performance.showNetwork
                onToggled: GlobalConfig.dashboard.performance.showNetwork = checked
            }
        }

        // Behaviour
        SettingsSection {
            title: qsTr("Behaviour")

            StepperRow {
                Layout.fillWidth: true
                first: true
                last: true
                label: qsTr("Drag threshold")
                subtext: qsTr("Pixels dragged before the dashboard opens")
                value: Config.dashboard.dragThreshold
                from: 0
                to: 200
                stepSize: 5
                onMoved: v => GlobalConfig.dashboard.dragThreshold = v
            }
        }
    }
}
