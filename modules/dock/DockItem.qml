pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.components.images
import qs.services
import qs.utils
import qs.modules.launcher.services

Item {
    id: root

    required property var modelData
    required property int index
    required property int iconSize
    required property bool isRunning
    required property bool isActive
    required property bool editMode
    required property bool isVertical
    required property string dockPosition

    readonly property bool isSeparator: root.modelData.isSeparator ?? false

    readonly property int dotSize: Math.max(4, Math.round(iconSize / 8))
    readonly property int effIcon: Math.max(Config.dock.minIconSize, Math.min(iconSize, Config.dock.maxIconSize))
    readonly property bool dragEnabled: Config.dock.dragAndDrop && !root.isSeparator
    readonly property bool wiggling: root.editMode && Config.dock.wiggleInEditMode && !content.held && !root.isSeparator
    readonly property alias held: content.held

    // Space reserved alongside the icon for the running indicators.
    readonly property int dotSpan: dotSize + 4
    // Indicators sit on the screen-edge side of the icon, so they read as underlining it
    // no matter which edge the dock is on.
    readonly property bool dotsAtStart: dockPosition === "top" || dockPosition === "left"

    readonly property int instanceCount: root.modelData.toplevels?.length ?? 0
    readonly property bool showIndicators: Config.dock.showRunningIndicators && root.isRunning && !root.isSeparator

    property bool dropHovered: false
    // Which side of this item the dragged icon would land on, tracked from the cursor's
    // position within it so the indicator reads correctly regardless of drag direction.
    property bool dropLeading: true
    property bool _dragGuard: false
    // Which window of a multi-window app the next click focuses.
    property int lastFocused: -1

    // Centre along the dock's main axis, for lining a popout up with this icon.
    readonly property real mainAxisCentre: root.isVertical ? root.y + root.height / 2 : root.x + root.width / 2

    signal rightClicked(var modelData, real center)
    signal hoverChanged(var modelData, real center, bool hovered)
    signal removeRequested(var modelData)
    signal dndReordered(int from, int to)
    signal activated

    function activate(): void {
        const tops = root.modelData.toplevels ?? [];
        if (tops.length === 0) {
            if (root.modelData.entry)
                Apps.launch(root.modelData.entry);
        } else if (Config.dock.cycleWindowsOnClick) {
            // Step through the app's windows so a second click on an already-focused app
            // reaches its other windows rather than doing nothing.
            root.lastFocused = (root.lastFocused + 1) % tops.length;
            Hypr.focusWindow(tops[root.lastFocused].address);
        } else {
            Hypr.focusWindow(tops[0].address);
        }
        root.activated();
    }

    implicitWidth: {
        if (root.isSeparator)
            return root.isVertical ? root.effIcon * 0.6 : 2;
        return root.isVertical ? root.effIcon + root.dotSpan : root.effIcon;
    }
    implicitHeight: {
        if (root.isSeparator)
            return root.isVertical ? 2 : root.effIcon * 0.6;
        return root.isVertical ? root.effIcon : root.effIcon + root.dotSpan;
    }
    z: held ? 1 : 0

    // Divider between pinned favourites and merely-running apps. Inert: no drag, no
    // popout, no drop target.
    StyledRect {
        anchors.fill: parent
        visible: root.isSeparator
        radius: Tokens.rounding.full
        color: Colours.palette.m3outlineVariant
    }

    StyledRect {
        anchors.fill: parent
        radius: Tokens.rounding.full
        color: Colours.palette.m3primary
        opacity: root.dropHovered ? 0.15 : 0

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    // Insertion affordance: a thin bar on the leading/trailing edge (relative to the dock's
    // flow direction) showing where the dragged icon will land, since the tint alone doesn't
    // say which side of the hovered item the drop lands on. Positioned via x/y rather than
    // anchors — an anchor that flips side at runtime as dropLeading toggles cannot be cleared
    // once set.
    StyledRect {
        id: dropIndicator

        width: root.isVertical ? parent.width : 3
        height: root.isVertical ? 3 : parent.height
        x: root.isVertical ? 0 : (root.dropLeading ? 0 : parent.width - width)
        y: root.isVertical ? (root.dropLeading ? 0 : parent.height - height) : 0
        radius: Tokens.rounding.full
        color: Colours.palette.m3primary
        opacity: root.dropHovered ? 1 : 0

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    // The Grid positions `root`, so only this inner item may be moved by a drag. It must not
    // be anchored either — anchors keep rewriting x/y, which silently makes drag.target inert.
    Item {
        id: content

        property bool held: false

        visible: !root.isSeparator
        width: root.width
        height: root.height
        Drag.active: held
        Drag.source: root
        Drag.hotSpot.x: width / 2
        Drag.hotSpot.y: height / 2

        states: State {
            name: "held"
            when: content.held

            PropertyChanges {
                content.scale: 1.05
                content.opacity: 0.85
            }
        }

        Behavior on scale {
            Anim {}
        }

        // Alternate the starting phase so neighbouring icons don't wiggle in lockstep
        SequentialAnimation {
            running: root.wiggling
            loops: Animation.Infinite
            alwaysRunToEnd: false

            onStopped: content.rotation = 0

            RotationAnimation {
                target: content
                from: root.index % 2 === 0 ? -2 : 2
                to: root.index % 2 === 0 ? 2 : -2
                duration: 130
                easing.type: Easing.InOutSine
            }

            RotationAnimation {
                target: content
                from: root.index % 2 === 0 ? 2 : -2
                to: root.index % 2 === 0 ? -2 : 2
                duration: 130
                easing.type: Easing.InOutSine
            }
        }

        ClippingRectangle {
            id: iconBg

            color: "transparent"
            radius: Tokens.rounding.full
            implicitWidth: root.effIcon
            implicitHeight: root.effIcon

            // Positioned rather than anchored: the icon and the indicator strip swap sides
            // with the dock's edge, and a conditional anchor cannot be cleared once set.
            x: root.isVertical && root.dotsAtStart ? root.dotSpan : 0
            y: !root.isVertical && root.dotsAtStart ? root.dotSpan : 0

            CachingIconImage {
                anchors.fill: parent
                implicitSize: parent.implicitHeight
                source: Icons.getAppIcon(root.modelData.appClass ?? "", "image-missing")
            }

            MouseArea {
                id: extraButtonArea

                anchors.fill: parent
                acceptedButtons: Qt.RightButton | Qt.MiddleButton
                hoverEnabled: false

                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton) {
                        root.rightClicked(root.modelData, root.mainAxisCentre);
                        return;
                    }
                    // Middle click always spawns a new window, even when the app is running.
                    if (Config.dock.middleClickNewInstance && root.modelData.entry)
                        Apps.launch(root.modelData.entry);
                }
            }

            // Drag lives on the StateLayer rather than a MouseArea beneath it: StateLayer is
            // itself a MouseArea and, being the topmost child, would otherwise swallow every
            // left press before a lower drag handler ever saw one.
            StateLayer {
                id: stateLayer

                anchors.fill: parent
                radius: Tokens.rounding.full
                cursorShape: root.dragEnabled ? (content.held ? Qt.ClosedHandCursor : Qt.OpenHandCursor) : Qt.PointingHandCursor

                drag.target: root.dragEnabled ? content : null
                drag.threshold: Config.dock.dragThreshold

                drag.onActiveChanged: {
                    if (drag.active) {
                        content.held = true;
                    } else {
                        // Must run while Drag.active is still true — it reports the accepted
                        // action and deactivates the drag itself. Clearing held first cancels
                        // the drag before DropArea.onDropped ever fires.
                        content.Drag.drop();
                        content.held = false;
                        content.x = 0;
                        content.y = 0;
                        root._dragGuard = true;
                    }
                }

                onEntered: root.hoverChanged(root.modelData, root.mainAxisCentre, true)
                onExited: root.hoverChanged(root.modelData, root.mainAxisCentre, false)
                onClicked: {
                    // Swallow the click that terminates a drag, else the drop also launches
                    if (root._dragGuard) {
                        root._dragGuard = false;
                        return;
                    }
                    root.activate();
                }

                // Via Connections so StateLayer's own onPressed (the ripple) still runs —
                // declaring onPressed here would replace it instead of adding to it.
                Connections {
                    function onPressed(): void {
                        root._dragGuard = false;
                    }

                    target: stateLayer
                }
            }
        }

        // Running indicators: one wide pill for a single window, up to maxIndicatorDots
        // pills beyond that, collapsing to squares once there are more windows than dots.
        Item {
            id: indicators

            readonly property int shown: Math.min(root.instanceCount, Math.max(1, Config.dock.maxIndicatorDots))
            readonly property bool collapsed: root.instanceCount > Math.max(1, Config.dock.maxIndicatorDots)

            visible: root.showIndicators
            width: root.isVertical ? root.dotSpan : root.effIcon
            height: root.isVertical ? root.effIcon : root.dotSpan

            x: root.isVertical ? (root.dotsAtStart ? 0 : root.effIcon + 4) : 0
            y: root.isVertical ? 0 : (root.dotsAtStart ? 0 : root.effIcon + 4)

            Row {
                anchors.centerIn: parent
                spacing: 3
                visible: !root.isVertical

                Repeater {
                    model: indicators.shown

                    StyledRect {
                        implicitWidth: indicators.collapsed ? root.dotSize : root.dotSize * 2.5
                        implicitHeight: root.dotSize
                        radius: Tokens.rounding.full
                        color: root.isActive ? Colours.palette.m3primary : Colours.palette.m3outlineVariant

                        Behavior on color {
                            CAnim {}
                        }
                    }
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: 3
                visible: root.isVertical

                Repeater {
                    model: indicators.shown

                    StyledRect {
                        implicitWidth: root.dotSize
                        implicitHeight: indicators.collapsed ? root.dotSize : root.dotSize * 2.5
                        radius: Tokens.rounding.full
                        color: root.isActive ? Colours.palette.m3primary : Colours.palette.m3outlineVariant

                        Behavior on color {
                            CAnim {}
                        }
                    }
                }
            }
        }

        StyledRect {
            id: removeBadge

            visible: root.editMode && root.modelData.isPinned
            implicitWidth: badgeIcon.implicitHeight + 2
            implicitHeight: badgeIcon.implicitHeight + 2
            radius: Tokens.rounding.full
            color: Colours.palette.m3error

            anchors.left: iconBg.left
            anchors.top: iconBg.top
            anchors.leftMargin: -4
            anchors.topMargin: -4

            MaterialIcon {
                id: badgeIcon

                anchors.centerIn: parent
                text: "remove"
                color: Colours.palette.m3onError
                fontStyle: Tokens.font.icon.small
            }

            MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                cursorShape: Qt.PointingHandCursor
                onClicked: root.removeRequested(root.modelData)
            }
        }
    }

    DropArea {
        anchors.fill: parent
        enabled: !root.isSeparator
        onEntered: drag => {
            const from = drag.source?.index ?? -1;
            root.dropHovered = from >= 0 && from !== root.index;
            root.dropLeading = root.isVertical ? drag.y < root.height / 2 : drag.x < root.width / 2;
        }
        onPositionChanged: drag => {
            root.dropLeading = root.isVertical ? drag.y < root.height / 2 : drag.x < root.width / 2;
        }
        onExited: root.dropHovered = false
        onDropped: drop => {
            root.dropHovered = false;
            const from = drop.source?.index ?? -1;
            if (from >= 0 && from !== root.index)
                root.dndReordered(from, root.index);
        }
    }
}
