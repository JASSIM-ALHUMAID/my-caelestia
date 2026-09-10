pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common
import "../../../../services/KeybindActions.js" as KBActions

PageBase {
    id: root

    readonly property int catIdx: nState.kbEditCat
    readonly property int bindIdx: nState.kbEditBind
    readonly property bool isNew: bindIdx < 0

    property string editDesc: ""
    property var editMods: []
    property string editKey: ""
    property string editActionId: "exec"
    property string editArgument: ""

    readonly property var currentAction: KBActions.getActionById(editActionId)
    readonly property bool actionHasArg: currentAction?.hasArg ?? false
    // Against both keybind systems, not just keybinds.json -- the staged combo isn't in the
    // registry's claims yet, so it's asked about directly rather than looked up.
    readonly property string conflict: editKey === "" ? "" : KeybindRegistry.describeClaims(editMods, editKey, isNew ? "" : `${catIdx}:${bindIdx}`)
    readonly property bool canSave: editDesc !== "" && editKey !== "" && (!actionHasArg || editArgument !== "")

    isSubPage: true
    title: isNew ? qsTr("New binding") : qsTr("Edit binding")

    Component.onCompleted: {
        if (isNew)
            return;
        const cat = KeybindsConfig.categories[catIdx];
        const bind = cat?.bindings[bindIdx];
        if (!bind)
            return;
        editDesc = bind.desc ?? "";
        editMods = (bind.modifiers ?? []).slice();
        editKey = bind.key ?? "";
        editActionId = bind.actionId ?? "exec";
        editArgument = bind.argument ?? "";
    }

    function save(): void {
        const binding = {
            desc: root.editDesc,
            modifiers: root.editMods,
            key: root.editKey,
            actionId: root.editActionId,
            argument: root.editArgument
        };
        if (root.isNew)
            KeybindsConfig.addBinding(root.catIdx, binding);
        else
            KeybindsConfig.updateBinding(root.catIdx, root.bindIdx, binding);
        root.nState.closeSubPage();
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Binding")
        }

        ConnectedRect {
            Layout.fillWidth: true
            first: true
            implicitHeight: descRow.implicitHeight + descRow.anchors.margins * 2

            RowLayout {
                id: descRow

                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.medium

                StyledText {
                    text: qsTr("Description")
                    font: Tokens.font.body.small
                    color: Colours.palette.m3onSurface
                }

                StyledTextField {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignRight
                    text: root.editDesc
                    placeholderText: qsTr("What this binding does")
                    onTextChanged: root.editDesc = text
                }
            }
        }

        KeyCaptureField {
            Layout.fillWidth: true
            modifiers: root.editMods
            key: root.editKey
            onCaptured: (mods, key) => {
                root.editMods = mods;
                root.editKey = key;
            }
        }

        ConnectedRect {
            Layout.fillWidth: true
            last: true
            implicitHeight: keyRow.implicitHeight + keyRow.anchors.margins * 2

            RowLayout {
                id: keyRow

                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.medium

                StyledText {
                    text: qsTr("Keysym (advanced)")
                    font: Tokens.font.body.small
                    color: Colours.palette.m3onSurface
                }

                StyledTextField {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignRight
                    text: root.editKey
                    placeholderText: qsTr("e.g. period, F5")
                    onTextChanged: root.editKey = text
                }
            }
        }

        StyledText {
            Layout.fillWidth: true
            Layout.leftMargin: Tokens.padding.small
            visible: root.conflict !== ""
            text: root.conflict
            color: Colours.palette.m3error
            font: Tokens.font.label.small
            wrapMode: Text.Wrap
        }

        SectionHeader {
            text: qsTr("Action")
        }

        Variants {
            id: actionVariants

            // Ordered by category so the menu's group headers each cover one contiguous run.
            // ACTIONS carries `category` on every entry; nothing read it until now.
            model: KBActions.actionsByCategory()

            MenuItem {
                required property var modelData

                readonly property string actionId: modelData.id
                readonly property bool hasArg: modelData.hasArg ?? false
                readonly property string argLabel: modelData.argLabel ?? ""

                text: modelData.label
                group: KBActions.categoryLabel(modelData.category)
            }
        }

        SelectRow {
            Layout.fillWidth: true
            first: true
            last: !root.actionHasArg
            label: qsTr("Action")
            menuItems: actionVariants.instances
            active: actionVariants.instances.find(i => i.actionId === root.editActionId) ?? actionVariants.instances[0]
            onSelected: item => {
                root.editActionId = item.actionId;
                if (!item.hasArg)
                    root.editArgument = "";
            }
        }

        ConnectedRect {
            Layout.fillWidth: true
            last: true
            visible: root.actionHasArg
            implicitHeight: argCol.implicitHeight + argCol.anchors.margins * 2

            ColumnLayout {
                id: argCol

                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.small

                StyledText {
                    Layout.fillWidth: true
                    text: root.currentAction?.argLabel ?? ""
                    font: Tokens.font.body.small
                    color: Colours.palette.m3onSurface
                }

                StyledInputArea {
                    Layout.fillWidth: true
                    allowNewlines: false
                    text: root.editArgument
                    placeholderText: qsTr("Value")
                    onTextEdited: text => root.editArgument = text
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.large
            spacing: Tokens.spacing.small

            TextButton {
                visible: !root.isNew
                text: qsTr("Delete")
                onClicked: {
                    KeybindsConfig.removeBinding(root.catIdx, root.bindIdx);
                    root.nState.closeSubPage();
                }
            }

            Item {
                Layout.fillWidth: true
            }

            TextButton {
                text: qsTr("Cancel")
                onClicked: root.nState.closeSubPage()
            }

            TextButton {
                type: TextButton.Filled
                text: qsTr("Save")
                disabled: !root.canSave
                onClicked: root.save()
            }
        }
    }
}
