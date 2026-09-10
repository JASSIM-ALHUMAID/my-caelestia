pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

RowLayout {
    id: root

    required property var lock

    readonly property real centerScale: Math.min(1, (lock.screen?.height ?? 1440) / 1440)
    readonly property int centerWidth: Tokens.sizes.lock.centerWidth * centerScale

    spacing: Tokens.spacing.largeIncreased * 2

    WidgetColumn {
        Layout.fillWidth: true
        spacing: Tokens.spacing.medium

        lock: root.lock
        widgets: Config.lock.leftWidgets
        centerScale: root.centerScale
        centerWidth: root.centerWidth
    }

    WidgetColumn {
        Layout.preferredWidth: root.centerWidth
        Layout.fillWidth: false
        Layout.fillHeight: true
        spacing: Tokens.spacing.largeIncreased

        lock: root.lock
        widgets: Config.lock.centerWidgets
        centerScale: root.centerScale
        centerWidth: root.centerWidth
    }

    WidgetColumn {
        Layout.fillWidth: true
        spacing: Tokens.spacing.medium

        lock: root.lock
        widgets: Config.lock.rightWidgets
        centerScale: root.centerScale
        centerWidth: root.centerWidth
    }
}
