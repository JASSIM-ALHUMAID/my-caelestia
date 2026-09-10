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

    required property string column // "left", "center", or "right"

    readonly property int maxOptionalWidgets: 4

    property int enabledCount

    readonly property var widgetLabels: ({
        weather: qsTr("Weather"),
        fetch: qsTr("System info"),
        media: qsTr("Media player"),
        power: qsTr("Power controls"),
        quote: qsTr("Random quote"),
        clock: qsTr("Clock"),
        date: qsTr("Date"),
        profilePic: qsTr("Profile picture"),
        passwordInput: qsTr("Password input"),
        stateMessage: qsTr("Status message"),
        resources: qsTr("System resources"),
        notifications: qsTr("Notifications"),
    })

    readonly property var widgetIcons: ({
        weather: "cloud",
        fetch: "terminal",
        media: "music_note",
        power: "power_settings_new",
        quote: "format_quote",
        clock: "schedule",
        date: "calendar_today",
        profilePic: "person",
        passwordInput: "lock",
        stateMessage: "info",
        resources: "memory",
        notifications: "notifications",
    })

    // Widgets that must always exist in exactly one column: they can be moved
    // between columns via the add menu but never removed or disabled.
    readonly property var forcedWidgets: ["passwordInput", "stateMessage"]

    readonly property var availableWidgets: ["weather", "fetch", "media", "power", "quote", "clock", "date", "profilePic", "resources", "notifications"]

    function labelFor(id: string): string {
        return widgetLabels[id] ?? id;
    }

    function isForced(id: string): bool {
        return forcedWidgets.includes(id);
    }

    function recount(): void {
        let n = 0;
        for (let i = 0; i < entriesModel.count; i++) {
            const item = entriesModel.get(i);
            if (!isForced(item.widgetId) && item.widgetEnabled)
                n++;
        }
        enabledCount = n;
    }

    function getEntries(): var {
        switch (root.column) {
        case "left": return GlobalConfig.lock.leftWidgets;
        case "center": return GlobalConfig.lock.centerWidgets;
        case "right": return GlobalConfig.lock.rightWidgets;
        }
        return [];
    }

    function setEntries(arr: var): void {
        switch (root.column) {
        case "left": GlobalConfig.lock.leftWidgets = arr; break;
        case "center": GlobalConfig.lock.centerWidgets = arr; break;
        case "right": GlobalConfig.lock.rightWidgets = arr; break;
        }
    }

    function addEntry(id: string): void {
        if (isForced(id)) {
            // Move it out of whichever column currently holds it
            for (const col of ["left", "center", "right"]) {
                if (col === root.column)
                    continue;
                const entries = GlobalConfig.lock[`${col}Widgets`];
                if (entries.some(e => e.id === id))
                    GlobalConfig.lock[`${col}Widgets`] = entries.filter(e => e.id !== id);
            }
        }
        entriesModel.append({ widgetId: id, widgetEnabled: isForced(id) ? true : enabledCount < maxOptionalWidgets });
        saveConfig();
    }

    function saveConfig(): void {
        recount();
        const arr = [];
        for (let i = 0; i < entriesModel.count; i++) {
            const item = entriesModel.get(i);
            arr.push({ id: item.widgetId, enabled: item.widgetEnabled });
        }
        root.setEntries(arr);
    }

    title: qsTr("Column widgets")
    isSubPage: true

    ColumnLayout {
        id: layout

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.small

        ListModel {
            id: entriesModel

            Component.onCompleted: {
                for (const e of root.getEntries())
                    append({ widgetId: e.id, widgetEnabled: e.enabled });
                root.recount();
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

                StyledText {
                    text: qsTr("%1/%2 on").arg(root.enabledCount).arg(root.maxOptionalWidgets)
                    color: root.enabledCount >= root.maxOptionalWidgets ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.small
                }

                IconButton {
                    id: addButton

                    enabled: addMenu.items.length > 0
                    opacity: enabled ? 1 : 0.5
                    icon: "add"
                    type: IconButton.Tonal
                    onClicked: addMenu.expanded = !addMenu.expanded
                }
            }
        }

        Repeater {
            id: repeater

            model: entriesModel

            delegate: DragReorderRow {
                id: dragItem

                required property int index
                required property string widgetId
                required property bool widgetEnabled

                width: layout.width
                dndIndex: index

                onReordered: (from, to) => {
                    entriesModel.move(from, to, 1);
                    root.saveConfig();
                }

                StyledText {
                    Layout.fillWidth: true
                    text: root.labelFor(dragItem.widgetId)
                    color: dragItem.widgetEnabled || root.isForced(dragItem.widgetId) ? Colours.palette.m3onSurface : Colours.palette.m3onSurfaceVariant
                }

                MaterialIcon {
                    visible: root.isForced(dragItem.widgetId)
                    text: "lock"
                    color: Colours.palette.m3onSurfaceVariant
                }

                StyledSwitch {
                    visible: !root.isForced(dragItem.widgetId)
                    checked: dragItem.widgetEnabled
                    onToggled: {
                        if (checked && root.enabledCount >= root.maxOptionalWidgets) {
                            checked = false;
                            return;
                        }
                        entriesModel.setProperty(dragItem.index, "widgetEnabled", checked);
                        root.saveConfig();
                    }
                }

                IconButton {
                    visible: !root.isForced(dragItem.widgetId)
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

            items: {
                const existing = [];
                for (let i = 0; i < entriesModel.count; i++)
                    existing.push(entriesModel.get(i).widgetId);

                const ids = [];

                // Regular widgets: any column, duplicates across columns allowed;
                // added disabled once maxOptionalWidgets enabled entries are reached
                ids.push(...root.availableWidgets.filter(id => !existing.includes(id)));

                // Forced widgets living in another column can be moved here
                ids.push(...root.forcedWidgets.filter(id => !existing.includes(id)));

                return ids.map(id => entryMenuItem.createObject(addMenu, { widgetId: id }));
            }
        }

        Component {
            id: entryMenuItem

            MenuItem {
                required property string widgetId

                text: root.isForced(widgetId) ? qsTr("%1 (move here)").arg(root.labelFor(widgetId)) : root.labelFor(widgetId)
                icon: root.widgetIcons[widgetId] ?? "widgets"
                onClicked: root.addEntry(widgetId)
            }
        }
    }
}
