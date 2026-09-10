pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

StyledRect {
    id: root

    implicitHeight: layout.implicitHeight + layout.anchors.margins * 2
    radius: Tokens.rounding.extraLarge
    color: Colours.tPalette.m3surfaceContainer

    RowLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.medium

        IconButton {
            Layout.fillWidth: true
            icon: "power_settings_new"
            type: IconButton.Tonal
            isRound: true
            shapeMorph: true
            onClicked: Quickshell.execDetached(["systemctl", "poweroff"])
        }

        IconButton {
            Layout.fillWidth: true
            icon: "restart_alt"
            type: IconButton.Tonal
            isRound: true
            shapeMorph: true
            onClicked: Quickshell.execDetached(["systemctl", "reboot"])
        }

        IconButton {
            Layout.fillWidth: true
            icon: "bedtime"
            type: IconButton.Tonal
            isRound: true
            shapeMorph: true
            onClicked: Quickshell.execDetached(["systemctl", "suspend"])
        }
    }
}
