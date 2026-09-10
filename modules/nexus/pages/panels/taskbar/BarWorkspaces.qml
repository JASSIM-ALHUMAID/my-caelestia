pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components.controls
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Workspaces")
    isSubPage: true

    readonly property string edge: root.nState.selectedEdge

    readonly property list<MenuItem> capitalisationItems: [
        MenuItem { text: qsTr("Preserve"); property string value: "preserve" },
        MenuItem { text: qsTr("Upper"); property string value: "upper" },
        MenuItem { text: qsTr("Lower"); property string value: "lower" },
    ]

    readonly property MenuItem activeCapitalisationItem: {
        for (const item of root.capitalisationItems)
            if (item.value === Config.bar[root.edge].workspaces.capitalisation) return item;
        return root.capitalisationItems[0];
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        StepperRow {
            Layout.fillWidth: true
            first: true
            label: qsTr("Shown")
            subtext: qsTr("Number of workspaces displayed")
            value: Config.bar[root.edge].workspaces.shown
            from: 1
            to: 20
            stepSize: 1
            onMoved: v => GlobalConfig.bar[root.edge].workspaces.shown = v
        }

        ToggleRow {
            Layout.fillWidth: true
            text: qsTr("Active indicator")
            checked: Config.bar[root.edge].workspaces.activeIndicator
            onToggled: GlobalConfig.bar[root.edge].workspaces.activeIndicator = checked
        }

        ToggleRow {
            Layout.fillWidth: true
            text: qsTr("Active trail")
            checked: Config.bar[root.edge].workspaces.activeTrail
            onToggled: GlobalConfig.bar[root.edge].workspaces.activeTrail = checked
        }

        ToggleRow {
            Layout.fillWidth: true
            text: qsTr("Occupied background")
            checked: Config.bar[root.edge].workspaces.occupiedBg
            onToggled: GlobalConfig.bar[root.edge].workspaces.occupiedBg = checked
        }

        SectionHeader {
            text: qsTr("Display")
        }

        ToggleRow {
            Layout.fillWidth: true
            text: qsTr("Real app icons")
            subtext: qsTr("Show real application icons on workspace indicator")
            checked: Config.bar[root.edge].workspaces.appIcons
            onToggled: GlobalConfig.bar[root.edge].workspaces.appIcons = checked
        }

        ToggleRow {
            Layout.fillWidth: true
            text: qsTr("Numbered workspaces")
            subtext: qsTr("Show workspace numbers instead of symbols")
            checked: Config.bar[root.edge].workspaces.numbered
            onToggled: GlobalConfig.bar[root.edge].workspaces.numbered = checked
        }

        SelectRow {
            Layout.fillWidth: true
            label: qsTr("Capitalisation")
            menuItems: root.capitalisationItems
            active: root.activeCapitalisationItem
            onSelected: item => GlobalConfig.bar[root.edge].workspaces.capitalisation = item.value
        }

        ToggleRow {
            Layout.fillWidth: true
            text: qsTr("Show windows")
            subtext: qsTr("Show icons of open windows on each workspace")
            checked: Config.bar[root.edge].workspaces.showWindows
            onToggled: GlobalConfig.bar[root.edge].workspaces.showWindows = checked
        }

        ToggleRow {
            Layout.fillWidth: true
            text: qsTr("Show windows on active workspace")
            subtext: qsTr("Show window icons on the currently focused workspace")
            checked: Config.bar[root.edge].workspaces.showWindowsOnActive
            onToggled: GlobalConfig.bar[root.edge].workspaces.showWindowsOnActive = checked
        }

        ToggleRow {
            Layout.fillWidth: true
            text: qsTr("Windows on special workspaces")
            checked: Config.bar[root.edge].workspaces.showWindowsOnSpecialWorkspaces
            onToggled: GlobalConfig.bar[root.edge].workspaces.showWindowsOnSpecialWorkspaces = checked
        }

        StepperRow {
            Layout.fillWidth: true
            label: qsTr("Max window icons")
            value: Config.bar[root.edge].workspaces.maxWindowIcons
            from: 0
            to: 20
            stepSize: 1
            onMoved: v => GlobalConfig.bar[root.edge].workspaces.maxWindowIcons = v
        }

        StepperRow {
            Layout.fillWidth: true
            label: qsTr("App icon spacing")
            subtext: qsTr("Gap between window icons on a workspace")
            value: Config.bar[root.edge].workspaces.windowIconSpacing
            from: 0
            to: 16
            stepSize: 1
            onMoved: v => GlobalConfig.bar[root.edge].workspaces.windowIconSpacing = v
        }

        ToggleRow {
            Layout.fillWidth: true
            last: true
            text: qsTr("Per-monitor workspaces")
            subtext: qsTr("Show each monitor's workspaces independently")
            checked: GlobalConfig.bar.perMonitorWorkspaces
            onToggled: GlobalConfig.bar.perMonitorWorkspaces = checked
        }
    }
}
