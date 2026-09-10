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

    title: qsTr("Bar entries")
    isSubPage: true

    readonly property string edge: root.nState.selectedEdge

    readonly property var entryLabels: ({
        logo: qsTr("Logo"),
        workspaces: qsTr("Workspaces"),
        dock: qsTr("Dock"),
        spacer: qsTr("Spacer"),
        activeWindow: qsTr("Active window"),
        tray: qsTr("Tray"),
        clock: qsTr("Clock"),
        timer: qsTr("Timer"),
        statusIcons: qsTr("Status icons"),
        wallpaperAdvance: qsTr("Wallpaper"),
        layoutSelector: qsTr("Tiling layout"),
        barPin: qsTr("Pin bar"),
        power: qsTr("Power"),
        visualiser: qsTr("Visualiser"),
    })

    readonly property var entryIcons: ({
        logo: "auto_awesome",
        workspaces: "workspaces",
        dock: "dock_to_bottom",
        spacer: "space_bar",
        activeWindow: "window",
        tray: "widgets",
        clock: "schedule",
        timer: "timer",
        statusIcons: "toggle_on",
        wallpaperAdvance: "wallpaper",
        layoutSelector: "dashboard",
        barPin: "keep",
        power: "power_settings_new",
        visualiser: "graphic_eq",
    })

    readonly property var availableEntries: ["logo", "workspaces", "dock", "spacer", "activeWindow", "tray", "clock", "timer", "statusIcons", "wallpaperAdvance", "layoutSelector", "barPin", "power", "visualiser"]

    readonly property var logoVariants: ["auto", "caelestia", "os"]

    readonly property var logoVariantLabels: ({ auto: qsTr("Auto"), caelestia: qsTr("Caelestia"), os: qsTr("OS") })

    function labelFor(id: string): string {
        return entryLabels[id] ?? id;
    }

    function cycleVariant(index: int, current: string): void {
        const i = logoVariants.indexOf(current);
        const next = logoVariants[(i + 1) % logoVariants.length];
        entriesModel.setProperty(index, "variant", next);
        saveConfig();
    }

    function addEntry(id: string): void {
        entriesModel.append({ entryId: id, enabled: true, variant: "auto" });
        saveConfig();
    }

    function saveConfig(): void {
        const arr = [];
        for (let i = 0; i < entriesModel.count; i++) {
            const item = entriesModel.get(i);
            arr.push({ id: item.entryId, enabled: item.enabled, variant: item.variant });
        }
        GlobalConfig.bar[root.edge].entries = arr;
    }

    ColumnLayout {
        id: layout

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.small

        ListModel {
            id: entriesModel

            Component.onCompleted: {
                for (const e of Config.bar[root.edge].entries)
                    append({ entryId: e.id, enabled: e.enabled, variant: e.variant ?? "auto" });
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: headerRow.implicitHeight

            RowLayout {
                id: headerRow

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: Tokens.spacing.small

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Drag to reorder")
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.small
                }

                IconButton {
                    id: addButton

                    icon: "add"
                    type: IconButton.Tonal
                    onClicked: addMenu.expanded = !addMenu.expanded
                }
            }
        }

        Repeater {
            model: entriesModel

            delegate: DragReorderRow {
                id: dragItem

                required property int index
                required property string entryId
                required property string variant

                width: layout.width
                dndIndex: index
                cardColour: Colours.tPalette.m3surfaceContainer

                onReordered: (from, to) => {
                    entriesModel.move(from, to, 1);
                    root.saveConfig();
                }

                StyledText {
                    Layout.fillWidth: true
                    text: root.labelFor(dragItem.entryId)
                    color: Colours.palette.m3onSurface
                }

                TextButton {
                    visible: dragItem.entryId === "logo"
                    type: TextButton.Tonal
                    font: Tokens.font.body.small
                    text: root.logoVariantLabels[dragItem.variant] ?? dragItem.variant
                    onClicked: root.cycleVariant(dragItem.index, dragItem.variant)
                }

                IconButton {
                    icon: "close"
                    type: IconButton.Text
                    onClicked: {
                        entriesModel.remove(dragItem.index);
                        root.saveConfig();
                    }
                }
            }
        }

        Menu {
            id: addMenu

            attachTo: addButton
            attachSideX: Menu.Right
            thisSideX: Menu.Right
            attachSideY: Menu.Bottom
            thisSideY: Menu.Top
            marginY: Tokens.spacing.small

            items: root.availableEntries.map(id => entryMenuItem.createObject(addMenu, {
                entryId: id
            }))
        }

        Component {
            id: entryMenuItem

            MenuItem {
                required property string entryId

                text: root.labelFor(entryId)
                icon: root.entryIcons[entryId] ?? "widgets"
                onClicked: root.addEntry(entryId)
            }
        }
    }
}
