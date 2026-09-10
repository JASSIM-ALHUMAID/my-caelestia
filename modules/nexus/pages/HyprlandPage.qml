import QtQuick.Layouts
import Caelestia.Config
import qs.modules.nexus
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Hyprland")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        NavRow {
            first: true
            icon: "tune"
            label: qsTr("Variables")
            status: qsTr("Gaps, blur, shadows, cursor, apps")
            onClicked: root.nState.openSubPage(PageCompRegistry.hyprlandSubPages.vars)
        }

        NavRow {
            icon: "settings_applications"
            label: qsTr("Config")
            status: qsTr("Layout, input, animations, gestures")
            onClicked: root.nState.openSubPage(PageCompRegistry.hyprlandSubPages.config)
        }

        NavRow {
            last: true
            icon: "keyboard"
            label: qsTr("Binds")
            status: qsTr("Workspace, window, app and shell shortcuts")
            onClicked: root.nState.openSubPage(PageCompRegistry.hyprlandSubPages.binds)
        }
    }
}
