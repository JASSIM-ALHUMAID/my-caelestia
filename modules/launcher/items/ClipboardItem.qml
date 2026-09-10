import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.launcher.services

Item {
    id: root

    required property var modelData
    required property var list

    function onClicked(): void {
        Clipboard.select(root.modelData, root.list);
    }

    implicitHeight: Tokens.sizes.launcher.itemHeight

    anchors.left: parent?.left
    anchors.right: parent?.right

    StateLayer {
        radius: Tokens.rounding.normal

        onClicked: {
            Clipboard.select(root.modelData, root.list);
        }
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: Tokens.padding.larger
        anchors.rightMargin: Tokens.padding.larger
        anchors.topMargin: Tokens.padding.smaller
        anchors.bottomMargin: Tokens.padding.smaller

        MaterialIcon {
            id: icon

            text: "content_paste"
            fontStyle: Tokens.font.icon.medium
            anchors.verticalCenter: parent.verticalCenter
        }

        StyledText {
            id: content

            anchors.left: icon.right
            anchors.leftMargin: Tokens.spacing.large
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

            text: root.modelData?.content ?? ""
            font.pointSize: Tokens.font.size.normal
            elide: Text.ElideRight
            maximumLineCount: 1
        }
    }
}
