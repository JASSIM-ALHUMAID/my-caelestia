pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.services
import qs.utils

Item {
    id: root

    required property var bar
    required property var barConfig
    required property var toplevel
    property color colour: Colours.palette.m3primary
    // Vertical bars stack the icon over a rotated title; horizontal bars place the title
    // beside the icon as normal horizontal text.
    readonly property bool vertical: bar.vertical ?? true

    readonly property string windowTitle: {
        const title = root.toplevel?.title;
        if (!title)
            return qsTr("Desktop");
        if (root.barConfig.activeWindow.compact) {
            // " - " (standard hyphen), " — " (em dash), " – " (en dash)
            const parts = title.split(/\s+[\-–—]\s+/);
            if (parts.length > 1)
                return parts[parts.length - 1].trim();
        }
        return title;
    }

    // Space available for the title along the bar's main axis.
    readonly property int maxMain: {
        const otherModules = bar.children.filter(c => c.id && c.item !== this && c.id !== "spacer");
        const otherSize = otherModules.reduce((acc, curr) => acc + (root.vertical ? (curr.item.nonAnimHeight ?? curr.height) : (curr.item.nonAnimWidth ?? curr.width)), 0);
        const barMain = root.vertical ? bar.height : bar.width;
        // Length - 2 cause repeater counts as a child
        return barMain - otherSize - bar.spacing * (bar.children.length - 1) - bar.vPadding * 2;
    }
    property Title current: text1

    clip: true
    implicitWidth: root.vertical ? Math.max(icon.implicitWidth, current.implicitHeight) : icon.implicitWidth + current.implicitWidth + current.anchors.leftMargin
    implicitHeight: root.vertical ? icon.implicitHeight + current.implicitWidth + current.anchors.topMargin : Math.max(icon.implicitHeight, current.implicitHeight)

    Loader {
        asynchronous: true
        anchors.fill: parent
        active: !root.barConfig.activeWindow.showOnHover

        sourceComponent: MouseArea {
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onPositionChanged: {
                const popouts = root.bar.popouts;
                if (popouts.hasCurrent && popouts.currentName !== "activewindow")
                    popouts.hasCurrent = false;
            }
            onClicked: {
                const popouts = root.bar.popouts;
                if (popouts.hasCurrent) {
                    popouts.hasCurrent = false;
                } else {
                    popouts.activeWindowToplevel = Qt.binding(() => root.toplevel);
                    popouts.currentName = "activewindow";
                    popouts.currentCenter = root.vertical ? root.mapToItem(root.bar, 0, root.implicitHeight / 2).y : root.mapToItem(root.bar, root.implicitWidth / 2, 0).x;
                    popouts.hasCurrent = true;
                }
            }
        }
    }

    MaterialIcon {
        id: icon

        anchors.horizontalCenter: root.vertical ? parent.horizontalCenter : undefined
        anchors.verticalCenter: root.vertical ? undefined : parent.verticalCenter
        anchors.left: root.vertical ? undefined : parent.left

        animate: true
        text: Icons.getAppCategoryIcon(root.toplevel?.lastIpcObject.class, "desktop_windows")
        color: root.colour
    }

    Title {
        id: text1
    }

    Title {
        id: text2
    }

    TextMetrics {
        id: metrics

        text: root.windowTitle
        font: root.Tokens.font.body.builders.small.letterSpacing(1.4).build()
        elide: Qt.ElideRight
        elideWidth: root.maxMain - (root.vertical ? icon.height : icon.width)

        onTextChanged: {
            const next = root.current === text1 ? text2 : text1;
            next.text = elidedText;
            root.current = next;
        }
        onElideWidthChanged: root.current.text = elidedText
    }

    Behavior on implicitHeight {
        Anim {}
    }

    Behavior on implicitWidth {
        Anim {
            type: Anim.DefaultSpatial
        }
    }

    component Title: StyledText {
        id: text

        // Vertical: below the icon, rotated to read along the bar. Horizontal: right of the
        // icon as normal text.
        anchors.horizontalCenter: root.vertical ? icon.horizontalCenter : undefined
        anchors.top: root.vertical ? icon.bottom : undefined
        anchors.topMargin: root.vertical ? Tokens.spacing.small : 0
        anchors.verticalCenter: root.vertical ? undefined : icon.verticalCenter
        anchors.left: root.vertical ? undefined : icon.right
        anchors.leftMargin: root.vertical ? 0 : Tokens.spacing.small

        font: metrics.font
        color: root.colour
        opacity: root.current === this ? 1 : 0

        transform: root.vertical ? [verticalShift, verticalRotation] : []

        readonly property Translate verticalShift: Translate {
            x: root.barConfig.activeWindow.inverted ? -text.implicitWidth + text.implicitHeight : 0
        }

        readonly property Rotation verticalRotation: Rotation {
            angle: root.barConfig.activeWindow.inverted ? 270 : 90
            origin.x: text.implicitHeight / 2
            origin.y: text.implicitHeight / 2
        }

        // When rotated the bounding box is swapped; horizontal uses the natural size.
        width: root.vertical ? implicitHeight : implicitWidth
        height: root.vertical ? implicitWidth : implicitHeight

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }
}
