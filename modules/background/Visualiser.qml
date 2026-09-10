pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Caelestia.Config
import Caelestia.Internal
import Caelestia.Services
import qs.components
import qs.services
import qs.modules.nexus

Item {
    id: root

    required property ShellScreen screen
    required property Item wallpaper

    readonly property bool shouldBeActive: Config.background.visualiser.enabled && (!Config.background.visualiser.autoHide || (Hypr.monitorFor(screen)?.activeWorkspace?.toplevels?.values.every(t => t.lastIpcObject?.floating) ?? true))
    readonly property string position: Config.background.visualiser.position
    readonly property bool vertical: position === "left" || position === "right"
    property real offset: shouldBeActive ? 0 : (vertical ? screen.width : screen.height) * 0.2

    // Indices come from PageCompRegistry, never a local copy — a duplicated map here silently
    // drifted two entries behind the registry and sent every click to the wrong page
    function getPageIndex(pageName: string): int {
        return PageCompRegistry.topLevelPages[pageName] ?? -1;
    }

    function openNexus(action: string): void {
        if (action === "nexus") {
            WindowFactory.create();
        } else if (action.startsWith("nexus/")) {
            const pageName = action.split("/")[1];
            const idx = root.getPageIndex(pageName);
            if (idx >= 0)
                WindowFactory.create(undefined, {}, idx);
        }
    }

    opacity: shouldBeActive ? 1 : 0

    Loader {
        asynchronous: true
        anchors.fill: parent
        active: root.opacity > 0 && Config.background.visualiser.blur

        sourceComponent: MultiEffect {
            source: root.wallpaper
            maskSource: wrapper
            maskEnabled: true
            blurEnabled: true
            blur: 1
            blurMax: 32
            autoPaddingEnabled: false
        }
    }

    Item {
        id: wrapper

        anchors.fill: parent
        layer.enabled: true

        Loader {
            asynchronous: true
            // Slide off the widget's own edge when hiding. All four margins are always set to a
            // number - anchors can't be un-set at runtime.
            readonly property real vOffset: root.position === "bottom" ? root.offset : root.position === "top" ? -root.offset : 0
            readonly property real hOffset: root.position === "right" ? root.offset : root.position === "left" ? -root.offset : 0

            anchors.fill: parent
            anchors.topMargin: vOffset
            anchors.bottomMargin: -vOffset
            anchors.leftMargin: hOffset
            anchors.rightMargin: -hOffset

            active: root.opacity > 0

            sourceComponent: Item {
                function tiltedValues(src: var, tilt: real): var {
                    if (tilt === 0 || src.length < 2)
                        return src;
                    const n = src.length;
                    const out = new Array(n);
                    for (let i = 0; i < n; i++)
                        out[i] = (src[i] || 0) * (1 + tilt * (i / (n - 1)));
                    return out;
                }

                ServiceRef {
                    service: Audio.cava
                }

                VisualiserBars {
                    id: bars

                    anchors.fill: parent
                    anchors.margins: Config.border.thickness
                    anchors.leftMargin: Visibilities.bars.get(root.screen).exclusiveZone + Tokens.spacing.small * Config.background.visualiser.spacing

                    position: Config.background.visualiser.position
                    reach: Config.background.visualiser.reach
                    style: Config.background.visualiser.style
                    thickness: Config.background.visualiser.thickness
                    centerGap: Config.background.visualiser.centerGap
                    values: tiltedValues(Audio.cava.values, GlobalConfig.services.visualiserTilt)
                    primaryColor: Qt.alpha(Colours.palette.m3primary, 0.7)
                    secondaryColor: Qt.alpha(Colours.palette.m3inversePrimary, 0.7)
                    rounding: Tokens.rounding.medium * Config.background.visualiser.rounding
                    spacing: Tokens.spacing.extraSmall * Config.background.visualiser.spacing
                    animationDuration: Tokens.anim.durations.normal

                    Behavior on anchors.leftMargin {
                        Anim {}
                    }
                }

                Item {
                    id: clickArea

                    // Restrict clicks to the edge strip the bars can occupy so the rest of
                    // the desktop stays interactive.
                    readonly property real stripReach: Config.background.visualiser.reach

                    x: root.position === "left" ? 0 : root.position === "right" ? parent.width - width : 0
                    y: root.position === "top" ? 0 : root.position === "bottom" ? parent.height - height : 0
                    width: root.vertical ? parent.width * stripReach : parent.width
                    height: root.vertical ? parent.height : parent.height * stripReach

                    TapHandler {
                        enabled: Config.background.visualiser.clickAction !== "none"
                        onTapped: root.openNexus(Config.background.visualiser.clickAction)
                    }
                }

                FrameAnimation {
                    running: root.opacity > 0 && !bars.settled
                    onTriggered: bars.advance(frameTime)
                }
            }
        }
    }

    Behavior on offset {
        Anim {}
    }

    Behavior on opacity {
        Anim {
            type: Anim.DefaultEffects
        }
    }
}
