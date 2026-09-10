pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common
import "../../../../services/HyprSchema.js" as Schema

// Hyprland keybinds -- the `kb*` keys of variables.lua, which hypr/hyprland/keybinds.lua feeds
// to hl.bind. Separate from the Keybindings page, which owns keybinds.json and applies its binds
// dynamically through KeybindApplier; these are compositor config and take effect on reload.
PageBase {
    id: root

    title: qsTr("Binds")
    isSubPage: true

    readonly property list<string> resetKeys: Schema.allKeys(Schema.BIND_SECTIONS)

    function resetAll(): void {
        for (const key of root.resetKeys)
            GlobalConfig.services.resetOption(key);
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Two clicks, matching the Variables page -- resetting every bind can't be undone, and
        // the second click has to land while the button is still asking.
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.extraSmall

            Item {
                Layout.fillWidth: true
            }

            IconTextButton {
                id: resetAllButton

                property bool confirming: false

                icon: confirming ? "warning" : "restart_alt"
                text: confirming ? qsTr("Reset every bind?") : qsTr("Reset all to defaults")
                type: IconTextButton.Tonal
                onClicked: {
                    if (confirming) {
                        confirming = false;
                        confirmTimeout.stop();
                        root.resetAll();
                    } else {
                        confirming = true;
                        confirmTimeout.restart();
                    }
                }

                Timer {
                    id: confirmTimeout

                    interval: 4000
                    onTriggered: resetAllButton.confirming = false
                }
            }
        }

        // Conflicts come from KeybindRegistry rather than a local pass, so a combo this page
        // shares with a keybinds.json shortcut is flagged here too.
        HyprSectionList {
            sections: Schema.BIND_SECTIONS
            conflicts: KeybindRegistry.hyprConflicts
        }
    }
}
