import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    required property var list
    readonly property string command: list.search.text.slice(`${GlobalConfig.launcher.actionPrefix}run `.length)

    function onClicked(): void {
        if (command.length === 0)
            return;

        Quickshell.execDetached(["app2unit", "--", "fish", "-c", command]);
        root.list.visibilities.launcher = false;
    }

    implicitHeight: Tokens.sizes.launcher.itemHeight

    anchors.left: parent?.left
    anchors.right: parent?.right

    StateLayer {
        radius: Tokens.rounding.normal
        onClicked: root.onClicked()
    }

    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: Tokens.padding.larger

        spacing: Tokens.spacing.normal

        MaterialIcon {
            text: "terminal"
            fontStyle: Tokens.font.icon.extraLarge
            Layout.alignment: Qt.AlignVCenter
        }

        StyledText {
            color: root.command.length > 0 ? Colours.palette.m3onSurface : Colours.palette.m3onSurfaceVariant
            text: root.command.length > 0 ? root.command : qsTr("Type a command to run")
            elide: Text.ElideRight

            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
        }

        StyledRect {
            color: Colours.palette.m3tertiary
            radius: Tokens.rounding.normal
            clip: true

            implicitWidth: (stateLayer.containsMouse ? label.implicitWidth + label.anchors.rightMargin : 0) + icon.implicitWidth + Tokens.padding.normal * 2
            implicitHeight: Math.max(label.implicitHeight, icon.implicitHeight) + Tokens.padding.small * 2

            Layout.alignment: Qt.AlignVCenter

            StateLayer {
                id: stateLayer

                onClicked: {
                    if (root.command.length === 0)
                        return;

                    Quickshell.execDetached(["app2unit", "--", ...AppCommands.terminal, "fish", "-c", `${root.command}; exec fish`]);
                    root.list.visibilities.launcher = false;
                }

                color: Colours.palette.m3onTertiary
            }

            StyledText {
                id: label

                anchors.verticalCenter: parent.verticalCenter
                anchors.right: icon.left
                anchors.rightMargin: Tokens.spacing.small

                text: qsTr("Open in terminal")
                color: Colours.palette.m3onTertiary
                font.pointSize: Tokens.font.size.normal

                opacity: stateLayer.containsMouse ? 1 : 0

                Behavior on opacity {
                    Anim {}
                }
            }

            MaterialIcon {
                id: icon

                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: Tokens.padding.normal

                text: "open_in_new"
                color: Colours.palette.m3onTertiary
                fontStyle: Tokens.font.icon.large
            }

            Behavior on implicitWidth {
                Anim {
                    type: Anim.Emphasized
                }
            }
        }
    }
}
