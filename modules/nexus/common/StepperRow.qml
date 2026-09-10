pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

ConnectedRect {
    id: root

    property alias label: label.text
    property string subtext
    property real value
    property real from: 0
    property real to: 99
    property real stepSize: 1
    property string resetIcon

    signal moved(value: real)
    signal resetRequested()

    // StyledSlider reports a raw continuous value, so the row snaps it to stepSize
    // itself and rounds off the floating point dust a fractional step leaves behind.
    function snap(v: real): real {
        const s = root.stepSize;
        const decimals = s < 1 ? Math.max(1, Math.ceil(-Math.log10(s))) : 0;
        const snapped = Math.round((v - root.from) / s) * s + root.from;
        const clamped = Math.max(root.from, Math.min(root.to, snapped));
        return Math.round(clamped * Math.pow(10, decimals)) / Math.pow(10, decimals);
    }

    implicitHeight: column.implicitHeight + column.anchors.margins * 2

    ColumnLayout {
        id: column

        anchors.fill: parent
        anchors.margins: Tokens.padding.medium
        anchors.leftMargin: Tokens.padding.largeIncreased
        anchors.rightMargin: Tokens.padding.largeIncreased
        spacing: Tokens.spacing.small

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.medium

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    id: label

                    Layout.fillWidth: true
                    font: Tokens.font.body.small
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    visible: root.subtext
                    text: root.subtext
                    color: Colours.palette.m3outline
                    font: Tokens.font.label.small
                    elide: Text.ElideRight
                }
            }

            IconButton {
                icon: root.resetIcon
                type: IconButton.Text
                visible: root.resetIcon !== ""
                onClicked: root.resetRequested()
            }

            CustomSpinBox {
                min: root.from
                max: root.to
                step: root.stepSize
                value: root.value
                onValueModified: v => root.moved(v)
            }
        }

        CustomMouseArea {
            function onWheel(event: WheelEvent): void {
                root.moved(root.snap(root.value + (event.angleDelta.y > 0 ? root.stepSize : -root.stepSize)));
            }

            Layout.fillWidth: true
            visible: root.to > root.from
            implicitHeight: Tokens.padding.medium * 2

            StyledSlider {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                implicitHeight: parent.implicitHeight

                radius: Tokens.rounding.small
                value: root.value
                from: root.from
                to: root.to
                enabled: root.enabled
                onInteraction: v => root.moved(root.snap(v))
            }
        }
    }
}
