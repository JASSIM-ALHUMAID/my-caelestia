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

        text: qsTr("Tiling Layout")
        font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
    }

    Repeater {
        model: HyprLayout.layouts

        delegate: Item {
            id: layoutDelegate

            required property string modelData
            readonly property bool active: HyprLayout.current === modelData

            Layout.fillWidth: true
            Layout.rightMargin: Tokens.padding.extraSmall

            implicitWidth: row.implicitWidth + Tokens.padding.large * 2
            implicitHeight: Math.max(36, row.implicitHeight + Tokens.padding.small)

            StateLayer {
                anchors.fill: parent

                radius: Tokens.rounding.full
                onClicked: HyprLayout.setLayout(layoutDelegate.modelData)
            }

            RowLayout {
                id: row

                anchors.fill: parent
                anchors.leftMargin: Tokens.padding.small
                anchors.rightMargin: Tokens.padding.small
                spacing: Tokens.spacing.small

                MaterialIcon {
                    text: HyprLayout.iconFor(layoutDelegate.modelData)
                    color: layoutDelegate.active ? Colours.palette.m3primary : Colours.palette.m3onSurface

                    Behavior on color {
                        CAnim {}
                    }
                }

                StyledText {
                    Layout.fillWidth: true

                    text: HyprLayout.displayName(layoutDelegate.modelData)
                    color: layoutDelegate.active ? Colours.palette.m3primary : Colours.palette.m3onSurface

                    Behavior on color {
                        CAnim {}
                    }
                }

                MaterialIcon {
                    text: "check"
                    color: Colours.palette.m3primary
                    opacity: layoutDelegate.active ? 1 : 0

                    Behavior on opacity {
                        Anim {}
                    }
                }
            }
        }
    }
}
