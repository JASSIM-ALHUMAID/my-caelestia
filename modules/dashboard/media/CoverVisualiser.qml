pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Quickshell
import M3Shapes
import Caelestia.Config
import Caelestia.Services
import qs.components
import qs.components.widgets
import qs.services

Item {
    id: root

    readonly property real centerX: width / 2
    readonly property real centerY: height / 2
    readonly property real spacing: Tokens.spacing.medium
    readonly property real maxMagnitude: (implicitWidth - cover.implicitWidth) / 2 - spacing

    property var smoothedValues: []

    ServiceRef {
        service: Audio.cava
    }

    FrameAnimation {
        running: true
        onTriggered: {
            const src = Audio.cava.values;
            const n = src.length;
            if (n === 0) {
                root.smoothedValues = [];
                return;
            }
            const tilt = GlobalConfig.services.visualiserTilt;
            const raw = new Array(n);
            for (let i = 0; i < n; i++) {
                const mult = n > 1 ? 1 + tilt * (i / (n - 1)) : 1;
                raw[i] = (src[i] || 0) * mult;
            }
            const prev = root.smoothedValues;
            if (prev.length !== n) {
                root.smoothedValues = raw;
                return;
            }
            const tau = 0.05;
            const alpha = 1.0 - Math.exp(-frameTime / tau);
            const smoothed = new Array(n);
            for (let i = 0; i < n; i++) {
                smoothed[i] = prev[i] + (raw[i] - prev[i]) * alpha;
            }
            root.smoothedValues = smoothed;
        }
    }

    Shape {
        anchors.fill: parent
        asynchronous: true
        preferredRendererType: Shape.CurveRenderer
        data: bars.instances
    }

    Variants {
        id: bars

        model: Array.from({
            length: GlobalConfig.services.visualiserBars
        }, (_, i) => i)

        ShapePath {
            id: bar

            required property int modelData
            readonly property real value: Math.max(1e-2, Math.min(1, root.smoothedValues[modelData] ?? 0))

            readonly property real angle: modelData * 2 * Math.PI / GlobalConfig.services.visualiserBars
            readonly property real dist: shapeEdgeDist + value * root.maxMagnitude
            readonly property real shapeEdgeDist: {
                cover.shape.rotation; // Update when shape rotation changes
                const sDist = cover.shape.distanceAtAngle(modelData * 360 / GlobalConfig.services.visualiserBars + 90);
                return sDist + root.spacing + strokeWidth / 2;
            }
            readonly property real cos: Math.cos(angle)
            readonly property real sin: Math.sin(angle)

            asynchronous: true
            capStyle: root.Tokens.rounding.scale === 0 ? ShapePath.SquareCap : ShapePath.RoundCap
            strokeWidth: 360 / GlobalConfig.services.visualiserBars - root.Tokens.spacing.small / 4
            strokeColor: Colours.palette.m3primary

            startX: root.centerX + shapeEdgeDist * cos
            startY: root.centerY + shapeEdgeDist * sin

            PathLine {
                x: root.centerX + bar.dist * bar.cos
                y: root.centerY + bar.dist * bar.sin
            }

            Behavior on strokeColor {
                CAnim {}
            }
        }
    }

    CoverArt {
        id: cover

        anchors.centerIn: parent
        shape.shape: MaterialShape.Cookie9Sided
        implicitWidth: Tokens.sizes.dashboard.mediaCoverArtSize
        implicitHeight: Tokens.sizes.dashboard.mediaCoverArtSize
    }
}
