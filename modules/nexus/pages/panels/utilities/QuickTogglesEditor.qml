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

    title: qsTr("Quick toggles")
    isSubPage: true

    readonly property var toggleLabels: ({
        wifi: qsTr("Wi-Fi"),
        bluetooth: qsTr("Bluetooth"),
        mic: qsTr("Microphone"),
        settings: qsTr("Settings"),
        gameMode: qsTr("Game mode"),
        dnd: qsTr("Do not disturb"),
        hyprsunset: qsTr("Night light"),
        vpn: qsTr("VPN"),
    })

    readonly property var toggleIcons: ({
        wifi: "wifi",
        bluetooth: "bluetooth",
        mic: "mic",
        settings: "settings",
        gameMode: "gamepad",
        dnd: "notifications_off",
        hyprsunset: "bedtime",
        vpn: "vpn_key",
    })

    // Must stay in sync with the DelegateChoice roleValues in modules/utilities/cards/Toggles.qml.
    // Ids not listed here are still kept if they appear in the config (they just render nothing).
    readonly property var knownToggles: ["wifi", "bluetooth", "mic", "settings", "gameMode", "dnd", "hyprsunset", "vpn"]

    // The card additionally hides the vpn toggle unless a provider is enabled, whatever this
    // list says — see Toggles.qml. Surfaced on the row so switching it on isn't a mystery.
    readonly property bool hasVpnProvider: GlobalConfig.utilities.vpn.provider.some(p => typeof p === "object" && p.enabled === true)

    function labelFor(id: string): string {
        return toggleLabels[id] ?? id;
    }

    function iconFor(id: string): string {
        return toggleIcons[id] ?? "widgets";
    }

    function saveConfig(): void {
        const arr = [];
        for (let i = 0; i < entriesModel.count; i++) {
            const item = entriesModel.get(i);
            arr.push({ id: item.toggleId, enabled: item.toggleEnabled });
        }
        GlobalConfig.utilities.quickToggles = arr;
    }

    ColumnLayout {
        id: layout

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.small

        ListModel {
            id: entriesModel

            // Config order first, then anything known the config never mentioned, so every
            // toggle is always listed and disabling one keeps its place in the order.
            Component.onCompleted: {
                const seen = new Set();

                for (const e of Config.utilities.quickToggles) {
                    if (seen.has(e.id))
                        continue;
                    seen.add(e.id);
                    append({ toggleId: e.id, toggleEnabled: e.enabled ?? true });
                }

                for (const id of root.knownToggles) {
                    if (seen.has(id))
                        continue;
                    append({ toggleId: id, toggleEnabled: false });
                }
            }
        }

        StyledText {
            Layout.fillWidth: true
            text: qsTr("Drag to reorder")
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.body.small
        }

        Repeater {
            model: entriesModel

            delegate: DragReorderRow {
                id: dragItem

                required property int index
                required property string toggleId
                required property bool toggleEnabled

                width: layout.width
                dndIndex: index

                onReordered: (from, to) => {
                    entriesModel.move(from, to, 1);
                    root.saveConfig();
                }

                MaterialIcon {
                    text: root.iconFor(dragItem.toggleId)
                    color: dragItem.toggleEnabled ? Colours.palette.m3onSurface : Colours.palette.m3onSurfaceVariant
                }

                StyledText {
                    Layout.fillWidth: true
                    text: root.labelFor(dragItem.toggleId)
                    color: dragItem.toggleEnabled ? Colours.palette.m3onSurface : Colours.palette.m3onSurfaceVariant
                }

                StyledText {
                    visible: dragItem.toggleId === "vpn" && !root.hasVpnProvider
                    text: qsTr("No provider configured")
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.small
                }

                StyledSwitch {
                    checked: dragItem.toggleEnabled
                    onToggled: {
                        entriesModel.setProperty(dragItem.index, "toggleEnabled", checked);
                        root.saveConfig();
                    }
                }
            }
        }
    }
}
