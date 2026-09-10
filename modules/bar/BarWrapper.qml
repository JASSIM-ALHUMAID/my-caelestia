pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Caelestia.Config
import qs.components
import qs.services
import qs.utils
import qs.modules.bar.popouts as BarPopouts

Item {
    id: root

    required property ShellScreen screen
    required property DrawerVisibilities visibilities
    required property BarPopouts.Wrapper popouts
    required property bool fullscreen
    // The per-edge BarEdgeConfig for this bar (root.barConfig.left/right/top/bottom). `var`
    // because the config subobjects are QML_ANONYMOUS and have no nameable QML type.
    required property var barConfig
    required property string edge

    // Default to vertical for any unknown/empty edge so the bar can never collapse to nothing
    readonly property bool vertical: edge !== "top" && edge !== "bottom"
    // Whether the bar sits on the right screen edge (consumed by the drawers layer for placement)
    readonly property bool atRight: edge === "right"

    readonly property bool disabled: Strings.testRegexList(root.barConfig.excludedScreens, screen.name)
    // Whether this edge actually has a bar: enabled in config and not excluded on this screen.
    // When false the wrapper reserves no space and renders nothing (the edge falls back to
    // just the window border in the drawers inset math).
    readonly property bool present: root.barConfig.enabled && !disabled

    // Empty workspace reveal: show the bar when no windows are open. Deliberately a continuous
    // condition OR'd into shouldBeVisible below, the way the dock does it (modules/dock/
    // Wrapper.qml). Driving `visibilities.bar` from a change handler instead asserts only at the
    // instant emptiness flips, and the hover-out path then clears the flag for good — nothing
    // re-asserts until the workspace changes again.
    readonly property HyprlandMonitor monitor: Hypr.monitorFor(screen)
    readonly property var activeToplevels: monitor?.activeWorkspace?.toplevels.values ?? []
    readonly property bool emptyWorkspace: root.activeToplevels.length === 0
    // An explicit toggle beats the reveal, but only for the current empty stretch: leaving the
    // workspace or opening a window re-arms it.
    property bool emptyRevealDismissed
    readonly property bool emptyReveal: present && root.barConfig.revealOnEmptyWorkspace && !root.barConfig.persistent && emptyWorkspace && !emptyRevealDismissed

    onEmptyWorkspaceChanged: emptyRevealDismissed = false

    // While the reveal is what's holding the bar open, `visibilities.bar` is false, so the
    // toggle's flip to true would be a silent no-op. Read that press as the hide the user meant.
    Connections {
        function onBarChanged(): void {
            if (root.visibilities.bar && root.emptyReveal) {
                root.emptyRevealDismissed = true;
                root.visibilities.bar = false;
            }
        }

        target: root.visibilities
    }

    readonly property int padding: Math.max(Tokens.padding.small, Config.border.thickness)
    // Cross-axis size of the expanded bar (width when vertical, height when horizontal)
    readonly property int contentWidth: Tokens.sizes.bar.innerWidth + padding * 2
    readonly property int collapsedThickness: fullscreen ? 0 : Config.border.thickness

    // Animated cross-axis size, mapped onto width or height depending on the edge.
    property int thickness: collapsedThickness
    readonly property int clampedWidth: Math.max(Config.border.minThickness, thickness)

    // What this bar would reserve if it were not floating. Exclusions.qml needs it to stack a
    // pinned dock on top of a floating bar, which still displaces the dock visually.
    // Only a pinned bar reserves space. Every transient reveal — hover, the keybind/IPC toggle,
    // drag — draws over the windows instead, so revealing the bar never reflows the workspace.
    // emptyReveal stays in: it only fires with no windows on the workspace, so there is nothing
    // to reflow, and the dock stacking above still needs a real zone to sit on.
    readonly property int visualZone: present && (root.barConfig.persistent || emptyReveal) ? contentWidth : Config.border.thickness
    // A floating bar draws over windows instead of reserving space for itself.
    readonly property int exclusiveZone: root.barConfig.floating ? Config.border.thickness : visualZone
    readonly property bool shouldBeVisible: !fullscreen && present && (root.barConfig.persistent || visibilities.bar || isHovered || emptyReveal)
    property bool isHovered

    function closeTray(): void {
        (content.item as Bar)?.closeTray();
    }

    function checkPopout(pos: real): void {
        (content.item as Bar)?.checkPopout(pos);
    }

    function handleWheel(pos: real, angleDelta: point): void {
        (content.item as Bar)?.handleWheel(pos, angleDelta);
    }

    clip: true
    // Stacking among the per-edge bars (and over the panels layer) where they meet at a corner.
    z: barConfig.zIndex
    visible: present && (vertical ? width : height) > 0
    implicitWidth: present && vertical ? thickness : 0
    implicitHeight: present && !vertical ? thickness : 0

    states: State {
        name: "visible"
        when: root.shouldBeVisible

        PropertyChanges {
            root.thickness: root.contentWidth
        }
    }

    transitions: [
        Transition {
            from: ""
            to: "visible"

            Anim {
                target: root
                property: "thickness"
                type: Anim.DefaultSpatial
            }
        },
        Transition {
            from: "visible"
            to: ""

            Anim {
                target: root
                property: "thickness"
                type: Anim.Emphasized
            }
        }
    ]

    Loader {
        id: content

        // Fill the main axis via anchors; pin the cross axis to the inner edge with x/y
        // (not a toggled anchor) so switching left<->right doesn't leave a stale anchor.
        anchors.top: root.vertical ? parent.top : undefined
        anchors.bottom: root.vertical ? parent.bottom : undefined
        anchors.left: root.vertical ? undefined : parent.left
        anchors.right: root.vertical ? undefined : parent.right
        x: root.vertical ? (root.atRight ? 0 : root.width - width) : 0
        y: root.vertical ? 0 : (root.edge === "bottom" ? 0 : root.height - height)

        active: root.shouldBeVisible

        sourceComponent: Bar {
            width: root.vertical ? root.contentWidth : undefined
            height: root.vertical ? undefined : root.contentWidth
            screen: root.screen
            visibilities: root.visibilities
            popouts: root.popouts // qmllint disable incompatible-type
            fullscreen: root.fullscreen
            barConfig: root.barConfig
            edge: root.edge
        }
    }
}
