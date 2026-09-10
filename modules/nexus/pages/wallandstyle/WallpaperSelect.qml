pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Components
import Caelestia.Config
import Caelestia.Models
import qs.components
import qs.components.controls
import qs.components.filedialog
import qs.services
import qs.utils
import qs.modules.nexus.common

PageBase {
    id: root

    // Relative path of the folder holding the applied wallpaper, "" when it is a root-level
    // file or lives outside every wallpaper dir. Stays a binding: if the rotation timer swaps
    // the wallpaper while this page is open, the matching folder opens itself.
    readonly property string autoExpandFolder: {
        if (!Wallpapers.actualCurrent)
            return "";
        for (const folder of Wallpapers.groups.folders)
            if (folder.entries.some(w => Wallpapers.isCurrent(w)))
                return folder.title;
        return "";
    }

    property Item pendingScrollItem

    // Called by the highlighted tile once it exists. The delay lets the section's expand
    // animation and the grid's layout settle, so mapToItem reports the final position.
    function requestScrollTo(item: Item): void {
        pendingScrollItem = item;
        scrollTimer.restart();
    }

    // Scrolls so `y` (a position in the flickable's content item) sits roughly centred.
    function scrollToContentY(y: real, itemHeight: real): void {
        const f = root.flickable;
        if (!f)
            return;
        const target = y - (f.height - itemHeight) / 2;
        f.contentY = Math.max(0, Math.min(target, Math.max(0, f.contentHeight - f.height)));
    }

    title: qsTr("Wallpapers")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.small

        Timer {
            id: scrollTimer

            interval: 400
            onTriggered: {
                const item = root.pendingScrollItem;
                root.pendingScrollItem = null;
                const f = root.flickable;
                if (!item || !f)
                    return;
                root.scrollToContentY(item.mapToItem(f.contentItem, 0, 0).y, item.height);
            }
        }

        ButtonRow {
            Layout.bottomMargin: Tokens.spacing.medium
            Layout.alignment: Qt.AlignHCenter
            spacing: Tokens.spacing.small

            IconTextButton {
                icon: "photo_library"
                text: qsTr("Browse")
                font: Tokens.font.body.large
                isRound: true
                shapeMorph: true
                horizontalPadding: Tokens.padding.extraLarge
                verticalPadding: Tokens.padding.medium
                onClicked: browseDialog.open()

                FileDialog {
                    id: browseDialog

                    title: qsTr("Select a wallpaper")
                    filterLabel: qsTr("Image/video files")
                    filters: Images.validWallpaperExtensions
                    onAccepted: path => {
                        Wallpapers.setWallpaper(path);
                        root.nState.closeSubPage();
                    }
                }
            }

            IconTextButton {
                icon: "shuffle"
                text: qsTr("Random")
                font: Tokens.font.body.large
                isRound: true
                shapeMorph: true
                horizontalPadding: Tokens.padding.extraLarge
                verticalPadding: Tokens.padding.medium
                type: IconTextButton.Tonal
                onClicked: {
                    Wallpapers.setRandom();
                    root.nState.closeSubPage();
                }
            }
        }

        WallItem {
            imgHeight: Math.round(width * 0.3)
            radius: Tokens.rounding.extraLarge
            source: Quickshell.shellPath("assets/wallpaper.webp")
            text: qsTr("Featured wallpaper")
            fillLabel: false
            onClicked: {
                Wallpapers.setWallpaper(Quickshell.shellPath("assets/wallpaper.webp"));
                root.nState.closeSubPage();
            }
        }

        StyledText {
            Layout.topMargin: Tokens.spacing.large
            text: qsTr("Local wallpapers")
            font: Tokens.font.title.small
        }

        GridLayout {
            Layout.fillWidth: true
            visible: Wallpapers.groups.roots.length > 0

            columns: Config.nexus.wallpapersPerRow
            rowSpacing: Tokens.spacing.medium
            columnSpacing: Tokens.spacing.large

            Repeater {
                model: {
                    const list = Wallpapers.groups.roots.slice();
                    while (list.length < Config.nexus.wallpapersPerRow)
                        list.push(null);
                    return list;
                }

                WallItem {
                    required property FileSystemEntry modelData

                    // Empty placeholders for sizing
                    opacity: modelData ? 1 : 0
                    enabled: modelData

                    source: String(modelData?.path ?? "")
                    text: modelData?.name ?? ""
                    highlighted: Wallpapers.isCurrent(modelData)
                    onClicked: {
                        Wallpapers.setWallpaper(modelData.path);
                        root.nState.closeSubPage();
                    }

                    Component.onCompleted: {
                        if (highlighted)
                            root.requestScrollTo(this);
                    }
                }
            }
        }

        Repeater {
            model: Wallpapers.groups.folders

            CollapsibleSection {
                id: section

                required property var modelData

                // Index of the applied wallpaper within this folder, -1 when it is elsewhere
                readonly property int targetIndex: modelData.entries.findIndex(w => Wallpapers.isCurrent(w))

                // Latches on first expand so collapsing a folder does not tear its tiles down
                property bool loadedOnce: false

                Layout.fillWidth: true
                Layout.topMargin: Tokens.spacing.small

                title: modelData.title
                description: qsTr("%1 wallpapers").arg(modelData.entries.length)
                showBackground: true
                expanded: modelData.title === root.autoExpandFolder

                onExpandedChanged: {
                    if (expanded)
                        loadedOnce = true;
                }

                // The auto-expanded section may already be expanded by the time the change
                // handler is connected, so cover that case explicitly.
                Component.onCompleted: {
                    if (expanded)
                        loadedOnce = true;
                }

                Loader {
                    id: gridLoader

                    Layout.fillWidth: true

                    active: section.loadedOnce
                    visible: active

                    // Only rows near the viewport are built, but the grid still reserves its
                    // full height, so scrollbar and scroll-to-target maths stay exact.
                    // Instantiating every tile froze the UI for ~1.7s per batch.
                    sourceComponent: Item {
                        id: grid

                        readonly property int perRow: Math.max(1, Config.nexus.wallpapersPerRow)
                        readonly property real colSpacing: Tokens.spacing.large
                        readonly property real cellWidth: (width - colSpacing * (perRow - 1)) / perRow
                        readonly property real rowStride: ruler.implicitHeight + Tokens.spacing.medium
                        readonly property int rowCount: Math.ceil(section.modelData.entries.length / perRow)

                        // Top of the viewport in this grid's own coordinates
                        readonly property real viewTop: {
                            const f = root.flickable;
                            if (!f)
                                return 0;
                            f.contentY; // establishes the dependency -- mapToItem is not reactive
                            f.contentHeight;
                            return f.contentY - grid.mapToItem(f.contentItem, 0, 0).y;
                        }
                        readonly property real viewHeight: root.flickable?.height ?? 0

                        // First and last row are derived in one binding on purpose: as two
                        // separate bindings the intermediate state spans the union of the old
                        // and new window, which built hundreds of tiles on every scroll jump.
                        readonly property var rowIndices: {
                            if (rowStride <= 0 || rowCount <= 0)
                                return [];
                            const first = Math.max(0, Math.floor(viewTop / rowStride) - 2);
                            const last = Math.min(rowCount - 1, Math.ceil((viewTop + viewHeight) / rowStride) + 2);
                            const out = [];
                            for (let r = first; r <= last; r++)
                                out.push(r);
                            return out;
                        }

                        implicitHeight: rowCount > 0 ? rowCount * rowStride - Tokens.spacing.medium : 0


                        // Never shown -- gives the exact height of a real tile so unbuilt rows
                        // still occupy the right amount of space.
                        WallItem {
                            id: ruler

                            width: grid.cellWidth
                            visible: false
                            enabled: false
                            text: "Ag"
                        }

                        Repeater {
                            model: grid.rowIndices

                            Row {
                                id: rowItem

                                required property int modelData

                                y: modelData * grid.rowStride
                                width: grid.width
                                spacing: grid.colSpacing

                                Repeater {
                                    model: section.modelData.entries.slice(rowItem.modelData * grid.perRow, rowItem.modelData * grid.perRow + grid.perRow)

                                    WallItem {
                                        required property FileSystemEntry modelData

                                        width: grid.cellWidth
                                        height: ruler.implicitHeight

                                        source: String(modelData?.path ?? "")
                                        text: modelData?.name ?? ""
                                        highlighted: Wallpapers.isCurrent(modelData)
                                        onClicked: {
                                            Wallpapers.setWallpaper(modelData.path);
                                            root.nState.closeSubPage();
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Brings the applied wallpaper into view once the expand animation settles. The
                // row position is arithmetic, so this does not require the tile to exist yet.
                Timer {
                    running: section.expanded && section.targetIndex >= 0
                    interval: 450
                    onTriggered: {
                        const g = gridLoader.item;
                        const f = root.flickable;
                        if (!g || !f)
                            return;
                        const row = Math.floor(section.targetIndex / g.perRow);
                        root.scrollToContentY(g.mapToItem(f.contentItem, 0, row * g.rowStride).y, g.rowStride);
                    }
                }
            }
        }

        Loader {
            Layout.fillWidth: true

            asynchronous: true
            active: Wallpapers.groups.roots.length === 0 && Wallpapers.groups.folders.length === 0
            visible: active

            sourceComponent: StyledRect {
                color: Colours.tPalette.m3surfaceContainer
                radius: Tokens.rounding.extraLarge
                implicitHeight: noWallsLayout.implicitHeight + Tokens.padding.extraExtraLarge * 2

                ColumnLayout {
                    id: noWallsLayout

                    anchors.centerIn: parent
                    spacing: Tokens.spacing.extraSmall

                    MaterialIcon {
                        Layout.alignment: Qt.AlignHCenter
                        text: "hide_image"
                        color: Colours.palette.m3outline
                        fontStyle: Tokens.font.icon.extraLarge
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("No local wallpapers found")
                        color: Colours.palette.m3outline
                        font: Tokens.font.title.small
                    }
                }
            }
        }
    }
}
