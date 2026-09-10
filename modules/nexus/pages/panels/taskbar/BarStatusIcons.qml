pragma ComponentBehavior: Bound

import QtQuick.Layouts
import Caelestia.Config
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Status icons")
    isSubPage: true

    readonly property string edge: root.nState.selectedEdge

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SettingsSection {
            first: true
            expanded: true
            title: qsTr("Visible icons")

            ToggleRow {
                Layout.fillWidth: true
                first: true
                text: qsTr("Speakers")
                checked: Config.bar[root.edge].status.showAudio
                onToggled: GlobalConfig.bar[root.edge].status.showAudio = checked
            }

            ToggleRow {
                Layout.fillWidth: true
                text: qsTr("Microphone")
                checked: Config.bar[root.edge].status.showMicrophone
                onToggled: GlobalConfig.bar[root.edge].status.showMicrophone = checked
            }

            ToggleRow {
                Layout.fillWidth: true
                text: qsTr("Keyboard layout")
                checked: Config.bar[root.edge].status.showKbLayout
                onToggled: GlobalConfig.bar[root.edge].status.showKbLayout = checked
            }

            ToggleRow {
                Layout.fillWidth: true
                text: qsTr("Network")
                checked: Config.bar[root.edge].status.showNetwork
                onToggled: GlobalConfig.bar[root.edge].status.showNetwork = checked
            }

            ToggleRow {
                Layout.fillWidth: true
                text: qsTr("Wi-Fi")
                checked: Config.bar[root.edge].status.showWifi
                onToggled: GlobalConfig.bar[root.edge].status.showWifi = checked
            }

            ToggleRow {
                Layout.fillWidth: true
                text: qsTr("Bluetooth")
                checked: Config.bar[root.edge].status.showBluetooth
                onToggled: GlobalConfig.bar[root.edge].status.showBluetooth = checked
            }

            ToggleRow {
                Layout.fillWidth: true
                text: qsTr("Battery")
                checked: Config.bar[root.edge].status.showBattery
                onToggled: GlobalConfig.bar[root.edge].status.showBattery = checked
            }

            ToggleRow {
                Layout.fillWidth: true
                last: true
                text: qsTr("Caps lock")
                checked: Config.bar[root.edge].status.showLockStatus
                onToggled: GlobalConfig.bar[root.edge].status.showLockStatus = checked
            }
        }

        // Battery
        SettingsSection {
            title: qsTr("Battery")

            ToggleRow {
                Layout.fillWidth: true
                first: true
                last: true
                text: qsTr("Show percentage")
                subtext: qsTr("Display battery percentage next to the icon")
                checked: Config.bar[root.edge].status.showBatteryPercentage
                onToggled: GlobalConfig.bar[root.edge].status.showBatteryPercentage = checked
            }
        }

        SettingsSection {
            title: qsTr("Behaviour")

            ToggleRow {
                Layout.fillWidth: true
                first: true
                last: true
                text: qsTr("Popout on hover")
                subtext: qsTr("Show a details popout when hovering the status icons")
                checked: Config.bar[root.edge].popouts.statusIcons
                onToggled: GlobalConfig.bar[root.edge].popouts.statusIcons = checked
            }
        }
    }
}
