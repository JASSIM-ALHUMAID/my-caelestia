import QtQuick
import Quickshell
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.services
import qs.utils

// Icon-over-label tile counterpart to AppItem, used by AppGrid. Reuses the same launch/pin
// semantics — the two visuals differ, the behaviour doesn't.
Item {
    id: root

    required property DesktopEntry modelData
    required property DrawerVisibilities visibilities
    required property bool pinMode
    required property var list

    // Fill the cell the view actually laid out, which is the panel's width divided by the
    // configured column count — not the raw token, or the tiles would leave a ragged gap at
    // the end of every row whenever the panel is wider than columns * gridItemWidth.
    implicitWidth: GridView.view?.cellWidth ?? Tokens.sizes.launcher.gridItemWidth
    implicitHeight: GridView.view?.cellHeight ?? Tokens.sizes.launcher.gridItemHeight

    StateLayer {
        radius: Tokens.rounding.large
        onClicked: {
            if (root.pinMode) {
                const appId = root.modelData.id;
                FavouriteApps.toggleFavourite(appId);
                Qt.callLater(() => {
                    const newIdx = root.list.model.values.findIndex(
                        item => item.id === appId
                    );
                    if (newIdx >= 0)
                        root.list.currentIndex = newIdx;
                });
            } else {
                Apps.launch(root.modelData);
                root.visibilities.launcher = false;
            }
        }
    }

    Column {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -Tokens.padding.small
        spacing: Tokens.spacing.small
        width: root.width - Tokens.padding.medium * 2

        IconImage {
            id: icon

            anchors.horizontalCenter: parent.horizontalCenter

            asynchronous: true
            source: Quickshell.iconPath(root.modelData?.icon, "image-missing")
            // Token-based, not root.width * 0.4: the cell width now grows with iconScale
            // itself, so deriving from it would apply the scale twice.
            implicitSize: Math.round(Tokens.sizes.launcher.gridItemWidth * 0.4 * Tokens.sizes.launcher.iconScale)
        }

        StyledText {
            id: name

            anchors.horizontalCenter: parent.horizontalCenter

            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight

            text: root.modelData?.name ?? ""
            font: Tokens.font.body.small
        }
    }

    Loader {
        id: favouriteIcon

        asynchronous: true
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: Tokens.padding.extraSmall
        active: root.modelData && FavouriteApps.isFavourite(root.modelData.id)

        sourceComponent: MaterialIcon {
            text: "favorite"
            fill: 1
            color: Colours.palette.m3primary
        }
    }
}
