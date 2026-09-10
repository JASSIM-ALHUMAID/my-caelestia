pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

StyledRect {
    id: root

    required property bool vertical
    readonly property color colour: Colours.palette.m3tertiary
    readonly property color urgentColour: Colours.palette.m3error
    readonly property bool isUrgent: CountdownTimer.active && CountdownTimer.remaining <= 10

    implicitWidth: root.vertical ? Tokens.sizes.bar.innerWidth : layout.implicitWidth + Tokens.padding.extraSmall * 2
    implicitHeight: root.vertical ? layout.implicitHeight + Tokens.padding.extraSmall * 2 : Tokens.sizes.bar.innerWidth

    // The rect is only the click/hover target — the icon and text carry the colour, as in Clock
    color: "transparent"
    radius: Tokens.rounding.full

    GridLayout {
        id: layout

        anchors.centerIn: parent

        flow: root.vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
        columns: root.vertical ? 1 : -1
        rows: root.vertical ? -1 : 1
        rowSpacing: Tokens.spacing.small
        columnSpacing: root.vertical ? Tokens.spacing.small : Tokens.spacing.medium

        MaterialIcon {
            Layout.alignment: Qt.AlignCenter
            text: CountdownTimer.active ? (CountdownTimer.running ? "timer" : "pause") : "timer_off"
            color: root.isUrgent ? root.urgentColour : root.colour

            Behavior on color {
                CAnim {}
            }
        }

        StyledText {
            visible: CountdownTimer.active

            Layout.alignment: Qt.AlignCenter
            horizontalAlignment: StyledText.AlignHCenter
            text: root.vertical ? CountdownTimer.formatted().replace(":", "\n") : CountdownTimer.formatted()
            font: Tokens.font.mono.medium
            color: root.isUrgent ? root.urgentColour : root.colour

            Behavior on color {
                CAnim {}
            }
        }
    }

    StateLayer {
        anchors.fill: parent

        radius: Tokens.rounding.full
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: event => {
            if (event.button === Qt.LeftButton)
                CountdownTimer.toggle();
            else if (event.button === Qt.RightButton)
                CountdownTimer.reset();
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton

        onWheel: event => {
            CountdownTimer.addTime(event.angleDelta.y > 0 ? 60 : -60);
        }
    }
}
