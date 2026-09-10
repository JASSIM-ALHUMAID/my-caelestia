pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.modules.bar.popouts // Need to import this module so the Wrapper type is the same as others

Item {
    id: root

    required property ShellScreen screen
    required property real borderThickness
    // Content-area insets (a bar's thickness, else the border) so the popout maps the hovered
    // item's screen coordinate into the inset panel area along its main axis.
    property real insetLeft: borderThickness
    property real insetTop: borderThickness
    // "hugged" | "floating" - how popouts appear relative to the bar
    // Computed from Config based on the current edge
    readonly property string popoutMode: Config.bar[root.edge].popouts.mode
    // Cross-axis distance between the popout and the bar. Floating popouts sit off the bar by
    // this much; hugged ones sit flush against it, so the gap is 0.
    readonly property int popoutGap: root.popoutMode === "floating" ? Config.bar[root.edge].popouts.gap : 0

    // Edge of the bar that triggered the current popout; set by the drawers interaction layer
    // as the cursor moves between bars. Drives which side the popout attaches to.
    property string edge: "left"
    readonly property bool atRight: edge === "right"
    readonly property bool atBottom: edge === "bottom"
    // Vertical bars (left/right) slide horizontally; horizontal bars (top/bottom) slide vertically.
    readonly property bool vertical: edge !== "top" && edge !== "bottom"

    readonly property alias content: content
    property real offsetScale: content.isDetached || content.hasCurrent ? 0 : 1

    // Position the popout along the bar's main axis so its centre tracks the hovered item,
    // clamped to stay within `extent`. `size` is the popout's main-axis size. The leading inset
    // converts the item's screen coordinate into the inset panel area (insetTop for vertical
    // bars where the main axis is y, insetLeft for horizontal bars where it is x).
    function mainAxisPos(extent: real, size: real): real {
        const off = content.currentCenter - (vertical ? insetTop : insetLeft) - size / 2;
        const diff = extent - Math.floor(off + size);
        if (diff < 0)
            return off + diff;
        return Math.max(off, 0);
    }

    visible: width > 0 && height > 0
    clip: true

    // Cross axis (slide direction) animates with offsetScale; main axis stays full size.
    implicitWidth: root.vertical ? content.implicitWidth * (1 - offsetScale) : content.implicitWidth
    implicitHeight: root.vertical ? content.implicitHeight : content.implicitHeight * (1 - offsetScale)

    x: {
        if (content.isDetached)
            return (parent.width - content.nonAnimWidth) / 2;
        if (root.vertical)
            // cross axis: pin to the bar's edge, offset by the gap (0 when hugged)
            return root.atRight ? parent.width - width - root.popoutGap : root.popoutGap;
        return mainAxisPos(parent.width, content.nonAnimWidth); // main axis for top/bottom bars
    }
    y: {
        if (content.isDetached)
            return (parent.height - content.nonAnimHeight) / 2;
        if (!root.vertical)
            // cross axis: pin to the bar's edge, offset by the gap (0 when hugged)
            return root.atBottom ? parent.height - height - root.popoutGap : root.popoutGap;
        return mainAxisPos(parent.height, content.nonAnimHeight); // main axis for left/right bars
    }

    Behavior on offsetScale {
        Anim {}
    }

    Behavior on x {
        // For a right bar (and similarly the main-axis follow) keep the edge pinned: when the
        // cross-axis edge tracks the animated size, a second animation would slide it in from afar.
        enabled: !(root.vertical && root.atRight && !content.isDetached)

        Anim {
            duration: content.animLength
            easing: content.animCurve
        }
    }

    Behavior on y {
        enabled: !(!root.vertical && root.atBottom && !content.isDetached) && root.offsetScale < 1

        Anim {
            duration: content.animLength
            easing: content.animCurve
        }
    }

    Wrapper {
        id: content

        screen: root.screen
        offsetScale: root.offsetScale
        closeGrace: Config.bar[root.edge].popouts.hoverGrace

        // Position with x/y only (no anchors) so flipping between vertical (left/right) and
        // horizontal (top/bottom) never toggles an anchor to undefined and leaves a stale one.
        // Hugged: main axis sits at 0 (the clip is already sized to the content there); cross axis
        // keeps the content pinned to the bar's edge and slides it out by offsetScale (+5px gap).
        // Floating: centred on both axes, so the content grows out of the clip's middle instead of
        // sliding out of the bar. The detachment itself comes from popoutGap on the clip's position.
        x: {
            // Floating mode: center horizontally in the clip wrapper
            if (root.popoutMode === "floating")
                return (parent.width - implicitWidth) / 2;
            // Hugged mode: current behavior
            if (!root.vertical)
                return 0; // main axis for horizontal bars
            if (root.atRight)
                return parent.width - implicitWidth + (implicitWidth + 5) * root.offsetScale;
            return -(implicitWidth + 5) * root.offsetScale; // left edge
        }
        y: {
            // Floating mode: center vertically in the clip wrapper
            if (root.popoutMode === "floating")
                return (parent.height - implicitHeight) / 2;
            // Hugged mode: current behavior
            if (root.vertical)
                return 0; // main axis for vertical bars
            if (root.atBottom)
                return parent.height - implicitHeight + (implicitHeight + 5) * root.offsetScale;
            return -(implicitHeight + 5) * root.offsetScale; // top edge
        }
    }
}
