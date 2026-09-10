pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Desktop battery")
    isSubPage: true

    readonly property list<MenuItem> styleItems: [
        MenuItem { text: qsTr("Vertical tank"); property int value: 0 },
        MenuItem { text: qsTr("Horizontal fill"); property int value: 1 },
        MenuItem { text: qsTr("Circular progress"); property int value: 2 }
    ]

    function itemForStyle(val: int): MenuItem {
        for (let i = 0; i < styleItems.length; i++) {
            if (styleItems[i].value === val)
                return styleItems[i];
        }
        return styleItems[0];
    }

    readonly property list<MenuItem> waveStyleItems: [
        MenuItem { text: qsTr("Liquid wave"); property int value: 0 },
        MenuItem { text: qsTr("Shimmer"); property int value: 1 },
        MenuItem { text: qsTr("Both"); property int value: 2 }
    ]

    readonly property list<MenuItem> randomTriggerItems: [
        MenuItem { text: qsTr("Plug in"); property int value: 0 },
        MenuItem { text: qsTr("Timer"); property int value: 1 },
        MenuItem { text: qsTr("Both"); property int value: 2 }
    ]

    function itemForRandomTrigger(val: int): MenuItem {
        for (let i = 0; i < randomTriggerItems.length; i++) {
            if (randomTriggerItems[i].value === val)
                return randomTriggerItems[i];
        }
        return randomTriggerItems[2];
    }

    readonly property list<MenuItem> boltStrengthItems: [
        MenuItem { text: qsTr("Subtle"); property int value: 0 },
        MenuItem { text: qsTr("Clear"); property int value: 1 },
        MenuItem { text: qsTr("Strong"); property int value: 2 }
    ]

    function itemForBoltStrength(val: int): MenuItem {
        for (let i = 0; i < boltStrengthItems.length; i++) {
            if (boltStrengthItems[i].value === val)
                return boltStrengthItems[i];
        }
        return boltStrengthItems[1];
    }

    function itemForWaveStyle(val: int): MenuItem {
        for (let i = 0; i < waveStyleItems.length; i++) {
            if (waveStyleItems[i].value === val)
                return waveStyleItems[i];
        }
        return waveStyleItems[0];
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SettingsSection {
            first: true
            expanded: true
            title: qsTr("General")

            ToggleRow {
                Layout.fillWidth: true
                first: true
                last: true
                text: qsTr("Enabled")
                subtext: qsTr("Show a battery widget on the desktop")
                checked: Config.background.desktopBattery.enabled
                onToggled: GlobalConfig.background.desktopBattery.enabled = checked
            }
        }

        SettingsSection {
            title: qsTr("Position")

            ConnectedRect {
                Layout.fillWidth: true
                first: true
                implicitHeight: pickerLayout.implicitHeight + pickerLayout.anchors.margins * 2

                ColumnLayout {
                    id: pickerLayout

                    anchors.fill: parent
                    anchors.margins: Tokens.padding.largeIncreased
                    spacing: Tokens.spacing.small

                    StyledText {
                        text: qsTr("Screen corner")
                        font: Tokens.font.body.small
                    }

                    PositionPicker {
                        Layout.alignment: Qt.AlignHCenter
                        value: Config.background.desktopBattery.position
                        onSelected: pos => GlobalConfig.background.desktopBattery.position = pos
                    }
                }
            }

            StepperRow {
                Layout.fillWidth: true
                last: true
                label: qsTr("Scale")
                subtext: qsTr("Size multiplier for the battery widget")
                value: Config.background.desktopBattery.scale
                from: 0.5
                to: 3.0
                stepSize: 0.1
                onMoved: v => GlobalConfig.background.desktopBattery.scale = v
            }
        }

        SettingsSection {
            title: qsTr("Style")

            SelectRow {
                Layout.fillWidth: true
                first: true
                last: true
                label: qsTr("Icon style")
                subtext: qsTr("Choose battery visualization")
                menuItems: root.styleItems
                active: root.itemForStyle(Config.background.desktopBattery.style)
                onSelected: item => GlobalConfig.background.desktopBattery.style = item.value
            }
        }

        SettingsSection {
            title: qsTr("Wave")

            ToggleRow {
                Layout.fillWidth: true
                first: true
                text: qsTr("Wavy fill")
                subtext: qsTr("Animate the fill surface as a travelling wave")
                checked: Config.background.desktopBattery.wavy
                onToggled: GlobalConfig.background.desktopBattery.wavy = checked
            }

            ToggleRow {
                Layout.fillWidth: true
                last: !waveShapeRow.visible
                text: qsTr("Animate only while charging")
                subtext: qsTr("Freeze the wave when running on battery")
                checked: Config.background.desktopBattery.waveOnlyWhenCharging
                onToggled: GlobalConfig.background.desktopBattery.waveOnlyWhenCharging = checked
            }

            SelectRow {
                id: waveShapeRow

                Layout.fillWidth: true
                last: true
                visible: Config.background.desktopBattery.style !== 2
                label: qsTr("Animation")
                subtext: qsTr("How the fill animates")
                menuItems: root.waveStyleItems
                active: root.itemForWaveStyle(Config.background.desktopBattery.waveStyle)
                onSelected: item => GlobalConfig.background.desktopBattery.waveStyle = item.value
            }
        }

        SettingsSection {
            title: qsTr("Charging")

            ToggleRow {
                Layout.fillWidth: true
                first: true
                text: qsTr("Pulsing bolt")
                subtext: qsTr("Beat the charging bolt while plugged in")
                checked: Config.background.desktopBattery.chargingBoltPulse
                onToggled: GlobalConfig.background.desktopBattery.chargingBoltPulse = checked
            }

            SelectRow {
                Layout.fillWidth: true
                visible: Config.background.desktopBattery.chargingBoltPulse
                label: qsTr("Pulse strength")
                subtext: qsTr("How hard the bolt beats")
                menuItems: root.boltStrengthItems
                active: root.itemForBoltStrength(Config.background.desktopBattery.chargingBoltPulseStrength)
                onSelected: item => GlobalConfig.background.desktopBattery.chargingBoltPulseStrength = item.value
            }

            ToggleRow {
                Layout.fillWidth: true
                text: qsTr("Energised wave")
                subtext: qsTr("Run the wave faster and taller while charging")
                checked: Config.background.desktopBattery.chargingEnergisedWave
                onToggled: GlobalConfig.background.desktopBattery.chargingEnergisedWave = checked
            }

            ToggleRow {
                Layout.fillWidth: true
                text: qsTr("Breathing glow")
                subtext: qsTr("Gently brighten and dim the fill")
                checked: Config.background.desktopBattery.chargingGlow
                onToggled: GlobalConfig.background.desktopBattery.chargingGlow = checked
            }

            ToggleRow {
                id: bubblesRow

                Layout.fillWidth: true
                visible: Config.background.desktopBattery.style !== 2
                text: qsTr("Rising bubbles")
                subtext: qsTr("Float bubbles up through the fill")
                checked: Config.background.desktopBattery.chargingBubbles
                onToggled: GlobalConfig.background.desktopBattery.chargingBubbles = checked
            }

            ToggleRow {
                Layout.fillWidth: true
                last: !randomTriggerRow.visible
                text: qsTr("Randomise")
                subtext: qsTr("Play a random one or two of the enabled effects instead of all of them")
                checked: Config.background.desktopBattery.chargingRandom
                onToggled: GlobalConfig.background.desktopBattery.chargingRandom = checked
            }

            SelectRow {
                id: randomTriggerRow

                Layout.fillWidth: true
                last: !randomIntervalRow.visible
                visible: Config.background.desktopBattery.chargingRandom
                label: qsTr("Change on")
                subtext: qsTr("When to pick a new set of effects")
                menuItems: root.randomTriggerItems
                active: root.itemForRandomTrigger(Config.background.desktopBattery.chargingRandomTrigger)
                onSelected: item => GlobalConfig.background.desktopBattery.chargingRandomTrigger = item.value
            }

            StepperRow {
                id: randomIntervalRow

                Layout.fillWidth: true
                last: true
                visible: Config.background.desktopBattery.chargingRandom && Config.background.desktopBattery.chargingRandomTrigger !== 0
                label: qsTr("Interval")
                subtext: qsTr("Seconds between changes")
                value: Config.background.desktopBattery.chargingRandomInterval
                from: 5
                to: 300
                stepSize: 5
                onMoved: v => GlobalConfig.background.desktopBattery.chargingRandomInterval = v
            }
        }

        SettingsSection {
            title: qsTr("Appearance")

            ToggleRow {
                Layout.fillWidth: true
                first: true
                last: true
                text: qsTr("Invert colours")
                subtext: qsTr("Swap light and dark colour roles")
                checked: Config.background.desktopBattery.invertColors
                onToggled: GlobalConfig.background.desktopBattery.invertColors = checked
            }
        }

        SettingsSection {
            title: qsTr("Background")

            ToggleRow {
                Layout.fillWidth: true
                first: true
                text: qsTr("Enabled")
                subtext: qsTr("Show a surface behind the battery")
                checked: Config.background.desktopBattery.background.enabled
                onToggled: GlobalConfig.background.desktopBattery.background.enabled = checked
            }

            SliderRow {
                Layout.fillWidth: true
                icon: "opacity"
                label: qsTr("Opacity")
                valueLabel: Math.round(Config.background.desktopBattery.background.opacity * 100) + "%"
                value: Config.background.desktopBattery.background.opacity
                onMoved: v => GlobalConfig.background.desktopBattery.background.opacity = v
            }

            ToggleRow {
                Layout.fillWidth: true
                last: true
                text: qsTr("Blur")
                subtext: qsTr("Blur the wallpaper behind the background")
                checked: Config.background.desktopBattery.background.blur
                onToggled: GlobalConfig.background.desktopBattery.background.blur = checked
            }
        }

        SettingsSection {
            title: qsTr("Shadow")

            ToggleRow {
                Layout.fillWidth: true
                first: true
                text: qsTr("Enabled")
                checked: Config.background.desktopBattery.shadow.enabled
                onToggled: GlobalConfig.background.desktopBattery.shadow.enabled = checked
            }

            SliderRow {
                Layout.fillWidth: true
                icon: "opacity"
                label: qsTr("Opacity")
                valueLabel: Math.round(Config.background.desktopBattery.shadow.opacity * 100) + "%"
                value: Config.background.desktopBattery.shadow.opacity
                onMoved: v => GlobalConfig.background.desktopBattery.shadow.opacity = v
            }

            StepperRow {
                Layout.fillWidth: true
                last: true
                label: qsTr("Blur")
                subtext: qsTr("Shadow spread amount")
                value: Config.background.desktopBattery.shadow.blur
                from: 0
                to: 1
                stepSize: 0.05
                onMoved: v => GlobalConfig.background.desktopBattery.shadow.blur = v
            }
        }

        SettingsSection {
            title: qsTr("Interaction")

            ToggleRow {
                Layout.fillWidth: true
                first: true
                text: qsTr("Hover effect")
                subtext: qsTr("Scale up when hovering over the widget")
                checked: Config.background.desktopBattery.hoverEnabled
                onToggled: GlobalConfig.background.desktopBattery.hoverEnabled = checked
            }

            StepperRow {
                Layout.fillWidth: true
                last: true
                label: qsTr("Hover scale")
                subtext: qsTr("Scale multiplier on hover")
                value: Config.background.desktopBattery.hoverScale
                from: 1.0
                to: 2.0
                stepSize: 0.05
                onMoved: v => GlobalConfig.background.desktopBattery.hoverScale = v
            }

            SelectRow {
                Layout.fillWidth: true
                last: true
                label: qsTr("Click action")
                subtext: qsTr("What happens when clicking the widget")
                active: root.itemForClickAction(Config.background.desktopBattery.clickAction)
                menuItems: root.clickActionMenuItems
                onSelected: item => GlobalConfig.background.desktopBattery.clickAction = item.value
            }
        }
    }

    readonly property list<MenuItem> clickActionMenuItems: [
        MenuItem { text: qsTr("Open Nexus"); icon: "settings"; property string value: "nexus" },
        MenuItem { text: qsTr("Open Battery"); icon: "battery_std"; property string value: "nexus/battery" },
        MenuItem { text: qsTr("Open Desktop"); icon: "desktop_windows"; property string value: "nexus/desktop" },
        MenuItem { text: qsTr("Open Animation"); icon: "animation"; property string value: "nexus/animation" },
        MenuItem { text: qsTr("Open Power & screen"); icon: "power_settings_new"; property string value: "nexus/power" },
        MenuItem { text: qsTr("Open Wallpaper & style"); icon: "palette"; property string value: "nexus/appearance" },
        MenuItem { text: qsTr("Open Network"); icon: "wifi"; property string value: "nexus/network" },
        MenuItem { text: qsTr("Open Audio"); icon: "volume_up"; property string value: "nexus/audio" },
        MenuItem { text: qsTr("Open Connected devices"); icon: "devices_other"; property string value: "nexus/devices" },
        MenuItem { text: qsTr("Open Updates"); icon: "update"; property string value: "nexus/updates" },
        MenuItem { text: qsTr("Open Plugins"); icon: "extension"; property string value: "nexus/plugins" },
        MenuItem { text: qsTr("Open Keybindings"); icon: "keyboard"; property string value: "nexus/keybindings" },
        MenuItem { text: qsTr("Open Panels"); icon: "dock_to_bottom"; property string value: "nexus/panels" },
        MenuItem { text: qsTr("Open Lock screen"); icon: "lock"; property string value: "nexus/lockscreen" },
        MenuItem { text: qsTr("Open Services"); icon: "build"; property string value: "nexus/services" },
        MenuItem { text: qsTr("Open Hyprland"); icon: "tune"; property string value: "nexus/hyprland" },
        MenuItem { text: qsTr("Open Language & region"); icon: "globe"; property string value: "nexus/language" },
        MenuItem { text: qsTr("Open About"); icon: "info"; property string value: "nexus/about" }
    ]

    function itemForClickAction(val: string): MenuItem {
        for (let i = 0; i < clickActionMenuItems.length; i++) {
            if (clickActionMenuItems[i].value === val)
                return clickActionMenuItems[i];
        }
        return clickActionMenuItems[0];
    }
}
