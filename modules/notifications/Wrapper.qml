import QtQuick
import Caelestia.Config
import qs.components

Item {
    id: root

    required property DrawerVisibilities visibilities
    required property Item sidebarPanel
    property alias osdPanel: content.osdPanel
    property alias sessionPanel: content.sessionPanel
    property alias utilitiesPanel: content.utilitiesPanel
    readonly property bool floating: Config.notifs.popoutMode === "floating"
    readonly property int edgeGap: floating ? Math.max(0, Config.notifs.popoutGap) : 0

    visible: height > 0
    implicitWidth: Math.max(sidebarPanel.width, content.implicitWidth)
    implicitHeight: content.implicitHeight

    function closeGrace(): void {
        graceTimer.restart();
    }

    function cancelClose(): void {
        graceTimer.stop();
    }

    Timer {
        id: graceTimer

        interval: Config.notifs.hoverGrace
        onTriggered: root.content?.restartAllTimers()
    }

    Connections {
        target: content

        function onCloseGraceRequested(): void {
            root.closeGrace();
        }

        function onPopoutOpened(): void {
            root.cancelClose();
            content.stopAllTimers();
        }
    }

    Content {
        id: content

        visibilities: root.visibilities
        edgeGap: root.edgeGap
    }
}
