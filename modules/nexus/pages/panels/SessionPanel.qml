pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Power Menu")
    isSubPage: true

    readonly property list<MenuItem> positionItems: [
        MenuItem { text: qsTr("Left"); property string value: "left" },
        MenuItem { text: qsTr("Right"); property string value: "right" },
        MenuItem { text: qsTr("Top"); property string value: "top" },
        MenuItem { text: qsTr("Bottom"); property string value: "bottom" },
    ]

    readonly property MenuItem activePositionItem: {
        for (const item of root.positionItems)
            if (item.value === Config.session.position) return item;
        return root.positionItems[0];
    }

    readonly property list<MenuItem> iconStyleItems: [
        MenuItem { text: qsTr("Outlined"); property string value: "outlined" },
        MenuItem { text: qsTr("Filled"); property string value: "filled" },
    ]

    readonly property MenuItem activeIconStyleItem: {
        for (const item of root.iconStyleItems)
            if (item.value === Config.session.iconStyle) return item;
        return root.iconStyleItems[0];
    }

    // The roster is fixed in C++ (SessionConfig's ctor) and entries are matched by id on
    // load, so items can be reordered and toggled but never added or removed.
    function itemFor(id: string): var {
        for (const item of GlobalConfig.session.items)
            if (item.id === id)
                return item;
        return null;
    }

    // Layout position is not meaningful to the config -- SessionItem carries an explicit
    // `order` int, which modules/session/Content.qml sorts on -- so persist the new order
    // by writing it back onto the existing items rather than replacing the list.
    function saveOrder(): void {
        for (let i = 0; i < itemsModel.count; i++) {
            const item = root.itemFor(itemsModel.get(i).itemId);
            if (item)
                item.order = i;
        }
    }

    ColumnLayout {
        id: layout

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SettingsSection {
            first: true
            expanded: true
            title: qsTr("General")

            ToggleRow {
                Layout.fillWidth: true
                first: true
                text: qsTr("Enabled")
                checked: Config.session.enabled
                onToggled: GlobalConfig.session.enabled = checked
            }

            ToggleRow {
                Layout.fillWidth: true
                text: qsTr("Reveal on hover")
                subtext: qsTr("Also requires this edge's hover gesture to be set to Session")
                checked: Config.session.showOnHover
                onToggled: GlobalConfig.session.showOnHover = checked
            }

            SelectRow {
                Layout.fillWidth: true
                label: qsTr("Position")
                subtext: qsTr("Which screen edge the power menu appears on")
                menuItems: root.positionItems
                active: root.activePositionItem
                onSelected: item => GlobalConfig.session.position = item.value
            }

            SelectRow {
                Layout.fillWidth: true
                last: true
                label: qsTr("Icon style")
                subtext: qsTr("Filled only affects icons with an enclosed shape, such as lock and sleep")
                menuItems: root.iconStyleItems
                active: root.activeIconStyleItem
                onSelected: item => GlobalConfig.session.iconStyle = item.value
            }
        }

        SettingsSection {
            title: qsTr("Items")

            StyledText {
                Layout.fillWidth: true
                Layout.bottomMargin: Tokens.spacing.extraSmall
                text: qsTr("Drag to reorder")
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.small
            }

            // Seeded from GlobalConfig, not the read-only Config propagator: the entries are

            // edited in place, and the roster is global-only (no per-monitor override).

            ListModel {
                id: itemsModel

                Component.onCompleted: {
                    const sorted = GlobalConfig.session.items.slice().sort((a, b) => a.order - b.order);
                    for (const item of sorted)
                        append({
                            itemId: item.id,
                            itemIcon: item.icon,
                            itemEnabled: item.enabled
                        });
                }
            }

            Repeater {
                model: itemsModel

                delegate: DragReorderRow {
                    id: dragItem

                    required property int index
                    required property string itemId
                    required property string itemIcon
                    required property bool itemEnabled

                    width: layout.width
                    dndIndex: index
                    slotSpacing: layout.spacing

                    onReordered: (from, to) => {
                        itemsModel.move(from, to, 1);
                        root.saveOrder();
                    }

                    MaterialIcon {
                        text: dragItem.itemIcon
                        color: Colours.palette.m3onSurfaceVariant
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: dragItem.itemId.charAt(0).toUpperCase() + dragItem.itemId.slice(1)
                        color: dragItem.itemEnabled ? Colours.palette.m3onSurface : Colours.palette.m3onSurfaceVariant
                    }

                    StyledSwitch {
                        checked: dragItem.itemEnabled
                        onToggled: {
                            itemsModel.setProperty(dragItem.index, "itemEnabled", checked);
                            const item = root.itemFor(dragItem.itemId);
                            if (item)
                                item.enabled = checked;
                        }
                    }
                }
            }
        }

        SettingsSection {
            title: qsTr("Behaviour")

            ToggleRow {
                Layout.fillWidth: true
                last: true
                text: qsTr("Vim keybinds")
                subtext: qsTr("Navigate items with Ctrl+hjkl")
                checked: Config.session.vimKeybinds
                onToggled: GlobalConfig.session.vimKeybinds = checked
            }
        }
    }
}
