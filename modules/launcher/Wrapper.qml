pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.modules.launcher.services

Item {
    id: root

    required property ShellScreen screen
    required property DrawerVisibilities visibilities
    required property var panels

    readonly property bool shouldBeActive: visibilities.launcher && Config.launcher.enabled

    readonly property bool floating: Config.launcher.mode === "floating"
    // Docked + "center" is meaningless (there's no edge to hug), so it's coerced to bottom
    // here rather than validated in C++, matching how other position properties are handled.
    readonly property string effectiveEdge: !floating && Config.launcher.position === "center" ? "bottom" : Config.launcher.position
    readonly property bool isVertical: effectiveEdge === "left" || effectiveEdge === "right"
    readonly property bool centered: effectiveEdge === "center"
    readonly property real gap: floating ? Config.launcher.gap : 0
    // Stack inboard of an open sidebar when they share an edge (existing helper).
    readonly property real inset: gap + panels.sidebarInset(effectiveEdge)
    readonly property real slideDistance: (isVertical ? width : height) + inset + 5 // 5 = overshoot

    readonly property real maxHeight: {
        let max = screen.height - Config.border.thickness * 2 + Tokens.padding.extraLarge;
        if (visibilities.dashboard && Config.dashboard.position === effectiveEdge)
            max -= panels.dashboard.nonAnimHeight;
        if (floating)
            max -= gap * 2;
        return max;
    }

    property real offsetScale: shouldBeActive ? 0 : 1

    property string initialText: ""
    property bool pinMode: false

    onShouldBeActiveChanged: {
        if (shouldBeActive) {
            initialText = LauncherIpc.text;
            pinMode = LauncherIpc.pinMode;
            LauncherIpc.text = "";
            LauncherIpc.pinMode = false;
            implicitHeight = Qt.binding(() => content.implicitHeight);
        } else {
            initialText = "";
            pinMode = false;
            implicitHeight = implicitHeight; // Break binding during close anim
        }
    }

    visible: offsetScale < 1
    implicitHeight: content.implicitHeight
    implicitWidth: content.implicitWidth || 630 // Hard coded fallback for first open
    opacity: 1 - offsetScale
    // Floating + centred has no edge to travel toward, so the reveal is opacity plus a
    // gentle scale instead of a slide.
    scale: centered ? 1 - 0.05 * offsetScale : 1

    // Positioned rather than anchored — see EdgeAnchoredPanel for why conditional anchors
    // can't move a panel between edges at runtime. Base position follows the osdWrapper
    // formula (Panels.qml); the slide term pushes the panel out past its edge as it hides.
    x: {
        if (centered)
            return (parent.width - width) / 2;
        if (effectiveEdge === "left")
            return inset - slideDistance * offsetScale;
        if (effectiveEdge === "right")
            return parent.width - width - inset + slideDistance * offsetScale;
        return (parent.width - width) / 2;
    }
    y: {
        if (centered)
            return (parent.height - height) / 2;
        if (effectiveEdge === "top")
            return inset - slideDistance * offsetScale;
        if (effectiveEdge === "bottom")
            return parent.height - height - inset + slideDistance * offsetScale;
        return (parent.height - height) / 2;
    }

    Component.onCompleted: Qt.callLater(() => Apps) // Load apps on init

    Behavior on offsetScale {
        Anim {}
    }

    Loader {
        id: content

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter

        active: root.shouldBeActive || root.visible

        sourceComponent: Content {
            initialText: root.initialText
            pinMode: root.pinMode
            visibilities: root.visibilities
            panels: root.panels
            maxHeight: root.maxHeight
            floating: root.floating
        }
    }
}
