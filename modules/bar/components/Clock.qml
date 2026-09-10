pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

StyledRect {
    id: root

    required property var barConfig
    required property bool vertical
    readonly property color colour: Colours.palette.m3tertiary
    readonly property int padding: root.barConfig.clock.background ? Tokens.padding.medium : Tokens.padding.extraSmall
    readonly property var font: Tokens.font.body.builders.small.scale(1.1)

    // Cross axis is fixed to the bar thickness; main axis grows with the content.
    implicitWidth: root.vertical ? Tokens.sizes.bar.innerWidth : layout.implicitWidth + root.padding * 2
    implicitHeight: root.vertical ? layout.implicitHeight + root.padding * 2 : Tokens.sizes.bar.innerWidth

    color: Qt.alpha(Colours.tPalette.m3surfaceContainer, root.barConfig.clock.background ? Colours.tPalette.m3surfaceContainer.a : 0)
    radius: Tokens.rounding.full

    GridLayout {
        id: layout

        anchors.centerIn: parent

        flow: root.vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
        columns: root.vertical ? 1 : -1
        rows: root.vertical ? -1 : 1
        rowSpacing: Tokens.spacing.small
        columnSpacing: Tokens.spacing.small

        MaterialIcon {
            visible: root.barConfig.clock.showIcon
            Layout.alignment: Qt.AlignCenter
            text: "calendar_month"
            color: root.colour
        }

        StyledText {
            id: dateText

            visible: root.barConfig.clock.showDate

            Layout.alignment: Qt.AlignCenter
            horizontalAlignment: StyledText.AlignHCenter
            text: Time.format(root.vertical ? "ddd\nd" : "ddd d")
            font: Tokens.font.body.small
            color: root.colour
        }

        StyledText {
            visible: root.barConfig.clock.showDate

            Layout.alignment: Qt.AlignCenter
            Layout.leftMargin: Tokens.spacing.extraSmall
            Layout.rightMargin: Tokens.spacing.extraSmall
            text: root.vertical ? "—" : "|"
            color: root.colour
            opacity: 0.3
        }

        StyledText {
            id: timeText

            Layout.alignment: Qt.AlignCenter
            text: {
                const twelve = GlobalConfig.services.useTwelveHourClock;
                if (root.vertical)
                    return Time.format(twelve ? "hh\nmm\nA" : "hh\nmm");
                return Time.format(twelve ? "hh:mm A" : "hh:mm");
            }
            font: Tokens.font.mono.medium
            color: root.colour
        }
    }
}
