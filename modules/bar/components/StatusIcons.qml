pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import Caelestia.Config
import qs.components
import qs.services
import qs.utils

StyledRect {
    id: root

    required property var barConfig
    required property bool vertical
    property color colour: Colours.palette.m3secondary
    readonly property alias items: iconColumn

    // Main-axis slack reclaimed when the lock-status slot is shown but empty.
    readonly property real lockGap: root.barConfig.status.showLockStatus && !Hypr.capsLock && !Hypr.numLock ? iconColumn.spacing : 0

    color: Colours.tPalette.m3surfaceContainer
    radius: Tokens.rounding.full

    clip: true
    implicitWidth: root.vertical ? Tokens.sizes.bar.innerWidth : iconColumn.implicitWidth + Tokens.padding.medium * 2 - lockGap
    implicitHeight: root.vertical ? iconColumn.implicitHeight + Tokens.padding.medium * 2 - lockGap : Tokens.sizes.bar.innerWidth

    GridLayout {
        id: iconColumn

        flow: root.vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
        columns: root.vertical ? 1 : -1
        rows: root.vertical ? -1 : 1

        anchors.left: root.vertical ? parent.left : undefined
        anchors.right: parent.right
        anchors.top: root.vertical ? undefined : parent.top
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.vertical ? Tokens.padding.medium : 0
        anchors.rightMargin: root.vertical ? 0 : Tokens.padding.medium

        rowSpacing: Tokens.spacing.medium / 2
        columnSpacing: Tokens.spacing.medium / 2

        readonly property int spacing: Tokens.spacing.medium / 2

        // Lock keys status
        WrappedLoader {
            name: "lockstatus"
            active: root.barConfig.status.showLockStatus

            // Collapses along the bar's main axis, so an enabled-but-idle lock slot costs
            // nothing but the layout spacing `lockGap` above already subtracts.
            sourceComponent: GridLayout {
                flow: root.vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
                columns: root.vertical ? 1 : -1
                rows: root.vertical ? -1 : 1
                rowSpacing: 0
                columnSpacing: 0

                Item {
                    implicitWidth: root.vertical ? capslockIcon.implicitWidth : Hypr.capsLock ? capslockIcon.implicitWidth : 0
                    implicitHeight: root.vertical ? Hypr.capsLock ? capslockIcon.implicitHeight : 0 : capslockIcon.implicitHeight

                    MaterialIcon {
                        id: capslockIcon

                        anchors.centerIn: parent

                        scale: Hypr.capsLock ? 1 : 0.5
                        opacity: Hypr.capsLock ? 1 : 0

                        text: "keyboard_capslock_badge"
                        color: root.colour

                        Behavior on opacity {
                            Anim {
                                type: Anim.DefaultEffects
                            }
                        }

                        Behavior on scale {
                            Anim {}
                        }
                    }

                    Behavior on implicitWidth {
                        Anim {}
                    }

                    Behavior on implicitHeight {
                        Anim {}
                    }
                }

                Item {
                    readonly property int gap: Hypr.capsLock && Hypr.numLock ? iconColumn.spacing : 0

                    Layout.topMargin: root.vertical ? gap : 0
                    Layout.leftMargin: root.vertical ? 0 : gap

                    implicitWidth: root.vertical ? numlockIcon.implicitWidth : Hypr.numLock ? numlockIcon.implicitWidth : 0
                    implicitHeight: root.vertical ? Hypr.numLock ? numlockIcon.implicitHeight : 0 : numlockIcon.implicitHeight

                    MaterialIcon {
                        id: numlockIcon

                        anchors.centerIn: parent

                        scale: Hypr.numLock ? 1 : 0.5
                        opacity: Hypr.numLock ? 1 : 0

                        text: "looks_one"
                        color: root.colour

                        Behavior on opacity {
                            Anim {
                                type: Anim.DefaultEffects
                            }
                        }

                        Behavior on scale {
                            Anim {}
                        }
                    }

                    Behavior on implicitWidth {
                        Anim {}
                    }

                    Behavior on implicitHeight {
                        Anim {}
                    }
                }
            }
        }

        // Audio icon
        WrappedLoader {
            name: "audio"
            active: root.barConfig.status.showAudio

            sourceComponent: MaterialIcon {
                animate: true
                text: Icons.getVolumeIcon(Audio.volume, Audio.muted)
                color: root.colour
            }
        }

        // Microphone icon
        WrappedLoader {
            name: "audio"
            active: root.barConfig.status.showMicrophone

            sourceComponent: MaterialIcon {
                animate: true
                text: Icons.getMicVolumeIcon(Audio.sourceVolume, Audio.sourceMuted)
                color: root.colour
            }
        }

        // Keyboard layout icon
        WrappedLoader {
            name: "kblayout"
            active: root.barConfig.status.showKbLayout

            sourceComponent: StyledText {
                animate: true
                text: Hypr.kbLayout
                color: root.colour
                font: Tokens.font.mono.medium
            }
        }

        // Network icon
        WrappedLoader {
            name: "network"
            active: root.barConfig.status.showNetwork && (!Nmcli.activeEthernet || root.barConfig.status.showWifi)

            sourceComponent: MaterialIcon {
                animate: true
                text: Nmcli.active ? Icons.getNetworkIcon(Nmcli.active.strength ?? 0) : "wifi_off"
                color: root.colour
            }
        }

        // Ethernet icon
        WrappedLoader {
            name: "ethernet"
            active: root.barConfig.status.showNetwork && Nmcli.activeEthernet

            sourceComponent: MaterialIcon {
                animate: true
                text: "cable"
                color: root.colour
            }
        }

        // Bluetooth section
        WrappedLoader {
            Layout.preferredHeight: root.vertical ? implicitHeight : -1
            Layout.preferredWidth: root.vertical ? -1 : implicitWidth

            name: "bluetooth"
            active: root.barConfig.status.showBluetooth

            // Connected devices extend along the bar, not across its thickness.
            sourceComponent: GridLayout {
                flow: root.vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
                columns: root.vertical ? 1 : -1
                rows: root.vertical ? -1 : 1
                rowSpacing: Tokens.spacing.medium / 2
                columnSpacing: Tokens.spacing.medium / 2

                // Bluetooth icon
                MaterialIcon {
                    animate: true
                    text: {
                        if (!Bluetooth.defaultAdapter?.enabled) // qmllint disable unresolved-type
                            return "bluetooth_disabled";
                        if (Bluetooth.devices.values.some(d => d.connected)) // qmllint disable unresolved-type
                            return "bluetooth_connected";
                        return "bluetooth";
                    }
                    color: root.colour
                }

                // Connected bluetooth devices
                Repeater {
                    model: ScriptModel {
                        values: Bluetooth.devices.values.filter(d => d.state !== BluetoothDeviceState.Disconnected) // qmllint disable unresolved-type
                    }

                    MaterialIcon {
                        id: device

                        required property BluetoothDevice modelData

                        animate: true
                        text: Icons.getBluetoothIcon(modelData?.icon)
                        color: root.colour
                        fill: 1

                        SequentialAnimation on opacity {
                            running: device.modelData?.state !== BluetoothDeviceState.Connected // qmllint disable unresolved-type
                            alwaysRunToEnd: true
                            loops: Animation.Infinite

                            Anim {
                                from: 1
                                to: 0
                                duration: Tokens.anim.durations.large
                                easing: Tokens.anim.standardAccel
                            }
                            Anim {
                                from: 0
                                to: 1
                                duration: Tokens.anim.durations.large
                                easing: Tokens.anim.standardDecel
                            }
                        }
                    }
                }
            }

            Behavior on Layout.preferredHeight {
                Anim {}
            }

            Behavior on Layout.preferredWidth {
                Anim {}
            }
        }

        // Battery section
        WrappedLoader {
            name: "battery"
            active: root.barConfig.status.showBattery

            // The percentage sits beside the icon on a top/bottom bar; stacking it under
            // the icon would overflow the bar's thickness and get clipped.
            sourceComponent: GridLayout {
                flow: root.vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
                columns: root.vertical ? 1 : -1
                rows: root.vertical ? -1 : 1
                rowSpacing: 0
                columnSpacing: root.vertical ? 0 : Tokens.spacing.extraSmall / 2

                readonly property bool isLaptop: UPower.displayDevice.isLaptopBattery

                readonly property color batteryColour: !UPower.onBattery || UPower.displayDevice.percentage > 0.2 ? root.colour : Colours.palette.m3error

                MaterialIcon {
                    Layout.alignment: root.vertical ? Qt.AlignHCenter : Qt.AlignVCenter
                    animate: true
                    text: {
                        if (!UPower.displayDevice.isLaptopBattery) {
                            if (PowerProfiles.profile === PowerProfile.PowerSaver)
                                return "energy_savings_leaf";
                            if (PowerProfiles.profile === PowerProfile.Performance)
                                return "rocket_launch";
                            return "balance";
                        }

                        const perc = UPower.displayDevice.percentage;
                        const charging = [UPowerDeviceState.Charging, UPowerDeviceState.FullyCharged, UPowerDeviceState.PendingCharge].includes(UPower.displayDevice.state);
                        if (perc === 1)
                            return charging ? "battery_charging_full" : "battery_full";
                        let level = Math.floor(perc * 7);
                        if (charging && (level === 4 || level === 1))
                            level--;
                        return charging ? `battery_charging_${(level + 3) * 10}` : `battery_${level}_bar`;
                    }
                    color: parent.batteryColour
                    fill: 1
                }

                StyledText {
                    Layout.alignment: root.vertical ? Qt.AlignHCenter : Qt.AlignVCenter
                    visible: root.barConfig.status.showBatteryPercentage && parent.isLaptop
                    animate: true
                    text: Math.round(UPower.displayDevice.percentage * 100)
                    color: parent.batteryColour
                    font: Tokens.font.mono.small
                }
            }
        }
    }

    component WrappedLoader: Loader {
        required property string name

        asynchronous: true
        Layout.alignment: root.vertical ? Qt.AlignHCenter : Qt.AlignVCenter
        visible: active
    }
}
