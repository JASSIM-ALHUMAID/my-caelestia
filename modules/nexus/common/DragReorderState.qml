pragma Singleton

import QtQuick
import Quickshell

// Shared state for an in-flight DragReorderRow drag. Only one drag can be active at a
// time, so a singleton is enough; `list` identifies which list is dragging so rows in
// other lists stay put.
Singleton {
    id: root

    property Item list
    property int fromIndex: -1
    property int toIndex: -1

    // Height of the slot the dragged row vacates (its own height plus the list spacing).
    property real slotHeight

    // True for the single frame in which the model is reordered. Displacement resets to
    // zero at the same moment the layout jumps to the new order, so that reset must not
    // animate -- otherwise rows slide a second time, in the wrong direction.
    property bool committing

    readonly property bool active: fromIndex >= 0

    function begin(list: Item, index: int, slotHeight: real): void {
        root.list = list;
        root.fromIndex = index;
        root.toIndex = index;
        root.slotHeight = slotHeight;
    }

    function clear(): void {
        root.list = null;
        root.fromIndex = -1;
        root.toIndex = -1;
    }
}
