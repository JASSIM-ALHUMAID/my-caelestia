pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config

Region {
    id: root

    required property Panels panels
    required property var win

    readonly property real borderThickness: win.contentItem.Config.border.thickness
    readonly property bool dashboardAtBottom: Config.dashboard.position === "bottom"
    readonly property bool dockAtBottom: Config.dock.position === "bottom"
    readonly property bool dockVertical: Config.dock.position === "left" || Config.dock.position === "right"
    // The sidebar follows Config.sidebar.edge; the session menu and OSD each follow their own
    // Config.*.position. An input region must hug the same edge as the panel it belongs to
    // (see Panels.qml), else the panel renders on one side while only the opposite side is
    // interactive — the panel then can't be hovered and vanishes on the first mouse move.
    readonly property bool panelsAtRight: Config.sidebar.edge !== "left"
    readonly property string sessionEdge: Config.session.position
    readonly property string osdEdge: Config.osd.position
    // Inboard depth an open sidebar claims, mirroring Panels.sidebarInset() so the mask lines up
    // with where the panels are actually drawn. Border-free on purpose: EdgeR adds the border
    // itself, so feeding it a value that already carries one over-reaches by that much.
    readonly property real sidebarDepth: panels.sidebar.width * (1 - panels.sidebar.offsetScale)

    x: win.clampInsetLeft + win.dragMaskPadding
    y: win.clampInsetTop + win.dragMaskPadding
    width: win.width - win.clampInsetLeft - win.clampInsetRight - win.dragMaskPadding * 2
    height: win.height - win.clampInsetTop - win.clampInsetBottom - win.dragMaskPadding * 2
    intersection: Intersection.Xor

    R {
        panel: root.panels.dashboard
        y: root.dashboardAtBottom ? root.win.height - height : 0
        height: panel.height * (1 - root.panels.dashboard.offsetScale) + root.borderThickness
    }

    EdgeR {
        panel: root.panels.launcher
        // The wrapper's own coerced edge, not the raw config value: a docked launcher
        // configured to "center" renders at the bottom, and a mask reading "center" would
        // land on the opposite side of the screen from the panel it belongs to.
        edge: root.panels.launcher.effectiveEdge
        floating: root.panels.launcher.floating
    }

    EdgeR {
        id: sessionRegion

        panel: root.panels.sessionWrapper
        edge: root.sessionEdge
        // Reaches across the sidebar only when the two actually share an edge.
        stack: root.sessionEdge === Config.sidebar.edge ? root.sidebarDepth : 0
    }

    R {
        panel: root.panels.sidebar
        x: root.panelsAtRight ? root.win.width - width : 0
        width: panel.width * (1 - root.panels.sidebar.offsetScale) + root.borderThickness
    }

    EdgeR {
        panel: root.panels.osdWrapper
        edge: root.osdEdge
        // Outboard of whatever else shares this edge. A session region on the same edge has
        // already accounted for the sidebar, so only add the sidebar separately when the
        // session menu lives somewhere else. Stack off contentDepth, not depth: the border is
        // added once per region, and inheriting the session's would push this one too far in.
        stack: root.osdEdge === root.sessionEdge ? sessionRegion.contentDepth : (root.osdEdge === Config.sidebar.edge ? root.sidebarDepth : 0)
    }

    R {
        panel: root.panels.notifications
    }

    R {
        panel: root.panels.utilities
        y: root.win.height - height
        height: panel.height * (1 - root.panels.utilities.offsetScale) + root.borderThickness
    }

    // Shrinks along whichever axis the dock slides on, so the interactive area tracks the
    // reveal animation instead of staying full size while the panel is off screen.
    R {
        panel: root.panels.dock
        x: root.dockVertical ? (Config.dock.position === "right" ? root.win.width - width : 0) : panel.x + root.win.insetLeft
        y: root.dockVertical ? panel.y + root.win.insetTop : (root.dockAtBottom ? root.win.height - height : 0)
        width: root.dockVertical ? panel.width * (1 - root.panels.dock.offsetScale) + root.borderThickness : panel.width
        height: root.dockVertical ? panel.height : panel.height * (1 - root.panels.dock.offsetScale) + root.borderThickness
    }

    R {
        panel: root.panels.dockMenu
    }

    R {
        panel: root.panels.popoutsWrapper
        // Shrink along the slide (cross) axis: width for vertical bars, height for horizontal.
        width: root.panels.popoutsWrapper.vertical ? panel.width * (1 - root.panels.popoutsWrapper.offsetScale) : panel.width
        height: root.panels.popoutsWrapper.vertical ? panel.height : panel.height * (1 - root.panels.popoutsWrapper.offsetScale)
    }

    component R: Region {
        required property Item panel

        x: panel.x + root.win.insetLeft
        y: panel.y + root.win.insetTop
        width: panel.width
        height: panel.height
        intersection: Intersection.Subtract
    }

    // A region that hugs whichever of the four edges its panel is docked to, spanning the
    // panel on the cross axis and `depth` inward from the edge (or, if `floating`, just the
    // panel's own rect — see below).
    component EdgeR: Region {
        required property Item panel
        required property string edge
        // Depth already claimed by panels stacked inboard of this one on the same edge.
        // Border-free, so that another EdgeR can stack off `contentDepth` without inheriting
        // a border thickness that its own `depth` adds again.
        property real stack: 0
        // A floating panel has a gap behind it that must stay click-through, so the region is
        // just the panel's own rect instead of reaching back to the screen edge.
        property bool floating: false

        readonly property bool isVertical: edge === "left" || edge === "right"
        // Most EdgeR panels are clip wrappers whose implicit size already shrinks as they
        // retreat (see Panels.qml), so panel.offsetScale is undefined for them and this is a
        // no-op. The launcher has no such wrapper — its own rect stays full size while sliding
        // out from behind — so its offsetScale multiplies depth directly to track the reveal.
        readonly property real contentDepth: (isVertical ? panel.width : panel.height) * (1 - (panel.offsetScale ?? 0)) + stack // qmllint disable missing-property
        readonly property real depth: contentDepth + root.borderThickness

        x: floating ? panel.x + root.win.insetLeft : (isVertical ? (edge === "right" ? root.win.width - depth : 0) : panel.x + root.win.insetLeft)
        y: floating ? panel.y + root.win.insetTop : (isVertical ? panel.y + root.win.insetTop : (edge === "bottom" ? root.win.height - depth : 0))
        width: floating ? panel.width : (isVertical ? depth : panel.width)
        height: floating ? panel.height : (isVertical ? panel.height : depth)
        intersection: Intersection.Subtract
    }
}
