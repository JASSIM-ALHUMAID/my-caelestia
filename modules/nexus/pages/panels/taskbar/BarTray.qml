pragma ComponentBehavior: Bound

import QtQuick.Layouts
import Caelestia.Config
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Tray")
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
            checked: Config.bar[root.edge].tray.background
            onToggled: GlobalConfig.bar[root.edge].tray.background = checked
        }

        ToggleRow {
            Layout.fillWidth: true
            text: qsTr("Recolour icons")
            checked: Config.bar[root.edge].tray.recolour
            onToggled: GlobalConfig.bar[root.edge].tray.recolour = checked
        }

        ToggleRow {
            Layout.fillWidth: true
            text: qsTr("Compact")
            checked: Config.bar[root.edge].tray.compact
            onToggled: GlobalConfig.bar[root.edge].tray.compact = checked
        }

        ToggleRow {
            Layout.fillWidth: true
            last: true
            text: qsTr("Popout on hover")
            subtext: qsTr("Show the tray menu popout when hovering")
            checked: Config.bar[root.edge].popouts.tray
            onToggled: GlobalConfig.bar[root.edge].popouts.tray = checked
        }
    }
}
