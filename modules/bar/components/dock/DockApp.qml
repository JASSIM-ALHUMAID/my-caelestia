pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.components.images
import qs.services
import qs.utils

// A single grouped app in the dock: rounded app icon + an active dot (positioned per
// root.barConfig.dock.activeIndicatorPosition) when one of its windows is focused.
Item {
    id: root

    required property ShellScreen screen
    required property var barConfig
    required property var modelData
    required property int iconSize
    required property string activeAddress

    readonly property string appClass: modelData.appClass
    readonly property var windows: modelData.windows
    // Window shown in the hover popout: the focused one if this app is active, else first.
    readonly property var toplevel: windows.find(w => w.address === root.activeAddress) ?? windows[0]
    readonly property bool active: windows.some(w => w.address === root.activeAddress)
    readonly property string indicatorPos: root.barConfig.dock.activeIndicatorPosition

    readonly property int dotSize: Math.round(Tokens.sizes.bar.innerWidth / 6)
    readonly property int dotGap: root.barConfig.dock.indicatorGap ?? 12   // gap between the dot and the icon
    readonly property int maxIcon: 32
    readonly property int effIcon: Math.max(16, Math.min(root.iconSize, root.maxIcon))
    readonly property bool horizontalIndicator: indicatorPos === "left" || indicatorPos === "right"

    implicitWidth: Tokens.sizes.bar.innerWidth
    implicitHeight: Tokens.sizes.bar.innerWidth

    // Focus this app's window; for a multi-window app, advance to the next window.
    function activate(): void {
        const ws = root.windows;
        if (ws.length === 0)
            return;
        let target;
        if (ws.length === 1) {
            target = ws[0];
        } else {
            const cur = ws.findIndex(w => w.address === root.activeAddress);
            target = ws[(cur + 1) % ws.length];
        }
        if (target)
            Hypr.focusWindow(target.address);
    }

    StateLayer {
        anchors.fill: parent
        radius: Tokens.rounding.normal
        onClicked: root.activate()
    }

    // Icon is anchored to the inner (content) side, away from the indicator. It only
    // depends on size/indicator side, so changing the gap never moves it. Positioned
    // with x/y so switching indicator sides doesn't leave stale anchors.
    ClippingRectangle {
        color: "transparent"
        radius: Tokens.rounding.full
        implicitWidth: root.effIcon
        implicitHeight: root.effIcon

        x: {
            if (root.indicatorPos === "left")
                return parent.width - root.effIcon;
            if (root.indicatorPos === "right")
                return 0;
            return (parent.width - root.effIcon) / 2;
        }
        y: {
            if (root.indicatorPos === "top")
                return parent.height - root.effIcon;
            if (root.indicatorPos === "bottom")
                return 0;
            return (parent.height - root.effIcon) / 2;
        }

        CachingIconImage {
            anchors.fill: parent
            implicitSize: parent.implicitHeight
            source: Icons.getAppIcon(root.appClass, "image-missing")
        }

        Behavior on x {
            Anim {}
        }

        Behavior on y {
            Anim {}
        }
    }

    // Every open app shows a dot; the focused app's dot is highlighted. Sits `dotGap`
    // from the icon's near edge, clamped to stay within the cell.
    StyledRect {
        id: dot

        implicitWidth: root.dotSize
        implicitHeight: root.dotSize
        radius: Tokens.rounding.full
        color: root.active ? Colours.palette.m3primary : Colours.palette.m3outlineVariant

        x: {
            if (root.indicatorPos === "left")
                return Math.max(0, parent.width - root.effIcon - root.dotGap - width);
            if (root.indicatorPos === "right")
                return Math.min(parent.width - width, root.effIcon + root.dotGap);
            return (parent.width - width) / 2;
        }
        y: {
            if (root.indicatorPos === "top")
                return Math.max(0, parent.height - root.effIcon - root.dotGap - height);
            if (root.indicatorPos === "bottom")
                return Math.min(parent.height - height, root.effIcon + root.dotGap);
            return (parent.height - height) / 2;
        }

        Behavior on color {
            CAnim {}
        }

        Behavior on x {
            Anim {}
        }

        Behavior on y {
            Anim {}
        }
    }
}
