pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell.Services.UPower
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.nexus
import qs.modules.nexus.pages.battery

Item {
    id: root

    required property Item wallpaper
    required property real absX
    required property real absY

    property real batteryScale: Config.background.desktopBattery.scale
    readonly property bool bgEnabled: Config.background.desktopBattery.background.enabled
    readonly property bool blurEnabled: bgEnabled && Config.background.desktopBattery.background.blur && !GameMode.enabled
    readonly property bool invertColors: Config.background.desktopBattery.invertColors
    readonly property bool useLightSet: Colours.light ? !invertColors : invertColors
    readonly property color safeFill: useLightSet ? Colours.palette.m3primaryContainer : Colours.palette.m3primary
    readonly property color safeOnFill: useLightSet ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onPrimary
    readonly property real percentage: UPower.displayDevice.percentage * 100
    readonly property bool charging: [UPowerDeviceState.Charging, UPowerDeviceState.FullyCharged, UPowerDeviceState.PendingCharge].includes(UPower.displayDevice.state)
    readonly property int batteryStyle: Config.background.desktopBattery.style

    // Interaction config
    readonly property bool hoverEnabled: Config.background.desktopBattery.hoverEnabled
    readonly property real hoverScale: Config.background.desktopBattery.hoverScale
    readonly property string clickAction: Config.background.desktopBattery.clickAction

    // Indices come from PageCompRegistry, never a local copy — a duplicated map here silently
    // drifted two entries behind the registry and sent every click to the wrong page
    function getPageIndex(pageName: string): int {
        return PageCompRegistry.topLevelPages[pageName] ?? -1;
    }

    readonly property real baseSize: batteryStyle === 1 ? 240 : 180
    readonly property real baseHeight: batteryStyle === 1 ? 120 : 220

    implicitWidth: baseSize * root.batteryScale + (Tokens.padding.large * 4 * root.batteryScale)
    implicitHeight: baseHeight * root.batteryScale + (Tokens.padding.extraLargeIncreased * root.batteryScale)

    // Hover state
    property bool isHovered: false
    property real currentScale: isHovered && hoverEnabled ? hoverScale : 1.0

    Item {
        id: batteryContainer

        anchors.fill: parent
        scale: root.currentScale

        layer.enabled: Config.background.desktopBattery.shadow.enabled
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Colours.palette.m3shadow
            shadowOpacity: Config.background.desktopBattery.shadow.opacity
            shadowBlur: Config.background.desktopBattery.shadow.blur
        }

        Loader {
            asynchronous: true
            anchors.fill: parent
            active: root.blurEnabled

            sourceComponent: MultiEffect {
                source: ShaderEffectSource {
                    sourceItem: root.wallpaper
                    sourceRect: Qt.rect(root.absX, root.absY, root.width, root.height)
                }
                maskSource: backgroundPlate
                maskEnabled: true
                blurEnabled: true
                blur: 1
                blurMax: 64
                autoPaddingEnabled: false
            }
        }

        StyledRect {
            id: backgroundPlate

            visible: root.bgEnabled
            anchors.fill: parent
            radius: Tokens.rounding.extraLarge * root.batteryScale
            opacity: Config.background.desktopBattery.background.opacity
            color: Colours.palette.m3surface

            layer.enabled: root.blurEnabled
        }

        BatteryIcon {
            anchors.centerIn: parent
            width: root.baseSize * root.batteryScale
            height: root.baseHeight * root.batteryScale
            percentage: root.percentage
            charging: root.charging
            style: root.batteryStyle
            trackColor: Colours.palette.m3secondaryContainer
            onTrackColor: Colours.palette.m3onSecondaryContainer
            fillColor: root.safeFill
            onFillColor: root.safeOnFill
            labelColor: Colours.palette.m3onSurface // circular style sits on the plate
            wavy: Config.background.desktopBattery.wavy
            waveStyle: Config.background.desktopBattery.waveStyle
            wavePaused: Config.background.desktopBattery.waveOnlyWhenCharging && !root.charging
            boltPulse: Config.background.desktopBattery.chargingBoltPulse
            boltPulseStrength: Config.background.desktopBattery.chargingBoltPulseStrength
            energisedWave: Config.background.desktopBattery.chargingEnergisedWave
            glow: Config.background.desktopBattery.chargingGlow
            bubbles: Config.background.desktopBattery.chargingBubbles
            randomise: Config.background.desktopBattery.chargingRandom
            randomTrigger: Config.background.desktopBattery.chargingRandomTrigger
            randomInterval: Config.background.desktopBattery.chargingRandomInterval
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: root.hoverEnabled

            onEntered: root.isHovered = true
            onExited: root.isHovered = false
            onClicked: {
                if (root.clickAction === "nexus") {
                    WindowFactory.create();
                } else if (root.clickAction.startsWith("nexus/")) {
                    const pageName = root.clickAction.split("/")[1];
                    const idx = root.getPageIndex(pageName);
                    if (idx >= 0)
                        WindowFactory.create(undefined, {}, idx);
                }
            }
        }
    }

    Behavior on batteryScale {
        Anim {}
    }

    Behavior on currentScale {
        Anim {
            type: Anim.FastSpatial
        }
    }

    Behavior on implicitWidth {
        Anim {
            type: Anim.StandardSmall
        }
    }

    Behavior on implicitHeight {
        Anim {
            type: Anim.StandardSmall
        }
    }
}
