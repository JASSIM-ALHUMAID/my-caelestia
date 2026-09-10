import QtQuick
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    // Read from barConfig (this screen's Config overlay, so a per-monitor override is
    // respected) but write to GlobalConfig, which is the singleton backed by shell.json.
    // Writing to the overlay would only touch that screen's scoped backend and never
    // persist. Same split as the "Persistent" switch in TaskbarPanel.qml.
    required property var barConfig
    required property string edge

    implicitWidth: icon.implicitHeight + Tokens.padding.small
    implicitHeight: icon.implicitHeight

    StateLayer {
        anchors.fill: undefined
        anchors.centerIn: parent
        implicitWidth: implicitHeight
        implicitHeight: icon.implicitHeight + Tokens.padding.small
        radius: Tokens.rounding.full

        onClicked: GlobalConfig.bar[root.edge].persistent = !root.barConfig.persistent
    }

    MaterialIcon {
        id: icon
        anchors.centerIn: parent
        text: "keep"
        fontStyle: Tokens.font.icon.large

        color: root.barConfig.persistent ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
        rotation: root.barConfig.persistent ? 0 : 45

        Behavior on rotation { Anim {} }
        Behavior on color { CAnim {} }
    }
}
