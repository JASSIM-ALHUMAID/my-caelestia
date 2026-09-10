pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.screensaver.effects

Item {
    id: root

    required property bool active
    required property string effectId
    property bool captureKeyboard: true

    signal dismissRequested()

    visible: active

    Rectangle {
        anchors.fill: parent

        color: Colours.palette.m3surfaceContainerLowest
    }

    // Unloaded once the outputs are blanked. The screensaver stays logically active -- waking
    // still runs through the idle monitor -- but there is no point animating, and EffectVideo
    // would otherwise keep decoding a video into a dark screen for as long as the machine sits
    // idle. Screen-off happens well after the screensaver appears, so this only ever tears down
    // something already invisible.
    Loader {
        anchors.fill: parent
        active: root.active && !Hypr.screensOff
        sourceComponent: registry.pick(root.effectId).component
    }

    Effects {
        id: registry
    }

    Item {
        anchors.fill: parent
        focus: root.active && root.captureKeyboard

        Keys.onPressed: event => {
            event.accepted = true;
            root.dismissRequested();
        }
    }

    MouseArea {
        id: wakeArea

        // Moving the mouse should wake the screensaver, not just clicking it. Un-idling the
        // compositor already hides it, but that waits out the idle monitor's own reporting,
        // which reads as a lag between the first nudge and the screen coming back.
        //
        // Mapping this surface under the cursor delivers an enter/motion event that is not the
        // user moving anything, so the first position seen becomes the origin and the cursor
        // has to travel a few pixels from it before that counts as activity.
        property real originX: -1
        property real originY: -1
        readonly property int slack: 8

        anchors.fill: parent
        enabled: root.active
        hoverEnabled: root.active

        onEnabledChanged: {
            originX = -1;
            originY = -1;
        }

        onPositionChanged: mouse => {
            if (originX < 0) {
                originX = mouse.x;
                originY = mouse.y;
                return;
            }

            if (Math.abs(mouse.x - originX) >= slack || Math.abs(mouse.y - originY) >= slack)
                root.dismissRequested();
        }

        onClicked: mouse => {
            mouse.accepted = true;
            root.dismissRequested();
        }
    }
}
