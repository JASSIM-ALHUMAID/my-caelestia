pragma ComponentBehavior: Bound

import QtQuick.Layouts
import Caelestia.Config
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Clock")
    isSubPage: true

    readonly property string edge: root.nState.selectedEdge

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        ToggleRow {
            Layout.fillWidth: true
            first: true
            text: qsTr("Background")
            checked: Config.bar[root.edge].clock.background
            onToggled: GlobalConfig.bar[root.edge].clock.background = checked
        }

        ToggleRow {
            Layout.fillWidth: true
            text: qsTr("Show date")
            checked: Config.bar[root.edge].clock.showDate
            onToggled: GlobalConfig.bar[root.edge].clock.showDate = checked
        }

        ToggleRow {
            Layout.fillWidth: true
            last: true
            text: qsTr("Show icon")
            checked: Config.bar[root.edge].clock.showIcon
            onToggled: GlobalConfig.bar[root.edge].clock.showIcon = checked
        }
    }
}
