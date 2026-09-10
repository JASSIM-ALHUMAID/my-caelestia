pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.services

Item {
    id: root

    property string type: "fade"
    property bool playing: false
    property bool loop: true
    property real restProgress: 0.4
    property Item fromItem: gradientA
    property Item toItem: gradientB
    property real progress: restProgress
    property point effCentre: Qt.point(0.5, 0.5)
    property vector4d effParams: Qt.vector4d(0, 0, 0, 0)
    property int waveCount: Config.background.transitionWaveCount
    property int stripeCount: Config.background.transitionStripeCount
    property int honeycombSize: Config.background.transitionHoneycombSize

    // Mirrors the shader map in modules/background/Wallpaper.qml
    readonly property var shaderMap: ({
            "fade": "../../background/shaders/wp_fade.frag.qsb",
            "wipe": "../../background/shaders/wp_wipe.frag.qsb",
            "grow": "../../background/shaders/wp_disc.frag.qsb",
            "outer": "../../background/shaders/wp_disc.frag.qsb",
            "wave": "../../background/shaders/wp_wave.frag.qsb",
            "diagonal": "../../background/shaders/wp_diagonal.frag.qsb",
            "stripes": "../../background/shaders/wp_stripes.frag.qsb",
            "zoom": "../../background/shaders/wp_zoom.frag.qsb",
            "honeycomb": "../../background/shaders/wp_honeycomb.frag.qsb",
            "iris": "../../background/shaders/wp_iris.frag.qsb",
            "pixelate": "../../background/shaders/wp_pixelate.frag.qsb"
        })

    signal finished

    // Mirrors modules/background/Wallpaper.qml suffix semantics
    function baseOf(type: string): string {
        const i = type.indexOf("-");
        if (i < 0)
            return type;
        const b = type.slice(0, i);
        return ["wipe", "grow", "outer", "diagonal", "stripes", "wave"].includes(b) ? b : type;
    }

    // Mirrors modules/background/Wallpaper.qml randomizeParams exactly, but keeps
    // suffix-determined variants deterministic instead of always random
    function roll(): void {
        const base = baseOf(root.type);
        const suffix = root.type.length > base.length ? root.type.slice(base.length + 1) : "";
        const edgeCentre = {
            "left": Qt.point(0, 0.5),
            "right": Qt.point(1, 0.5),
            "top": Qt.point(0.5, 0),
            "bottom": Qt.point(0.5, 1)
        };
        const randomCentre = () => Qt.point(Math.random(), Math.random());

        let centre = Qt.point(0.5, 0.5);
        let params = Qt.vector4d(0, 0, 0, 0);

        switch (base) {
        case "wipe": {
            const dirs = {
                "left": 0,
                "right": 1,
                "top": 2,
                "bottom": 3
            };
            params = Qt.vector4d(dirs[suffix] ?? Math.floor(Math.random() * 4), 0.1, 0, 0);
            break;
        }
        case "grow":
            centre = edgeCentre[suffix] ?? randomCentre();
            params = Qt.vector4d(0, 0.1, 0, 0);
            break;
        case "outer":
            centre = edgeCentre[suffix] ?? randomCentre();
            params = Qt.vector4d(1, 0.1, 0, 0);
            break;
        case "wave": {
            const angles = {
                "left": 0,
                "right": Math.PI,
                "top": Math.PI / 2,
                "bottom": Math.PI * 1.5,
                "tl": Math.PI / 4,
                "tr": Math.PI * 0.75,
                "br": Math.PI * 1.25,
                "bl": Math.PI * 1.75
            };
            const keys = Object.keys(angles);
            const angle = angles[suffix] ?? angles[keys[Math.floor(Math.random() * keys.length)]];
            const cfg = Config.background.transitionWaveCount;
            const waves = cfg > 0 ? Math.min(8, cfg) : 1 + Math.floor(Math.random() * 8);
            params = Qt.vector4d(0.16 / waves, 1 / waves, 0, angle);
            break;
        }
        case "diagonal": {
            const corners = {
                "tl": 0,
                "tr": 1,
                "bl": 2,
                "br": 3
            };
            params = Qt.vector4d(corners[suffix] ?? Math.floor(Math.random() * 4), 0, 0, 0);
            break;
        }
        case "stripes": {
            const angles = {
                "top": 0,
                "bottom": Math.PI,
                "left": Math.PI / 2,
                "right": Math.PI * 1.5
            };
            const angle = angles[suffix] ?? Math.random() * 2 * Math.PI;
            const cfg = Config.background.transitionStripeCount;
            const count = cfg > 0 ? Math.max(2, Math.min(24, cfg)) : Math.round(Math.random() * 20 + 4);
            params = Qt.vector4d(count, angle, 0.1, 0);
            break;
        }
        case "honeycomb": {
            centre = randomCentre();
            const bands = [[0.012, 0.03], [0.02, 0.06], [0.05, 0.12], [0.1, 0.2]];
            const band = bands[Math.max(0, Math.min(3, Config.background.transitionHoneycombSize))];
            params = Qt.vector4d(band[0] + Math.random() * (band[1] - band[0]), 0, 0, 0);
            break;
        }
        case "iris":
            centre = Qt.point(0.5, 0.5);
            params = Qt.vector4d(0.1, 0, 0, 0);
            break;
        case "pixelate":
            params = Qt.vector4d(0.1, 0, root.width, root.height);
            break;
        default:
            centre = Qt.point(0.5, 0.5);
            params = Qt.vector4d(0, 0, 0, 0);
            break;
        }

        root.effCentre = centre;
        root.effParams = params;
    }

    onWaveCountChanged: roll()

    onStripeCountChanged: roll()

    onHoneycombSizeChanged: roll()

    Component.onCompleted: roll()

    onTypeChanged: roll()

    onPlayingChanged: {
        if (!playing)
            progress = restProgress;
    }

    Rectangle {
        id: gradientA

        anchors.fill: parent
        visible: false

        gradient: Gradient {
            GradientStop {
                position: 0
                color: Colours.palette.m3primaryContainer
            }
            GradientStop {
                position: 1
                color: Colours.palette.m3primary
            }
        }
    }

    Rectangle {
        id: gradientB

        anchors.fill: parent
        visible: false

        gradient: Gradient {
            orientation: Gradient.Horizontal

            GradientStop {
                position: 0
                color: Colours.palette.m3tertiary
            }
            GradientStop {
                position: 1
                color: Colours.palette.m3tertiaryContainer
            }
        }
    }

    ShaderEffectSource {
        id: fromSrc

        anchors.fill: parent
        sourceItem: root.fromItem
        visible: false
    }

    ShaderEffectSource {
        id: toSrc

        anchors.fill: parent
        sourceItem: root.toItem
        visible: false
    }

    ShaderEffect {
        readonly property variant fromTex: fromSrc
        readonly property variant toTex: toSrc
        readonly property real progress: root.progress
        readonly property real aspectRatio: root.height > 0 ? root.width / root.height : 1
        readonly property point centre: root.effCentre
        readonly property vector4d params: root.effParams
        readonly property vector4d fillColor: Qt.vector4d(Config.background.fillColor.r, Config.background.fillColor.g, Config.background.fillColor.b, Config.background.fillColor.a)

        anchors.fill: parent
        blending: false
        fragmentShader: Qt.resolvedUrl(root.shaderMap[root.baseOf(root.type)] ?? root.shaderMap["fade"])
    }

    SequentialAnimation {
        id: anim

        running: root.playing
        loops: root.loop ? Animation.Infinite : 1

        onFinished: {
            if (!root.loop)
                root.finished();
        }

        ScriptAction {
            script: root.roll()
        }
        PropertyAction {
            target: root
            property: "progress"
            value: 0
        }
        NumberAnimation {
            target: root
            property: "progress"
            from: 0
            to: 1
            duration: 1100
            easing.type: Easing.InOutCubic
        }
        PauseAnimation {
            duration: 400
        }
    }
}
