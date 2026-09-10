pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.launcher.items
import qs.modules.launcher.services

// Tiled counterpart to AppList, used only for the "apps" and "pin" listStates when
// Config.launcher.appLayout is "grid" (see ContentList's useGrid). No StyledGridView exists
// in the repo — components/filedialog/FolderContents.qml is the in-repo GridView precedent.
GridView {
    id: root

    required property StyledTextField search
    required property DrawerVisibilities visibilities
    required property string listState

    readonly property int columns: Config.launcher.gridColumns

    // Tiles grow by exactly how much the scaled icon overflows the default one, which keeps
    // the label, spacing and padding geometry the tile was designed around intact.
    readonly property int baseIcon: Math.round(Tokens.sizes.launcher.gridItemWidth * 0.4)
    readonly property int iconGrowth: Math.max(0, Math.round(baseIcon * Tokens.sizes.launcher.iconScale) - baseIcon)
    readonly property int tileWidth: Tokens.sizes.launcher.gridItemWidth + iconGrowth
    readonly property int tileHeight: Tokens.sizes.launcher.gridItemHeight + iconGrowth

    model: ScriptModel {
        id: model

        values: root.listState === "pin" ? Apps.search(root.search.text.slice(GlobalConfig.launcher.actionPrefix.length + 4)) : Apps.search(root.search.text)

        onValuesChanged: root.currentIndex = 0
    }

    // Divide the actual width rather than using the token directly: ContentList stretches this
    // view to the panel with an AnchorChanges (see its "apps" state), so a fixed cell width
    // would let the panel's real width decide the column count and quietly ignore the setting.
    // The token is the per-tile width the panel *asks* for, via implicitWidth below.
    cellWidth: columns > 0 ? width / columns : tileWidth
    cellHeight: tileHeight
    // Config.launcher.maxShown is reinterpreted here as a cap on visible *items* rather than
    // rows, so the one setting stays meaningful in both the list and grid layouts.
    implicitWidth: tileWidth * columns
    implicitHeight: cellHeight * Math.ceil(Math.min(Config.launcher.maxShown, count) / columns)

    clip: true

    // Keyboard nav moves currentIndex without the view following it (highlightFollowsCurrentItem
    // is off so the highlight rect can animate itself), so the range is what actually scrolls a
    // selection back into view once it leaves the visible rows — same as AppList.
    preferredHighlightBegin: 0
    preferredHighlightEnd: height
    highlightRangeMode: GridView.ApplyRange

    highlightFollowsCurrentItem: false
    highlight: StyledRect {
        radius: Tokens.rounding.large
        color: Colours.palette.m3onSurface
        opacity: 0.08

        x: root.currentItem?.x ?? 0
        y: root.currentItem?.y ?? 0
        implicitWidth: root.cellWidth
        implicitHeight: root.cellHeight

        Behavior on x {
            Anim {}
        }

        Behavior on y {
            Anim {}
        }
    }

    delegate: AppGridItem {
        visibilities: root.visibilities
        pinMode: root.listState === "pin"
        list: root
    }

    // Left/Right move one tile; Up/Down (mapped to these by Content.qml) move one whole row.
    // Clamped rather than wrapped, so the last partial row can't land past `count`.
    function incrementCurrentIndex(): void {
        currentIndex = Math.min(currentIndex + columns, count - 1);
    }

    function decrementCurrentIndex(): void {
        currentIndex = Math.max(currentIndex - columns, 0);
    }

    function incrementCurrentIndexHorizontal(): void {
        currentIndex = Math.min(currentIndex + 1, count - 1);
    }

    function decrementCurrentIndexHorizontal(): void {
        currentIndex = Math.max(currentIndex - 1, 0);
    }

    StyledScrollBar.vertical: StyledScrollBar {
        flickable: root
    }
}
