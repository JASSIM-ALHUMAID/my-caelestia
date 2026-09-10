import QtQuick
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    implicitWidth: icon.implicitHeight + Tokens.padding.small
    implicitHeight: icon.implicitHeight

    StateLayer {
        // Cursed workaround to make the height larger than the parent
        anchors.fill: undefined
        anchors.centerIn: parent

        implicitWidth: implicitHeight
        implicitHeight: icon.implicitHeight + Tokens.padding.small

        radius: Tokens.rounding.full
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        // Hovering opens the picker popout, so a click is the coarse control: forwards on
        // left, backwards on right.
        onClicked: event => {
            HyprLayout.cycle(event.button === Qt.RightButton ? -1 : 1);
            bounceAnim.restart();
        }
    }

    MaterialIcon {
        id: icon

        anchors.centerIn: parent

        text: HyprLayout.iconFor(HyprLayout.current)
        fontStyle: Tokens.font.icon.builders.small.weight(Font.Bold).build()

        SequentialAnimation {
            id: bounceAnim

            Anim {
                target: icon
                property: "scale"
                to: 0.7
                type: Anim.FastEffects
            }
            Anim {
                target: icon
                property: "scale"
                to: 1
                type: Anim.DefaultSpatial
            }
        }
    }
}
