pragma ComponentBehavior: Bound

import "center"
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils
import qs.modules.screensaver

WlSessionLockSurface {
    id: root

    required property WlSessionLock lock
    required property Pam pam

    readonly property bool unlocking: cardLoader.item?.unlocking ?? minimalLoader.item?.unlocking ?? false

    contentItem.Config.screen: screen.name
    contentItem.Tokens.screen: screen.name

    color: "transparent"

    component LockBlurEffect: MultiEffect {
        autoPaddingEnabled: false
        blurEnabled: Config.lock.blurred > 0
        blur: Config.lock.blurred
        blurMax: 64
        blurMultiplier: 1
    }

    Component {
        id: blurEffectA

        LockBlurEffect {}
    }

    Component {
        id: blurEffectB

        LockBlurEffect {}
    }

    // The lock's locked property only notifies on unlock, so pause media from
    // the surface, which is created exactly when the lock engages.
    Component.onCompleted: {
        if (Config.lock.pauseMediaOnLock) {
            for (const player of Players.list) {
                if (player.isPlaying && player.canPause)
                    player.pause();
            }
        }
    }

    Item {
        id: background

        property bool alternateBlurEffect: false

        function refreshBlur(): void {
            if (Config.lock.blurred > 0)
                alternateBlurEffect = !alternateBlurEffect;
        }

        anchors.fill: parent
        opacity: 0

        Component.onCompleted: opacity = 1

        Behavior on opacity {
            Anim {
                type: Anim.StandardLarge
            }
        }

        Connections {
            function onUnlock(): void {
                background.opacity = 0;
            }

            function onResumed(): void {
                background.refreshBlur();
            }

            target: root.lock
        }

        Loader {
            id: screencopyLoader

            anchors.fill: parent
            active: !Config.lock.hideWindows

            sourceComponent: Component {
                ScreencopyView {
                    anchors.fill: parent
                    captureSource: root.screen

                    layer.enabled: true
                    layer.effect: background.alternateBlurEffect ? blurEffectB : blurEffectA
                }
            }
        }

        Loader {
            id: wallpaperLoader

            anchors.fill: parent
            active: Config.lock.hideWindows

            sourceComponent: Component {
                Image {
                    anchors.fill: parent
                    source: Wallpapers.thumbnailFor(Wallpapers.current)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize: {
                        const dpr = (QsWindow.window as QsWindow)?.devicePixelRatio ?? 1;
                        return Qt.size(width * dpr * 0.5, height * dpr * 0.5);
                    }

                    layer.enabled: true
                    layer.effect: background.alternateBlurEffect ? blurEffectB : blurEffectA
                }
            }
        }
    }

    Loader {
        id: cardLoader

        anchors.centerIn: parent
        active: !Config.lock.minimal
        sourceComponent: cardLock
    }

    Loader {
        id: minimalLoader

        anchors.fill: parent
        active: Config.lock.minimal
        sourceComponent: minimalLock
    }

    ScreensaverContent {
        anchors.fill: parent
        z: 1

        active: Screensaver.showingOnLockScreen
        effectId: Screensaver.effectiveEffectId
        captureKeyboard: false
        onDismissRequested: Screensaver.hide()
    }

    Component {
        id: cardLock

        Item {
            id: lockContent

            readonly property alias unlocking: unlockAnim.running

            readonly property int size: lockIcon.implicitHeight + Tokens.padding.large * 4
            readonly property int radius: size / 4 * Tokens.rounding.scale

            readonly property real targetWidth: (root.screen?.height ?? 0) * Tokens.sizes.lock.heightMult * Tokens.sizes.lock.ratio
            readonly property real targetHeight: {
                const screenH = root.screen?.height ?? 0;
                const wanted = content.implicitHeight + Tokens.padding.extraLargeIncreased * 2;
                return Math.max(screenH * 0.5, Math.min(screenH * 0.92, wanted));
            }

            // Set after the intro animation; gates the adaptive height behaviour.
            property bool ready: false

            onTargetHeightChanged: {
                if (ready)
                    implicitHeight = targetHeight;
            }

            implicitWidth: size
            implicitHeight: size

            rotation: 180
            scale: 0

            Behavior on implicitHeight {
                enabled: lockContent.ready

                Anim {}
            }

            Connections {
                function onUnlock(): void {
                    unlockAnim.start();
                }

                target: root.lock
            }

            SequentialAnimation {
                id: unlockAnim

                PropertyAction {
                    target: lockContent
                    property: "ready"
                    value: false
                }
                ParallelAnimation {
                    Anim {
                        target: lockContent
                        properties: "implicitWidth,implicitHeight"
                        to: lockContent.size
                    }
                    Anim {
                        target: lockBg
                        property: "radius"
                        to: lockContent.radius
                    }
                    Anim {
                        target: content
                        property: "scale"
                        to: 0
                    }
                    Anim {
                        target: content
                        property: "opacity"
                        to: 0
                        type: Anim.StandardSmall
                    }
                    Anim {
                        target: lockIcon
                        property: "opacity"
                        to: 1
                        type: Anim.StandardLarge
                    }
                    SequentialAnimation {
                        PauseAnimation {
                            duration: Tokens.anim.durations.small
                        }
                        Anim {
                            type: Anim.Standard
                            target: lockContent
                            property: "opacity"
                            to: 0
                        }
                    }
                }
                PropertyAction {
                    target: root.lock
                    property: "locked"
                    value: false
                }
            }

            SequentialAnimation {
                id: initAnim

                running: true

                ParallelAnimation {
                    Anim {
                        target: lockContent
                        property: "scale"
                        to: 1
                        type: Anim.FastSpatial
                    }
                    Anim {
                        target: lockContent
                        property: "rotation"
                        to: 360
                        duration: Tokens.anim.durations.expressiveFastSpatial
                        easing: Tokens.anim.standardAccel
                    }
                }
                ParallelAnimation {
                    Anim {
                        target: lockIcon
                        property: "rotation"
                        to: 360
                        easing: Tokens.anim.standardDecel
                    }
                    Anim {
                        type: Anim.DefaultEffects
                        target: lockIcon
                        property: "opacity"
                        to: 0
                    }
                    Anim {
                        type: Anim.DefaultEffects
                        target: content
                        property: "opacity"
                        to: 1
                    }
                    Anim {
                        target: content
                        property: "scale"
                        to: 1
                    }
                    Anim {
                        target: lockBg
                        property: "radius"
                        to: lockContent.Tokens.rounding.extraLarge * 1.5
                    }
                    Anim {
                        target: lockContent
                        property: "implicitWidth"
                        to: lockContent.targetWidth
                    }
                    Anim {
                        target: lockContent
                        property: "implicitHeight"
                        to: lockContent.targetHeight
                    }
                }
                PropertyAction {
                    target: lockContent
                    property: "ready"
                    value: true
                }
            }

            StyledRect {
                id: lockBg

                anchors.fill: parent
                color: Colours.palette.m3surface
                radius: lockContent.radius
                opacity: Colours.transparency.enabled ? Colours.transparency.base : 1

                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    blurMax: 15
                    shadowColor: Qt.alpha(Colours.palette.m3shadow, 0.7)
                }
            }

            MaterialIcon {
                id: lockIcon

                anchors.centerIn: parent
                text: "lock"
                fontStyle: Tokens.font.icon.builders.extraLarge.scale(4).weight(Font.Bold).build()
                rotation: 180
            }

            Content {
                id: content

                anchors.centerIn: parent
                width: lockContent.targetWidth - Tokens.padding.extraLargeIncreased
                height: lockContent.implicitHeight - Tokens.padding.extraLargeIncreased

                lock: root
                opacity: 0
                scale: 0
            }
        }
    }

    Component {
        id: minimalLock

        Item {
            id: minimalContent

            readonly property alias unlocking: minimalUnlockAnim.running

            readonly property real centerScale: Math.min(1, (root.screen?.height ?? 1440) / 1440)
            readonly property int centerWidth: Tokens.sizes.lock.centerWidth * centerScale

            anchors.fill: parent
            opacity: 0
            scale: 1.2

            Component.onCompleted: introAnim.start()

            Connections {
                function onUnlock(): void {
                    minimalUnlockAnim.start();
                }

                target: root.lock
            }

            ParallelAnimation {
                id: introAnim

                Anim {
                    target: minimalContent
                    property: "opacity"
                    to: 1
                    type: Anim.StandardLarge
                }
                Anim {
                    target: minimalContent
                    property: "scale"
                    to: 1
                    type: Anim.FastSpatial
                }
            }

            SequentialAnimation {
                id: minimalUnlockAnim

                ParallelAnimation {
                    Anim {
                        target: minimalContent
                        property: "opacity"
                        to: 0
                        type: Anim.StandardSmall
                    }
                    Anim {
                        target: minimalContent
                        property: "scale"
                        to: 1.1
                    }
                }
                PropertyAction {
                    target: root.lock
                    property: "locked"
                    value: false
                }
            }

            Clock {
                anchors.centerIn: parent
                centerScale: minimalContent.centerScale * 1.5
            }

            ColumnLayout {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Tokens.padding.extraLargeIncreased
                spacing: Tokens.spacing.normal

                StateMessage {
                    Layout.fillWidth: true
                    pam: root.pam
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Tokens.spacing.small

                    PasswordInput {
                        centerWidth: minimalContent.centerWidth
                        lock: root
                    }

                    IconButton {
                        icon: "power_settings_new"
                        type: IconButton.Tonal
                        isRound: true
                        onClicked: Quickshell.execDetached(["systemctl", "poweroff"])
                    }

                    IconButton {
                        icon: "restart_alt"
                        type: IconButton.Tonal
                        isRound: true
                        onClicked: Quickshell.execDetached(["systemctl", "reboot"])
                    }

                    IconButton {
                        icon: "bedtime"
                        type: IconButton.Tonal
                        isRound: true
                        onClicked: Quickshell.execDetached(["systemctl", "suspend"])
                    }
                }
            }
        }
    }
}
