pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    required property int dndIndex

    readonly property bool held: content.held

    property color cardColour: Colours.layer(Colours.palette.m3surfaceContainer, held ? 4 : 2)

    // Spacing of the list this row sits in; used to size the gap the drag opens up.
    property real slotSpacing: Tokens.spacing.small

    default property alias rowData: row.data

    signal reordered(from: int, to: int)

    // How far this row slides to make room for the row currently being dragged.
    readonly property real dragShift: {
        const s = DragReorderState;
        if (!s.active || s.list !== root.parent || root.dndIndex === s.fromIndex)
            return 0;
        if (s.fromIndex < s.toIndex && root.dndIndex > s.fromIndex && root.dndIndex <= s.toIndex)
            return -s.slotHeight;
        if (s.fromIndex > s.toIndex && root.dndIndex >= s.toIndex && root.dndIndex < s.fromIndex)
            return s.slotHeight;
        return 0;
    }

    height: content.implicitHeight
    z: content.held ? 100 : 0

    // Settling the dropped card into its new slot: capture where it sits on screen before
    // the model changes, then offset it by however far its slot moved and animate that
    // away. Whichever of the relayout or the callLater lands first finishes the settle.
    property real settleFromY
    property bool settlePending

    function captureSettle(): void {
        settleFromY = root.mapToItem(null, 0, 0).y + content.y;
        settlePending = true;
        Qt.callLater(finishSettle);
    }

    function finishSettle(): void {
        if (!settlePending)
            return;
        settlePending = false;
        settleAnim.stop();
        content.y = settleFromY - root.mapToItem(null, 0, 0).y;
        settleAnim.restart();
    }

    Connections {
        target: root
        enabled: root.settlePending

        function onYChanged(): void {
            root.finishSettle();
        }
    }

    DropArea {
        anchors.fill: parent
        onEntered: drag => {
            const from = (drag.source as Item)?.dndIndex ?? -1;
            if (from >= 0 && DragReorderState.list === root.parent)
                DragReorderState.toIndex = root.dndIndex;
        }
        onDropped: drop => {
            const from = (drop.source as Item)?.dndIndex ?? -1;
            const to = root.dndIndex;
            if (from >= 0 && from !== to)
                root.reordered(from, to);
        }
    }

    StyledRect {
        id: content

        property int dndIndex: root.dndIndex
        property bool held

        implicitWidth: root.width
        implicitHeight: row.implicitHeight + Tokens.padding.medium * 2
        radius: Tokens.rounding.medium
        color: root.cardColour
        opacity: held ? 0.85 : 1.0
        scale: held ? 1.05 : 1.0

        Drag.active: held
        Drag.source: content
        Drag.hotSpot.x: width / 2
        Drag.hotSpot.y: height / 2

        transform: Translate {
            y: content.held ? 0 : root.dragShift

            Behavior on y {
                enabled: !DragReorderState.committing

                Anim {}
            }
        }

        Anim {
            id: settleAnim

            target: content
            property: "y"
            to: 0
        }

        Behavior on color {
            CAnim {}
        }
        Behavior on opacity {
            Anim {}
        }
        Behavior on scale {
            Anim {}
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.SizeVerCursor
            drag.target: parent
            drag.axis: Drag.YAxis
            onPressed: {
                settleAnim.stop();
                root.settlePending = false;
                content.held = true;
                DragReorderState.begin(root.parent, root.dndIndex, root.height + root.slotSpacing);
            }
            onReleased: {
                root.captureSettle();

                // The model reorder and the reset of every row's dragShift happen in the
                // same instant; the reset must not animate or rows slide twice.
                DragReorderState.committing = true;
                content.Drag.drop();
                content.held = false;
                content.x = 0;
                DragReorderState.clear();
                Qt.callLater(() => DragReorderState.committing = false);
            }
        }

        RowLayout {
            id: row

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Tokens.padding.large
            anchors.rightMargin: Tokens.padding.small
            spacing: Tokens.spacing.medium

            MaterialIcon {
                text: "drag_indicator"
                color: Colours.palette.m3onSurfaceVariant
            }
        }
    }
}
