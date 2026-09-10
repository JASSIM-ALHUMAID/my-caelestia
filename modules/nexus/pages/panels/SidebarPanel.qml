pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Sidebar")
    isSubPage: true

    readonly property list<MenuItem> edgeItems: [
        MenuItem { text: qsTr("Left"); property string value: "left" },
        MenuItem { text: qsTr("Right"); property string value: "right" },
    ]

    readonly property MenuItem activeEdgeItem: {
        for (const item of root.edgeItems)
            if (item.value === Config.sidebar.edge) return item;
        return root.edgeItems[0];
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
            checked: Config.sidebar.enabled
            onToggled: GlobalConfig.sidebar.enabled = checked
        }

        SelectRow {
            Layout.fillWidth: true
            label: qsTr("Edge")
            subtext: qsTr("Which screen edge the sidebar sits on")
            menuItems: root.edgeItems
            active: root.activeEdgeItem
            onSelected: item => GlobalConfig.sidebar.edge = item.value
        }

        StepperRow {
            Layout.fillWidth: true
            last: true
            label: qsTr("Drag threshold")
            subtext: qsTr("Pixels dragged before the sidebar opens")
            value: Config.sidebar.dragThreshold
            from: 0
            to: 200
            stepSize: 5
            onMoved: v => GlobalConfig.sidebar.dragThreshold = v
        }
    }
}
