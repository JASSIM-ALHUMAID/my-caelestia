pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.components.filedialog
import qs.services
import qs.utils

Item {
    id: root

    property string source: Wallpapers.current
    property Item current: one
    property bool completed
    readonly property bool videoProgressAvailable: current?.videoProgressAvailable ?? false
    readonly property real videoProgress: current?.videoProgress ?? 0

    // Transition state
    property bool transitioning: false
    property bool redirecting: false
    property bool redirectPending: false
    property bool reversed: false
    property real transitionProgress: 0
    property Item outgoingSlot
    property Item incomingSlot
    property bool fromFrozen: false
    property var frozenGrab
    property string activeTransitionType: ""
    property string queuedReplayType: ""
    property point transitionCentre: Qt.point(0.5, 0.5)
    property vector4d transitionParams: Qt.vector4d(0, 0, 0, 0)
    property color transitionFillColor: Config.background.fillColor

    readonly property string transitionType: Config.background.transitionType
    readonly property int transitionDuration: Config.background.transitionDuration

    // transitionEasing is either a named preset, an appearance.curves token name, or "custom".
    // The latter two resolve to bezier segments, which QML's easing.bezierCurve takes in the
    // same layout the curves are stored in; anything else falls through to a named Easing.Type.
    readonly property list<real> easingPoints: {
        const name = Config.background.transitionEasing;
        if (name === "custom")
            return Config.background.transitionCurve;
        const token = TokenConfig.appearance.curves[name];
        return token !== undefined && token.length >= 6 ? token : [];
    }
    readonly property bool hasTransition: transitionType !== "none" && transitionType.length > 0 && transitionDuration > 0

    readonly property list<string> transitionTypes: ["fade", "wipe", "grow", "outer", "wave", "diagonal", "stripes", "zoom", "honeycomb", "iris", "pixelate"]

    // Every shader shares one uniform layout, so a single ShaderEffect drives them all
    readonly property var shaderMap: ({
            "fade": "shaders/wp_fade.frag.qsb",
            "wipe": "shaders/wp_wipe.frag.qsb",
            "grow": "shaders/wp_disc.frag.qsb",
            "outer": "shaders/wp_disc.frag.qsb",
            "wave": "shaders/wp_wave.frag.qsb",
            "diagonal": "shaders/wp_diagonal.frag.qsb",
            "stripes": "shaders/wp_stripes.frag.qsb",
            "zoom": "shaders/wp_zoom.frag.qsb",
            "honeycomb": "shaders/wp_honeycomb.frag.qsb",
            "iris": "shaders/wp_iris.frag.qsb",
            "pixelate": "shaders/wp_pixelate.frag.qsb"
        })

    // Direction variants use a suffix, e.g. wipe-left, grow-top, diagonal-tl;
    // a bare directional name means "random" per switch
    function baseOf(type: string): string {
        const i = type.indexOf("-");
        if (i < 0)
            return type;
        const b = type.slice(0, i);
        return ["wipe", "grow", "outer", "diagonal", "stripes", "wave"].includes(b) ? b : type;
    }

    function shaderFor(type: string): url {
        return Qt.resolvedUrl(shaderMap[baseOf(type)] ?? shaderMap["fade"]);
    }

    function resolveTransitionType(): string {
        if (transitionType === "none" || transitionType === "")
            return "none";
        const types = transitionType.split(",");
        if (types.length === 1)
            return types[0];
        return types[Math.floor(Math.random() * types.length)];
    }

    function randomizeParams(type: string): void {
        const base = baseOf(type);
        const suffix = type.length > base.length ? type.slice(base.length + 1) : "";
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
            params.x = suffix in dirs ? dirs[suffix] : Math.floor(Math.random() * 4);
            params.y = 0.1;
            break;
        }
        case "grow":
            centre = edgeCentre[suffix] ?? randomCentre();
            params.y = 0.1;
            break;
        case "outer":
            params.x = 1;
            params.y = 0.1;
            centre = edgeCentre[suffix] ?? randomCentre();
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
            const angle = suffix in angles ? angles[suffix] : angles[keys[Math.floor(Math.random() * keys.length)]];
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
            params.x = suffix in corners ? corners[suffix] : Math.floor(Math.random() * 4);
            break;
        }
        case "stripes": {
            const angles = {
                "top": 0,
                "bottom": Math.PI,
                "left": Math.PI / 2,
                "right": Math.PI * 1.5
            };
            const angle = suffix in angles ? angles[suffix] : Math.random() * 2 * Math.PI;
            const cfg = Config.background.transitionStripeCount;
            const count = cfg > 0 ? Math.max(2, Math.min(24, cfg)) : Math.round(Math.random() * 20 + 4);
            params = Qt.vector4d(count, angle, 0.1, 0);
            break;
        }
        case "honeycomb": {
            centre = randomCentre();
            const bands = [[0.012, 0.03], [0.02, 0.06], [0.05, 0.12], [0.1, 0.2]];
            const band = bands[Math.max(0, Math.min(3, Config.background.transitionHoneycombSize))];
            params.x = band[0] + Math.random() * (band[1] - band[0]);
            break;
        }
        case "iris":
            centre = Qt.point(0.5, 0.5);
            params.x = 0.1;
            break;
        case "pixelate":
            params = Qt.vector4d(0.1, 0, root.width, root.height);
            break;
        }

        transitionCentre = centre;
        transitionParams = params;
    }

    function runAnim(from: real, to: real): void {
        if (transitionAnim.running) {
            redirecting = true;
            transitionAnim.stop();
            redirecting = false;
        }
        transitionAnim.from = from;
        transitionAnim.to = to;
        transitionAnim.duration = transitionDuration * Math.abs(to - from);
        toSource.scheduleUpdate();
        transitionAnim.start();
    }

    function startTransition(outgoing: Item, incoming: Item, type: string, fromItem: Item): void {
        outgoingSlot = outgoing;
        incomingSlot = incoming;
        activeTransitionType = type;
        randomizeParams(type);
        reversed = false;
        transitioning = true;
        transitionProgress = 0;
        incomingSlot.update();

        if (fromItem) {
            // fromItem is frozenImage, already holding the interrupted composite
            fromFrozen = true;
        } else {
            fromFrozen = false;
            fromSource.sourceItem = outgoing;
            fromSource.sourceRect = Qt.rect(0, 0, outgoing?.width ?? 0, outgoing?.height ?? 0);
            fromSource.scheduleUpdate();
        }

        if (incomingSlot.slotReady)
            runAnim(0, 1);
    }

    function cancelRedirect(): void {
        redirectPending = false;
        redirectTimer.stop();
    }

    function finishTransition(): void {
        cancelRedirect();
        if (reversed && outgoingSlot) {
            current = outgoingSlot;
            if (incomingSlot)
                incomingSlot.path = ""; // unload so a hidden video/gif stops decoding
        } else if (incomingSlot) {
            current = incomingSlot;
            if (outgoingSlot)
                outgoingSlot.path = ""; // unload to free memory
        }
        queuedReplayType = source && source !== current.path && Config.background.transitionInterruptReplay !== "new" ? activeTransitionType : "";
        transitioning = false;
        transitionProgress = 0;
        reversed = false;
        outgoingSlot = null;
        incomingSlot = null;
        activeTransitionType = "";
        fromSource.sourceItem = null;
        fromFrozen = false;
        frozenImage.source = "";
        frozenGrab = null;

        if (source && source !== current.path)
            Qt.callLater(() => applySourceChange());
    }

    function applySourceChange(): void {
        if (!hasTransition || !completed) {
            if (current === one)
                two.update();
            else
                one.update();
            return;
        }

        if (!transitioning) {
            if (source && source !== current.path) {
                const type = queuedReplayType !== "" ? queuedReplayType : resolveTransitionType();
                queuedReplayType = "";
                startTransition(current, current === one ? two : one, type, null);
            }
            return;
        }

        if (!incomingSlot || !outgoingSlot)
            return;

        if (!source) {
            // Wallpaper removed mid-transition: finish instantly, placeholder takes over
            redirecting = true;
            transitionAnim.stop();
            redirecting = false;
            finishTransition();
        } else if (source === outgoingSlot.path) {
            // Switching back to the outgoing wallpaper: play the transition backwards
            cancelRedirect();
            reversed = true;
            runAnim(transitionProgress, 0);
        } else if (source === incomingSlot.path) {
            cancelRedirect();
            if (reversed) {
                reversed = false;
                runAnim(transitionProgress, 1);
            }
        } else if (Config.background.transitionInterrupt === "reverse") {
            // A third wallpaper: play the transition backwards, then finishTransition
            // kicks off a fresh transition to the latest source
            cancelRedirect();
            reversed = true;
            runAnim(transitionProgress, 0);
        } else if (!redirectPending) {
            // A third wallpaper: copy the current composite with grabToImage, then
            // restart the transition playing on top of that frozen frame once the
            // grab completes
            redirectPending = true;
            if (transitionAnim.running)
                transitionAnim.pause();
            if (compositeEffect.grabToImage(result => {
                if (!root.redirectPending)
                    return;
                root.frozenGrab = result; // keep the grab alive while frozenImage uses its url
                frozenImage.source = result.url;
                root.finalizeRedirect();
            })) {
                redirectTimer.restart();
            } else {
                finalizeRedirect();
            }
        }
        // else: a redirect is pending; finalizeRedirect picks up the latest source
    }

    function finalizeRedirect(): void {
        cancelRedirect();

        if (!transitioning) {
            applySourceChange();
            return;
        }

        const savedOutgoing = outgoingSlot;
        const savedType = Config.background.transitionInterruptReplay === "new" ? resolveTransitionType() : activeTransitionType;
        redirecting = true;
        transitionAnim.stop();
        redirecting = false;

        // frozenImage already holds the frozen composite, so progress 0 renders the
        // exact pixels that were on screen; falls back to re-grabbing the outgoing
        // slot (old wallpaper) if the frozen frame is unavailable, so the from
        // layer is never blank
        const frozen = frozenImage.status === Image.Ready && frozenImage.source != "" ? frozenImage : null;
        startTransition(savedOutgoing, savedOutgoing === one ? two : one, savedType, frozen);
    }

    onSourceChanged: applySourceChange()

    Component.onCompleted: {
        if (source)
            Qt.callLater(() => {
                one.update();
                completed = true;
            });
        else
            completed = true;
    }

    // No-wallpaper placeholder
    Loader {
        asynchronous: true
        anchors.fill: parent

        active: root.completed && !root.source

        sourceComponent: StyledRect {
            color: Colours.palette.m3surfaceContainer

            Row {
                anchors.centerIn: parent
                spacing: Tokens.spacing.largeIncreased

                MaterialIcon {
                    text: "sentiment_stressed"
                    color: Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.builders.extraLarge.scale(5).build()
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Tokens.spacing.small

                    StyledText {
                        text: qsTr("Wallpaper missing?")
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.builders.large.size(28 * 2).weight(Font.Bold).build()
                    }

                    StyledRect {
                        implicitWidth: selectWallText.implicitWidth + Tokens.padding.extraLargeIncreased
                        implicitHeight: selectWallText.implicitHeight + Tokens.padding.small

                        radius: Tokens.rounding.full
                        color: Colours.palette.m3primary

                        FileDialog {
                            id: dialog

                            title: qsTr("Select a wallpaper")
                            filterLabel: qsTr("Image/video files")
                            filters: Images.validWallpaperExtensions
                            onAccepted: path => Wallpapers.setWallpaper(path)
                        }

                        StateLayer {
                            radius: parent.radius
                            color: Colours.palette.m3onPrimary
                            onClicked: dialog.open()
                        }

                        StyledText {
                            id: selectWallText

                            anchors.centerIn: parent

                            text: qsTr("Set it now!")
                            color: Colours.palette.m3onPrimary
                            font: Tokens.font.body.large
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        z: -1
        visible: !["cover", "stretch"].includes(Config.background.fillMode)
        color: Config.background.fillColor
    }

    Slot {
        id: one
    }

    Slot {
        id: two
    }

    // Transition overlay
    Item {
        id: transitionOverlay

        anchors.fill: parent
        visible: root.transitioning
        z: 10

        // Frozen texture of the outgoing wallpaper for normal transition starts
        ShaderEffectSource {
            id: fromSource

            anchors.fill: parent
            live: false
            visible: false
        }

        // CPU-side copy of the interrupted composite (grabToImage), so the new
        // transition can play on top of the frozen frame without a texture
        // feedback cycle
        Image {
            id: frozenImage

            anchors.fill: parent
            visible: false
            asynchronous: false
            cache: false
            fillMode: Image.Stretch
        }

        // Live texture of the incoming wallpaper so videos/gifs play during the transition
        ShaderEffectSource {
            id: toSource

            anchors.fill: parent
            sourceItem: root.incomingSlot
            live: root.incomingSlot && Images.isValidVideoByName(root.incomingSlot.path)
            visible: false
        }

        ShaderEffect {
            id: compositeEffect

            readonly property variant fromTex: root.fromFrozen ? frozenImage : fromSource
            readonly property variant toTex: toSource
            readonly property real progress: root.transitionProgress
            readonly property real aspectRatio: height > 0 ? width / height : 1
            readonly property point centre: root.transitionCentre
            readonly property vector4d params: root.transitionParams
            readonly property vector4d fillColor: Qt.vector4d(root.transitionFillColor.r, root.transitionFillColor.g, root.transitionFillColor.b, root.transitionFillColor.a)

            anchors.fill: parent
            blending: false
            fragmentShader: root.shaderFor(root.activeTransitionType)
        }

        NumberAnimation {
            id: transitionAnim

            target: root
            property: "transitionProgress"
            easing.type: {
                if (root.easingPoints.length >= 6)
                    return Easing.Bezier;

                switch (Config.background.transitionEasing) {
                case "outCubic": return Easing.OutCubic;
                case "outExpo": return Easing.OutExpo;
                case "linear": return Easing.Linear;
                case "inCubic": return Easing.InCubic;
                default: return Easing.InOutCubic;
                }
            }
            easing.bezierCurve: root.easingPoints

            onRunningChanged: {
                if (!running && root.transitioning && !root.redirecting)
                    root.finishTransition();
            }
        }

        // Fallback in case a scheduled grab never completes (e.g. no frame produced)
        Timer {
            id: redirectTimer

            interval: 250

            onTriggered: {
                if (root.redirectPending)
                    root.finalizeRedirect();
            }
        }
    }

    component Slot: Item {
        id: slot

        property string path
        property bool slotReady: false
        property bool itemReady: loader.item && loader.item.ready
        readonly property bool video: Images.isValidVideoByName(path)
        readonly property bool videoProgressAvailable: video && slotReady && (loader.item?.progressAvailable ?? false)
        readonly property real videoProgress: videoProgressAvailable ? loader.item.playbackProgress : 0

        function update(): void {
            if (path === root.source) {
                slotReady = true;
                if (!root.transitioning)
                    root.current = slot;
            } else {
                slotReady = false;
                path = root.source;
                if (loader.item && loader.item.ready)
                    slotReady = true;
            }
        }

        anchors.fill: parent
        z: root.current === slot ? 1 : 0

        opacity: {
            if (root.transitioning) {
                if (root.incomingSlot === slot || root.outgoingSlot === slot)
                    return 1;
            }
            return root.current === slot ? 1 : 0;
        }

        scale: {
            if (root.transitioning)
                return 1;
            if (root.current === slot)
                return 1;
            return Wallpapers.showPreview ? 1 : 0.8;
        }

        onPathChanged: {
            slotReady = false;
            if (!path)
                loader.setSource("");
            else if (Images.isValidVideoByName(path))
                loader.setSource("WallpaperVideo.qml", { path });
            else if (Images.isAnimatedImageByName(path))
                loader.setSource("WallpaperAnimated.qml", { path });
            else
                loader.setSource("WallpaperImage.qml", { path });
        }

        onItemReadyChanged: {
            if (itemReady) {
                slot.slotReady = true;
                if (!root.hasTransition) {
                    root.current = slot;
                } else if (root.transitioning && root.incomingSlot === slot && !transitionAnim.running) {
                    root.runAnim(0, 1);
                }
            }
        }

        Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
        }
        Behavior on scale {
            NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
        }

        // Opaque backing so the letterbox area never shows the slot underneath
        Rectangle {
            anchors.fill: parent
            visible: slot.path.length > 0 && !["cover", "stretch"].includes(Config.background.fillMode)
            color: Config.background.fillColor
        }

        Loader {
            id: loader

            anchors.fill: parent
            asynchronous: true

            onStatusChanged: {
                if (status === Loader.Error && Images.isValidVideoByName(slot.path)) {
                    console.warn("Wallpaper: failed to load video player (is QtMultimedia installed?), falling back to a static frame");
                    setSource("WallpaperImage.qml", {
                        path: Wallpapers.videoFramePath(slot.path)
                    });
                }
            }
        }

        Connections {
            target: loader.item
            ignoreUnknownSignals: true

            function onDecodeFailed(): void {
                console.warn(`Wallpaper: no video frames decoded for ${slot.path} (unsupported codec?), falling back to a static frame`);
                loader.setSource("WallpaperImage.qml", {
                    path: Wallpapers.videoFramePath(slot.path)
                });
            }
        }
    }
}
