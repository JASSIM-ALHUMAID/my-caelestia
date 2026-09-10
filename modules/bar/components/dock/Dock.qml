pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.services

// A dock of the apps open on the active workspace (per-monitor aware). Windows are
// grouped per app class; clicking focuses/cycles an app's windows and an active dot
// marks the app owning the focused window. Hovering an icon opens the active-window
// popout for that app (handled by Bar.qml checkPopout).
Item {
    id: root

    required property ShellScreen screen
    required property bool vertical
    required property var barConfig
    required property int workspaceId
    required property var activeToplevel

    readonly property alias layout: layout
    readonly property alias items: items

    readonly property string activeAddress: root.activeToplevel?.address ?? ""
    readonly property int iconSize: Math.min(root.barConfig.dock.iconSize ?? 30, Tokens.sizes.bar.innerWidth)

    // --- Overflow budget -------------------------------------------------------------
    // Derived from the window model and tokens only, never from our laid-out geometry, so
    // the bar's overflow budget can read it without its own cap feeding back.

    // Max app icons to show; -1 means unlimited (no cap in effect)
    property int itemLimit: -1
    readonly property var groups: root.itemLimit >= 0 ? root.allGroups.slice(0, root.itemLimit) : root.allGroups
    readonly property int hiddenCount: root.allGroups.length - root.groups.length

    // A DockApp is innerWidth square regardless of the icon it draws
    readonly property real itemUnit: Tokens.sizes.bar.innerWidth + Tokens.spacing.small
    readonly property real intrinsicMain: {
        const n = root.allGroups.length;
        return n > 0 ? n * Tokens.sizes.bar.innerWidth + Tokens.spacing.small * (n - 1) : 0;
    }

    // One entry per app class on the active workspace, preserving first-seen order.
    readonly property var allGroups: {
        const wins = Hypr.toplevels.values.filter(t => t.workspace?.id === root.workspaceId);
        const byClass = ({});
        const order = [];
        for (const w of wins) {
            const cls = w.lastIpcObject?.class ?? "";
            if (!byClass[cls]) {
                byClass[cls] = [];
                order.push(cls);
            }
            byClass[cls].push(w);
        }
        return order.map(cls => ({
            appClass: cls,
            windows: byClass[cls]
        }));
    }

    implicitWidth: vertical ? Tokens.sizes.bar.innerWidth : layout.implicitWidth
    implicitHeight: vertical ? layout.implicitHeight : Tokens.sizes.bar.innerWidth
    visible: items.count > 0

    Grid {
        id: layout

        anchors.centerIn: parent

        columns: root.vertical ? 1 : -1
        rows: root.vertical ? -1 : 1
        flow: root.vertical ? Grid.LeftToRight : Grid.TopToBottom
        spacing: Tokens.spacing.small

        add: Transition {
            Anim {
                properties: "scale"
                from: 0
                to: 1
                easing: Tokens.anim.standardDecel
            }
        }

        move: Transition {
            Anim {
                properties: "scale"
                to: 1
                easing: Tokens.anim.standardDecel
            }
            Anim {
                properties: "x,y"
            }
        }

        Repeater {
            id: items

            model: ScriptModel {
                values: root.groups
            }

            DockApp {
                screen: root.screen
                iconSize: root.iconSize
                activeAddress: root.activeAddress
                barConfig: root.barConfig
            }
        }

        // "+N" chip for the apps the overflow cap dropped
        StyledText {
            visible: root.hiddenCount > 0 && root.barConfig.overflow.showCount
            text: `+${root.hiddenCount}`
            color: Colours.palette.m3outline
            font.pointSize: Tokens.font.body.small.pointSize
            width: root.vertical ? Tokens.sizes.bar.innerWidth : implicitWidth
            height: root.vertical ? implicitHeight : Tokens.sizes.bar.innerWidth
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }
}
