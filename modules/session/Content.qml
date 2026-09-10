pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils

// Buttons run down the menu on the left and right edges, and across it on the top and
// bottom, so the menu always reads along the edge it is docked to.
Grid {
    id: root

    required property DrawerVisibilities visibilities

    readonly property string position: Config.session.position
    readonly property bool isVertical: position === "left" || position === "right"
    // The window border already supplies spacing on the docked edge, so trim padding there.
    readonly property real edgeTrim: CUtils.clamp(Tokens.padding.large - Config.border.thickness, 0, Tokens.padding.large)

    // Focus the nearest shown button, `step` being +1 for next and -1 for previous.
    //
    // Resolved on demand rather than bound to a nextItem/prevItem pair: a Repeater only
    // registers a delegate once its construction returns, so while bindings evaluate,
    // itemAt() is null for every later index -- a bound `next` would be null forever.
    //
    // Disabled items stay in the model — hiding rather than filtering them lets the menu
    // react live when they're toggled in settings — so navigation has to skip past them,
    // along with the gif, which is decoration and has no button to land on.
    function focusAt(from: int, step: int): bool {
        for (let i = from + step; i >= 0 && i < repeater.count; i += step) {
            const slot = repeater.itemAt(i);
            // modelData.enabled rather than slot.visible: `visible` is effective
            // visibility, still false while the panel animates open, which is exactly
            // when the first focus lands.
            if (slot?.button && slot.modelData.enabled) {
                slot.button.forceActiveFocus();
                return true;
            }
        }
        return false;
    }

    function focusedIndex(): int {
        for (let i = 0; i < repeater.count; i++)
            if (repeater.itemAt(i)?.button?.activeFocus)
                return i;
        return -1;
    }

    // No-op when something already holds focus, so returning from the launcher restores
    // the menu without yanking focus back to the first button.
    function focusFirst(): void {
        if (focusedIndex() < 0)
            focusAt(-1, 1);
    }

    // Both arrow axes navigate: the menu is one-dimensional, nothing else claims the cross
    // axis, and keying off `isVertical` is what left half the arrows dead per position.
    function navigate(key: int, modifiers: int): bool {
        let step = 0;

        if (modifiers & Qt.ControlModifier) {
            if (!Config.session.vimKeybinds)
                return false;
            if (key === Qt.Key_H || key === Qt.Key_K || key === Qt.Key_P)
                step = -1;
            else if (key === Qt.Key_L || key === Qt.Key_J || key === Qt.Key_N)
                step = 1;
        } else if (key === Qt.Key_Left || key === Qt.Key_Up || key === Qt.Key_Backtab) {
            step = -1;
        } else if (key === Qt.Key_Right || key === Qt.Key_Down || key === Qt.Key_Tab) {
            step = 1;
        }

        if (step === 0)
            return false;

        const from = root.focusedIndex();
        return root.focusAt(from < 0 ? (step > 0 ? -1 : repeater.count) : from, step);
    }

    columns: isVertical ? 1 : repeater.count

    // The Loader activates because `session` went true, so on a first open that signal has
    // already fired by the time this exists -- hence focusing here as well as on the
    // signal. callLater defers past the construction of the remaining delegates.
    Component.onCompleted: Qt.callLater(focusFirst)

    Connections {
        target: root.visibilities

        function onSessionChanged(): void {
            if (root.visibilities.session)
                Qt.callLater(root.focusFirst);
        }

        function onLauncherChanged(): void {
            if (!root.visibilities.launcher)
                Qt.callLater(root.focusFirst);
        }
    }

    padding: Tokens.padding.large
    leftPadding: position === "left" ? edgeTrim : padding
    rightPadding: position === "right" ? edgeTrim : padding
    topPadding: position === "top" ? edgeTrim : padding
    bottomPadding: position === "bottom" ? edgeTrim : padding
    spacing: Tokens.spacing.large

    Repeater {
        id: repeater

        model: Config.session.items.slice().sort((a, b) => a.order - b.order)

        delegate: Item {
            id: slot

            required property var modelData
            required property int index

            // The gif is an ordinary roster entry so it reorders with the rest, but it is
            // decoration: no command, and nothing for the keyboard to land on.
            readonly property bool isGif: modelData.id === "gif"
            readonly property Item button: isGif ? null : sessionButton

            // Bound per item rather than filtered out of the model, so toggling an item in
            // settings shows or hides it immediately instead of only after a reload.
            visible: modelData.enabled

            implicitWidth: Tokens.sizes.session.button
            implicitHeight: Tokens.sizes.session.button

            SessionButton {
                id: sessionButton

                anchors.fill: parent
                visible: !slot.isGif
                enabled: !slot.isGif

                icon: slot.modelData.icon
                command: slot.modelData.command
            }

            Loader {
                anchors.fill: parent
                active: slot.isGif
                asynchronous: true

                sourceComponent: AnimatedImage {
                    sourceSize.width: width * ((QsWindow.window as QsWindow)?.devicePixelRatio ?? 1)

                    playing: visible
                    asynchronous: true
                    speed: Config.general.sessionGifSpeed
                    source: Paths.absolutePath(Config.paths.sessionGif)
                    fillMode: AnimatedImage.PreserveAspectFit
                }
            }
        }
    }

    component SessionButton: IconButton {
        id: button

        required property list<string> command

        implicitWidth: Tokens.sizes.session.button
        implicitHeight: Tokens.sizes.session.button

        // Outlined keeps the set reading as one style: filling changes only the glyphs with
        // an enclosed area (lock, bedtime), leaving stroke-only ones like logout and cached
        // untouched.
        iconFill: Config.session.iconStyle === "filled" ? 1 : 0

        inactiveColour: activeFocus ? Colours.palette.m3secondaryContainer : Colours.tPalette.m3surfaceContainer
        inactiveOnColour: activeFocus ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
        radius: pressed ? Tokens.rounding.medium : activeFocus ? Tokens.rounding.extraLarge : Tokens.rounding.largeIncreased
        font: Tokens.font.icon.builders.large.scale(1.3).build()
        onClicked: Quickshell.execDetached(button.command)

        Keys.onEnterPressed: Quickshell.execDetached(button.command)
        Keys.onReturnPressed: Quickshell.execDetached(button.command)
        Keys.onEscapePressed: root.visibilities.session = false
        Keys.onPressed: event => {
            // Shift+Tab arrives as Key_Tab with the modifier on some layouts, as Key_Backtab
            // on others; normalise to Backtab so navigate() sees one case.
            const key = event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier) ? Qt.Key_Backtab : event.key;
            event.accepted = root.navigate(key, event.modifiers);
        }
    }
}
