import QtQuick

// A panel that docks to one screen edge and slides out through it when hidden.
//
// Placement is derived entirely from `position`, so a panel can be moved between edges purely
// by config: it hugs its edge, centres on the cross axis, and the reveal always travels along
// the docking axis.
//
// Position is set through x/y rather than anchors on purpose. Conditional anchor bindings
// can't un-anchor a side once it has been set — assigning `undefined` to an anchor line that
// already holds one leaves it in place — so switching edges at runtime would accumulate
// anchors until the panel was pinned on all four sides and stretched to fill the screen.
Item {
    id: root

    // Which screen edge this panel docks to: "left" | "right" | "top" | "bottom".
    property string position: "left"
    readonly property bool isVertical: position === "left" || position === "right"

    // Extra clearance added to the slide distance when a neighbouring panel shares this
    // edge, so the two don't wipe across each other on the way out.
    property real edgeOffset: 0
    // Small overshoot so the panel clears its edge (and its shadow) completely.
    readonly property int slideOvershoot: 5

    property bool shouldBeActive: false
    // 0 = fully revealed, 1 = fully tucked away behind its edge.
    property real offsetScale: shouldBeActive ? 0 : 1

    // How far the panel travels along the docking axis: its own thickness on that axis,
    // plus the overshoot and any neighbour clearance.
    readonly property real slideDistance: (isVertical ? width : height) + slideOvershoot + edgeOffset

    visible: offsetScale < 1
    opacity: 1 - offsetScale

    // The parent is a clip box that shrinks along the docking axis as the panel retreats, so
    // the panel keeps sliding past its edge and out of view.
    x: {
        if (position === "left")
            return -slideDistance * offsetScale;
        if (position === "right")
            return parent.width - width + slideDistance * offsetScale;
        return (parent.width - width) / 2;
    }
    y: {
        if (position === "top")
            return -slideDistance * offsetScale;
        if (position === "bottom")
            return parent.height - height + slideDistance * offsetScale;
        return (parent.height - height) / 2;
    }

    Behavior on offsetScale {
        Anim {}
    }
}
