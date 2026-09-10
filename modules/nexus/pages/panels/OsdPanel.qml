pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("OSD")
    isSubPage: true

    readonly property list<MenuItem> positionItems: [
        MenuItem { text: qsTr("Left"); property string value: "left" },
        MenuItem { text: qsTr("Right"); property string value: "right" },
        MenuItem { text: qsTr("Top"); property string value: "top" },
        MenuItem { text: qsTr("Bottom"); property string value: "bottom" },
    ]

    readonly property MenuItem activePositionItem: {
        for (const item of root.positionItems)
            if (item.value === Config.osd.position) return item;
        return root.positionItems[0];
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("General")
        }

        ToggleRow {
            Layout.fillWidth: true
            first: true
            text: qsTr("Enabled")
            checked: Config.osd.enabled
            onToggled: GlobalConfig.osd.enabled = checked
        }

        ToggleRow {
            Layout.fillWidth: true
            text: qsTr("Reveal on hover")
            subtext: qsTr("Also requires this edge's hover gesture to be set to OSD")
            checked: Config.osd.showOnHover
            onToggled: GlobalConfig.osd.showOnHover = checked
        }

        SelectRow {
            Layout.fillWidth: true
            last: true
            label: qsTr("Position")
            subtext: qsTr("Which screen edge the OSD appears on")
            menuItems: root.positionItems
            active: root.activePositionItem
            onSelected: item => GlobalConfig.osd.position = item.value
        }

        SectionHeader {
            text: qsTr("Features")
        }

        ToggleRow {
            Layout.fillWidth: true
            first: true
            text: qsTr("Brightness control")
            checked: Config.osd.enableBrightness
            onToggled: GlobalConfig.osd.enableBrightness = checked
        }

        ToggleRow {
            Layout.fillWidth: true
            last: true
            text: qsTr("Microphone control")
            checked: Config.osd.enableMicrophone
            onToggled: GlobalConfig.osd.enableMicrophone = checked
        }

        SectionHeader {
            text: qsTr("Behaviour")
        }

        StepperRow {
            Layout.fillWidth: true
            last: true
            label: qsTr("Hide delay")
            subtext: qsTr("Milliseconds before OSD hides")
            value: Config.osd.hideDelay
            from: 500
            to: 5000
            stepSize: 100
            onMoved: v => GlobalConfig.osd.hideDelay = v
        }
    }
}
