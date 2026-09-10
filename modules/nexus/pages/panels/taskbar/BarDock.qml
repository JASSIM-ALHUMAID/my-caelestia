pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components.controls
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Dock")
    isSubPage: true

    readonly property string edge: root.nState.selectedEdge

    readonly property list<MenuItem> indicatorItems: [
        MenuItem { text: qsTr("Left"); property string value: "left" },
        MenuItem { text: qsTr("Right"); property string value: "right" },
        MenuItem { text: qsTr("Top"); property string value: "top" },
        MenuItem { text: qsTr("Bottom"); property string value: "bottom" },
    ]

    readonly property MenuItem activeIndicatorItem: {
        for (const item of root.indicatorItems)
            if (item.value === Config.bar[root.edge].dock.activeIndicatorPosition) return item;
        return root.indicatorItems[0];
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Behaviour")
        }

        ToggleRow {
            Layout.fillWidth: true
            first: true
            last: true
            text: qsTr("Show special workspace apps")
            subtext: qsTr("Switch Dock and Active window entries to the open special workspace")
            checked: Config.bar[root.edge].dock.showSpecialWorkspaceApps
            onToggled: GlobalConfig.bar[root.edge].dock.showSpecialWorkspaceApps = checked
        }

        SectionHeader {
            text: qsTr("Appearance")
        }

        StepperRow {
            Layout.fillWidth: true
            label: qsTr("Icon size")
            value: Config.bar[root.edge].dock.iconSize
            from: 16
            to: 64
            stepSize: 2
            onMoved: v => GlobalConfig.bar[root.edge].dock.iconSize = v
        }

        StepperRow {
            Layout.fillWidth: true
            label: qsTr("Indicator gap")
            subtext: qsTr("Space between the active dot and the app icon")
            value: Config.bar[root.edge].dock.indicatorGap
            from: 0
            to: 40
            stepSize: 2
            onMoved: v => GlobalConfig.bar[root.edge].dock.indicatorGap = v
        }

        SelectRow {
            Layout.fillWidth: true
            last: true
            label: qsTr("Indicator position")
            subtext: qsTr("Which side of the icon the active dot appears on")
            menuItems: root.indicatorItems
            active: root.activeIndicatorItem
            onSelected: item => GlobalConfig.bar[root.edge].dock.activeIndicatorPosition = item.value
        }
    }
}
