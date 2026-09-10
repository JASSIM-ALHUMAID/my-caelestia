pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

RowLayout {
    id: root

    required property string label
    property string text
    property string placeholder: ""

    signal textModified(text: string)

    Layout.fillWidth: true
    spacing: Tokens.spacing.normal

    StyledText {
        Layout.fillWidth: true
        text: root.label
    }

    StyledTextField {
        id: field

        text: root.text
        placeholderText: root.placeholder
        horizontalAlignment: TextInput.AlignHCenter

        padding: Tokens.padding.small
        leftPadding: Tokens.padding.normal
        rightPadding: Tokens.padding.normal

        onAccepted: root.commit()
        onEditingFinished: root.commit()

        background: StyledRect {
            implicitWidth: 100
            radius: Tokens.rounding.small
            color: Colours.tPalette.m3surfaceContainerHigh
        }
    }

    function commit(): void {
        if (field.text !== root.text)
            root.textModified(field.text);
    }
}
