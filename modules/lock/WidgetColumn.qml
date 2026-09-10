pragma ComponentBehavior: Bound

import "center"
import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

ColumnLayout {
    id: root

    required property var lock
    required property var widgets
    property real centerScale: 1
    property int centerWidth: 0

    Repeater {
        model: root.widgets

        DelegateChooser {
            role: "id"

            DelegateChoice {
                roleValue: "weather"
                delegate: WeatherInfo {
                    required enabled

                    Layout.fillWidth: true
                    visible: enabled
                    rootHeight: root.height
                }
            }
            DelegateChoice {
                roleValue: "fetch"
                delegate: Fetch {
                    required enabled

                    Layout.fillWidth: true
                    visible: enabled
                    rootHeight: root.height
                }
            }
            DelegateChoice {
                roleValue: "media"
                delegate: Media {
                    required enabled

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: enabled
                    lock: root.lock
                }
            }
            DelegateChoice {
                roleValue: "power"
                delegate: Power {
                    required enabled

                    Layout.fillWidth: true
                    visible: enabled
                }
            }
            DelegateChoice {
                roleValue: "quote"
                delegate: Quote {
                    required enabled

                    Layout.fillWidth: true
                    visible: enabled
                }
            }
            DelegateChoice {
                roleValue: "resources"
                delegate: Resources {
                    required enabled

                    Layout.fillWidth: true
                    visible: enabled
                }
            }
            DelegateChoice {
                roleValue: "notifications"
                delegate: StyledRect {
                    required enabled

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: enabled

                    bottomRightRadius: Tokens.rounding.extraLarge
                    radius: Tokens.rounding.medium
                    color: Colours.tPalette.m3surfaceContainer

                    NotifDock {
                        lock: root.lock
                    }
                }
            }
            DelegateChoice {
                roleValue: "clock"
                delegate: Clock {
                    required enabled

                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: Tokens.padding.large
                    visible: enabled
                    centerScale: root.centerScale
                }
            }
            DelegateChoice {
                roleValue: "date"
                delegate: StyledText {
                    required enabled

                    Layout.alignment: Qt.AlignHCenter
                    visible: enabled

                    text: Time.format("dddd • d MMM").toUpperCase()
                    color: Colours.palette.m3onSurface
                    font: Tokens.font.title.builders.medium.weight(Font.DemiBold).build()
                }
            }
            DelegateChoice {
                roleValue: "profilePic"
                delegate: ProfilePic {
                    required enabled

                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: Tokens.spacing.extraExtraLarge * root.centerScale
                    Layout.bottomMargin: Tokens.spacing.extraLarge * root.centerScale
                    visible: enabled
                    centerWidth: root.centerWidth
                }
            }
            DelegateChoice {
                roleValue: "passwordInput"
                delegate: PasswordInput {
                    Layout.alignment: Qt.AlignHCenter
                    centerWidth: root.centerWidth
                    lock: root.lock
                }
            }
            DelegateChoice {
                roleValue: "stateMessage"
                delegate: StateMessage {
                    Layout.fillWidth: true
                    pam: root.lock.pam
                }
            }
        }
    }
}
