pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services

Item {
    id: root

    property string value: "bottom-right"

    readonly property list<var> positions: [
        { label: qsTr("Top left"),     value: "top-left",     row: 0, column: 0 },
        { label: qsTr("Top right"),    value: "top-right",    row: 0, column: 1 },
        { label: qsTr("Bottom left"),  value: "bottom-left",  row: 1, column: 0 },
        { label: qsTr("Bottom right"), value: "bottom-right", row: 1, column: 1 }
    ]

    signal selected(position: string)

    implicitWidth: grid.implicitWidth
    implicitHeight: grid.implicitHeight

    GridLayout {
        id: grid

        rows: 2
        columns: 2
        columnSpacing: Tokens.spacing.small
        rowSpacing: Tokens.spacing.small

        Repeater {
            model: root.positions

            StyledRect {
                required property var modelData

                Layout.row: modelData.row
                Layout.column: modelData.column
                Layout.preferredWidth: 120
                Layout.preferredHeight: 48
                radius: Tokens.rounding.medium
                color: root.value === modelData.value ? Colours.palette.m3primary : Colours.palette.m3surfaceVariant

                Behavior on color {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }

                StyledText {
                    anchors.centerIn: parent
                    text: parent.modelData.label
                    font: Tokens.font.body.small
                    color: root.value === parent.modelData.value ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.selected(parent.modelData.value)
                }
            }
        }
    }
}
