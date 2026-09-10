pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Caelestia.Config
import qs.components
import qs.services

StyledRect {
    id: root

    required property bool vertical
    required property var barConfig

    readonly property alias layout: layout
    readonly property alias items: items
    readonly property alias expandIcon: expandIcon

    readonly property int padding: root.barConfig.tray.background ? Tokens.padding.medium : Tokens.padding.extraSmall
    readonly property int spacing: root.barConfig.tray.background ? Tokens.spacing.small : 0

    property bool expanded

    // --- Overflow budget -------------------------------------------------------------
    // Derived from the tray model and tokens only, never from our laid-out geometry, so the
    // bar's overflow budget can read it without its own cap feeding back. Slicing keeps the
    // list's prefix so surviving indices still line up with the `traymenu<i>` popouts
    // registered in popouts/Content.qml.

    // Max icons to show; -1 means unlimited (no cap in effect)
    property int itemLimit: -1
    readonly property var trayItems: SystemTray.items.values.filter(i => !GlobalConfig.bar.trayHiddenIcons.includes(i.id))
    readonly property var shownItems: root.itemLimit >= 0 ? root.trayItems.slice(0, root.itemLimit) : root.trayItems
    readonly property int hiddenCount: root.trayItems.length - root.shownItems.length

    readonly property real itemSize: Tokens.font.body.small.pointSize * 2
    // Main-axis cost of one icon; zero while collapsed, where the stack isn't laid out
    readonly property bool stackShown: root.expanded || !root.barConfig.tray.compact
    readonly property real itemUnit: root.stackShown ? root.itemSize + Tokens.spacing.small : 0

    // Main-axis size this entry would take with no icon limit applied
    readonly property real intrinsicMain: {
        const n = root.trayItems.length;
        const stack = n > 0 ? n * root.itemSize + Tokens.spacing.small * (n - 1) : 0;
        if (!root.barConfig.tray.compact)
            return stack + root.padding * 2;
        return (root.expanded ? root.expandMain + stack + root.spacing : root.expandMain) + root.padding * 2;
    }

    // Main-axis (length) extents of the stack and the expand affordance
    readonly property real layoutMain: vertical ? layout.implicitHeight : layout.implicitWidth
    readonly property real expandMain: vertical ? expandIcon.implicitHeight : expandIcon.implicitWidth

    readonly property real nonAnimMain: {
        if (!root.barConfig.tray.compact)
            return layoutMain + padding * 2;
        return (expanded ? expandMain + layoutMain + spacing : expandMain) + padding * 2;
    }
    // Back-compat alias: ActiveWindow reads `nonAnimHeight` off sibling entries
    readonly property real nonAnimHeight: nonAnimMain

    clip: true
    visible: (vertical ? height : width) > 0

    implicitWidth: vertical ? Tokens.sizes.bar.innerWidth : nonAnimMain
    implicitHeight: vertical ? nonAnimMain : Tokens.sizes.bar.innerWidth

    color: Qt.alpha(Colours.tPalette.m3surfaceContainer, (root.barConfig.tray.background && root.trayItems.length > 0) ? Colours.tPalette.m3surfaceContainer.a : 0)
    radius: Tokens.rounding.full

    Grid {
        id: layout

        // Single column when vertical, single row when horizontal
        columns: root.vertical ? 1 : -1
        rows: root.vertical ? -1 : 1
        flow: root.vertical ? Grid.LeftToRight : Grid.TopToBottom

        anchors.horizontalCenter: root.vertical ? parent.horizontalCenter : undefined
        anchors.verticalCenter: root.vertical ? undefined : parent.verticalCenter
        anchors.top: root.vertical ? parent.top : undefined
        anchors.left: root.vertical ? undefined : parent.left
        anchors.topMargin: root.vertical ? root.padding : 0
        anchors.leftMargin: root.vertical ? 0 : root.padding
        spacing: Tokens.spacing.small

        opacity: root.expanded || !root.barConfig.tray.compact ? 1 : 0

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
                values: root.shownItems
            }

            TrayItem {
                barConfig: root.barConfig
            }
        }

        // "+N" chip for the icons the overflow cap dropped
        StyledText {
            visible: root.hiddenCount > 0 && root.barConfig.overflow.showCount
            text: `+${root.hiddenCount}`
            color: Colours.palette.m3outline
            font.pointSize: Tokens.font.body.small.pointSize
            width: root.vertical ? root.itemSize : implicitWidth
            height: root.vertical ? implicitHeight : root.itemSize
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    Loader {
        id: expandIcon

        asynchronous: true

        anchors.horizontalCenter: root.vertical ? parent.horizontalCenter : undefined
        anchors.verticalCenter: root.vertical ? undefined : parent.verticalCenter
        anchors.bottom: root.vertical ? parent.bottom : undefined
        anchors.right: root.vertical ? undefined : parent.right

        active: root.barConfig.tray.compact && root.trayItems.length > 0

        // The shave and the inner icon's offset both run along the bar's main axis: the
        // chevron sits at the far end of the stack, pointing back toward it.
        sourceComponent: Item {
            readonly property int margin: root.barConfig.tray.background ? Tokens.padding.extraSmall : -Tokens.padding.extraSmall

            implicitWidth: root.vertical ? expandIconInner.implicitWidth : expandIconInner.implicitWidth - Tokens.padding.small
            implicitHeight: root.vertical ? expandIconInner.implicitHeight - Tokens.padding.small : expandIconInner.implicitHeight

            MaterialIcon {
                id: expandIconInner

                anchors.horizontalCenter: root.vertical ? parent.horizontalCenter : undefined
                anchors.verticalCenter: root.vertical ? undefined : parent.verticalCenter
                anchors.bottom: root.vertical ? parent.bottom : undefined
                anchors.right: root.vertical ? undefined : parent.right
                anchors.bottomMargin: root.vertical ? parent.margin : 0
                anchors.rightMargin: root.vertical ? 0 : parent.margin
                text: "expand_less"
                fontStyle: Tokens.font.icon.large
                // "expand_less" points up; rotate it to point back along the main axis.
                rotation: root.vertical ? (root.expanded ? 180 : 0) : (root.expanded ? 90 : -90)

                Behavior on rotation {
                    Anim {}
                }

                Behavior on anchors.bottomMargin {
                    Anim {}
                }

                Behavior on anchors.rightMargin {
                    Anim {}
                }
            }
        }
    }

    // Only the main-axis dimension actually changes; the cross-axis Behavior is a no-op.
    Behavior on implicitHeight {
        Anim {}
    }

    Behavior on implicitWidth {
        Anim {
            type: Anim.DefaultSpatial
        }
    }
}
