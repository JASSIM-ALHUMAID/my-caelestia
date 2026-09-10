pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common
import "bezier.js" as Bezier

// A marker driven along a track by the curve being edited. Reading control point
// numbers tells you very little about how a curve feels; watching it move does.
ColumnLayout {
    id: root

    property list<real> controlPoints: [0.2, 0, 0, 1, 1, 1]
    property int duration: 800
    property bool looping: true

    // Linear time in [0, 1]. The canvas tracer follows the same value, so the dot on
    // the curve and the dot on the track always agree.
    readonly property real progress: driver.running || driver.paused ? driver.value : idle.value

    function replay(): void {
        driver.restart();
    }

    spacing: Tokens.spacing.medium

    // Held at 1 when nothing is playing so the marker rests at the end of the track
    QtObject {
        id: idle

        property real value: 1
    }

    NumberAnimation {
        id: driver

        property real value: 1

        target: driver
        property: "value"
        from: 0
        to: 1
        duration: root.duration
        loops: root.looping ? Animation.Infinite : 1
        running: root.looping
    }

    onLoopingChanged: {
        if (root.looping)
            driver.restart();
        else
            driver.stop();
    }

    onDurationChanged: if (driver.running) driver.restart()

    StyledRect {
        Layout.fillWidth: true
        implicitHeight: 56
        color: Colours.tPalette.m3surfaceContainer
        radius: Tokens.rounding.large

        Item {
            id: track

            anchors.fill: parent
            anchors.leftMargin: Tokens.padding.largeIncreased
            anchors.rightMargin: Tokens.padding.largeIncreased

            readonly property real eased: Bezier.valueAt(root.controlPoints, root.progress)

            StyledRect {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                implicitHeight: 2
                radius: 1
                color: Qt.alpha(Colours.palette.m3outline, 0.35)
            }

            // Trail from the start of the track to the marker
            StyledRect {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.max(0, marker.x + marker.width / 2)
                implicitHeight: 2
                radius: 1
                color: Qt.alpha(Colours.palette.m3primary, 0.5)
            }

            StyledRect {
                id: marker

                // Clamped so an overshooting curve can't push the marker outside the card
                readonly property real travel: parent.width - width

                anchors.verticalCenter: parent.verticalCenter
                x: Math.max(-width / 2, Math.min(travel + width / 2, track.eased * travel))
                implicitWidth: 20
                implicitHeight: 20
                radius: Tokens.rounding.full
                color: Colours.palette.m3primary
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Tokens.spacing.medium

        IconTextButton {
            icon: "play_arrow"
            text: qsTr("Replay")
            type: IconTextButton.Tonal
            onClicked: root.replay()
        }

        StyledText {
            Layout.fillWidth: true
            text: qsTr("%1 ms").arg(root.duration)
            font: Tokens.font.label.small
            color: Colours.palette.m3outline
        }

        StyledSwitch {
            checked: root.looping
            onToggled: root.looping = checked
        }

        StyledText {
            text: qsTr("Loop")
            font: Tokens.font.label.small
            color: Colours.palette.m3outline
        }
    }
}
