import QtQuick
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.nexus

Item {
    id: root

    // Wallpaper & style lives at the top of the appearance category; resolve it from the
    // registry rather than hardcoding an index (see DesktopClock.getPageIndex for the
    // hardcoded variant this avoids)
    readonly property int settingsPageIdx: {
        const idx = PageRegistry.pages.findIndex(p => p.icon === "palette");
        return idx === -1 ? 0 : idx;
    }

    implicitWidth: icon.implicitHeight + Tokens.padding.small
    implicitHeight: icon.implicitHeight

    StateLayer {
        // Cursed workaround to make the height larger than the parent
        anchors.fill: undefined
        anchors.centerIn: parent

        implicitWidth: implicitHeight
        implicitHeight: icon.implicitHeight + Tokens.padding.small

        radius: Tokens.rounding.full
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: event => {
            if (event.button === Qt.RightButton) {
                WindowFactory.create(undefined, {}, root.settingsPageIdx);
                return;
            }

            // Same action as the Super+Shift+W keybind (caelestia shell wallpaper random).
            // Spin regardless of the return value - applying is async, so the spin is the
            // only immediate feedback, and a no-op click should still feel responsive.
            Wallpapers.advance();
            spinAnim.restart();
        }
    }

    MaterialIcon {
        id: icon

        anchors.centerIn: parent

        text: "wallpaper"
        fontStyle: Tokens.font.icon.builders.small.weight(Font.Bold).build()

        RotationAnimation {
            id: spinAnim

            target: icon
            from: 0
            to: 360
            duration: Tokens.anim.durations.expressiveSlowEffects
            easing: Tokens.anim.standard
        }
    }
}
