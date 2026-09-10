pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import Caelestia.Services
import qs.components
import qs.services

StyledRect {
    id: root

    required property var barConfig
    required property bool vertical
    required property bool inverted
    required property var popouts

    readonly property double silenceThreshold: 0.01
    readonly property int fadeDuration: 400
    readonly property bool hideOnSilence: root.barConfig.visualiser.silenceBehavior === "hide"
    readonly property bool silent: {
        const vals = Audio.cava.values;
        for (let i = 0; i < vals.length; i++) {
            if (vals[i] > root.silenceThreshold) return false;
        }
        return true;
    }
    // barCount must be >= 2 to avoid div-by-zero in src-index mapping below.
    readonly property int barCount: Math.max(2, root.barConfig.visualiser.bars)
    readonly property int barWidth: root.barConfig.visualiser.barWidth
    readonly property int barLength: root.barConfig.visualiser.barLength
    readonly property int barRounding: root.barConfig.visualiser.barRounding
    readonly property int barAmplitude: root.barConfig.visualiser.barAmplitude
    readonly property int barSpacing: root.barConfig.visualiser.barSpacing

    readonly property string resolvedFillMode: root.barConfig.visualiser.fillMode || "outward"

    readonly property bool pinBottom: !root.vertical && (
        (resolvedFillMode === "outward" && !root.inverted) ||
        (resolvedFillMode === "inward" && root.inverted)
    )
    readonly property bool pinTop: !root.vertical && (
        (resolvedFillMode === "outward" && root.inverted) ||
        (resolvedFillMode === "inward" && !root.inverted)
    )
    readonly property bool pinLeft: root.vertical && (
        (resolvedFillMode === "outward" && !root.inverted) ||
        (resolvedFillMode === "inward" && root.inverted)
    )
    readonly property bool pinRight: root.vertical && (
        (resolvedFillMode === "outward" && root.inverted) ||
        (resolvedFillMode === "inward" && !root.inverted)
    )
    readonly property bool centerFill: resolvedFillMode === "center"
    readonly property bool mirrorFill: resolvedFillMode === "mirror"

    readonly property string resolvedColorMode: root.barConfig.visualiser.barColorMode || "solid"
    readonly property string resolvedColorSource: root.barConfig.visualiser.barColorSource || "dynamic"

    readonly property color barGradientTop: {
        const c = root.parseColor(root.barConfig.visualiser.barCustomColor);
        return c.valid ? c.color : Colours.palette.m3primary;
    }
    readonly property color barGradientBottom: {
        const c = root.parseColor(root.barConfig.visualiser.barCustomColor2);
        return c.valid ? c.color : Colours.palette.m3inversePrimary;
    }

    readonly property var displayValues: {
        const vals = root.barValues;
        if (!root.mirrorFill || vals.length < 2)
            return vals;
        // Mirror: low freq at edges, high freq in centre
        const n = vals.length;
        const mirrored = new Array(n * 2 - 1);
        for (let i = 0; i < n; i++) {
            mirrored[i] = vals[i];
            if (i < n - 1)
            mirrored[n * 2 - 2 - i] = vals[i];
        }
        return mirrored;
    }

    property var barValues: []
    property var prevBarValues: []
    // Beat-reactive amplitude multiplier; decays exponentially from 1 + beatPulseAmount back to 1
    property real beatBoost: 1.0

    // Linear interpolation between two colours
    function lerpColor(a: color, b: color, t: real): color {
        t = Math.max(0, Math.min(1, t));
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, a.a + (b.a - a.a) * t);
    }

    function parseColor(hex: string): var {
        if (!hex || hex.length < 4 || hex[0] !== "#")
            return { valid: false, color: "transparent" };
        const cleaned = hex.length === 4
            ? "#" + hex[1] + hex[1] + hex[2] + hex[2] + hex[3] + hex[3]
            : hex;
        if (!/^-?[0-9a-fA-F]{6}$/.test(cleaned))
            return { valid: false, color: "transparent" };
        return { valid: true, color: cleaned };
    }

    // Colours for each bar index, accounting for color mode
    function barColorForIndex(idx: int, total: int, fallback: color): color {
        switch (root.resolvedColorMode) {
        case "gradient": {
            if (root.resolvedColorSource === "custom") {
                const c1 = root.parseColor(root.barConfig.visualiser.barCustomColor);
                if (!c1.valid) return fallback;
                const c2 = root.parseColor(root.barConfig.visualiser.barCustomColor2);
                if (!c2.valid) return c1.color;
                return root.lerpColor(c1.color, c2.color, idx / Math.max(1, total - 1));
            }
            return !root.vertical
                ? (root.pinBottom || root.mirrorFill
                    ? root.lerpColor(Colours.palette.m3primary, Colours.palette.m3inversePrimary, idx / Math.max(1, total - 1))
                    : root.lerpColor(Colours.palette.m3inversePrimary, Colours.palette.m3primary, idx / Math.max(1, total - 1)))
                : (root.pinLeft
                    ? root.lerpColor(Colours.palette.m3primary, Colours.palette.m3inversePrimary, idx / Math.max(1, total - 1))
                    : root.lerpColor(Colours.palette.m3inversePrimary, Colours.palette.m3primary, idx / Math.max(1, total - 1)));
        }
        case "bar_gradient": {
            const c = root.parseColor(root.barConfig.visualiser.barCustomColor);
            return root.resolvedColorSource === "custom" ? (c.valid ? c.color : fallback) : fallback;
        }
        case "solid": {
            const c = root.parseColor(root.barConfig.visualiser.barCustomColor);
            return root.resolvedColorSource === "custom" ? (c.valid ? c.color : fallback) : fallback;
        }
        default:
            return fallback;
        }
    }

    implicitWidth: root.vertical
        ? Math.min(root.barLength, 60)
        : root.barCount * root.barWidth + (root.barCount - 1) * root.barSpacing + Tokens.padding.small * 2
    implicitHeight: root.vertical
        ? root.barCount * root.barWidth + (root.barCount - 1) * root.barSpacing + Tokens.padding.small * 2
        : Math.min(root.barLength, 60)

    opacity: root.hideOnSilence && root.silent ? 0.0 : 1.0

    // Opacity alone leaves the entry's implicit size in the bar layout, so a hidden
    // visualiser still reserves its full main-axis length. The bar hides the whole
    // loader once the fade has finished, which drops it (and its layout spacing) out
    // of the GridLayout entirely.
    readonly property bool collapsed: root.hideOnSilence && root.silent && root.opacity <= 0.01

    Behavior on opacity {
        NumberAnimation { duration: root.fadeDuration; easing.type: Easing.OutQuad }
    }

    TapHandler {
        enabled: root.barConfig.visualiser.clickAction === "nexus"
        onTapped: root.popouts.currentName = root.popouts.currentName === "nexus" ? "" : "nexus"
    }

    ServiceRef {
        service: Audio.cava
    }

    ServiceRef {
        service: Audio.beatTracker
    }

    Connections {
        enabled: root.barConfig.visualiser.beatPulse
        target: Audio.beatTracker
        function onBeat(bpm: real): void {
            root.beatBoost = 1.0 + root.barConfig.visualiser.beatPulseAmount;
        }
    }

    FrameAnimation {
        // No point smoothing bars nobody can see
        running: !root.collapsed
        onTriggered: {
            // Decay beat boost
            if (root.beatBoost > 1.001) {
                const boostTau = root.barConfig.visualiser.beatDecay / 1000;
                root.beatBoost = 1.0 + (root.beatBoost - 1.0) * Math.exp(-frameTime / boostTau);
            } else {
                root.beatBoost = 1.0;
            }
            const beatMult = root.beatBoost;

            const src = Audio.cava.values;
            const count = root.barCount;
            if (src.length === 0) {
                root.barValues = [];
                return;
            }
            const tilt = root.barConfig.visualiser.tilt;
            const raw = [];
            for (let i = 0; i < count; i++) {
                const idx = Math.round(i * (src.length - 1) / (count - 1));
                const mult = count > 1 ? 1 + tilt * (i / (count - 1)) : 1;
                raw.push(Math.max(0.01, (src[Math.min(idx, src.length - 1)] || 0) * mult * beatMult));
            }
            if (root.prevBarValues.length !== raw.length) {
                root.prevBarValues = raw.slice();
                root.barValues = raw;
                return;
            }
            const dt = frameTime;
            const tau = root.barConfig.visualiser.smoothing / 1000;
            const alpha = 1.0 - Math.exp(-dt / tau);
            const smoothed = [];
            for (let i = 0; i < raw.length; i++) {
                const diff = raw[i] - root.prevBarValues[i];
                smoothed.push(root.prevBarValues[i] + diff * alpha);
            }
            root.prevBarValues = smoothed;
            root.barValues = smoothed;
        }
    }

    Item {
        id: barsContainer

        anchors.fill: parent
        anchors.margins: Tokens.padding.small

        Repeater {
            model: root.displayValues

            Item {
                required property real modelData
                required property int index

                x: root.vertical ? 0 : index * (root.barWidth + root.barSpacing)
                y: root.vertical ? index * (root.barWidth + root.barSpacing) : 0
                width: root.vertical ? barsContainer.width : root.barWidth
                height: root.vertical ? root.barWidth : barsContainer.height

                Rectangle {
                    id: fill

                    readonly property real extent: Math.min(
                        (root.vertical ? barsContainer.width : barsContainer.height) * modelData * root.barAmplitude / 100,
                        root.vertical ? barsContainer.width : barsContainer.height,
                        root.barLength
                    )

                    readonly property color resolvedColor: root.barColorForIndex(index, root.displayValues.length, Colours.palette.m3primary)

                    color: root.resolvedColorMode === "bar_gradient" ? "transparent" : resolvedColor
                    radius: root.barRounding

                    gradient: root.resolvedColorMode === "bar_gradient" ? barGrad : null
                    Gradient {
                        id: barGrad
                        orientation: root.vertical ? Gradient.Horizontal : Gradient.Vertical
                        GradientStop {
                            position: 0.0
                            color: root.resolvedColorSource === "custom" ? root.barGradientTop : Colours.palette.m3primary
                        }
                        GradientStop {
                            position: 1.0
                            color: root.resolvedColorSource === "custom" ? root.barGradientBottom : Colours.palette.m3inversePrimary
                        }
                    }

                    width: root.vertical ? extent : root.barWidth
                    height: root.vertical ? root.barWidth : extent

                    x: root.vertical ? (
                        root.pinLeft ? 0
                        : root.pinRight ? parent.width - width
                        : (root.centerFill || root.mirrorFill) ? (parent.width - width) / 2
                        : 0
                    ) : 0

                    y: !root.vertical ? (
                        root.pinBottom ? parent.height - height
                        : root.pinTop ? 0
                        : (root.centerFill || root.mirrorFill) ? (parent.height - height) / 2
                        : 0
                    ) : 0
                }
            }
        }
    }
}
