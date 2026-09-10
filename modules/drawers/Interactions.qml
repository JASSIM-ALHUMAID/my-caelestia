import QtQuick
import QtQuick.Controls
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.modules.bar as Bar
import qs.modules.bar.popouts as BarPopouts

CustomMouseArea {
    id: root

    required property ShellScreen screen
    required property BarPopouts.Wrapper popouts
    required property DrawerVisibilities visibilities
    required property Panels panels
    // The ContentWindow root, for per-side content insets (insetLeft/Right/Top/Bottom).
    required property var win
    required property Bar.BarWrapper barLeft
    required property Bar.BarWrapper barRight
    required property Bar.BarWrapper barTop
    required property Bar.BarWrapper barBottom
    required property real borderThickness
    required property bool fullscreen

    property point dragStart
    property bool dashboardShortcutActive
    property bool osdShortcutActive
    property bool utilitiesShortcutActive
    property bool dockShortcutActive
    property bool sessionShortcutActive
    // The bar was opened by keybind/IPC rather than by hover, so hover-out must not close it.
    property bool barShortcutActive
    // Which edge's hover opened the bar, "" when it wasn't hover that opened it. All four bars
    // share the single `visibilities.bar` flag while hideOnHoverOut is per-edge, so the hide
    // decision has to read the config of the bar that actually did the revealing.
    property string barRevealEdge
    // A bar held open because the workspace is empty is not hover-revealed, so hover-out must
    // leave it alone — the same exemption dockForcedOpen gives the dock below.
    readonly property bool barEmptyRevealed: barLeft.emptyReveal || barRight.emptyReveal || barTop.emptyReveal || barBottom.emptyReveal

    // Per-side insets of the usable content area (a bar's thickness, else the border).
    readonly property real panelLeftInset: win.insetLeft
    readonly property real panelTopInset: win.insetTop
    readonly property real panelBottomInset: win.insetBottom
    // Sidebar side only. The osd and session menu carry their own positions — use osdEdge /
    // sessionEdge and inEdgePanel() for those, never this.
    readonly property bool panelsAtRight: Config.sidebar.edge !== "left"

    // The bar (if any) whose content area contains (x, y). `clamped` uses the collapsed
    // thickness so a hidden bar can still be revealed by hovering/dragging its thin edge.
    function barAt(x: real, y: real): Bar.BarWrapper {
        if (barLeft.present && x < barLeft.implicitWidth)
            return barLeft;
        if (barRight.present && x > width - barRight.implicitWidth)
            return barRight;
        if (barTop.present && y < barTop.implicitHeight)
            return barTop;
        if (barBottom.present && y > height - barBottom.implicitHeight)
            return barBottom;
        return null;
    }
    function barAtClamped(x: real, y: real): Bar.BarWrapper {
        if (barLeft.present && x < barLeft.clampedWidth)
            return barLeft;
        if (barRight.present && x > width - barRight.clampedWidth)
            return barRight;
        if (barTop.present && y < barTop.clampedWidth)
            return barTop;
        if (barBottom.present && y > height - barBottom.clampedWidth)
            return barBottom;
        return null;
    }
    // Cursor position along a bar's main axis (y for vertical bars, x for horizontal).
    function barMainPos(b: Bar.BarWrapper, x: real, y: real): real {
        return b.vertical ? y : x;
    }
    // Drag delta in the bar's inward (reveal) direction.
    function barRevealDelta(b: Bar.BarWrapper, dragX: real, dragY: real): real {
        if (b.edge === "left")
            return dragX;
        if (b.edge === "right")
            return -dragX;
        if (b.edge === "top")
            return dragY;
        return -dragY; // bottom
    }
    function barFor(edge: string): Bar.BarWrapper {
        if (edge === "left")
            return barLeft;
        if (edge === "right")
            return barRight;
        if (edge === "top")
            return barTop;
        if (edge === "bottom")
            return barBottom;
        return null;
    }
    // Drop the transient hover reveal on every bar except `keep` (null clears all of them). A
    // bar with an open popout is exempt: the pointer moving off the bar and onto its own popout
    // must not pull the bar out from under it.
    function clearBarHover(keep: Bar.BarWrapper): void {
        for (const b of [barLeft, barRight, barTop, barBottom]) {
            if (b === keep || !b.isHovered)
                continue;
            if (popouts.hasCurrent && panels.popoutsWrapper.edge === b.edge)
                continue;
            b.isHovered = false;
        }
    }

    readonly property bool dashboardAtBottom: Config.dashboard.position === "bottom"

    readonly property bool dockAtBottom: Config.dock.position === "bottom"
    readonly property bool dockVertical: Config.dock.position === "left" || Config.dock.position === "right"
    // A pinned dock (or one revealed by an empty workspace) stays open regardless of the
    // hover arbitration below, so those paths must not try to close it.
    readonly property bool dockForcedOpen: panels.dock.forcedOpen

    // Expose the dock Wrapper's close grace timer so hover logic doesn't kill the dock
    // while the popout's onEntered still has a chance to fire and cancel the close.
    readonly property bool dockCloseGracePending: panels.dock.closeGracePending ?? false

    // Per-edge gesture arbitration. Several panels can occupy one screen edge (launcher,
    // dashboard and dock live on top or bottom; the osd and session menu can be placed on
    // any of the four), so the edge — not the panel — decides what a hover or an inward
    // drag opens. Config.edges.<edge>.hover / .drag name the winning panel; "none" disables
    // the gesture. A panel's own showOnHover still acts as its opt-out.
    // A floating launcher owns no edge, so hover/drag reveal applies to docked mode only — it
    // opens by keybind/IPC/click instead. An empty edge makes edgeOccupied/closeOthersOnEdge/
    // hoverOwns/dragOwns no-op for the launcher automatically, no extra branching needed.
    readonly property string launcherEdge: panels.launcher.floating ? "" : panels.launcher.effectiveEdge
    readonly property string dashboardEdge: dashboardAtBottom ? "bottom" : "top"
    readonly property string dockEdge: Config.dock.position
    readonly property string sidebarEdge: panelsAtRight ? "right" : "left"
    readonly property string osdEdge: Config.osd.position
    readonly property string sessionEdge: Config.session.position

    function hoverOwns(panel: string, edge: string): bool {
        return Config.edges[edge]?.hover === panel;
    }
    function dragOwns(panel: string, edge: string): bool {
        return Config.edges[edge]?.drag === panel;
    }
    // Whether some panel other than `exclude` is already open on `edge`. Hover must not
    // reopen a panel over one the user just drag-opened on the same edge, or the two fight
    // for every mouse move.
    //
    // Each clause also tests the panel's own `enabled`: DrawerVisibilities is persistent, so a
    // visibility left true from before a panel was disabled would otherwise mark the edge
    // occupied forever and silently kill hover for everything else on it.
    function edgeOccupied(edge: string, exclude: string): bool {
        if (exclude !== "launcher" && launcherEdge === edge && visibilities.launcher && Config.launcher.enabled)
            return true;
        if (exclude !== "dashboard" && dashboardEdge === edge && visibilities.dashboard && Config.dashboard.enabled)
            return true;
        if (exclude !== "dock" && dockEdge === edge && visibilities.dock && Config.dock.enabled)
            return true;
        if (exclude !== "osd" && osdEdge === edge && visibilities.osd && Config.osd.enabled)
            return true;
        if (exclude !== "session" && sessionEdge === edge && visibilities.session && Config.session.enabled)
            return true;
        return false;
    }
    // Close the other panels sharing `edge` so two can never be open on the same edge.
    function closeOthersOnEdge(edge: string, keep: string): void {
        if (keep !== "launcher" && launcherEdge === edge)
            visibilities.launcher = false;
        if (keep !== "dashboard" && dashboardEdge === edge)
            visibilities.dashboard = false;
        if (keep !== "dock" && dockEdge === edge)
            visibilities.dock = false;
        if (keep !== "osd" && osdEdge === edge)
            visibilities.osd = false;
        if (keep !== "session" && sessionEdge === edge)
            visibilities.session = false;
    }

    // Hit-test a top/bottom panel against whichever horizontal edge it's docked to.
    // While the panel is already open, test against its full height so moving onto it
    // (e.g. during the reveal animation) doesn't dismiss it before it finishes opening.
    function inVerticalPanel(panel: Item, x: real, y: real, atBottom: bool, open: bool): bool {
        if (!withinPanelWidth(panel, x, y))
            return false;
        const panelHeight = panel.height * (open ? 1 : (1 - (panel.offsetScale ?? 0))); // qmllint disable missing-property
        if (atBottom)
            return y > height - Math.max(Config.border.minThickness, panelBottomInset + panelHeight);
        return y < Math.max(Config.border.minThickness, panelTopInset + panelHeight);
    }
    function inDashboardPanel(x: real, y: real): bool {
        return inVerticalPanel(panels.dashboard, x, y, dashboardAtBottom, visibilities.dashboard);
    }
    function inDockPanel(x: real, y: real): bool {
        if (!Config.dock.enabled)
            return false;
        // inVerticalPanel is used on the horizontal edges for its `open` handling, which
        // tests against the panel's full height mid-reveal so the animation isn't
        // self-cancelling. The vertical edges fall back to the generic four-edge test.
        if (dockVertical)
            return inEdgePanel(panels.dock, x, y, dockEdge);
        return inVerticalPanel(panels.dock, x, y, dockAtBottom, visibilities.dock);
    }

    function withinPanelHeight(panel: Item, x: real, y: real): bool {
        const panelY = root.panelTopInset + panel.y;
        return y >= panelY - Config.border.rounding && y <= panelY + panel.height + Config.border.rounding;
    }

    function withinPanelWidth(panel: Item, x: real, y: real): bool {
        const panelX = root.panelLeftInset + panel.x;
        return x >= panelX - Config.border.rounding && x <= panelX + panel.width + Config.border.rounding;
    }

    function inLeftPanel(panel: Item, x: real, y: real): bool {
        if (panels.popoutsWrapper.atRight)
            return x > root.panelLeftInset + panel.x && withinPanelHeight(panel, x, y);
        return x < root.panelLeftInset + panel.x + panel.width && withinPanelHeight(panel, x, y);
    }

    // Whether the cursor is within the popout (used to keep it open while moving onto it).
    // For vertical bars the popout sits beside the bar (inLeftPanel); for horizontal bars it
    // sits above/below, so test the x-extent plus the appropriate vertical half.
    function inPopout(panel: Item, x: real, y: real): bool {
        const w = panels.popoutsWrapper;
        if (w.vertical)
            return inLeftPanel(panel, x, y);
        if (!withinPanelWidth(panel, x, y))
            return false;
        if (w.atBottom)
            return y > root.panelTopInset + panel.y;
        return y < root.panelTopInset + panel.y + panel.height;
    }

    function inRightPanel(panel: Item, x: real, y: real): bool {
        return x > Math.min(width - Config.border.minThickness, root.panelLeftInset + panel.x) && withinPanelHeight(panel, x, y);
    }

    function inLeftSidePanel(panel: Item, x: real, y: real): bool {
        return x < Math.max(Config.border.minThickness, root.panelLeftInset + panel.x + panel.width) && withinPanelHeight(panel, x, y);
    }

    function inTopPanel(panel: Item, x: real, y: real): bool {
        const panelHeight = panel.height * (1 - (panel.offsetScale ?? 0)); // qmllint disable missing-property
        return y < Math.max(Config.border.minThickness, panelTopInset + panelHeight) && withinPanelWidth(panel, x, y);
    }

    function inBottomPanel(panel: Item, x: real, y: real, isCorner = false): bool {
        const panelHeight = panel.height * (1 - (panel.offsetScale ?? 0)); // qmllint disable missing-property
        return y > height - Math.max(Config.border.minThickness, panelBottomInset + panelHeight) - (isCorner ? Config.border.rounding : 0) && withinPanelWidth(panel, x, y);
    }

    // Hit-test a panel against whichever of the four edges it is docked to. Lets the osd and
    // session menu be placed anywhere without every call site branching on the edge itself.
    function inEdgePanel(panel: Item, x: real, y: real, edge: string): bool {
        if (edge === "right")
            return inRightPanel(panel, x, y);
        if (edge === "left")
            return inLeftSidePanel(panel, x, y);
        if (edge === "top")
            return inTopPanel(panel, x, y);
        return inBottomPanel(panel, x, y);
    }
    // Whether the cursor is still within the panel's span on the axis it does *not* slide
    // along, so a drag that wanders off the side of the panel stops steering it.
    function withinPanelCrossAxis(panel: Item, x: real, y: real, edge: string): bool {
        return edge === "left" || edge === "right" ? withinPanelHeight(panel, x, y) : withinPanelWidth(panel, x, y);
    }
    // Drag delta in the inward (reveal) direction for `edge` — the panel counterpart of
    // barRevealDelta above.
    function edgeRevealDelta(edge: string, dragX: real, dragY: real): real {
        if (edge === "left")
            return dragX;
        if (edge === "right")
            return -dragX;
        if (edge === "top")
            return dragY;
        return -dragY; // bottom
    }
    // Whether (x, y) is clear of the open sidebar. Only panels sharing the sidebar's edge can
    // be covered by it; anywhere else the sidebar is irrelevant and must not gate the gesture.
    function clearOfSidebar(edge: string, x: real): bool {
        if (edge !== sidebarEdge)
            return true;
        const revealed = panels.sidebar.width * (1 - panels.sidebar.offsetScale);
        return panelsAtRight ? x < width - revealed : x > root.panelLeftInset + revealed;
    }

    // Session hover arbitration. Kept in one function and called from each onPositionChanged
    // branch rather than pasted into all of them, unlike the OSD blocks below. `gateOnSidebar`
    // is set for the branch where the sidebar is showing and could be covering the session.
    function applySessionHover(x: real, y: real, gateOnSidebar: bool): void {
        const hoverEnabled = Config.session.enabled && Config.session.showOnHover && hoverOwns("session", sessionEdge);
        const show = hoverEnabled && (!gateOnSidebar || clearOfSidebar(sessionEdge, x)) && inEdgePanel(panels.sessionWrapper, x, y, sessionEdge) && (visibilities.session || !edgeOccupied(sessionEdge, "session"));

        if (!sessionShortcutActive) {
            if (hoverEnabled) {
                if (show && !visibilities.session)
                    closeOthersOnEdge(sessionEdge, "session");
                visibilities.session = show;
            }
        } else if (show) {
            // Hovering the panel while it is shortcut-open hands control back to hover.
            sessionShortcutActive = false;
        }
    }

    // Show dock on hover, as this edge's arbitration allows. Hover drives visibility
    // continuously (like the dashboard) so the dock hides again as soon as the pointer leaves
    // it, rather than waiting to exit the whole mask. Factored out of onPositionChanged so the
    // close-grace landing can re-run it against the last known pointer position.
    function applyDockHover(x: real, y: real): void {
        const hoverEnabled = Config.dock.showOnHover && hoverOwns("dock", dockEdge);
        const show = hoverEnabled && inDockPanel(x, y) && (visibilities.dock || !edgeOccupied(dockEdge, "dock"));

        if (!dockShortcutActive && !panels.dockMenu.shouldBeActive) {
            if (hoverEnabled) {
                if (show && !visibilities.dock)
                    closeOthersOnEdge(dockEdge, "dock");
                // A forced-open dock is never driven down by hover; it would only flicker
                // back open on the Wrapper's own binding.
                if (show || (Config.dock.hideOnHoverOut && !dockForcedOpen && !root.dockCloseGracePending))
                    visibilities.dock = show || dockForcedOpen;
            }
        } else if (show) {
            dockShortcutActive = false;
        }
    }

    function onWheel(event: WheelEvent): void {
        if (fullscreen)
            return;
        const b = barAt(event.x, event.y);
        if (b)
            b.handleWheel(barMainPos(b, event.x, event.y), event.angleDelta);
    }

    anchors.fill: parent
    acceptedButtons: fullscreen ? Qt.NoButton : Qt.AllButtons
    hoverEnabled: true

    onPressed: event => dragStart = Qt.point(event.x, event.y)
    onContainsMouseChanged: {
        if (!containsMouse) {
            // Only hide if not activated by shortcut
            if (!osdShortcutActive) {
                visibilities.osd = false;
                root.panels.osd.hovered = false;
            }

            if (!dashboardShortcutActive)
                visibilities.dashboard = false;

            // Only for a hover-revealed session: one opened by keybind or IPC must survive the
            // pointer leaving the drawers window.
            if (!sessionShortcutActive && Config.session.showOnHover)
                visibilities.session = false;

            if (!utilitiesShortcutActive)
                visibilities.utilities = false;

            // Hide a hover-revealed bar on hover out, per the config of the edge that revealed
            // it. A bar opened by keybind or IPC (barShortcutActive) must survive the pointer
            // leaving the drawers window, exactly as the dock does, and a bar with a popout on
            // screen is not hover-revealed any more.
            const revealer = barFor(barRevealEdge);
            if (visibilities.bar && !barShortcutActive && !popouts.hasCurrent && !barEmptyRevealed && revealer?.present && revealer.barConfig.hideOnHoverOut && !revealer.barConfig.persistent)
                visibilities.bar = false;

            if (Config.dock.hideOnHoverOut && visibilities.dock && !dockForcedOpen && !panels.dockMenu.shouldBeActive && !root.dockCloseGracePending)
                visibilities.dock = false;

            if (!popouts.currentName.startsWith("traymenu") || ((popouts.current as StackView)?.depth ?? 0) <= 1)
                popouts.closeDeferred();

            clearBarHover(null);
        }
    }

    onPositionChanged: event => {
        if (popouts.isDetached)
            return;

        const x = event.x;
        const y = event.y;
        const dragX = x - dragStart.x;
        const dragY = y - dragStart.y;

        if (fullscreen) {
            const osdHoverEnabled = hoverOwns("osd", osdEdge);
            const showOsd = osdHoverEnabled && inEdgePanel(panels.osdWrapper, x, y, osdEdge);

            if (!osdShortcutActive) {
                if (osdHoverEnabled) {
                    root.visibilities.osd = showOsd;
                    root.panels.osd.hovered = showOsd;
                }
            } else if (showOsd) {
                osdShortcutActive = false;
                root.panels.osd.hovered = true;
            }
            return;
        }

        const hoverBar = barAtClamped(x, y);
        if (hoverBar?.barConfig.showOnHover) {
            // Show bar in non-exclusive mode on hover
            if (!visibilities.bar)
                hoverBar.isHovered = true;
            // hideOnHoverOut off means the bar latches open once hovered. The latch has to be
            // visibilities.bar and not isHovered: isHovered is hover's own transient state, and
            // a bar latched through it could no longer be dismissed by the toggle or a drag.
            if (!hoverBar.barConfig.hideOnHoverOut)
                visibilities.bar = true;
            // Hovering the bar while it is shortcut-open hands control back to hover, matching
            // the dock. barRevealEdge then names the bar whose config governs the close.
            barShortcutActive = false;
            barRevealEdge = hoverBar.edge;
        }
        clearBarHover(hoverBar);

        // Show/hide bar on drag (drag inward reveals, outward hides)
        const dragBar = barAtClamped(dragStart.x, dragStart.y);
        if (pressed && dragBar) {
            const revealDelta = barRevealDelta(dragBar, dragX, dragY);
            if (revealDelta > dragBar.barConfig.dragThreshold)
                visibilities.bar = true;
            else if (revealDelta < -dragBar.barConfig.dragThreshold)
                visibilities.bar = false;
        }

        if (panels.sidebar.offsetScale === 1) {
            // Show osd on hover, if this edge's arbitration gives it the hover gesture
            const osdHoverEnabled = Config.osd.showOnHover && hoverOwns("osd", osdEdge);
            const showOsd = osdHoverEnabled && inEdgePanel(panels.osdWrapper, x, y, osdEdge);

            // Always update visibility based on hover if not in shortcut mode
            if (!osdShortcutActive) {
                if (osdHoverEnabled) {
                    visibilities.osd = showOsd;
                    root.panels.osd.hovered = showOsd;
                }
            } else if (showOsd) {
                // If hovering over OSD area while in shortcut mode, transition to hover control
                osdShortcutActive = false;
                root.panels.osd.hovered = true;
            }

            applySessionHover(x, y, false);

            // Drag starts from the correct edge to reveal sidebar
            const showSidebar = panelsAtRight
                ? pressed && dragStart.x > Math.min(width - Config.border.minThickness, root.panelLeftInset + panels.sidebar.x)
                : pressed && dragStart.x < Math.max(Config.border.minThickness, root.panelLeftInset + panels.sidebar.x + panels.sidebar.width);
            // Drag direction that reveals the sidebar (inward from its edge)
            const sidebarRevealDrag = panelsAtRight ? dragX < -Config.sidebar.dragThreshold : dragX > Config.sidebar.dragThreshold;

            // Show/hide session on drag. A closed session's hit zone is a thin strip at the very
            // edge — exactly where a sidebar reveal drag starts — so only claim the gesture when
            // this edge actually gives the drag to the session. Otherwise the drag falls through
            // to the sidebar below instead of being swallowed.
            const inSession = dragOwns("session", sessionEdge) && inEdgePanel(panels.sessionWrapper, dragStart.x, dragStart.y, sessionEdge);
            if (pressed && inSession && withinPanelCrossAxis(panels.sessionWrapper, x, y, sessionEdge)) {
                const sessionDelta = edgeRevealDelta(sessionEdge, dragX, dragY);
                if (sessionDelta > Config.session.dragThreshold)
                    visibilities.session = true;
                else if (sessionDelta < -Config.session.dragThreshold)
                    visibilities.session = false;

                // Show sidebar on drag if in session area and session is nearly fully visible
                if (showSidebar && panels.session.offsetScale <= 0 && sidebarRevealDrag)
                    visibilities.sidebar = true;
            } else if (showSidebar && sidebarRevealDrag) {
                // Show sidebar on drag if not in session area
                visibilities.sidebar = true;
            }
        } else {
            // Show osd on hover, if this edge's arbitration gives it the hover gesture.
            // The open sidebar only masks the osd when the two share an edge.
            const osdHoverEnabled = Config.osd.showOnHover && hoverOwns("osd", osdEdge);
            const showOsd = osdHoverEnabled && clearOfSidebar(osdEdge, x) && inEdgePanel(panels.osdWrapper, x, y, osdEdge);

            // Always update visibility based on hover if not in shortcut mode
            if (!osdShortcutActive) {
                if (osdHoverEnabled) {
                    visibilities.osd = showOsd;
                    root.panels.osd.hovered = showOsd;
                }
            } else if (showOsd) {
                // If hovering over OSD area while in shortcut mode, transition to hover control
                osdShortcutActive = false;
                root.panels.osd.hovered = true;
            }

            applySessionHover(x, y, true);

            // Show/hide session on drag
            const inSession = inEdgePanel(panels.sessionWrapper, dragStart.x, dragStart.y, sessionEdge);
            if (dragOwns("session", sessionEdge) && pressed && clearOfSidebar(sessionEdge, dragStart.x) && inSession && withinPanelCrossAxis(panels.sessionWrapper, x, y, sessionEdge)) {
                const sessionDelta = edgeRevealDelta(sessionEdge, dragX, dragY);
                if (sessionDelta > Config.session.dragThreshold)
                    visibilities.session = true;
                else if (sessionDelta < -Config.session.dragThreshold)
                    visibilities.session = false;
            }

            // Hide sidebar on drag (outward from its edge)
            // The sidebar hangs below the notification stack, so its hit test must use the
            // drag's own y — a hardcoded 0 falls outside the panel as soon as a notification
            // is on screen, and the hide gesture silently stops working.
            const inSidebarArea = panelsAtRight
                ? inRightPanel(panels.sidebar, dragStart.x, dragStart.y)
                : inLeftSidePanel(panels.sidebar, dragStart.x, dragStart.y);
            const sidebarHideDrag = panelsAtRight ? dragX > Config.sidebar.dragThreshold : dragX < -Config.sidebar.dragThreshold;
            if (pressed && inSidebarArea && sidebarHideDrag)
                visibilities.sidebar = false;
        }

        // Show launcher on hover and/or inward drag, as this edge's arbitration allows.
        // Hover and drag are independent so one edge can hover one panel and drag another.
        if (Config.launcher.showOnHover && hoverOwns("launcher", launcherEdge)) {
            if (!visibilities.launcher && inEdgePanel(panels.launcher, x, y, launcherEdge) && !edgeOccupied(launcherEdge, "launcher")) {
                visibilities.launcher = true;
                closeOthersOnEdge(launcherEdge, "launcher");
            }
        }
        if (dragOwns("launcher", launcherEdge) && pressed && inEdgePanel(panels.launcher, dragStart.x, dragStart.y, launcherEdge) && withinPanelCrossAxis(panels.launcher, x, y, launcherEdge)) {
            // Reveal by dragging inward from the launcher's edge; hide by dragging back out.
            const launcherDelta = edgeRevealDelta(launcherEdge, dragX, dragY);
            if (launcherDelta > Config.launcher.dragThreshold) {
                visibilities.launcher = true;
                closeOthersOnEdge(launcherEdge, "launcher");
            } else if (launcherDelta < -Config.launcher.dragThreshold) {
                visibilities.launcher = false;
            }
        }

        // Show dashboard on hover, if this edge's arbitration gives it the hover gesture
        const dashboardHoverEnabled = Config.dashboard.showOnHover && hoverOwns("dashboard", dashboardEdge);
        const showDashboard = dashboardHoverEnabled && inDashboardPanel(x, y) && (visibilities.dashboard || !edgeOccupied(dashboardEdge, "dashboard"));

        // Always update visibility based on hover if not in shortcut mode. When hover does
        // not govern the dashboard, leave visibility alone — otherwise moving the mouse
        // would instantly close a dashboard opened by drag or shortcut.
        if (!dashboardShortcutActive) {
            if (dashboardHoverEnabled) {
                if (showDashboard && !visibilities.dashboard)
                    closeOthersOnEdge(dashboardEdge, "dashboard");
                visibilities.dashboard = showDashboard;
            }
        } else if (showDashboard) {
            // If hovering over dashboard area while in shortcut mode, transition to hover control
            dashboardShortcutActive = false;
        }

        // Show/hide dashboard on drag (for touchscreen devices)
        if (dragOwns("dashboard", dashboardEdge) && pressed && inDashboardPanel(dragStart.x, dragStart.y) && withinPanelWidth(panels.dashboard, x, y)) {
            // Reveal by dragging inward from the dashboard's edge (down from top, up from bottom)
            const dashReveal = dashboardAtBottom ? dragY < -Config.dashboard.dragThreshold : dragY > Config.dashboard.dragThreshold;
            const dashHide = dashboardAtBottom ? dragY > Config.dashboard.dragThreshold : dragY < -Config.dashboard.dragThreshold;
            if (dashReveal) {
                visibilities.dashboard = true;
                closeOthersOnEdge(dashboardEdge, "dashboard");
            } else if (dashHide) {
                visibilities.dashboard = false;
            }
        }

        applyDockHover(x, y);

        // The reveal gesture runs inward from whichever edge the dock is on, so it reads the
        // drag delta through the same helpers the other four-edge panels use.
        if (dragOwns("dock", dockEdge) && pressed && inDockPanel(dragStart.x, dragStart.y) && withinPanelCrossAxis(panels.dock, x, y, dockEdge)) {
            const inward = edgeRevealDelta(dockEdge, dragX, dragY);
            if (inward > Config.dock.dragThreshold) {
                visibilities.dock = true;
                closeOthersOnEdge(dockEdge, "dock");
            } else if (inward < -Config.dock.dragThreshold && !dockForcedOpen) {
                visibilities.dock = false;
            }
        }

        // Show utilities on hover
        const showUtilities = inBottomPanel(panels.utilities, x, y, true);

        // Always update visibility based on hover if not in shortcut mode
        if (!utilitiesShortcutActive) {
            visibilities.utilities = showUtilities;
        } else if (showUtilities) {
            // If hovering over utilities area while in shortcut mode, transition to hover control
            utilitiesShortcutActive = false;
        }

        // Show popouts on hover over whichever bar the cursor is on
        const popoutBar = barAt(x, y);
        if (popoutBar) {
            panels.popoutsWrapper.edge = popoutBar.edge;
            popoutBar.checkPopout(barMainPos(popoutBar, x, y));
        } else if (inPopout(panels.popoutsWrapper, x, y)) {
            popouts.open();
        } else if (!popouts.currentName.startsWith("traymenu") || ((popouts.current as StackView)?.depth ?? 0) <= 1) {
            popouts.closeDeferred();
        }
    }

    // Tear down tray menus only once a deferred close actually lands - doing it alongside
    // closeDeferred() would blank the popout while it's still on screen during the grace.
    Connections {
        target: root.popouts

        function onClosed(): void {
            root.win.closeAllTrays();
        }
    }

    // Monitor individual visibility changes
    Connections {
        function onLauncherChanged() {
            // If launcher is hidden, clear shortcut flags for dashboard and OSD
            if (!root.visibilities.launcher) {
                root.dashboardShortcutActive = false;
                root.osdShortcutActive = false;
                root.utilitiesShortcutActive = false;
                root.sessionShortcutActive = false;

                // Also hide dashboard and OSD if they're not being hovered
                const inDashboardArea = root.inDashboardPanel(root.mouseX, root.mouseY);
                const inOsdArea = root.inEdgePanel(root.panels.osdWrapper, root.mouseX, root.mouseY, root.osdEdge);

                if (!inDashboardArea) {
                    root.visibilities.dashboard = false;
                }
                if (!inOsdArea) {
                    root.visibilities.osd = false;
                    root.panels.osd.hovered = false;
                }
            }
        }

        function onDashboardChanged() {
            if (root.visibilities.dashboard) {
                // Dashboard became visible, immediately check if this should be shortcut mode
                const inDashboardArea = root.inDashboardPanel(root.mouseX, root.mouseY);
                if (!inDashboardArea) {
                    root.dashboardShortcutActive = true;
                }
            } else {
                // Dashboard hidden, clear shortcut flag
                root.dashboardShortcutActive = false;
            }
        }

        function onOsdChanged() {
            if (root.visibilities.osd) {
                // OSD became visible, immediately check if this should be shortcut mode
                const inOsdArea = root.inEdgePanel(root.panels.osdWrapper, root.mouseX, root.mouseY, root.osdEdge);
                if (!inOsdArea) {
                    root.osdShortcutActive = true;
                }
            } else {
                // OSD hidden, clear shortcut flag
                root.osdShortcutActive = false;
            }
        }

        function onSessionChanged() {
            if (root.visibilities.session) {
                // Session became visible; if the pointer isn't on it, a keybind or IPC opened
                // it, so hover must not immediately close it again.
                const inSessionArea = root.inEdgePanel(root.panels.sessionWrapper, root.mouseX, root.mouseY, root.sessionEdge);
                if (!inSessionArea) {
                    root.sessionShortcutActive = true;
                }
            } else {
                // Session hidden, clear shortcut flag
                root.sessionShortcutActive = false;
            }
        }

        function onBarChanged() {
            if (root.visibilities.bar) {
                // Bar became visible; if the pointer isn't on a bar, a keybind or IPC opened it,
                // so hover-out must not immediately close it again. Otherwise remember which
                // edge the pointer revealed it from — that bar's config governs the close.
                // Gated on containsMouse: outside the mask mouseX/mouseY can be negative, and a
                // negative coordinate satisfies the left/top edge tests in barAtClamped.
                const hovered = root.containsMouse ? root.barAtClamped(root.mouseX, root.mouseY) : null;
                root.barShortcutActive = !hovered;
                root.barRevealEdge = hovered?.edge ?? "";
            } else {
                root.barShortcutActive = false;
                root.barRevealEdge = "";
            }
        }

        function onDockChanged() {
            if (root.visibilities.dock) {
                // Dock became visible, immediately check if this should be shortcut mode
                const inDockArea = root.inDockPanel(root.mouseX, root.mouseY);
                if (!inDockArea) {
                    root.dockShortcutActive = true;
                }
            } else {
                // Dock hidden, clear shortcut flag
                root.dockShortcutActive = false;
            }
        }

        function onUtilitiesChanged() {
            if (root.visibilities.utilities) {
                // Utilities became visible, immediately check if this should be shortcut mode
                const inUtilitiesArea = root.inBottomPanel(root.panels.utilities, root.mouseX, root.mouseY);
                if (!inUtilitiesArea) {
                    root.utilitiesShortcutActive = true;
                }
            } else {
                // Utilities hidden, clear shortcut flag
                root.utilitiesShortcutActive = false;
            }
        }

        target: root.visibilities
    }

    // dockCloseGracePending keeps the dock up while a preview is winding down, so the moment
    // that grace lands the decision it suppressed has to be retaken. A pointer that left the
    // dock and then stopped moving never produces another onPositionChanged, which is what
    // left the dock stuck open after any preview had been hovered.
    Connections {
        function onPopoutClosed(): void {
            if (root.containsMouse)
                root.applyDockHover(root.mouseX, root.mouseY);
            else if (Config.dock.hideOnHoverOut && root.visibilities.dock && !root.dockForcedOpen && !root.panels.dockMenu.shouldBeActive)
                root.visibilities.dock = false;
        }

        target: root.panels.dock
    }
}
