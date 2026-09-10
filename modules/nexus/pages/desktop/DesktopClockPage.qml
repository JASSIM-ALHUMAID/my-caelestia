pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Desktop clock")
    isSubPage: true

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
                subtext: qsTr("Show a clock widget on the desktop")
                checked: Config.background.desktopClock.enabled
                onToggled: GlobalConfig.background.desktopClock.enabled = checked
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
                        value: Config.background.desktopClock.position
                        onSelected: pos => GlobalConfig.background.desktopClock.position = pos
                    }
                }
            }

            StepperRow {
                Layout.fillWidth: true
                last: true
                label: qsTr("Scale")
                subtext: qsTr("Size multiplier for the clock widget")
                value: Config.background.desktopClock.scale
                from: 0.5
                to: 3.0
                stepSize: 0.1
                onMoved: v => GlobalConfig.background.desktopClock.scale = v
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
                checked: Config.background.desktopClock.invertColors
                onToggled: GlobalConfig.background.desktopClock.invertColors = checked
            }
        }

        SettingsSection {
            title: qsTr("Background")

            ToggleRow {
                Layout.fillWidth: true
                first: true
                text: qsTr("Enabled")
                subtext: qsTr("Show a surface behind the clock")
                checked: Config.background.desktopClock.background.enabled
                onToggled: GlobalConfig.background.desktopClock.background.enabled = checked
            }

            SliderRow {
                Layout.fillWidth: true
                icon: "opacity"
                label: qsTr("Opacity")
                valueLabel: Math.round(Config.background.desktopClock.background.opacity * 100) + "%"
                value: Config.background.desktopClock.background.opacity
                onMoved: v => GlobalConfig.background.desktopClock.background.opacity = v
            }

            ToggleRow {
                Layout.fillWidth: true
                last: true
                text: qsTr("Blur")
                subtext: qsTr("Blur the wallpaper behind the background")
                checked: Config.background.desktopClock.background.blur
                onToggled: GlobalConfig.background.desktopClock.background.blur = checked
            }
        }

        SettingsSection {
            title: qsTr("Shadow")

            ToggleRow {
                Layout.fillWidth: true
                first: true
                text: qsTr("Enabled")
                checked: Config.background.desktopClock.shadow.enabled
                onToggled: GlobalConfig.background.desktopClock.shadow.enabled = checked
            }

            SliderRow {
                Layout.fillWidth: true
                icon: "opacity"
                label: qsTr("Opacity")
                valueLabel: Math.round(Config.background.desktopClock.shadow.opacity * 100) + "%"
                value: Config.background.desktopClock.shadow.opacity
                onMoved: v => GlobalConfig.background.desktopClock.shadow.opacity = v
            }

            StepperRow {
                Layout.fillWidth: true
                last: true
                label: qsTr("Blur")
                subtext: qsTr("Shadow spread amount")
                value: Config.background.desktopClock.shadow.blur
                from: 0
                to: 1
                stepSize: 0.05
                onMoved: v => GlobalConfig.background.desktopClock.shadow.blur = v
            }
        }

        SettingsSection {
            title: qsTr("Interaction")

            SelectRow {
                Layout.fillWidth: true
                first: true
                label: qsTr("Click action")
                subtext: qsTr("What happens when clicking the widget")
                menuItems: root.clickActionItems
                active: root.activeClickAction
                onSelected: item => GlobalConfig.background.desktopClock.clickAction = item.value
            }

            ToggleRow {
                Layout.fillWidth: true
                text: qsTr("Hover effect")
                subtext: qsTr("Scale up when hovering over the widget")
                checked: Config.background.desktopClock.hoverEnabled
                onToggled: GlobalConfig.background.desktopClock.hoverEnabled = checked
            }

            StepperRow {
                Layout.fillWidth: true
                last: true
                label: qsTr("Hover scale")
                subtext: qsTr("Scale multiplier on hover")
                value: Config.background.desktopClock.hoverScale
                from: 1.0
                to: 2.0
                stepSize: 0.05
                onMoved: v => GlobalConfig.background.desktopClock.hoverScale = v
            }
        }
    }

    readonly property list<MenuItem> clickActionItems: [
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

    readonly property MenuItem activeClickAction: {
        for (const item of root.clickActionItems)
            if (item.value === Config.background.desktopClock.clickAction) return item;
        return root.clickActionItems[0];
    }
}
