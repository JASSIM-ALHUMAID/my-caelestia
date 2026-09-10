pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.components.images
import qs.services
import qs.utils

// A single window indicator in the workspaces list: either a Material category
// glyph (default) or the real app icon with rounded corners (when appIcons is on).
Item {
    id: root

    required property var barConfig
    required property var toplevel
    readonly property string appClass: toplevel?.lastIpcObject.class ?? ""

    implicitWidth: categoryIcon.implicitWidth
    implicitHeight: categoryIcon.implicitHeight

    // Material category icon (default); also the size reference for the app icon
    MaterialIcon {
        id: categoryIcon

        visible: !root.barConfig.workspaces.appIcons
        grade: 0
        text: Icons.getAppCategoryIcon(root.appClass, "terminal")
        color: Colours.palette.m3onSurfaceVariant
    }

    // Real app icon with rounded corners, matched to the category icon's height
    ClippingRectangle {
        visible: root.barConfig.workspaces.appIcons
        anchors.centerIn: parent

        color: "transparent"
        radius: Tokens.rounding.medium
        implicitWidth: categoryIcon.implicitHeight
        implicitHeight: categoryIcon.implicitHeight

        CachingIconImage {
            anchors.fill: parent
            implicitSize: parent.implicitHeight
            source: Icons.getAppIcon(root.appClass, "image-missing")
        }
    }
}
