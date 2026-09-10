pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Visualiser")
    isSubPage: true

    readonly property list<MenuItem> positionItems: [
        MenuItem { text: qsTr("Top"); property string value: "top" },
        MenuItem { text: qsTr("Bottom"); property string value: "bottom" },
        MenuItem { text: qsTr("Left"); property string value: "left" },
        MenuItem { text: qsTr("Right"); property string value: "right" },
    ]

    readonly property MenuItem activePositionItem: {
        for (const item of root.positionItems)
            if (item.value === Config.background.visualiser.position) return item;
        return root.positionItems[1];
    }

    readonly property list<MenuItem> styleItems: [
        MenuItem { text: qsTr("Bars"); property string value: "bars" },
        MenuItem { text: qsTr("Audio waveform"); property string value: "waveform" },
        MenuItem { text: qsTr("Traveling sine"); property string value: "sine" },
        MenuItem { text: qsTr("Smooth outline"); property string value: "outline" },
    ]

    readonly property MenuItem activeStyleItem: {
        for (const item of root.styleItems)
            if (item.value === Config.background.visualiser.style) return item;
        return root.styleItems[0];
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
            if (item.value === Config.background.visualiser.clickAction) return item;
        return root.clickActionItems[0];
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
                text: qsTr("Enabled")
                subtext: qsTr("Show the audio visualiser on the desktop")
                checked: Config.background.visualiser.enabled
                onToggled: GlobalConfig.background.visualiser.enabled = checked
            }

            ToggleRow {
                Layout.fillWidth: true
                last: true
                text: qsTr("Auto-hide")
                subtext: qsTr("Hide when non-floating windows are present")
                checked: Config.background.visualiser.autoHide
                onToggled: GlobalConfig.background.visualiser.autoHide = checked
            }
        }

        SettingsSection {
            title: qsTr("Interaction")

            SelectRow {
                Layout.fillWidth: true
                first: true
                last: true
                label: qsTr("Click action")
                subtext: qsTr("What happens when clicking the visualiser")
                menuItems: root.clickActionItems
                active: root.activeClickAction
                onSelected: item => GlobalConfig.background.visualiser.clickAction = item.value
            }
        }

        SettingsSection {
            title: qsTr("Appearance")

            ToggleRow {
                Layout.fillWidth: true
                first: true
                text: qsTr("Blur")
                subtext: qsTr("Blur the wallpaper behind the visualiser")
                checked: Config.background.visualiser.blur
                onToggled: GlobalConfig.background.visualiser.blur = checked
            }

            SelectRow {
                Layout.fillWidth: true
                label: qsTr("Position")
                subtext: qsTr("Which screen edge the visualiser grows from")
                menuItems: root.positionItems
                active: root.activePositionItem
                onSelected: item => GlobalConfig.background.visualiser.position = item.value
            }

            SelectRow {
                Layout.fillWidth: true
                label: qsTr("Style")
                subtext: qsTr("How the audio visualiser is drawn")
                menuItems: root.styleItems
                active: root.activeStyleItem
                onSelected: item => GlobalConfig.background.visualiser.style = item.value
            }

            StepperRow {
                Layout.fillWidth: true
                label: qsTr("Reach")
                subtext: qsTr("How far across the screen the visualiser can reach at full volume")
                value: Config.background.visualiser.reach
                from: 0.05
                to: 1
                stepSize: 0.05
                onMoved: v => GlobalConfig.background.visualiser.reach = v
            }

            StepperRow {
                Layout.fillWidth: true
                label: qsTr("Frequency bands")
                subtext: qsTr("Number of frequency bands sampled from the audio")
                value: GlobalConfig.services.visualiserBars
                from: 10
                to: 120
                stepSize: 2
                onMoved: v => GlobalConfig.services.visualiserBars = v
            }

            StepperRow {
                Layout.fillWidth: true
                visible: root.activeStyleItem.value !== "bars"
                label: qsTr("Wave thickness")
                subtext: qsTr("Width of waveform and outline strokes")
                value: Config.background.visualiser.thickness
                from: 2
                to: 24
                stepSize: 1
                onMoved: v => GlobalConfig.background.visualiser.thickness = v
            }

            StepperRow {
                Layout.fillWidth: true
                label: qsTr("Center gap")
                subtext: qsTr("Empty space between the two sides (%)")
                value: Math.round(Config.background.visualiser.centerGap * 100)
                from: 0
                to: 80
                stepSize: 5
                onMoved: v => GlobalConfig.background.visualiser.centerGap = v / 100
            }

            StepperRow {
                Layout.fillWidth: true
                visible: root.activeStyleItem.value === "bars"
                label: qsTr("Rounding")
                subtext: qsTr("Bar corner rounding multiplier")
                value: Config.background.visualiser.rounding
                from: 0
                to: 3
                stepSize: 0.1
                onMoved: v => GlobalConfig.background.visualiser.rounding = v
            }

            StepperRow {
                Layout.fillWidth: true
                visible: root.activeStyleItem.value === "bars"
                label: qsTr("Spacing")
                subtext: qsTr("Gap between bars multiplier")
                value: Config.background.visualiser.spacing
                from: 0
                to: 3
                stepSize: 0.1
                onMoved: v => GlobalConfig.background.visualiser.spacing = v
            }

            StepperRow {
                Layout.fillWidth: true
                last: true
                label: qsTr("Frequency tilt")
                subtext: qsTr("Boost highs (>0) or lows (<0). Applies to all visualisers.")
                value: GlobalConfig.services.visualiserTilt
                from: -1
                to: 1
                stepSize: 0.1
                onMoved: v => GlobalConfig.services.visualiserTilt = v
            }
        }
    }
}
