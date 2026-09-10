pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components

EdgeAnchoredPanel {
    id: root

    required property DrawerVisibilities visibilities
    readonly property real nonAnimWidth: content.implicitWidth

    // Content lives in a Loader, so nothing has been measured before the first open. Fall
    // back to the menu's natural extent along each axis, else the reveal would animate from
    // a zero-size panel and appear to pop in rather than slide.
    readonly property int fallbackThickness: Tokens.sizes.session.button + Tokens.padding.large * 2

    position: Config.session.position
    shouldBeActive: visibilities.session && Config.session.enabled

    implicitWidth: content.implicitWidth || (isVertical ? fallbackThickness : 510)
    implicitHeight: content.implicitHeight || (isVertical ? 510 : fallbackThickness)

    Loader {
        id: content

        anchors.centerIn: parent

        active: root.shouldBeActive || root.visible

        sourceComponent: Content {
            visibilities: root.visibilities
        }
    }
}
