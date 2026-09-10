pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Caelestia.Blobs
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.services
import qs.modules.bar

StyledWindow {
    id: root

    readonly property alias barLeft: barLeft
    readonly property alias barRight: barRight
    readonly property alias barTop: barTop
    readonly property alias barBottom: barBottom
    readonly property alias interactionWrapper: interactions

    // Reservation state for the dock, read by Exclusions. A pinned dock reserves its
    // thickness on its edge so windows tile beside it rather than underneath it. Suppressed
    // is part of the test because a dock hidden behind a fullscreen window is not on screen
    // to be tiled beside, and reserving anyway leaves the fullscreen window short of an edge.
    readonly property bool dockReserves: Config.dock.enabled && Config.dock.pinned && !Config.dock.keepHidden && !panels.dock.suppressed && !Config.dock.excludedScreens.includes(screen.name)
    readonly property string dockPosition: Config.dock.position
    readonly property real dockThickness: panels.dock.thickness

    readonly property HyprlandMonitor monitor: Hypr.monitorFor(screen)
    readonly property bool hasSpecialWorkspace: (monitor?.lastIpcObject.specialWorkspace?.name.length ?? 0) > 0
    readonly property bool hasFullscreen: {
        if (hasSpecialWorkspace) {
            const specialName = monitor?.lastIpcObject.specialWorkspace?.name;
            if (!specialName)
                return false;
            const specialWs = Hypr.workspaces.values.find(ws => ws.name === specialName);
            return specialWs?.toplevels.values.some(t => t.lastIpcObject.fullscreen > 1) ?? false;
        }
        return monitor?.activeWorkspace?.toplevels.values.some(t => t.lastIpcObject.fullscreen > 1) ?? false;
    }

    property real fsTransitionProg: hasFullscreen ? 1 : 0
    readonly property bool hasOverlayContent: fsTransitionProg > 0 && (
        contentItem.Config.general.showOverFullscreen ||
        Notifs.popups.length > 0 ||
        (visibilities.osd && Config.osd.enabled) ||
        (visibilities.launcher && Config.launcher.enabled && Config.launcher.fullscreen !== "off") ||
        (visibilities.dashboard && Config.dashboard.enabled && Config.dashboard.fullscreen !== "off") ||
        (panels.dock.shouldBeActive && Config.dock.availableOnFullscreen)
    )
    readonly property real sdfBorderOffset: 2 * fsTransitionProg // SDFs joins are not exact, so offset by 2px to ensure nothing shows
    readonly property real borderThickness: contentItem.Config.border.thickness * (1 - fsTransitionProg)
    readonly property real borderRounding: contentItem.Config.border.rounding * (1 - fsTransitionProg)
    readonly property real shadowOpacity: 0.7 * (1 - fsTransitionProg)
    readonly property real borderLayoutThickness: hasFullscreen ? 0 : contentItem.Config.border.thickness
    readonly property real clampedThickness: contentItem.Config.border.clampedThickness
    // Per-side content insets: a bar's animated thickness where one occupies that edge,
    // otherwise just the window border. Lets panels/regions/border stay edge-agnostic.
    readonly property real insetLeft: barLeft.present ? barLeft.implicitWidth : borderThickness
    readonly property real insetRight: barRight.present ? barRight.implicitWidth : borderThickness
    readonly property real insetTop: barTop.present ? barTop.implicitHeight : borderThickness
    readonly property real insetBottom: barBottom.present ? barBottom.implicitHeight : borderThickness
    // Clamped (min-thickness) variants for the input mask so it never collapses to nothing.
    readonly property real clampInsetLeft: barLeft.present ? barLeft.clampedWidth : clampedThickness
    readonly property real clampInsetRight: barRight.present ? barRight.clampedWidth : clampedThickness
    readonly property real clampInsetTop: barTop.present ? barTop.clampedWidth : clampedThickness
    readonly property real clampInsetBottom: barBottom.present ? barBottom.clampedWidth : clampedThickness
    // Back-compat single-left-bar inset still used by a few left-anchored consumers.
    readonly property real panelLeftInset: insetLeft

    function closeAllTrays(): void {
        barLeft.closeTray();
        barRight.closeTray();
        barTop.closeTray();
        barBottom.closeTray();
    }

    property color surfaceColour: Colours.tPalette.m3surface

    readonly property int dragMaskPadding: {
        if (focusGrab.active || panels.popouts.isDetached)
            return 0;

        if (monitor?.lastIpcObject.specialWorkspace?.name || monitor?.activeWorkspace.lastIpcObject.windows > 0)
            return 0;

        const thresholds = [];
        for (const panel of ["dashboard", "launcher", "session", "sidebar", "dock"])
            if (contentItem.Config[panel].enabled)
                thresholds.push(contentItem.Config[panel].dragThreshold);
        // Every drag panel can be disabled at once; Math.max of nothing is -Infinity, which
        // would propagate into the input mask geometry.
        return thresholds.length > 0 ? Math.max(...thresholds) : 0;
    }

    onHasFullscreenChanged: {
        if (Config.launcher.fullscreen === "off")
            visibilities.launcher = false;
        visibilities.session = false;
        if (Config.dashboard.fullscreen === "off")
            visibilities.dashboard = false;
        panels.popouts.close();
    }

    name: "drawers"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: root.hasOverlayContent ? WlrLayer.Overlay : WlrLayer.Top
    WlrLayershell.keyboardFocus: visibilities.launcher || visibilities.session ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    mask: hasFullscreen ? emptyRegion : regions

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    Behavior on fsTransitionProg {
        Anim {}
    }

    Behavior on surfaceColour {
        CAnim {}
    }

    Region {
        id: emptyRegion

        x: panels.notifications.x + root.insetLeft
        y: panels.notifications.y + root.insetTop
        width: panels.notifications.width
        height: panels.notifications.height

        Region {
            // Match the OSD's rendered edge (Config.osd.position) so volume/brightness stays
            // hoverable over fullscreen wherever the OSD has been placed.
            readonly property string edge: Config.osd.position
            readonly property bool isVertical: edge === "left" || edge === "right"
            readonly property real inset: {
                if (edge === "left")
                    return root.insetLeft;
                if (edge === "right")
                    return root.insetRight;
                return edge === "top" ? root.insetTop : root.insetBottom;
            }
            // All four sourced from the clip wrapper: it is what carries the reveal animation
            // and the stacking inset, and mixing in the inner panel's size only lines up while
            // the wrapper happens not to shrink on the cross axis.
            readonly property real depth: (isVertical ? panels.osdWrapper.width : panels.osdWrapper.height) + inset + panels.osdWrapper.inset

            x: isVertical ? (edge === "right" ? root.width - depth : 0) : panels.osdWrapper.x + root.insetLeft
            y: isVertical ? panels.osdWrapper.y + root.insetTop : (edge === "bottom" ? root.height - depth : 0)
            width: isVertical ? depth : panels.osdWrapper.width
            height: isVertical ? panels.osdWrapper.height : depth
        }

        Region {
            x: panels.dashboard.x + root.insetLeft
            y: panels.dashboard.y + root.insetTop
            width: Config.dashboard.fullscreen !== "off" ? panels.dashboard.width : 0
            height: Config.dashboard.fullscreen !== "off" ? panels.dashboard.height : 0
        }

        // Keeps the dock clickable over a fullscreen window, matching the opt-in that
        // hasOverlayContent above makes for rendering it.
        Region {
            readonly property bool shown: Config.dock.enabled && Config.dock.availableOnFullscreen

            x: panels.dock.x + root.insetLeft
            y: panels.dock.y + root.insetTop
            width: shown ? panels.dock.width : 0
            height: shown ? panels.dock.height : 0
        }
    }

    Regions {
        id: regions

        panels: panels
        win: root
    }

    HyprlandFocusGrab {
        id: focusGrab

        // The dock is deliberately absent: it can be revealed by hover, and grabbing focus
        // on hover would steal keyboard input from the focused window on every pass over
        // the screen edge. Its right-click menu does need the grab; its hover preview
        // must not, for the same reason.
        active: (visibilities.launcher && root.contentItem.Config.launcher.enabled) || (visibilities.session && root.contentItem.Config.session.enabled) || (visibilities.sidebar && root.contentItem.Config.sidebar.enabled) || (visibilities.dashboard && root.contentItem.Config.dashboard.enabled) || panels.dockMenu.menuOpen || (panels.popouts.currentName.startsWith("traymenu") && (panels.popouts.current as StackView)?.depth > 1)
        windows: [root]
        onCleared: {
            visibilities.launcher = false;
            visibilities.session = false;
            visibilities.sidebar = false;
            visibilities.dashboard = false;
            visibilities.dock = false;
            // shouldBeActive can stay true even once visibilities.dock is cleared (a pinned or
            // forcedOpen dock), which otherwise left a right-click menu stuck open on
            // click-outside with no other dismissal path.
            panels.dock.closePopout();
            panels.popouts.hasCurrent = false;
            root.closeAllTrays();
        }
    }

    StyledRect {
        anchors.fill: parent
        opacity: (visibilities.session && Config.session.enabled) || panels.popouts.detachedMode !== "" ? 0.5 : 0
        color: Colours.palette.m3scrim

        Behavior on opacity {
            Anim {
                type: Anim.SlowEffects
            }
        }
    }

    Item {
        anchors.fill: parent
        opacity: root.surfaceColour.a
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            blurMax: 15
            shadowColor: Qt.alpha(Colours.palette.m3shadow, Math.max(0, root.shadowOpacity))
        }

        BlobGroup {
            id: blobGroup

            color: root.surfaceColour
            smoothing: root.contentItem.Config.border.smoothing
        }

        // Floating notifications need their own group: shapes in the main group are
        // deliberately blended into the shell frame across the smoothing radius.
        BlobGroup {
            id: floatingNotifsBlobGroup

            color: root.surfaceColour
            smoothing: root.contentItem.Config.border.smoothing
        }

        BlobInvertedRect {
            anchors.fill: parent
            anchors.margins: -50 // Make border thicker to smooth out bulge from closed drawers
            group: blobGroup
            radius: root.borderRounding
            borderLeft: root.insetLeft - anchors.margins - root.sdfBorderOffset
            borderRight: root.insetRight - anchors.margins - root.sdfBorderOffset
            borderTop: root.insetTop - anchors.margins - root.sdfBorderOffset
            borderBottom: root.insetBottom - anchors.margins - root.sdfBorderOffset
        }

        PanelBg {
            id: dashBg

            panel: panels.dashboard
            deformAmount: 0.1
        }

        PanelBg {
            id: launcherBg

            // Every other panel hides by sliding out through its edge, which carries its blob
            // off screen with it. A centred launcher has no edge to travel toward — it only
            // fades — so the blob would keep painting a surface in the middle of the screen
            // long after the launcher closed. Collapsing the size is what actually removes it:
            // BlobShape culls neighbours on zero width/height, not on visibility (see
            // dockMenuBg). Non-centred launchers keep the full size and slide as before.
            readonly property real reveal: panels.launcher.centered ? 1 - panels.launcher.offsetScale : 1

            panel: panels.launcher
            deformAmount: 0.1
            // Shrink about the centre, so the fade reads as the panel receding rather than
            // as its top-left corner eating it.
            x: panels.launcher.x + root.insetLeft + (panels.launcher.width - implicitWidth) / 2
            y: panels.launcher.y + root.insetTop + (panels.launcher.height - implicitHeight) / 2
            implicitWidth: panels.launcher.width * reveal
            implicitHeight: panels.launcher.height * reveal
        }

        PanelBg {
            id: dockBg

            panel: panels.dock
            deformAmount: 0.1
        }

        PanelBg {
            id: dockMenuBg

            readonly property bool hugged: Config.dock.popoutMode === "hugged"
            readonly property bool dockAtLeft: Config.dock.position === "left"
            readonly property bool dockAtTop: Config.dock.position === "top"
            readonly property bool dockVertical: Config.dock.position === "left" || Config.dock.position === "right"
            // Extend back toward the dock so the two metaball surfaces merge instead of
            // sitting as two separate rounded rects. panels.dockMenu already animates its
            // x/y as it slides out of the dock, so this reads the same animated source.
            property real extraSpan: hugged ? 0.2 : 0
            // Off unless hugged: a floating popout paints its own surface. Collapsing the size
            // rather than setting `visible` is what actually removes it — BlobShape culls
            // neighbours on zero width/height, not on visibility, so a hidden-but-sized rect
            // would keep bulging the group's surface long after the popout closed.
            readonly property bool shown: hugged && panels.dockMenu.visible

            panel: panels.dockMenu
            deformAmount: 0.1
            // The shift must read the raw panel size, not this rect's own already-extended
            // implicitWidth, else it over-travels by a further factor of extraSpan.
            x: panels.dockMenu.x + root.insetLeft - (dockVertical && dockAtLeft ? panels.dockMenu.width * extraSpan : 0)
            y: panels.dockMenu.y + root.insetTop - (!dockVertical && dockAtTop ? panels.dockMenu.height * extraSpan : 0)
            implicitWidth: shown ? panels.dockMenu.width * (dockVertical ? 1 + extraSpan : 1) : 0
            implicitHeight: shown ? panels.dockMenu.height * (!dockVertical ? 1 + extraSpan : 1) : 0

            Behavior on extraSpan {
                Anim {
                    type: Anim.DefaultSpatial
                }
            }
        }

        PanelBg {
            id: sessionBg

            panel: panels.sessionWrapper
            deformAmount: 0.2
            // Track the panel itself, not its clip box: the box shrinks along whichever axis
            // the panel slides on, so following it would squash the blob instead of moving it.
            x: panels.sessionWrapper.x + panels.session.x + root.insetLeft
            y: panels.sessionWrapper.y + panels.session.y + root.insetTop
            implicitWidth: panels.session.width
            implicitHeight: panels.session.height
        }

        PanelBg {
            id: sidebarBg

            panel: panels.sidebar
            deformAmount: 0.03
            implicitHeight: panel.height * (1 / rawDeformMatrix.m22) + 2
            exclude: panels.sidebar.offsetScale > 0.08 ? [] : [utilsBg]
            bottomLeftRadius: Math.max(0, Math.min(1, panels.sidebar.offsetScale / 0.3)) * radius
        }

        PanelBg {
            id: osdBg

            panel: panels.osdWrapper
            deformAmount: 0.25
            x: panels.osdWrapper.x + panels.osd.x + root.insetLeft
            y: panels.osdWrapper.y + panels.osd.y + root.insetTop
            implicitWidth: panels.osd.width
            implicitHeight: panels.osd.height
        }

        PanelBg {
            id: notifsBg

            panel: panels.notifications
            group: panels.notifications.floating ? floatingNotifsBlobGroup : blobGroup
        }

        PanelBg {
            id: utilsBg

            panel: panels.utilities
            deformAmount: panels.sidebar.visible ? 0.1 : 0.15
            exclude: panels.sidebar.offsetScale > 0.08 ? [] : [sidebarBg]
            topLeftRadius: Math.max(0, Math.min(1, panels.sidebar.offsetScale / 0.3)) * radius
        }

        PanelBg {
            id: popoutBg

            readonly property bool popVertical: panels.popoutsWrapper.vertical
            // Extra span toward the bar so movement deformation never detaches the panel from it.
            // In floating mode, don't extend toward the bar.
            readonly property bool isFloating: Config.bar[panels.popoutsWrapper.edge].popouts.mode === "floating"
            property real extraSpan: panels.popouts.isDetached ? 0 : (isFloating ? 0 : 0.2)

            panel: panels.popoutsWrapper
            deformAmount: panels.popouts.isDetached ? 0.05 : panels.popouts.hasCurrent ? 0.15 : 0.1
            // For vertical bars the blob extends toward the bar (left/right) to keep the
            // deformation attached during movement. For horizontal bars the blob tracks the
            // popout exactly: extending it up/down into the bar/border region stops the metaball
            // surface from rendering behind the content. popouts.x/y carry the slide offset.
            // Sizes come from the clip wrapper, whose cross axis collapses to 0 when hidden (via
            // offsetScale), rather than the inner Wrapper's static size, so the blob hides with the
            // popout. The extraSpan offset must read the same animated source as implicitWidth.
            x: panels.popoutsWrapper.x + panels.popouts.x + root.insetLeft - (popVertical && !panels.popoutsWrapper.atRight ? panels.popoutsWrapper.width * extraSpan : 0)
            y: panels.popoutsWrapper.y + panels.popouts.y + root.insetTop
            implicitWidth: panels.popoutsWrapper.width * (popVertical ? 1 + extraSpan : 1)
            implicitHeight: panels.popoutsWrapper.height

            Behavior on extraSpan {
                Anim {
                    type: Anim.DefaultSpatial
                }
            }
        }
    }

    DrawerVisibilities {
        id: visibilities

        Component.onCompleted: Visibilities.load(root.screen, this)
    }

    Interactions {
        id: interactions

        screen: root.screen
        popouts: panels.popouts
        visibilities: visibilities
        panels: panels
        win: root
        barLeft: barLeft
        barRight: barRight
        barTop: barTop
        barBottom: barBottom
        borderThickness: root.borderLayoutThickness
        fullscreen: root.hasFullscreen

        Panels {
            id: panels

            screen: root.screen
            visibilities: visibilities
            insetLeft: root.insetLeft
            insetRight: root.insetRight
            insetTop: root.insetTop
            insetBottom: root.insetBottom
            borderThickness: root.borderThickness

            utilities.horizontalStretch: (sidebarBg.rawDeformMatrix.m11 - 1) / 2 + 1
            utilities.deformMatrix: utilsBg.rawDeformMatrix

            dashboard.transform: Matrix4x4 {
                matrix: dashBg.deformMatrix
            }
            launcher.transform: Matrix4x4 {
                matrix: launcherBg.deformMatrix
            }
            dock.transform: Matrix4x4 {
                matrix: dockBg.deformMatrix
            }
            session.transform: Matrix4x4 {
                matrix: sessionBg.deformMatrix
            }
            sidebar.transform: Matrix4x4 {
                matrix: sidebarBg.deformMatrix
            }
            osd.transform: Matrix4x4 {
                matrix: osdBg.deformMatrix
            }
            notifications.transform: Matrix4x4 {
                matrix: notifsBg.deformMatrix
            }
            utilities.transform: Matrix4x4 {
                matrix: utilsBg.deformMatrix
            }
            popouts.transform: Matrix4x4 {
                matrix: popoutBg.deformMatrix
            }
        }

        // One BarWrapper per edge. Each reserves space / renders only when its config is
        // enabled (see BarWrapper.present). Position the cross-axis with x/y rather than
        // toggling anchors: switching an anchor to undefined at runtime leaves the bar floating.
        BarWrapper {
            id: barLeft

            edge: "left"
            barConfig: root.contentItem.Config.bar.left

            anchors.top: parent.top
            anchors.bottom: parent.bottom
            x: 0

            screen: root.screen
            visibilities: visibilities
            popouts: panels.popouts
            fullscreen: root.hasFullscreen

            Component.onCompleted: Visibilities.bars.set(root.screen, this)
        }

        BarWrapper {
            id: barRight

            edge: "right"
            barConfig: root.contentItem.Config.bar.right

            anchors.top: parent.top
            anchors.bottom: parent.bottom
            x: parent.width - width

            screen: root.screen
            visibilities: visibilities
            popouts: panels.popouts
            fullscreen: root.hasFullscreen
        }

        BarWrapper {
            id: barTop

            edge: "top"
            barConfig: root.contentItem.Config.bar.top

            anchors.left: parent.left
            anchors.right: parent.right
            y: 0

            screen: root.screen
            visibilities: visibilities
            popouts: panels.popouts
            fullscreen: root.hasFullscreen
        }

        BarWrapper {
            id: barBottom

            edge: "bottom"
            barConfig: root.contentItem.Config.bar.bottom

            anchors.left: parent.left
            anchors.right: parent.right
            y: parent.height - height

            screen: root.screen
            visibilities: visibilities
            popouts: panels.popouts
            fullscreen: root.hasFullscreen
        }
    }

    component PanelBg: BlobRect {
        required property Item panel
        property real deformAmount: 0.15

        group: blobGroup
        x: panel.x + root.insetLeft
        y: panel.y + root.insetTop
        implicitWidth: panel.width
        implicitHeight: panel.height
        radius: Tokens.rounding.extraLarge
        deformScale: (deformAmount * Config.appearance.deformScale) / 10000
    }
}
