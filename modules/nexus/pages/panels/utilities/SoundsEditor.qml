import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Sounds")
    isSubPage: true

    Component.onCompleted: Sounds.loadAvailable()

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("General")
        }

        ToggleRow {
            Layout.fillWidth: true
            first: true
            text: qsTr("Enabled")
            subtext: qsTr("Play a sound on shell events. Individual events can still be silenced below")
            checked: Config.utilities.sounds.enabled
            onToggled: GlobalConfig.utilities.sounds.enabled = checked
        }

        StepperRow {
            Layout.fillWidth: true
            last: true
            label: qsTr("Minimum gap")
            subtext: qsTr("Shortest time between two of the same sound, so a held volume key does not stutter")
            value: Config.utilities.sounds.throttleMs
            from: 0
            to: 1000
            stepSize: 50
            onMoved: v => GlobalConfig.utilities.sounds.throttleMs = v
        }

        SectionHeader {
            text: qsTr("Events")
        }

        SoundRow {
            Layout.fillWidth: true
            first: true
            label: qsTr("Charger plugged in")
            subtext: qsTr("When the power supply is connected")
            value: Config.utilities.sounds.chargerPlugged
            onPicked: name => GlobalConfig.utilities.sounds.chargerPlugged = name
        }

        SoundRow {
            Layout.fillWidth: true
            label: qsTr("Charger unplugged")
            subtext: qsTr("When the power supply is removed")
            value: Config.utilities.sounds.chargerUnplugged
            onPicked: name => GlobalConfig.utilities.sounds.chargerUnplugged = name
        }

        SoundRow {
            Layout.fillWidth: true
            label: qsTr("Service enabled")
            subtext: qsTr("Game mode, night light, VPN, do not disturb or idle inhibit turning on")
            value: Config.utilities.sounds.serviceOn
            onPicked: name => GlobalConfig.utilities.sounds.serviceOn = name
        }

        SoundRow {
            Layout.fillWidth: true
            label: qsTr("Service disabled")
            subtext: qsTr("The same services turning off")
            value: Config.utilities.sounds.serviceOff
            onPicked: name => GlobalConfig.utilities.sounds.serviceOff = name
        }

        SoundRow {
            Layout.fillWidth: true
            label: qsTr("Shell startup")
            subtext: qsTr("Once when the shell process starts, not on a config reload")
            value: Config.utilities.sounds.startup
            onPicked: name => GlobalConfig.utilities.sounds.startup = name
        }

        SoundRow {
            Layout.fillWidth: true
            label: qsTr("Volume change")
            subtext: qsTr("Each volume step, rate-limited by the gap above")
            value: Config.utilities.sounds.volumeChange
            onPicked: name => GlobalConfig.utilities.sounds.volumeChange = name
        }

        SoundRow {
            Layout.fillWidth: true
            last: true
            label: qsTr("Brightness change")
            subtext: qsTr("Each brightness step. No sound is set by default")
            value: Config.utilities.sounds.brightnessChange
            onPicked: name => GlobalConfig.utilities.sounds.brightnessChange = name
        }
    }

    // One picker per event, each with its own Variants rather than a shared list: SelectRow renders
    // the MenuItem instances it is handed, and two menus cannot own the same ones.
    component SoundRow: SelectRow {
        id: soundRow

        required property string value

        signal picked(name: string)

        menuItems: soundVariants.instances
        // Matched on modelData, not text, so the translated "None" label never round-trips back
        // into config.
        active: soundVariants.instances.find(i => i.modelData === soundRow.value) ?? null

        // Covers a configured value that is a file path, or a name not installed here: it still
        // has to display rather than read as empty.
        fallbackIcon: "volume_off"
        fallbackText: soundRow.value || qsTr("None")

        // Auditioning on selection is the point of the page — it is how you find out what a name
        // sounds like without leaving it. preview() bypasses the master switch, which may well
        // still be off at this moment.
        onSelected: item => {
            soundRow.picked(item.modelData);
            Sounds.preview(item.modelData);
        }

        Variants {
            id: soundVariants

            model: ["", ...Sounds.available]

            MenuItem {
                required property string modelData

                text: modelData === "" ? qsTr("None") : modelData
                activeIcon: "volume_up"
            }
        }
    }
}
