pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus
import qs.modules.nexus.common
import "../../../services/KeybindActions.js" as KBActions

// The keybinds.json shortcuts -- arbitrary key -> action pairs the shell applies dynamically
// through KeybindApplier. Distinct from Hyprland -> Binds, which edits the compositor's own `kb*`
// variables; KeybindRegistry is what lets the two see each other's collisions.
//
// Rows mirror the Hyprland binds page: capture in place, conflict warning under the label. The
// fields a schema row has no equivalent for -- description, action, argument, delete -- stay in
// BindingEditor behind the row's tune button.
PageBase {
    id: root

    title: qsTr("Keybindings")

    function openEditor(catIdx: int, bindIdx: int): void {
        root.nState.kbEditCat = catIdx;
        root.nState.kbEditBind = bindIdx;
        root.nState.openSubPage(PageCompRegistry.keybindsSubPages.editor);
    }

    // "Run command · brave-browser-nightly". Gives the row the same two-line shape as a schema
    // row, where the schema supplies a static subtext and here it's derived from the action.
    function actionSummary(binding: var): string {
        const act = KBActions.getActionById(binding.actionId);
        if (!act)
            return qsTr("Unknown action");
        return act.hasArg && binding.argument ? `${act.label} · ${binding.argument}` : act.label;
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

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
                text: confirming ? qsTr("Reset every binding?") : qsTr("Reset all to defaults")
                type: IconTextButton.Tonal
                onClicked: {
                    if (confirming) {
                        confirming = false;
                        confirmTimeout.stop();
                        KeybindsConfig.resetToDefaults();
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

        Repeater {
            model: KeybindsConfig.categories

            CollapsibleSection {
                id: section

                required property var modelData
                required property int index

                Layout.fillWidth: true
                // Category names are user data from keybinds.json, not translatable literals, so
                // unlike HyprSectionList this deliberately doesn't wrap them in qsTr.
                title: modelData.name
                showBackground: false

                Repeater {
                    model: section.modelData.bindings

                    KeyCaptureField {
                        id: bindRow

                        required property var modelData
                        required property int index

                        readonly property string bindId: `${section.index}:${bindRow.index}`

                        first: index === 0
                        label: modelData.desc
                        subtext: KeybindApplier.unsupported[bindId] ?? root.actionSummary(modelData)
                        conflictText: KeybindRegistry.jsonConflicts[bindId] ?? KeybindApplier.unsupported[bindId] ?? ""
                        modifiers: modelData.modifiers ?? []
                        key: modelData.key ?? ""
                        allowTextEntry: true
                        actionIcon: "tune"
                        onCaptured: (mods, k) => KeybindsConfig.updateBindingKey(section.index, bindRow.index, mods, k)
                        onTextCommitted: combo => {
                            const parsed = KBActions.parseKeyCombo(combo);
                            KeybindsConfig.updateBindingKey(section.index, bindRow.index, parsed.mods, parsed.key);
                        }
                        onActionTriggered: root.openEditor(section.index, bindRow.index)
                    }
                }

                ConnectedRect {
                    id: addRow

                    Layout.fillWidth: true
                    last: true
                    implicitHeight: addRowLayout.implicitHeight + addRowLayout.anchors.margins * 2

                    StateLayer {
                        onClicked: root.openEditor(section.index, -1)
                    }

                    RowLayout {
                        id: addRowLayout

                        anchors.fill: parent
                        anchors.margins: Tokens.padding.medium
                        anchors.leftMargin: Tokens.padding.largeIncreased
                        anchors.rightMargin: Tokens.padding.largeIncreased
                        spacing: Tokens.spacing.medium

                        MaterialIcon {
                            text: "add"
                            color: Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.icon.medium
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: qsTr("Add binding")
                            font: Tokens.font.body.small
                        }
                    }
                }
            }
        }
    }
}
