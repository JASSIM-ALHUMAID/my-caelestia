import QtQuick
import Quickshell
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.services
import qs.utils

Item {
    id: root

    required property var modelData
    required property var list

    readonly property bool isFavourite: FavouriteApps.isFavourite(root.modelData.id)

    function onClicked(): void {
        FavouriteApps.toggleFavourite(root.modelData.id);
    }

    // Derived from the token rather than the box we sit in: the row grows to fit the icon
    // just below, so reading parent.height here would compound the scale on every pass.
    readonly property int iconSize: Math.round((Tokens.sizes.launcher.itemHeight - Tokens.padding.small * 2) * 0.8 * Tokens.sizes.launcher.iconScale)

    implicitHeight: Math.max(Tokens.sizes.launcher.itemHeight, iconSize + Tokens.padding.small * 2)

    anchors.left: parent?.left
    anchors.right: parent?.right

    StateLayer {
        radius: Tokens.rounding.large
        onClicked: {
            const appId = root.modelData.id;
            FavouriteApps.toggleFavourite(appId);
            Qt.callLater(() => {
                const newIdx = root.list.model.values.findIndex(
                    item => item.id === appId
                );
                if (newIdx >= 0)
                    root.list.currentIndex = newIdx;
            });
        }
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: Tokens.padding.medium
        anchors.rightMargin: Tokens.padding.medium
        anchors.margins: Tokens.padding.small

        IconImage {
            id: icon

            asynchronous: true
            source: Quickshell.iconPath(root.modelData?.icon, "image-missing")
            implicitSize: root.iconSize

            anchors.verticalCenter: parent.verticalCenter
        }

        Item {
            anchors.left: icon.right
            anchors.leftMargin: Tokens.spacing.medium
            anchors.verticalCenter: icon.verticalCenter

            implicitWidth: parent.width - icon.width - favouriteIcon.width
            implicitHeight: name.implicitHeight + desc.implicitHeight

            StyledText {
                id: name

                text: root.modelData?.name ?? ""
                font: Tokens.font.body.medium
            }

            StyledText {
                id: desc

                text: (root.modelData?.comment || root.modelData?.genericName || root.modelData?.name) ?? ""
                font: Tokens.font.body.small
                color: Colours.palette.m3outline

                elide: Text.ElideRight
                width: root.width - icon.width - favouriteIcon.width - Tokens.rounding.extraLargeIncreased

                anchors.top: name.bottom
            }
        }

        Loader {
            id: favouriteIcon

            asynchronous: true
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            active: root.modelData && FavouriteApps.isFavourite(root.modelData.id)

            sourceComponent: MaterialIcon {
                text: "favorite"
                fill: 1
                color: Colours.palette.m3primary
            }
        }
    }
}
