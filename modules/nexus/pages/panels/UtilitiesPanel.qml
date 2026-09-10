import QtQuick.Layouts
import Caelestia.Config
import qs.modules.nexus
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Utilities")
    isSubPage: true

    readonly property int enabledToggles: Config.utilities.quickToggles.filter(t => t.enabled ?? true).length

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
            subtext: qsTr("The drawer holding recording, idle inhibit and quick toggles")
            checked: Config.utilities.enabled
            onToggled: GlobalConfig.utilities.enabled = checked
        }

        StepperRow {
            Layout.fillWidth: true
            last: true
            label: qsTr("Max toasts")
            subtext: qsTr("How many toasts stack up before the oldest is dropped")
            value: Config.utilities.maxToasts
            from: 1
            to: 10
            stepSize: 1
            onMoved: v => GlobalConfig.utilities.maxToasts = v
        }

        SectionHeader {
            text: qsTr("Quick toggles")
        }

        NavRow {
            Layout.fillWidth: true
            first: true
            last: true
            icon: "toggle_on"
            label: qsTr("Quick toggles")
            status: qsTr("%1 of %2 shown").arg(root.enabledToggles).arg(Config.utilities.quickToggles.length)
            onClicked: root.nState.openSubPage(PageCompRegistry.panelsSubPages.quickToggles)
        }

        SectionHeader {
            text: qsTr("Sounds")
        }

        NavRow {
            Layout.fillWidth: true
            first: true
            last: true
            icon: "volume_up"
            label: qsTr("Sounds")
            status: Config.utilities.sounds.enabled ? qsTr("On") : qsTr("Off")
            onClicked: root.nState.openSubPage(PageCompRegistry.panelsSubPages.sounds)
        }
    }
}
