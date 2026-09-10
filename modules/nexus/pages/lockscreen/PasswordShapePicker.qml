pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import M3Shapes
import qs.components
import qs.components.controls
import qs.services
import qs.modules.lock
import qs.modules.nexus.common

ConnectedRect {
    id: root

    readonly property list<string> selected: GlobalConfig.lock.passwordShapes ?? []
    readonly property int previewCount: 6
    property var previewShapes: []

    readonly property string summary: {
        if (selected.length === 0)
            return qsTr("Nothing selected — using the default set");
        if (selected.length === 1)
            return qsTr("Every character is a %1").arg(selected[0]);
        return qsTr("Each character picks one of the %1 selected shapes at random").arg(selected.length);
    }

    function toggle(name: string): void {
        let sel = [...selected];
        if (sel.includes(name))
            sel = sel.filter(n => n !== name);
        else
            sel.push(name);
        GlobalConfig.lock.passwordShapes = sel;
    }

    function reroll(): void {
        const pool = PasswordShapes.resolve(selected);
        const out = [];
        for (let i = 0; i < previewCount; i++)
            out.push(pool[Math.floor(Math.random() * pool.length)]);
        previewShapes = out;
    }

    onSelectedChanged: reroll()
    Component.onCompleted: reroll()

    implicitHeight: column.implicitHeight + Tokens.padding.largeIncreased * 2

    Column {
        id: column

        anchors.fill: parent
        anchors.margins: Tokens.padding.largeIncreased
        spacing: Tokens.spacing.small

        Item {
            width: parent.width
            implicitHeight: headerBtns.implicitHeight

            Column {
                anchors.left: parent.left
                anchors.right: headerBtns.left
                anchors.verticalCenter: parent.verticalCenter

                StyledText {
                    text: qsTr("Shapes")
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.label.medium
                }

                StyledText {
                    width: parent.width
                    text: root.summary
                    color: Colours.palette.m3outline
                    font: Tokens.font.label.small
                    elide: Text.ElideRight
                }
            }

            Row {
                id: headerBtns

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: Tokens.spacing.extraSmall

                TextButton {
                    text: qsTr("All")
                    type: TextButton.Text
                    onClicked: GlobalConfig.lock.passwordShapes = PasswordShapes.catalog.map(e => e.name)
                }

                TextButton {
                    text: qsTr("Reset")
                    type: TextButton.Text
                    onClicked: GlobalConfig.lock.passwordShapes = []
                }
            }
        }

        // Live preview: a fake password field filled from the current selection
        StyledRect {
            id: preview

            width: parent.width
            implicitHeight: previewRow.implicitHeight + Tokens.padding.medium * 2

            color: Colours.tPalette.m3surfaceContainerHigh
            radius: Tokens.rounding.full

            StateLayer {
                radius: preview.radius
                onClicked: root.reroll()
            }

            Row {
                id: previewRow

                anchors.centerIn: parent
                spacing: Tokens.spacing.extraSmall

                Repeater {
                    model: root.previewShapes

                    MaterialShape {
                        required property int modelData

                        anchors.verticalCenter: parent.verticalCenter
                        implicitSize: Tokens.font.body.medium.pointSize
                        shape: modelData
                        color: Colours.palette.m3onSurface
                    }
                }
            }

            MaterialIcon {
                anchors.right: parent.right
                anchors.rightMargin: Tokens.padding.medium
                anchors.verticalCenter: parent.verticalCenter
                text: "casino"
                color: Colours.palette.m3outline
                fontStyle: Tokens.font.icon.builders.small.build()
            }
        }

        Grid {
            id: grid

            readonly property real cellWidth: (width - spacing * (columns - 1)) / columns

            width: parent.width
            columns: 7
            spacing: Tokens.spacing.small

            Repeater {
                model: PasswordShapes.catalog

                StyledRect {
                    id: chip

                    required property var modelData
                    readonly property bool selected: root.selected.includes(modelData.name)

                    implicitWidth: grid.cellWidth
                    implicitHeight: grid.cellWidth
                    radius: Tokens.rounding.medium
                    color: selected ? Colours.palette.m3primaryContainer : Colours.tPalette.m3surfaceContainerHigh

                    MaterialShape {
                        anchors.centerIn: parent
                        implicitSize: Math.round(chip.implicitWidth * 0.5)
                        shape: chip.modelData.shape
                        color: chip.selected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurfaceVariant
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: "transparent"
                        radius: parent.radius
                        border.width: chip.selected ? 2 : 0
                        border.color: Colours.palette.m3primary
                    }

                    StateLayer {
                        radius: parent.radius
                        onClicked: root.toggle(chip.modelData.name)
                    }
                }
            }
        }
    }
}
