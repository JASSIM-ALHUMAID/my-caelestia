import QtQuick.Layouts
import Caelestia.Config
import qs.modules.nexus
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Panels")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        NavRow {
            first: true
            icon: "dashboard"
            label: qsTr("Dashboard")
            status: Config.dashboard.enabled ? qsTr("Enabled") : qsTr("Disabled")
            onClicked: root.nState.openSubPage(PageCompRegistry.panelsSubPages.dashboard)
        }

        NavRow {
            icon: "dock_to_bottom"
            label: qsTr("Taskbar")
            status: Config.bar.persistent ? qsTr("Always visible") : Config.bar.showOnHover ? qsTr("Reveal on hover") : qsTr("Reveal on drag")
            onClicked: root.nState.openSubPage(PageCompRegistry.panelsSubPages.taskbar)
        }

        NavRow {
            icon: "apps"
            label: qsTr("Launcher")
            status: Config.launcher.enabled ? qsTr("Enabled") : qsTr("Disabled")
            onClicked: root.nState.openSubPage(PageCompRegistry.panelsSubPages.launcher)
        }

        NavRow {
            icon: "dock_to_bottom"
            label: qsTr("Dock")
            status: Config.dock.enabled ? qsTr("Enabled") : qsTr("Disabled")
            onClicked: root.nState.openSubPage(PageCompRegistry.panelsSubPages.dock)
        }

        NavRow {
            icon: "notifications"
            label: qsTr("Notifications")
            status: Config.notifs.expire ? qsTr("Expire on") : qsTr("Expire off")
            onClicked: root.nState.openSubPage(PageCompRegistry.panelsSubPages.notifications)
        }

        NavRow {
            icon: "swap_vert"
            label: qsTr("Edge Gestures")
            status: qsTr("Hover %1 · drag %2").arg(Config.edges.bottom.hover).arg(Config.edges.bottom.drag)
            onClicked: root.nState.openSubPage(PageCompRegistry.panelsSubPages.edgeConflict)
        }

        NavRow {
            icon: "volume_up"
            label: qsTr("OSD")
            status: Config.osd.enabled ? qsTr("Enabled") : qsTr("Disabled")
            onClicked: root.nState.openSubPage(PageCompRegistry.panelsSubPages.osd)
        }

        NavRow {
            icon: "power_settings_new"
            label: qsTr("Power Menu")
            status: Config.session.enabled ? qsTr("Enabled") : qsTr("Disabled")
            onClicked: root.nState.openSubPage(PageCompRegistry.panelsSubPages.session)
        }

        NavRow {
            icon: "dock_to_right"
            label: qsTr("Sidebar")
            status: Config.sidebar.enabled ? qsTr("Enabled") : qsTr("Disabled")
            onClicked: root.nState.openSubPage(PageCompRegistry.panelsSubPages.sidebar)
        }

        NavRow {
            last: true
            icon: "tune"
            label: qsTr("Utilities")
            status: Config.utilities.enabled ? qsTr("Enabled") : qsTr("Disabled")
            onClicked: root.nState.openSubPage(PageCompRegistry.panelsSubPages.utilities)
        }
    }
}
