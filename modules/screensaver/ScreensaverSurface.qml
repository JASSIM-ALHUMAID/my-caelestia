pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

PanelWindow {
    id: root

    required property bool active
    required property string effectId

    WlrLayershell.namespace: "caelestia-screensaver"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    color: "transparent"
    surfaceFormat.opaque: true

    visible: root.active && !Visibilities.sessionLocked
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    ScreensaverContent {
        anchors.fill: parent

        active: root.active && !Visibilities.sessionLocked
        effectId: root.effectId
        captureKeyboard: true
        onDismissRequested: Screensaver.hide()
    }
}
