pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils

Item {
    id: root

    required property Brightness.Monitor monitor
    required property DrawerVisibilities visibilities

    required property real volume
    required property bool muted
    required property real sourceVolume
    required property bool sourceMuted
    required property real brightness

    // The OSD lays its sliders out across the edge it hugs: stacked vertically on the left
    // and right, side by side along the top and bottom.
    readonly property string position: Config.osd.position
    readonly property bool isVertical: position === "left" || position === "right"
    readonly property int sliderLength: Tokens.sizes.osd.sliderHeight
    readonly property int sliderThickness: Tokens.sizes.osd.sliderWidth

    // The window border eats into the padding on the docked edge, so pad that side less and
    // nudge the contents away from it.
    readonly property real edgeCompensation: CUtils.clamp(Tokens.padding.large - Config.border.thickness, 0, Tokens.padding.large) / 2
    readonly property real edgeShift: position === "left" || position === "top" ? edgeCompensation : -edgeCompensation

    implicitWidth: layout.implicitWidth + (isVertical ? Tokens.padding.large + edgeCompensation * 2 : Tokens.padding.large * 2)
    implicitHeight: layout.implicitHeight + (isVertical ? Tokens.padding.large * 2 : Tokens.padding.large + edgeCompensation * 2)

    GridLayout {
        id: layout

        anchors.centerIn: parent
        anchors.horizontalCenterOffset: root.isVertical ? root.edgeShift : 0
        anchors.verticalCenterOffset: root.isVertical ? 0 : root.edgeShift

        // One column when stacked, one row when laid out along a horizontal edge. The count is
        // the fixed number of sliders rather than children.length: `children` doesn't notify,
        // so that binding kept an early value of 0 and collapsed the layout to zero width.
        columns: root.isVertical ? 1 : 3
        rowSpacing: Tokens.spacing.medium
        columnSpacing: Tokens.spacing.medium

        // Speaker volume
        CustomMouseArea {
            function onWheel(event: WheelEvent) {
                if (event.angleDelta.y > 0)
                    Audio.incrementVolume();
                else if (event.angleDelta.y < 0)
                    Audio.decrementVolume();
            }

            implicitWidth: root.isVertical ? root.sliderThickness : root.sliderLength
            implicitHeight: root.isVertical ? root.sliderLength : root.sliderThickness

            FilledSlider {
                anchors.fill: parent

                orientation: root.isVertical ? Qt.Vertical : Qt.Horizontal
                icon: Icons.getVolumeIcon(value, root.muted)
                value: root.volume
                to: GlobalConfig.services.maxVolume
                onMoved: Audio.setVolume(value)
            }
        }

        // Microphone volume. Dropped to make room for brightness when the session menu is
        // sharing the OSD's edge and squeezing it, but not when they're on different edges.
        WrappedLoader {
            shouldBeActive: Config.osd.enableMicrophone && (!Config.osd.enableBrightness || !(root.visibilities.session && Config.session.position === root.position))

            sourceComponent: CustomMouseArea {
                function onWheel(event: WheelEvent) {
                    if (event.angleDelta.y > 0)
                        Audio.incrementSourceVolume();
                    else if (event.angleDelta.y < 0)
                        Audio.decrementSourceVolume();
                }

                implicitWidth: root.isVertical ? root.sliderThickness : root.sliderLength
                implicitHeight: root.isVertical ? root.sliderLength : root.sliderThickness

                FilledSlider {
                    anchors.fill: parent

                    orientation: root.isVertical ? Qt.Vertical : Qt.Horizontal
                    icon: Icons.getMicVolumeIcon(value, root.sourceMuted)
                    value: root.sourceVolume
                    to: GlobalConfig.services.maxVolume
                    onMoved: Audio.setSourceVolume(value)
                }
            }
        }

        // Brightness
        WrappedLoader {
            shouldBeActive: Config.osd.enableBrightness

            sourceComponent: CustomMouseArea {
                function onWheel(event: WheelEvent) {
                    const monitor = root.monitor;
                    if (!monitor)
                        return;
                    if (event.angleDelta.y > 0)
                        monitor.setBrightness(monitor.brightness + GlobalConfig.services.brightnessIncrement);
                    else if (event.angleDelta.y < 0)
                        monitor.setBrightness(monitor.brightness - GlobalConfig.services.brightnessIncrement);
                }

                implicitWidth: root.isVertical ? root.sliderThickness : root.sliderLength
                implicitHeight: root.isVertical ? root.sliderLength : root.sliderThickness

                FilledSlider {
                    anchors.fill: parent

                    orientation: root.isVertical ? Qt.Vertical : Qt.Horizontal
                    icon: `brightness_${(Math.round(value * 6) + 1)}`
                    value: root.brightness
                    onMoved: root.monitor?.setBrightness(value)
                }
            }
        }
    }

    // Collapses along the layout's main axis, so an optional slider slides out of the stack
    // vertically or out of the row horizontally, whichever way the OSD is laid out.
    component WrappedLoader: Loader {
        required property bool shouldBeActive
        property real extent: shouldBeActive ? root.sliderLength : 0

        asynchronous: true
        Layout.preferredHeight: root.isVertical ? extent : -1
        Layout.preferredWidth: root.isVertical ? -1 : extent
        opacity: shouldBeActive ? 1 : 0
        active: opacity > 0
        visible: active

        Behavior on extent {
            Anim {
                type: Anim.Emphasized
            }
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }
}
