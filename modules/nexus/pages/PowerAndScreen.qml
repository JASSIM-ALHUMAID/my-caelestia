import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    readonly property list<MenuItem> timeoutItems: [
        MenuItem { text: qsTr("1 minute") },
        MenuItem { text: qsTr("3 minutes") },
        MenuItem { text: qsTr("5 minutes") },
        MenuItem { text: qsTr("10 minutes") },
        MenuItem { text: qsTr("15 minutes") },
        MenuItem { text: qsTr("30 minutes") },
        MenuItem { text: qsTr("Never") },
    ]
    readonly property list<int> timeoutValues: [60, 180, 300, 600, 900, 1800, 0]

    function timeoutToIndex(val: int): int {
        let best = 0;
        let bestDiff = Math.abs(root.timeoutValues[0] - val);
        for (let i = 1; i < root.timeoutValues.length; i++) {
            const diff = Math.abs(root.timeoutValues[i] - val);
            if (diff < bestDiff) {
                bestDiff = diff;
                best = i;
            }
        }
        return best;
    }

    title: qsTr("Power & screen")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Screen timeout
        SettingsSection {
            first: true
            expanded: true
            title: qsTr("Screen timeout")

            SelectRow {
                Layout.fillWidth: true
                first: true
                label: qsTr("Lock screen after")
                subtext: qsTr("Automatically lock the screen after inactivity")
                menuItems: root.timeoutItems
                active: root.timeoutItems[root.timeoutToIndex(GlobalConfig.general.idle.lockTimeout)]
                onSelected: item => GlobalConfig.general.idle.lockTimeout = root.timeoutValues[root.timeoutItems.indexOf(item)]
            }

            SelectRow {
                Layout.fillWidth: true
                label: qsTr("Turn off screen after")
                subtext: qsTr("Dim and turn off the display after inactivity")
                menuItems: root.timeoutItems
                active: root.timeoutItems[root.timeoutToIndex(GlobalConfig.general.idle.screenOffTimeout)]
                onSelected: item => GlobalConfig.general.idle.screenOffTimeout = root.timeoutValues[root.timeoutItems.indexOf(item)]
            }

            SelectRow {
                Layout.fillWidth: true
                last: true
                label: qsTr("Suspend after")
                subtext: qsTr("Put the system to sleep after extended inactivity")
                menuItems: root.timeoutItems
                active: root.timeoutItems[root.timeoutToIndex(GlobalConfig.general.idle.suspendTimeout)]
                onSelected: item => GlobalConfig.general.idle.suspendTimeout = root.timeoutValues[root.timeoutItems.indexOf(item)]
            }
        }

        // Power behavior
        SettingsSection {
            title: qsTr("Power behavior")

            ToggleRow {
                Layout.fillWidth: true
                first: true
                text: qsTr("Lock before sleep")
                subtext: qsTr("Lock the screen when the system suspends")
                checked: GlobalConfig.general.idle.lockBeforeSleep
                onToggled: GlobalConfig.general.idle.lockBeforeSleep = checked
            }

            ToggleRow {
                Layout.fillWidth: true
                text: qsTr("Inhibit when media playing")
                subtext: qsTr("Prevent screen off and suspend while audio is playing")
                checked: GlobalConfig.general.idle.inhibitWhenAudio
                onToggled: GlobalConfig.general.idle.inhibitWhenAudio = checked
            }

            ToggleRow {
                Layout.fillWidth: true
                last: true
                text: qsTr("Also delay locking when media playing")
                subtext: qsTr("Turn off to keep the auto-lock running while audio plays")
                checked: GlobalConfig.general.idle.inhibitLockWhenAudio
                onToggled: GlobalConfig.general.idle.inhibitLockWhenAudio = checked
            }
        }

        // Night light
        SettingsSection {
            title: qsTr("Night light")

            ToggleRow {
                Layout.fillWidth: true
                first: true
                text: qsTr("Night light")
                subtext: qsTr("Reduce blue light in the evening")
                checked: HyprSunset.enabled
                onToggled: GlobalConfig.utilities.hyprsunset.enabled = checked
            }

            SliderRow {
                Layout.fillWidth: true
                icon: "thermostat"
                label: qsTr("Colour temperature")
                valueLabel: qsTr("%1K").arg(Math.round(value))
                value: HyprSunset.temperature
                from: HyprSunset.minTemperature
                to: HyprSunset.maxTemperature
                wheelStep: 100
                enabled: HyprSunset.enabled
                onMoved: v => HyprSunset.setTemperature(v)
            }

            SliderRow {
                Layout.fillWidth: true
                icon: "brightness_6"
                label: qsTr("Gamma")
                valueLabel: qsTr("%1%").arg(Math.round(value))
                value: HyprSunset.gamma
                from: HyprSunset.minGamma
                to: HyprSunset.maxGamma
                wheelStep: 5
                enabled: HyprSunset.enabled
                onMoved: v => HyprSunset.setGamma(v)
            }

            ToggleRow {
                Layout.fillWidth: true
                text: qsTr("Automatic schedule")
                subtext: qsTr("Turn night light on and off at set times")
                checked: HyprSunset.automatic
                onToggled: GlobalConfig.utilities.hyprsunset.automatic = checked
            }

            TimePickerRow {
                Layout.fillWidth: true
                label: qsTr("From")
                subtext: qsTr("When night light turns on")
                enabled: HyprSunset.automatic
                time: GlobalConfig.utilities.hyprsunset.from
                onTimeModified: t => GlobalConfig.utilities.hyprsunset.from = t
            }

            TimePickerRow {
                Layout.fillWidth: true
                last: true
                label: qsTr("To")
                subtext: qsTr("When night light turns off")
                enabled: HyprSunset.automatic
                time: GlobalConfig.utilities.hyprsunset.to
                onTimeModified: t => GlobalConfig.utilities.hyprsunset.to = t
            }
        }
    }
}
