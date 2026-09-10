import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.modules.dashboard as Dashboard
import qs.modules.dock as DockPanel
import qs.modules.launcher as Launcher
import qs.modules.notifications as Notifications
import qs.modules.osd as Osd
import qs.modules.session as Session
import qs.modules.sidebar as Sidebar
import qs.modules.utilities as Utilities
import qs.modules.bar.popouts as BarPopouts
import qs.modules.utilities.toasts as Toasts

Item {
    id: root

    required property ShellScreen screen
    required property DrawerVisibilities visibilities
    required property real insetLeft
    required property real insetRight
    required property real insetTop
    required property real insetBottom
    required property real borderThickness

    readonly property alias osd: osd
    readonly property alias osdWrapper: osdWrapper
    readonly property alias notifications: notifications
    readonly property alias session: session
    readonly property alias sessionWrapper: sessionWrapper
    readonly property alias launcher: launcher
    readonly property alias dashboard: dashboard
    readonly property alias popouts: popoutsWrapper.content
    readonly property alias popoutsWrapper: popoutsWrapper
    readonly property alias utilities: utilities
    readonly property alias toasts: toasts
    readonly property alias sidebar: sidebar
    readonly property alias dock: dockPanel
    readonly property alias dockMenu: dockMenu

    readonly property bool panelsAtRight: Config.sidebar.edge !== "left"

    // How far a panel docked to `edge` must sit inboard to clear the sidebar. The sidebar
    // only ever occupies left or right, so a panel on any other edge is unaffected by it —
    // that's what lets the OSD and session menu be positioned independently.
    function sidebarInset(edge: string): real {
        return edge === Config.sidebar.edge ? sidebar.width * (1 - sidebar.offsetScale) : 0;
    }

    anchors.fill: parent
    anchors.leftMargin: insetLeft
    anchors.rightMargin: insetRight
    anchors.topMargin: insetTop
    anchors.bottomMargin: insetBottom

    state: Config.sidebar.edge === "left" ? "left" : ""

    // Only panels that genuinely follow the sidebar belong here. The OSD and session menu
    // anchor themselves from their own Config.*.position instead (see below).
    states: [
        State {
            name: "left"

            AnchorChanges {
                target: notifications
                anchors.right: undefined
                anchors.left: parent.left
            }
            PropertyChanges {
                notifications.anchors.rightMargin: 0
                notifications.anchors.leftMargin: sidebar.width * (1 - sidebar.offsetScale) + notifications.edgeGap
            }

            AnchorChanges {
                target: utilities
                anchors.right: undefined
                anchors.left: parent.left
            }

            AnchorChanges {
                target: toasts
                anchors.right: undefined
                anchors.left: sidebar.right
            }

            AnchorChanges {
                target: sidebar
                anchors.right: undefined
                anchors.left: parent.left
            }
        }
    ]

    // A clip box that hugs the OSD's configured edge. The OSD stacks outboard of anything
    // else already on that edge — the session menu, and the sidebar if it lives there too —
    // but is untouched by either when it sits on a different edge entirely.
    Item {
        id: osdWrapper

        readonly property string edge: Config.osd.position
        readonly property bool isVertical: edge === "left" || edge === "right"
        readonly property real sessionInset: edge === Config.session.position ? (isVertical ? session.width : session.height) * (1 - session.offsetScale) : 0
        readonly property real inset: root.sidebarInset(edge) + sessionInset

        // Positioned rather than anchored — see EdgeAnchoredPanel for why conditional anchors
        // can't move a panel between edges at runtime.
        x: edge === "left" ? inset : edge === "right" ? parent.width - width - inset : (parent.width - width) / 2
        y: edge === "top" ? inset : edge === "bottom" ? parent.height - height - inset : (parent.height - height) / 2

        clip: inset > 0

        // Shrink along the docking axis as the panel slides away, so neighbours close up.
        implicitWidth: isVertical ? osd.implicitWidth * (1 - osd.offsetScale) : osd.implicitWidth
        implicitHeight: isVertical ? osd.implicitHeight : osd.implicitHeight * (1 - osd.offsetScale)

        Osd.Wrapper {
            id: osd

            screen: root.screen
            visibilities: root.visibilities
            edgeOffset: osdWrapper.inset > 0 ? 12 : 0
        }
    }

    Notifications.Wrapper {
        id: notifications

        visibilities: root.visibilities
        sidebarPanel: sidebar
        osdPanel: osdWrapper
        sessionPanel: sessionWrapper
        utilitiesPanel: utilities

        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: notifications.edgeGap
        anchors.rightMargin: sidebar.width * (1 - sidebar.offsetScale) + notifications.edgeGap
    }

    // As above, but the session menu only ever stacks outboard of the sidebar.
    Item {
        id: sessionWrapper

        readonly property string edge: Config.session.position
        readonly property bool isVertical: edge === "left" || edge === "right"
        readonly property real inset: root.sidebarInset(edge)

        x: edge === "left" ? inset : edge === "right" ? parent.width - width - inset : (parent.width - width) / 2
        y: edge === "top" ? inset : edge === "bottom" ? parent.height - height - inset : (parent.height - height) / 2

        clip: inset > 0

        implicitWidth: isVertical ? session.implicitWidth * (1 - session.offsetScale) : session.implicitWidth
        implicitHeight: isVertical ? session.implicitHeight : session.implicitHeight * (1 - session.offsetScale)

        Session.Wrapper {
            id: session

            visibilities: root.visibilities
            edgeOffset: sessionWrapper.inset > 0 ? 14 : 0
        }
    }

    Launcher.Wrapper {
        id: launcher

        screen: root.screen
        visibilities: root.visibilities
        panels: root
        // Positions itself via x/y for all four edges plus floating/centre — see Wrapper.qml.
    }

    Dashboard.Wrapper {
        id: dashboard

        visibilities: root.visibilities

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top

        states: State {
            name: "bottom"
            when: Config.dashboard.position === "bottom"

            AnchorChanges {
                target: dashboard
                anchors.top: undefined
                anchors.bottom: dashboard.parent.bottom
            }
        }
    }

    DockPanel.Wrapper {
        id: dockPanel

        screen: root.screen
        visibilities: root.visibilities

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom

        // AnchorChanges rather than ternary anchors: assigning `undefined` to an anchor
        // does not release it once it has been bound.
        states: [
            State {
                name: "top"
                when: Config.dock.position === "top"

                AnchorChanges {
                    target: dockPanel
                    anchors.bottom: undefined
                    anchors.top: dockPanel.parent.top
                }
            },
            State {
                name: "left"
                when: Config.dock.position === "left"

                AnchorChanges {
                    target: dockPanel
                    anchors.bottom: undefined
                    anchors.horizontalCenter: undefined
                    anchors.left: dockPanel.parent.left
                    anchors.verticalCenter: dockPanel.parent.verticalCenter
                }
            },
            State {
                name: "right"
                when: Config.dock.position === "right"

                AnchorChanges {
                    target: dockPanel
                    anchors.bottom: undefined
                    anchors.horizontalCenter: undefined
                    anchors.right: dockPanel.parent.right
                    anchors.verticalCenter: dockPanel.parent.verticalCenter
                }
            }
        ]
    }

    // Sibling of the dock rather than a child of it: the dock's Loader is torn down whenever
    // the dock hides, which would destroy the popout mid-interaction.
    DockPanel.Popout {
        id: dockMenu

        // Flush against the dock, like a hugged bar popout — the blobs need proximity to
        // merge, and dockMenuBg's extraSpan supplies the overlap the old 8px gap compensated for.
        readonly property int huggedGap: 0
        readonly property int gap: Config.dock.popoutMode === "floating" ? Config.dock.popoutGap : dockMenu.huggedGap

        visibilities: root.visibilities
        dockWrapper: dockPanel
        mode: dockPanel.popoutMode
        targetData: dockPanel.popoutTarget
        editMode: dockPanel.editMode

        // The card sits beside the dock on the dock's own axis and is centred on the icon
        // along the other one. It emerges from the dock and retreats into it when closing,
        // so the slide always runs toward the dock's screen edge.
        x: {
            if (!dockPanel.isVertical) {
                const desired = dockPanel.x + dockPanel.popoutCenter - implicitWidth / 2;
                return Math.max(0, Math.min(desired, root.width - implicitWidth));
            }
            const atLeft = Config.dock.position === "left";
            const base = atLeft ? dockPanel.x + dockPanel.width + gap : dockPanel.x - implicitWidth - gap;
            const slide = (implicitWidth + gap) * offsetScale;
            return atLeft ? base - slide : base + slide;
        }
        y: {
            if (dockPanel.isVertical) {
                const desired = dockPanel.y + dockPanel.popoutCenter - implicitHeight / 2;
                return Math.max(0, Math.min(desired, root.height - implicitHeight));
            }
            const atTop = Config.dock.position === "top";
            const base = atTop ? dockPanel.y + dockPanel.height + gap : dockPanel.y - implicitHeight - gap;
            const slide = (implicitHeight + gap) * offsetScale;
            return atTop ? base - slide : base + slide;
        }

        onEditModeRequested: active => dockPanel.editMode = active
        onAddAppRequested: dockPanel.openLauncher(true)
        onCloseRequested: dockPanel.closePopout()
    }

    BarPopouts.ClipWrapper {
        id: popoutsWrapper

        screen: root.screen
        borderThickness: root.borderThickness
        insetLeft: root.insetLeft
        insetTop: root.insetTop
    }

    Utilities.Wrapper {
        id: utilities

        visibilities: root.visibilities
        sidebar: sidebar
        popouts: popoutsWrapper.content

        anchors.bottom: parent.bottom
        anchors.right: parent.right
    }

    Toasts.Toasts {
        id: toasts

        anchors.bottom: sidebar.visible ? parent.bottom : utilities.top
        anchors.right: sidebar.left
        anchors.margins: Tokens.padding.medium
    }

    Sidebar.Wrapper {
        id: sidebar

        visibilities: root.visibilities
        atRight: root.panelsAtRight

        anchors.top: notifications.bottom
        anchors.bottom: utilities.top
        anchors.right: parent.right
    }
}
