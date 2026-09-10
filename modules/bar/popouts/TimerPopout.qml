pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

ColumnLayout {
    id: root

    spacing: Tokens.spacing.small

    StyledText {
        Layout.topMargin: Tokens.padding.medium
        Layout.rightMargin: Tokens.padding.extraSmall

        text: qsTr("Timer")
        font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
    }

    StyledText {
        Layout.alignment: Qt.AlignHCenter
        Layout.rightMargin: Tokens.padding.extraSmall

        text: CountdownTimer.formatted()
        font: Tokens.font.mono.builders.large.weight(Font.Medium).build()
        color: CountdownTimer.running ? Colours.palette.m3primary : Colours.palette.m3onSurface

        Behavior on color {
            CAnim {}
        }
    }

    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        Layout.rightMargin: Tokens.padding.extraSmall
        Layout.bottomMargin: Tokens.spacing.small

        spacing: Tokens.spacing.small

        ControlButton {
            icon: CountdownTimer.running ? "pause" : "play_arrow"
            onTriggered: CountdownTimer.toggle()
        }

        ControlButton {
            icon: "replay"
            active: CountdownTimer.active
            onTriggered: CountdownTimer.reset()
        }

        ControlButton {
            icon: "add"
            active: CountdownTimer.active
            onTriggered: CountdownTimer.addTime(60)
        }
    }

    Repeater {
        model: GlobalConfig.services.timerPresets

        delegate: Item {
            id: presetDelegate

            required property int index
            required property int modelData

            readonly property bool active: Math.round(CountdownTimer.duration / 60) === presetDelegate.modelData

            Layout.fillWidth: true
            Layout.rightMargin: Tokens.padding.extraSmall

            implicitWidth: row.implicitWidth + Tokens.padding.large * 2
            implicitHeight: Math.max(36, row.implicitHeight + Tokens.padding.small)

            StateLayer {
                anchors.fill: parent

                radius: Tokens.rounding.full
                onClicked: CountdownTimer.start(presetDelegate.modelData * 60)
            }

            RowLayout {
                id: row

                anchors.fill: parent
                anchors.leftMargin: Tokens.padding.small
                anchors.rightMargin: Tokens.padding.small
                spacing: Tokens.spacing.small

                MaterialIcon {
                    text: "timer"
                    color: presetDelegate.active ? Colours.palette.m3primary : Colours.palette.m3onSurface

                    Behavior on color {
                        CAnim {}
                    }
                }

                StyledText {
                    Layout.fillWidth: true

                    text: qsTr("%1 min").arg(presetDelegate.modelData)
                    color: presetDelegate.active ? Colours.palette.m3primary : Colours.palette.m3onSurface

                    Behavior on color {
                        CAnim {}
                    }
                }

                MaterialIcon {
                    text: "check"
                    color: Colours.palette.m3primary
                    opacity: presetDelegate.active ? 1 : 0

                    Behavior on opacity {
                        Anim {}
                    }
                }
            }
        }
    }

    // A round icon button for the transport row. `active` false dims it and drops the click,
    // so reset/+1m read as unavailable while the timer is idle.
    component ControlButton: Item {
        id: control

        property string icon
        property bool active: true

        signal triggered

        implicitWidth: 36
        implicitHeight: 36

        opacity: control.active ? 1 : 0.4

        Behavior on opacity {
            Anim {}
        }

        StateLayer {
            anchors.fill: parent

            radius: Tokens.rounding.full
            onClicked: {
                if (control.active)
                    control.triggered();
            }
        }

        MaterialIcon {
            anchors.centerIn: parent

            text: control.icon
            color: Colours.palette.m3onSurface
        }
    }
}
