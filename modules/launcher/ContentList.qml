pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils

Item {
    id: root

    required property var content
    required property DrawerVisibilities visibilities
    required property var panels
    required property real maxHeight
    required property StyledTextField search
    required property int padding
    required property int rounding

    // Single source of truth for which results view search.text selects — previously computed
    // independently here (just the wallpaper prefix) and again in AppList (every other
    // prefix), which could disagree. AppList takes this as `listState` and uses it verbatim
    // as its own `state:`.
    readonly property string listState: {
        const text = search.text;
        const prefix = GlobalConfig.launcher.actionPrefix;
        if (text.startsWith(prefix)) {
            if (GlobalConfig.launcher.enableDangerousActions && text.startsWith(`${prefix}run `))
                return "run";
            if (text.startsWith(`${prefix}wallpaper `))
                return "wallpapers";

            for (const action of ["calc", "timer", "scheme", "variant", "emoji", "clip", "pin"])
                if (text.startsWith(`${prefix}${action} `))
                    return action === "clip" ? "clipboard" : action;

            return "actions";
        }

        return "apps";
    }
    readonly property bool showWallpapers: listState === "wallpapers"
    // Grid layout only applies to the app and pin lists; everything else (actions, calc,
    // emoji, etc.) stays on the row-based AppList regardless of Config.launcher.appLayout.
    readonly property bool useGrid: Config.launcher.appLayout === "grid" && (listState === "apps" || listState === "pin")
    readonly property var currentList: showWallpapers ? wallpaperList.item : (useGrid ? gridList.item : appList.item) // Can be ListView, GridView or PathView, so can't type properly
    readonly property real contentImplicitHeight: useGrid ? gridList.implicitHeight : appList.implicitHeight
    // Same growth AppGrid applies to its tiles. Duplicated rather than read off gridList
    // because this is consumed inside a PropertyChanges, where the loader may be inactive.
    readonly property int gridTileWidth: {
        const base = Math.round(Tokens.sizes.launcher.gridItemWidth * 0.4);
        return Tokens.sizes.launcher.gridItemWidth + Math.max(0, Math.round(base * Tokens.sizes.launcher.iconScale) - base);
    }
    // Resolved here rather than inside the PropertyChanges below: the Config attached property
    // needs a screen, and inside a State it resolves against the QQuickState instead of a
    // visual item, so it reads back undefined (same reason Tokens is reached via `root.` there).
    readonly property real appsWidth: useGrid ? Config.launcher.gridColumns * gridTileWidth : Tokens.sizes.launcher.itemWidth
    property string animState: showWallpapers ? "wallpapers" : "apps"

    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom

    clip: true
    state: animState

    states: [
        State {
            name: "apps"

            PropertyChanges {
                root.implicitWidth: root.appsWidth
                root.implicitHeight: Math.min(root.maxHeight, root.contentImplicitHeight > 0 ? root.contentImplicitHeight : empty.implicitHeight)
                appList.active: !root.useGrid
                gridList.active: root.useGrid
            }

            AnchorChanges {
                anchors.left: root.parent.left
                anchors.right: root.parent.right
            }
        },
        State {
            name: "wallpapers"

            PropertyChanges {
                root.implicitWidth: Math.max(root.Tokens.sizes.launcher.itemWidth * 1.2, wallpaperList.implicitWidth)
                root.implicitHeight: root.Tokens.sizes.launcher.wallpaperHeight
                wallpaperList.active: true
            }
        }
    ]

    Behavior on animState {
        SequentialAnimation {
            Anim {
                target: root
                property: "opacity"
                from: 1
                to: 0
                type: Anim.DefaultEffects
            }
            PropertyAction {}
            Anim {
                target: root
                property: "opacity"
                from: 0
                to: 1
                type: Anim.DefaultEffects
            }
        }
    }

    Loader {
        id: appList

        active: false

        anchors.fill: parent

        sourceComponent: AppList {
            search: root.search
            visibilities: root.visibilities
            listState: root.listState
        }
    }

    Loader {
        id: gridList

        active: false

        anchors.fill: parent

        sourceComponent: AppGrid {
            search: root.search
            visibilities: root.visibilities
            listState: root.listState
        }
    }

    Loader {
        id: wallpaperList

        asynchronous: true
        active: false

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter

        sourceComponent: WallpaperList {
            search: root.search
            visibilities: root.visibilities
            panels: root.panels
            content: root.content
        }
    }

    Row {
        id: empty

        opacity: root.currentList?.count === 0 ? 1 : 0
        scale: root.currentList?.count === 0 ? 1 : 0.5

        spacing: Tokens.spacing.medium
        padding: Tokens.padding.large

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter

        MaterialIcon {
            text: root.state === "wallpapers" ? "wallpaper_slideshow" : "manage_search"
            color: Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.extraLarge

            anchors.verticalCenter: parent.verticalCenter
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter

            StyledText {
                text: root.state === "wallpapers" ? qsTr("No wallpapers found") : qsTr("No results")
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.builders.large.weight(Font.Medium).build()
            }

            StyledText {
                text: root.state === "wallpapers" && Wallpapers.list.length === 0 ? qsTr("Try putting some wallpapers in %1").arg(Paths.shortenHome(Wallpapers.wallpaperDirs[0] ?? "~/Pictures/Wallpapers")) : qsTr("Try searching for something else")
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.medium
            }
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        Behavior on scale {
            Anim {}
        }
    }

    Behavior on implicitWidth {
        enabled: root.visibilities.launcher

        Anim {}
    }

    Behavior on implicitHeight {
        enabled: root.visibilities.launcher

        Anim {}
    }
}
