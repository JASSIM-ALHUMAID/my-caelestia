pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Desktop")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Widgets")
        }

        NavRow {
            Layout.fillWidth: true
            first: true
            icon: "schedule"
            label: qsTr("Desktop clock")
            status: Config.background.desktopClock.enabled ? qsTr("Enabled") : qsTr("Disabled")
            onClicked: root.nState.openSubPage(1)
        }

        NavRow {
            Layout.fillWidth: true
            icon: "battery_std"
            label: qsTr("Desktop battery")
            status: Config.background.desktopBattery.enabled ? qsTr("Enabled") : qsTr("Disabled")
            onClicked: root.nState.openSubPage(3)
        }

        NavRow {
            Layout.fillWidth: true
            last: true
            icon: "equalizer"
            label: qsTr("Visualiser")
            status: Config.background.visualiser.enabled ? qsTr("Enabled") : qsTr("Disabled")
            onClicked: root.nState.openSubPage(2)
        }
    }
}
