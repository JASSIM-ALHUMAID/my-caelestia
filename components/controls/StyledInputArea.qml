pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    property string text: ""
    property string placeholderText: ""
    property bool readOnly: false
    property bool allowNewlines: true

    // Expose activeFocus through alias to avoid FINAL property override
    readonly property alias hasFocus: inputArea.activeFocus

    signal textEdited(string text)

    signal editingFinished

    implicitHeight: inputArea.implicitHeight + Tokens.padding.small * 2

    StyledRect {
        id: container

        anchors.fill: parent
        color: inputHover.containsMouse || inputArea.activeFocus ? Colours.layer(Colours.palette.m3surfaceContainer, 3) : Colours.layer(Colours.palette.m3surfaceContainer, 2)
        radius: Tokens.rounding.medium
        border.width: 1
        border.color: inputArea.activeFocus ? Colours.palette.m3primary : Qt.alpha(Colours.palette.m3outline, 0.3)
        opacity: root.enabled ? 1 : 0.5

        Behavior on color {
            CAnim {}
        }
        Behavior on border.color {
            CAnim {}
        }

        MouseArea {
            id: inputHover

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.IBeamCursor
            acceptedButtons: Qt.NoButton
            enabled: root.enabled
        }

        StyledTextArea {
            id: inputArea

            anchors.fill: parent
            anchors.margins: Tokens.padding.small
            padding: 0
            placeholderText: root.placeholderText
            readOnly: root.readOnly
            enabled: root.enabled
            Keys.onReturnPressed: event => event.accepted = !root.allowNewlines
            Keys.onEnterPressed: event => event.accepted = !root.allowNewlines

            onTextChanged: {
                root.text = text;
                root.textEdited(text);
            }

            onEditingFinished: {
                root.editingFinished();
            }

            Connections {
                target: root

                function onTextChanged(): void {
                    if (!inputArea.activeFocus)
                        inputArea.text = root.text;
                }
            }
        }
    }
}
