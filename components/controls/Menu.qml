pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import Quickshell
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.components.effects
import qs.services
import qs.modules.drawers

MouseArea {
    id: root

    enum Side {
        Top,
        Bottom,
        Left,
        Right
    }

    required property Item attachTo
    property int attachSideX: Menu.Right
    property int attachSideY: Menu.Bottom
    property int thisSideX: Menu.Right
    property int thisSideY: Menu.Top
    property real marginX
    property real marginY

    property list<MenuItem> items
    property MenuItem active: items[0] ?? null
    property bool expanded

    signal itemSelected(item: MenuItem)

    parent: {
        const win = QsWindow.window;
        const contentWin = win as ContentWindow; // If inside the drawer content window, put it inside the interaction wrapper so hover works
        return contentWin ? contentWin.interactionWrapper : (win as QsWindow).contentItem;
    }
    anchors.fill: parent

    enabled: expanded
    onClicked: expanded = false

    opacity: expanded ? 1 : 0
    layer.enabled: opacity < 1

    Behavior on opacity {
        Anim {
            type: Anim.DefaultEffects
        }
    }

    TransformWatcher {
        id: watcher

        a: root.parent
        b: root.attachTo
    }

    Elevation {
        id: menu

        x: {
            watcher.transform; // mapToItem is not reactive so this forces updates
            const item = root.attachTo;
            let off = root.attachSideX === Menu.Left ? 0 : item.width;
            if (root.thisSideX === Menu.Right)
                off -= width;
            return item.mapToItem(root.parent, off, 0).x + root.marginX;
        }
        y: {
            watcher.transform; // mapToItem is not reactive so this forces updates
            const item = root.attachTo;
            let off = root.attachSideY === Menu.Top ? 0 : item.height;
            if (root.thisSideY === Menu.Bottom)
                off -= height;
            return item.mapToItem(root.parent, 0, off).y + root.marginY;
        }

        radius: Tokens.rounding.large
        level: 2

        implicitWidth: Math.max(200, menuColumn.implicitWidth + Tokens.padding.extraSmall * 2)
        implicitHeight: Math.min(menuColumn.implicitHeight + Tokens.padding.extraSmall * 2, root.parent.height * 0.6)

        transform: Scale {
            yScale: root.expanded ? 1 : 0.1
            origin.y: root.thisSideY === Menu.Bottom ? menu.height : 0

            Behavior on yScale {
                Anim {}
            }
        }

        StyledRect {
            anchors.fill: parent
            radius: parent.radius
            color: Colours.palette.m3surfaceContainerLow
            clip: true

            Flickable {
                id: menuFlickable

                anchors.fill: parent
                anchors.margins: Tokens.padding.extraSmall
                contentHeight: menuColumn.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: menuColumn

                    width: parent.width

                    Repeater {
                        id: repeater

                        model: root.items

                        Column {
                            id: itemWrapper

                            required property int index
                            required property MenuItem modelData

                            // Header at the start of each run of items sharing a group. Items
                            // with no group -- every caller but the keybind action picker --
                            // never produce one, so this list renders exactly as it always has.
                            readonly property string group: modelData?.group ?? ""
                            readonly property bool showGroup: group !== "" && (index === 0 || (root.items[index - 1]?.group ?? "") !== group)

                            width: menuColumn.width

                            // A Loader rather than a `visible: false` Text -- an invisible item
                            // still takes its height in a Column, which would leave a gap above
                            // every ungrouped item.
                            Loader {
                                width: itemWrapper.width
                                active: itemWrapper.showGroup

                                sourceComponent: StyledText {
                                    leftPadding: Tokens.padding.medium
                                    topPadding: Tokens.padding.small
                                    bottomPadding: Tokens.padding.extraSmall
                                    text: itemWrapper.group
                                    color: Colours.palette.m3outline
                                    font: Tokens.font.label.small
                                }
                            }

                            StyledRect {
                                id: item

                                readonly property int index: itemWrapper.index
                                readonly property MenuItem modelData: itemWrapper.modelData
                                readonly property bool active: modelData === root?.active

                                width: itemWrapper.width
                                implicitHeight: menuOptionRow.implicitHeight + Tokens.padding.medium * 2

                                radius: active ? Tokens.rounding.medium : Tokens.rounding.extraSmall
                                topLeftRadius: index === 0 ? Tokens.rounding.medium : radius
                                topRightRadius: index === 0 ? Tokens.rounding.medium : radius
                                bottomLeftRadius: index === repeater?.count - 1 ? Tokens.rounding.medium : radius
                                bottomRightRadius: index === repeater?.count - 1 ? Tokens.rounding.medium : radius

                                color: Qt.alpha(Colours.palette.m3tertiaryContainer, active ? 1 : 0)

                                Behavior on radius {
                                    Anim {}
                                }

                                StateLayer {
                                    topLeftRadius: parent.topLeftRadius
                                    topRightRadius: parent.topRightRadius
                                    bottomLeftRadius: parent.bottomLeftRadius
                                    bottomRightRadius: parent.bottomRightRadius

                                    color: item.active ? Colours.palette.m3onTertiaryContainer : Colours.palette.m3onSurface
                                    disabled: !root.expanded
                                    onClicked: {
                                        root.itemSelected(item.modelData);
                                        root.active = item.modelData;
                                        item.modelData.clicked();
                                        root.expanded = false;
                                    }
                                }

                                RowLayout {
                                    id: menuOptionRow

                                    anchors.fill: parent
                                    anchors.margins: Tokens.padding.medium
                                    spacing: Tokens.spacing.small

                                    Loader {
                                        readonly property string source: item.modelData?.iconSource ?? ""

                                        asynchronous: true
                                        Layout.alignment: Qt.AlignVCenter
                                        active: source.length > 0
                                        visible: active

                                        sourceComponent: IconImage {
                                            asynchronous: true
                                            source: item.modelData.iconSource
                                            implicitSize: leadingIcon.implicitHeight
                                        }
                                    }

                                    MaterialIcon {
                                        id: leadingIcon

                                        Layout.alignment: Qt.AlignVCenter
                                        Layout.preferredWidth: visible ? implicitWidth : 0
                                        visible: !(item.modelData?.iconSource.length > 0)
                                        text: item.modelData?.icon ?? ""
                                        color: item.active ? Colours.palette.m3onTertiaryContainer : Colours.palette.m3onSurfaceVariant
                                    }

                                    StyledText {
                                        Layout.alignment: Qt.AlignVCenter
                                        Layout.fillWidth: true
                                        text: item.modelData?.text ?? ""
                                        color: item.active ? Colours.palette.m3onTertiaryContainer : Colours.palette.m3onSurface
                                    }

                                    Loader {
                                        asynchronous: true
                                        Layout.alignment: Qt.AlignVCenter
                                        active: item.modelData?.trailingIcon.length > 0
                                        visible: active

                                        sourceComponent: MaterialIcon {
                                            text: item.modelData.trailingIcon
                                            color: item.active ? Colours.palette.m3onTertiaryContainer : Colours.palette.m3onSurfaceVariant
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

            }

            StyledScrollBar {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                flickable: menuFlickable
                policy: T.ScrollBar.AsNeeded
            }
        }
    }
}
