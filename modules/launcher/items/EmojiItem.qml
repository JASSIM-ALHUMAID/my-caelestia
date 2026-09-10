import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.launcher.services

Item {
    id: root

    required property var list

    readonly property int emojiFontSize: 28
    readonly property string searchText: list.search.text.split(" ").slice(1).join(" ")
    readonly property var filteredEmojis: Emojis.search(searchText)

    implicitHeight: 400

    anchors.left: parent?.left
    anchors.right: parent?.right

    GridView {
        id: grid

        anchors.fill: parent
        anchors.margins: Tokens.padding.normal
        cellWidth: width / 6
        cellHeight: cellWidth
        model: filteredEmojis
        clip: true

        highlight: StyledRect {
            radius: Tokens.rounding.normal
            color: Colours.palette.m3onSurface
            opacity: 0.08
        }

        delegate: Item {
            width: grid.cellWidth
            height: grid.cellHeight

            StateLayer {
                anchors.fill: parent
                radius: Tokens.rounding.normal

                onClicked: {
                    Quickshell.execDetached(["wl-copy", modelData.glyph]);
                    root.list.visibilities.launcher = false;
                }
            }

            StyledText {
                anchors.centerIn: parent

                text: modelData.glyph
                font.pointSize: root.emojiFontSize
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                maximumLineCount: 1
            }
        }

        StyledScrollBar.vertical: StyledScrollBar {
            flickable: grid
        }
    }

    function onClicked(): void {
        if (grid.currentIndex >= 0 && grid.currentIndex < filteredEmojis.length) {
            Quickshell.execDetached(["wl-copy", filteredEmojis[grid.currentIndex].glyph]);
            root.list.visibilities.launcher = false;
        }
    }

    function incrementCurrentIndex(): void {
        grid.moveCurrentIndexDown();
    }

    function decrementCurrentIndex(): void {
        grid.moveCurrentIndexUp();
    }

    function incrementCurrentIndexHorizontal(): void {
        grid.moveCurrentIndexRight();
    }

    function decrementCurrentIndexHorizontal(): void {
        grid.moveCurrentIndexLeft();
    }
}
