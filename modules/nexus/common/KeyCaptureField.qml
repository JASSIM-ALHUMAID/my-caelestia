pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common
import "../../../services/KeybindActions.js" as KBActions

// A connected row that captures a shortcut by having the user press it. Used both by the
// Keybindings page (keybinds.json) and by the Hyprland binds page (variables.lua `kb*`).
//
// Two modes exist beyond plain capture:
//   modsOnly       the value is a modifier *prefix* with no key -- Hyprland's kbGoToWs and
//                  friends, which keybinds.lua completes with a digit. Capture commits when
//                  the user starts releasing, since there is no key press to end it.
//   allowTextEntry an "edit" affordance that swaps the display for a text field, for the
//                  combo forms a keyboard can't produce: mouse:272, mouse_up, SUPER_L.
ConnectedRect {
    id: root

    property string label: qsTr("Shortcut")
    property string subtext
    property var modifiers: []
    property string key: ""
    property bool capturing: false
    property var heldMods: []
    property string errorText: ""
    property bool modsOnly: false
    property bool allowTextEntry: false
    property bool editing: false
    property string resetIcon
    // Set by the owning page when this bind's combo is claimed by another bind. Advisory only.
    property string conflictText
    // Optional trailing affordance, for rows that carry more than a shortcut -- the keybinds.json
    // page uses it to reach the editor for description, action and argument.
    property string actionIcon

    readonly property string comboText: KBActions.formatKeyCombo(modifiers, key)

    signal captured(mods: var, key: string)
    signal cancelled
    signal textCommitted(combo: string)
    signal resetRequested
    signal actionTriggered

    Layout.fillWidth: true
    implicitHeight: rowLayout.implicitHeight + rowLayout.anchors.margins * 2

    onCapturingChanged: capturing ? KeybindApplier.suspend() : KeybindApplier.resume()

    Component.onDestruction: {
        if (capturing)
            KeybindApplier.resume();
    }

    function startCapture(): void {
        if (root.capturing || root.editing)
            return;
        root.errorText = "";
        root.heldMods = [];
        root.capturing = true;
        focusGrabber.forceActiveFocus();
    }

    // An empty combo is not an unbind -- hl.bind("") is a config error -- so a cleared field
    // reverts rather than being written.
    function commitText(): void {
        root.editing = false;
        const text = textField.text.trim();
        if (text.length > 0 && text !== root.comboText)
            root.textCommitted(text);
    }

    StateLayer {
        enabled: !root.editing
        onClicked: root.startCapture()
    }

    RowLayout {
        id: rowLayout

        anchors.fill: parent
        anchors.margins: Tokens.padding.medium
        anchors.leftMargin: Tokens.padding.largeIncreased
        anchors.rightMargin: Tokens.padding.largeIncreased
        spacing: Tokens.spacing.medium

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                text: root.label
                font: Tokens.font.body.small
                color: Colours.palette.m3onSurface
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.conflictText || root.subtext
                color: root.conflictText ? Colours.palette.m3error : Colours.palette.m3outline
                font: Tokens.font.label.small
                elide: Text.ElideRight
            }
        }

        IconButton {
            icon: root.actionIcon
            type: IconButton.Text
            visible: root.actionIcon !== "" && !root.editing && !root.capturing
            onClicked: root.actionTriggered()
        }

        IconButton {
            icon: root.resetIcon
            type: IconButton.Text
            visible: root.resetIcon !== "" && !root.editing
            onClicked: root.resetRequested()
        }

        IconButton {
            icon: "edit"
            type: IconButton.Text
            visible: root.allowTextEntry && !root.editing && !root.capturing
            onClicked: {
                textField.text = root.comboText;
                root.editing = true;
                textField.forceActiveFocus();
                textField.selectAll();
            }
        }

        StyledTextField {
            id: textField

            visible: root.editing
            horizontalAlignment: TextInput.AlignHCenter

            Layout.preferredWidth: 180
            padding: Tokens.padding.small
            leftPadding: Tokens.padding.normal
            rightPadding: Tokens.padding.normal

            onAccepted: root.commitText()
            onEditingFinished: root.commitText()
            Keys.onEscapePressed: {
                root.editing = false;
                textField.text = root.comboText;
            }

            background: StyledRect {
                radius: Tokens.rounding.small
                color: Colours.tPalette.m3surfaceContainerHigh
            }
        }

        StyledText {
            Layout.alignment: Qt.AlignVCenter
            visible: !root.editing
            text: {
                if (root.capturing) {
                    if (root.errorText)
                        return root.errorText;
                    if (root.heldMods.length > 0)
                        return root.modsOnly ? KBActions.formatModifiers(root.heldMods) : `${KBActions.formatModifiers(root.heldMods)} + …`;
                    return root.modsOnly ? qsTr("Hold modifiers, then release…") : qsTr("Press shortcut… (Esc to cancel)");
                }
                return root.comboText || qsTr("Click to set");
            }
            color: root.errorText ? Colours.palette.m3error : (root.capturing ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant)
            font: Tokens.font.label.small

            Item {
                id: focusGrabber

                implicitWidth: 0
                implicitHeight: 0

                Keys.onPressed: event => {
                    event.accepted = true;

                    if (event.key === Qt.Key_Escape) {
                        root.capturing = false;
                        root.cancelled();
                        return;
                    }

                    if (KBActions.isModifierKey(event.key)) {
                        const mods = [];
                        if (event.modifiers & Qt.MetaModifier)
                            mods.push("SUPER");
                        if (event.modifiers & Qt.ControlModifier)
                            mods.push("CTRL");
                        if (event.modifiers & Qt.AltModifier)
                            mods.push("ALT");
                        if (event.modifiers & Qt.ShiftModifier)
                            mods.push("SHIFT");
                        // Qt reports the state *before* the press, so the key just pressed is
                        // missing from `modifiers`. Accumulate rather than replace, and never
                        // shrink -- modsOnly commits off a release, by which point the set has
                        // already started coming apart.
                        const merged = root.heldMods.slice();
                        for (const m of mods)
                            if (!merged.includes(m))
                                merged.push(m);
                        const self = KBActions.modifierNameForKey(event.key);
                        if (self && !merged.includes(self))
                            merged.push(self);
                        root.heldMods = merged;
                        return;
                    }

                    if (root.modsOnly) {
                        root.errorText = qsTr("Modifiers only");
                        errorTimer.restart();
                        return;
                    }

                    const r = KBActions.qtEventToBinding(event.key, event.modifiers, event.text);
                    if (r) {
                        root.capturing = false;
                        root.captured(r.mods, r.key);
                    } else {
                        root.errorText = qsTr("Unsupported key");
                        errorTimer.restart();
                    }
                }

                // A mods-only value has no terminating key press, so the first release ends the
                // capture and commits everything held up to that point.
                Keys.onReleased: event => {
                    if (!root.modsOnly || !root.capturing)
                        return;
                    event.accepted = true;
                    if (!KBActions.isModifierKey(event.key) || root.heldMods.length === 0)
                        return;
                    root.capturing = false;
                    root.captured(root.heldMods, "");
                }

                onActiveFocusChanged: {
                    if (!activeFocus && root.capturing) {
                        root.capturing = false;
                        root.cancelled();
                    }
                }
            }
        }
    }

    Timer {
        id: errorTimer

        interval: 1200
        onTriggered: root.errorText = ""
    }
}
