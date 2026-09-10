import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

// A connected-row text field, matching StepperRow/SelectRow. components/controls/TextFieldRow
// is a bare RowLayout with no ConnectedRect background, so it can't join a row group.
ConnectedRect {
    id: root

    property alias label: label.text
    property string subtext
    property string value
    property string placeholder
    property string resetIcon

    signal edited(value: string)
    signal resetRequested()

    implicitHeight: rowLayout.implicitHeight + rowLayout.anchors.margins * 2

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
                id: label

                Layout.fillWidth: true
                font: Tokens.font.body.small
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                visible: root.subtext
                text: root.subtext
                color: Colours.palette.m3outline
                font: Tokens.font.label.small
                elide: Text.ElideRight
            }
        }

        IconButton {
            icon: root.resetIcon
            type: IconButton.Text
            visible: root.resetIcon !== ""
            onClicked: root.resetRequested()
        }

        StyledTextField {
            id: field

            // Only follow the config while the user isn't mid-edit, so a reset or an external
            // change lands in the field but typing isn't clobbered.
            text: root.value
            placeholderText: root.placeholder
            horizontalAlignment: TextInput.AlignHCenter

            Layout.preferredWidth: 180
            padding: Tokens.padding.small
            leftPadding: Tokens.padding.normal
            rightPadding: Tokens.padding.normal

            onAccepted: root.commit()
            onEditingFinished: root.commit()

            background: StyledRect {
                radius: Tokens.rounding.small
                color: Colours.tPalette.m3surfaceContainerHigh
            }
        }
    }

    function commit(): void {
        if (field.text !== root.value)
            root.edited(field.text);
    }
}
