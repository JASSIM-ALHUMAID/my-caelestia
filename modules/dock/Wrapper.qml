pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    required property DrawerVisibilities visibilities
    required property ShellScreen screen

    readonly property HyprlandMonitor monitor: Hypr.monitorFor(screen)
    readonly property var activeToplevels: monitor?.activeWorkspace?.toplevels.values ?? []
    // Hyprland reports fullscreen as a mode, where >1 means true fullscreen rather than
    // maximised — matching the test ContentWindow already uses.
    readonly property bool hasFullscreen: activeToplevels.some(t => t.lastIpcObject.fullscreen > 1)

    readonly property bool onThisScreen: !Config.dock.excludedScreens.includes(screen.name)

    // Reveal gates, in the same precedence order ambxst uses: fullscreen wins over
    // everything, then keepHidden (which deliberately beats pinned, so a dock can be
    // parked without losing its pinned state), then the always-open cases.
    readonly property bool suppressed: hasFullscreen && !Config.dock.availableOnFullscreen
    readonly property bool forcedOpen: !Config.dock.keepHidden && !suppressed && (Config.dock.pinned || (Config.dock.revealOnEmptyWorkspace && activeToplevels.length === 0))

    readonly property bool shouldBeActive: Config.dock.enabled && onThisScreen && !suppressed && (forcedOpen || visibilities.dock)
    readonly property Content content: loader.item as Content

    readonly property string position: Config.dock.position
    readonly property bool isVertical: position === "left" || position === "right"
    // Thickness along the axis the dock reserves space on, including its edge gap.
    readonly property real thickness: (isVertical ? implicitWidth : implicitHeight) + Config.dock.margin

    readonly property string popoutMode: content?.popoutMode ?? ""
    readonly property var popoutTarget: content?.popoutTarget ?? null
    readonly property real popoutCenter: content?.popoutCenter ?? 0
    readonly property bool closeGracePending: closeTimer.running

    property real offsetScale: shouldBeActive ? 0 : 1
    property bool editMode: false

    // Lets Interactions re-evaluate hover visibility the moment the grace lands. Without it a
    // pointer that left the dock and then stopped moving never gets another onPositionChanged,
    // so the dock stays up for as long as nothing else nudges the mouse.
    signal popoutClosed

    function closePopout(): void {
        const wasOpen = (root.content?.popoutMode?.length ?? 0) > 0;
        closeTimer.stop();
        root.content?.closePopout();
        // Only when something actually closed: closePopout is also the idempotent teardown
        // called on every dock hide, and signalling from those would have hover logic
        // re-deciding the dock's visibility on paths that never opened a popout at all.
        if (wasOpen)
            root.popoutClosed();
    }

    function closeDeferred(): void {
        if ((root.content?.popoutMode?.length ?? 0) > 0)
            closeTimer.restart();
    }

    function cancelClose(): void {
        closeTimer.stop();
    }

    // The extra 5 is overshoot, so the panel is fully clear of the edge rather than leaving a
    // hairline behind while the opacity fade finishes.
    function edgeMargin(extent: real): real {
        return Config.dock.margin - (extent + Config.dock.margin + 5) * root.offsetScale;
    }

    function openLauncher(pin) {
        root.content?.openLauncher(pin);
    }

    visible: offsetScale < 1
    // Only the margin matching the currently anchored edge takes effect; each slides the
    // panel away from its own screen edge. The horizontal pair moves by height, the
    // vertical pair by width. Each lerps from Config.dock.margin when open to fully
    // offscreen when closed, so `margin` is the visual edge gap it reads as in the settings
    // page — and the same gap `thickness` already folds into the exclusive zone.
    anchors.bottomMargin: edgeMargin(implicitHeight)
    anchors.topMargin: edgeMargin(implicitHeight)
    anchors.leftMargin: edgeMargin(implicitWidth)
    anchors.rightMargin: edgeMargin(implicitWidth)
    implicitHeight: loader.implicitHeight
    implicitWidth: loader.implicitWidth
    opacity: 1 - offsetScale

    onShouldBeActiveChanged: {
        if (!shouldBeActive) {
            editMode = false;
            closePopout();
        }
    }

    Timer {
        id: closeTimer

        interval: Config.dock.hoverGrace
        onTriggered: root.closePopout()
    }

    Connections {
        target: root.content

        function onCloseGraceRequested(): void {
            root.closeDeferred();
        }

        function onPopoutOpened(): void {
            closeTimer.stop();
        }
    }

    Behavior on offsetScale {
        Anim {}
    }

    Loader {
        id: loader

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter

        active: root.shouldBeActive || root.visible

        sourceComponent: Content {
            visibilities: root.visibilities
            editMode: root.editMode
            onEditModeRequested: active => root.editMode = active
        }
    }
}
