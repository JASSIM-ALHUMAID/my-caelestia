pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.modules.nexus.common
import qs.modules.nexus.pages.lockscreen

PageBase {
    id: root

    function columnCount(configList: var): string {
        const forced = ["passwordInput", "stateMessage"];
        const enabled = configList.filter(e => e.enabled && !forced.includes(e.id)).length;
        return qsTr("%1/4 on").arg(enabled);
    }

    title: qsTr("Lock screen")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Columns")
        }

        NavRow {
            Layout.fillWidth: true
            first: true
            icon: "align_horizontal_left"
            label: qsTr("Left column")
            status: root.columnCount(GlobalConfig.lock.leftWidgets)
            onClicked: root.nState.openSubPage(1)
        }

        NavRow {
            Layout.fillWidth: true
            icon: "align_horizontal_center"
            label: qsTr("Center column")
            status: root.columnCount(GlobalConfig.lock.centerWidgets)
            onClicked: root.nState.openSubPage(2)
        }

        NavRow {
            Layout.fillWidth: true
            last: true
            icon: "align_horizontal_right"
            label: qsTr("Right column")
            status: root.columnCount(GlobalConfig.lock.rightWidgets)
            onClicked: root.nState.openSubPage(3)
        }

        SectionHeader {
            text: qsTr("Appearance")
        }

        ToggleRow {
            Layout.fillWidth: true
            first: true
            text: qsTr("Minimal mode")
            subtext: qsTr("Only a clock in the center and the password field at the bottom")
            checked: GlobalConfig.lock.minimal
            onToggled: GlobalConfig.lock.minimal = checked
        }

        ToggleRow {
            Layout.fillWidth: true
            text: qsTr("Recolour logo")
            subtext: qsTr("Apply theme colours to the distribution logo in the system info widget")
            checked: GlobalConfig.lock.recolourLogo
            onToggled: GlobalConfig.lock.recolourLogo = checked
        }

        ToggleRow {
            Layout.fillWidth: true
            text: qsTr("Hide notifications")
            subtext: qsTr("Show 'Unlock for notifications' instead of previewing them")
            checked: GlobalConfig.lock.hideNotifs
            onToggled: GlobalConfig.lock.hideNotifs = checked
        }

        ToggleRow {
            Layout.fillWidth: true
            text: qsTr("Hide windows")
            subtext: qsTr("Show only the wallpaper instead of blurred screen content")
            checked: GlobalConfig.lock.hideWindows
            onToggled: GlobalConfig.lock.hideWindows = checked
        }

        SliderRow {
            Layout.fillWidth: true
            last: true
            icon: "blur_on"
            label: qsTr("Blur amount")
            valueLabel: Math.round(GlobalConfig.lock.blurred * 100) + "%"
            value: GlobalConfig.lock.blurred
            to: 1.0
            onMoved: v => GlobalConfig.lock.blurred = v
        }

        SettingsSection {
            title: qsTr("Password characters")

            PasswordShapePicker {
                Layout.fillWidth: true
                first: true
                last: true
            }
        }

        SettingsSection {
            title: qsTr("Screensaver")

            ToggleRow {
                Layout.fillWidth: true
                first: true
                last: true
                text: qsTr("Allow while locked")
                subtext: qsTr("Show the screensaver over the lock screen; press any key or click to reveal sign-in")
                checked: GlobalConfig.lock.allowScreensaver
                onToggled: GlobalConfig.lock.allowScreensaver = checked
            }
        }

        SectionHeader {
            text: qsTr("Media")
        }

        ToggleRow {
            Layout.fillWidth: true
            first: true
            text: qsTr("Pause media on lock")
            subtext: qsTr("Pause all playing media when the screen locks")
            checked: GlobalConfig.lock.pauseMediaOnLock
            onToggled: GlobalConfig.lock.pauseMediaOnLock = checked
        }

        ToggleRow {
            Layout.fillWidth: true
            last: true
            text: qsTr("Media controls")
            subtext: qsTr("Allow play/pause from the lockscreen; otherwise only track info is shown")
            checked: GlobalConfig.lock.mediaControls
            onToggled: GlobalConfig.lock.mediaControls = checked
        }
    }
}
