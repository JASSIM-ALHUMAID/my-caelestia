pragma ComponentBehavior: Bound

import QtQuick
import Caelestia
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils
import qs.modules.launcher.services

Item {
    id: root

    required property DrawerVisibilities visibilities
    required property var panels
    required property real maxHeight
    required property string initialText
    required property bool pinMode
    required property bool floating

    readonly property int padding: Tokens.padding.large
    readonly property int rounding: Tokens.rounding.extraLarge
    // Whether the current results view has a working horizontal nav pair — true for the app
    // grid and for the emoji picker's PathView (AppList's own horizontal pair is a no-op
    // everywhere else, per AppList.incrementCurrentIndexHorizontal).
    readonly property bool horizontalNav: list.useGrid || search.text.startsWith(`${GlobalConfig.launcher.actionPrefix}emoji `)

    implicitWidth: listWrapper.width + padding * 2
    implicitHeight: searchWrapper.height + listWrapper.height + padding + searchWrapper.anchors.bottomMargin

    Item {
        id: listWrapper

        implicitWidth: list.width
        implicitHeight: list.height + root.padding

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: searchWrapper.top
        anchors.bottomMargin: root.padding

        ContentList {
            id: list

            content: root
            visibilities: root.visibilities
            panels: root.panels
            maxHeight: root.maxHeight - searchWrapper.implicitHeight - root.padding * 3
            search: search
            padding: root.padding
            rounding: root.rounding
        }
    }

    StyledRect {
        id: searchWrapper

        color: Colours.layer(Colours.palette.m3surfaceContainer, 2)
        radius: Tokens.rounding.full

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: root.padding
        // Only docked launchers sit flush to the screen edge; a floating one keeps the
        // plain padding on every side.
        anchors.bottomMargin: root.floating ? root.padding : CUtils.clamp(root.padding - Config.border.thickness, 0, root.padding)

        implicitHeight: Math.max(searchIcon.implicitHeight, search.implicitHeight, clearIcon.implicitHeight)

        MaterialIcon {
            id: searchIcon

            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: root.padding

            text: root.pinMode ? "bookmark" : "search"
            color: Colours.palette.m3onSurfaceVariant
        }

        StyledTextField {
            id: search

            text: root.initialText

            anchors.left: searchIcon.right
            anchors.right: clearIcon.left
            anchors.leftMargin: Tokens.spacing.small
            anchors.rightMargin: Tokens.spacing.small

            topPadding: Tokens.padding.medium
            bottomPadding: Tokens.padding.medium

            placeholderText: root.pinMode ? qsTr("Pin an app to the dock") : qsTr("Type \"%1\" for commands").arg(GlobalConfig.launcher.actionPrefix)

            onAccepted: {
                const currentItem = list.currentList?.currentItem;
                if (currentItem) {
                    if (root.pinMode) {
                        const appId = currentItem.modelData.id;
                        FavouriteApps.toggleFavourite(appId);
                        Qt.callLater(() => {
                            const newIdx = list.currentList.model.values.findIndex(
                                item => item.id === appId
                            );
                            if (newIdx >= 0)
                                list.currentList.currentIndex = newIdx;
                        });
                    } else if (list.showWallpapers) {
                        if (Colours.scheme === "dynamic" && currentItem.modelData.path !== Wallpapers.actualCurrent)
                            Wallpapers.previewColourLock = true;
                        Wallpapers.setWallpaper(currentItem.modelData.path);
                        root.visibilities.launcher = false;
                    } else if (text.startsWith(GlobalConfig.launcher.actionPrefix)) {
                        if (text.startsWith(`${GlobalConfig.launcher.actionPrefix}calc `)
                            || text.startsWith(`${GlobalConfig.launcher.actionPrefix}timer `)
                            || text.startsWith(`${GlobalConfig.launcher.actionPrefix}run `)
                            || text.startsWith(`${GlobalConfig.launcher.actionPrefix}emoji `)
                            || text.startsWith(`${GlobalConfig.launcher.actionPrefix}clip `)
                            || text.startsWith(`${GlobalConfig.launcher.actionPrefix}pin `))
                            currentItem.onClicked();
                        else
                            currentItem.modelData.onClicked(list.currentList);
                    } else {
                        Apps.launch(currentItem.modelData);
                        root.visibilities.launcher = false;
                    }
                }
            }

            Keys.onUpPressed: list.currentList?.decrementCurrentIndex()
            Keys.onDownPressed: list.currentList?.incrementCurrentIndex()

            // Shared with the text field's own caret movement: only steal the arrow when the
            // caret is already at the corresponding end of the query, otherwise let it edit
            // normally (event.accepted = false).
            Keys.onLeftPressed: event => {
                if (root.horizontalNav && search.cursorPosition === 0) {
                    list.currentList?.decrementCurrentIndexHorizontal?.();
                    event.accepted = true;
                } else {
                    event.accepted = false;
                }
            }
            Keys.onRightPressed: event => {
                if (root.horizontalNav && search.cursorPosition === search.text.length) {
                    list.currentList?.incrementCurrentIndexHorizontal?.();
                    event.accepted = true;
                } else {
                    event.accepted = false;
                }
            }

            Keys.onEscapePressed: root.visibilities.launcher = false

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Tab) {
                    if (root.horizontalNav)
                        list.currentList?.incrementCurrentIndexHorizontal?.();
                    else
                        list.currentList?.incrementCurrentIndex();
                    event.accepted = true;
                    return;
                }
                if (event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))) {
                    if (root.horizontalNav)
                        list.currentList?.decrementCurrentIndexHorizontal?.();
                    else
                        list.currentList?.decrementCurrentIndex();
                    event.accepted = true;
                    return;
                }

                if (!GlobalConfig.launcher.vimKeybinds)
                    return;

                if (event.modifiers & Qt.ControlModifier) {
                    if (event.key === Qt.Key_J || event.key === Qt.Key_N) {
                        list.currentList?.incrementCurrentIndex();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_K || event.key === Qt.Key_P) {
                        list.currentList?.decrementCurrentIndex();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_H) {
                        list.currentList?.decrementCurrentIndexHorizontal?.();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_L) {
                        list.currentList?.incrementCurrentIndexHorizontal?.();
                        event.accepted = true;
                    }
                }
            }

            Component.onCompleted: forceActiveFocus()

            Connections {
                target: LauncherIpc

                function onTextChanged(): void {
                    if (LauncherIpc.text) {
                        search.text = LauncherIpc.text;
                        LauncherIpc.text = "";
                    }
                }
            }

            Connections {
                function onLauncherChanged(): void {
                    if (!root.visibilities.launcher)
                        search.text = "";
                }

                function onSessionChanged(): void {
                    if (!root.visibilities.session)
                        search.forceActiveFocus();
                }

                target: root.visibilities
            }
        }

        MaterialIcon {
            id: clearIcon

            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: root.padding

            width: search.text ? implicitWidth : implicitWidth / 2
            opacity: {
                if (!search.text)
                    return 0;
                if (mouse.pressed)
                    return 0.7;
                if (mouse.containsMouse)
                    return 0.8;
                return 1;
            }

            text: "close"
            color: Colours.palette.m3onSurfaceVariant

            MouseArea {
                id: mouse

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: search.text ? Qt.PointingHandCursor : undefined

                onClicked: search.text = ""
            }

            Behavior on width {
                Anim {
                    type: Anim.StandardSmall
                }
            }

            Behavior on opacity {
                Anim {
                    type: Anim.StandardSmall
                }
            }
        }
    }
}
