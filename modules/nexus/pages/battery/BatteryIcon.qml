pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Components
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

StyledRect {
    id: root

    required property real percentage
    required property bool charging
    property int style: 0 // 0=vertical tank, 1=horizontal fill, 2=circular progress

    // Color properties with palette defaults - override as needed
    property color trackColor: Colours.tPalette.m3surfaceContainerHigh
    property color onTrackColor: Colours.palette.m3onSurface
    property color fillColor: Colours.palette.m3primary
    property color onFillColor: Colours.palette.m3onPrimary
    property color labelColor: Colours.palette.m3onSurface // circular style only

    // Fill animation
    property bool wavy: false
    property bool wavePaused: false
    property int waveStyle: 0 // 0=liquid wave, 1=shimmer, 2=both
    readonly property int waveFrequency: 8
    readonly property int waveDuration: 2000
    readonly property bool liquidWave: wavy && waveStyle !== 1
    readonly property bool shimmer: wavy && waveStyle !== 0
    readonly property int shimmerDuration: 2400

    // Wavelength is fullLength / frequency; tuned for the battery's own geometry, not
    // the much wider dashboard media bars. In filled mode lineWidth draws nothing and
    // only scales the amplitude (amplitude = lineWidth * amplitudeMultiplier).
    readonly property int surfaceWaveFrequency: 2
    readonly property int surfaceWaveWidth: 20
    readonly property real surfaceWaveAmplitude: surfaceWaveWidth * 0.5 * contentScale
    // paintLinear insets the drawn path by lineWidth / 2 at each end, so the overhang
    // has to clear that before it buys any real coverage past the clip
    readonly property real waveOverhang: surfaceWaveWidth * contentScale

    // Charging animations - each gated internally on `charging`, so callers only pass
    // the config value through
    property bool boltPulse: false
    property int boltPulseStrength: 1 // 0=subtle, 1=clear, 2=strong
    property bool energisedWave: false
    property bool glow: false
    property bool bubbles: false

    // Randomiser. The four toggles above are the pool: with randomise off every
    // checked effect plays, with it on a random 1-2 of them play at a time.
    property bool randomise: false
    property int randomTrigger: 2 // 0=on plug in, 1=on timer, 2=both
    property int randomInterval: 30 // seconds

    enum Effect {
        EffectBoltPulse,
        EffectEnergisedWave,
        EffectGlow,
        EffectBubbles
    }

    readonly property var effectPool: {
        const pool = [];
        if (boltPulse)
            pool.push(BatteryIcon.EffectBoltPulse);
        if (energisedWave)
            pool.push(BatteryIcon.EffectEnergisedWave);
        if (glow)
            pool.push(BatteryIcon.EffectGlow);
        if (bubbles && style !== 2)
            pool.push(BatteryIcon.EffectBubbles);
        return pool;
    }

    property var activeEffects: []

    function rollEffects(): void {
        const pool = root.effectPool;
        if (pool.length === 0) {
            root.activeEffects = [];
            return;
        }

        // Fisher-Yates, then take 1-2. Deliberate randomness here, unlike the bubble
        // positions, which are index-derived so they stay stable across reloads.
        const shuffled = pool.slice();
        for (let i = shuffled.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            const tmp = shuffled[i];
            shuffled[i] = shuffled[j];
            shuffled[j] = tmp;
        }
        root.activeEffects = shuffled.slice(0, Math.min(pool.length, 1 + Math.floor(Math.random() * 2)));
    }

    function effectActive(effect: int): bool {
        return !root.randomise || root.activeEffects.indexOf(effect) >= 0;
    }

    onChargingChanged: {
        // Trigger 1 is timer-only, so it does not re-roll on plug in
        if (charging && randomise && randomTrigger !== 1)
            rollEffects();
    }

    onRandomiseChanged: {
        if (randomise && charging)
            rollEffects();
    }

    onEffectPoolChanged: {
        if (randomise && charging)
            rollEffects();
    }

    Timer {
        running: root.randomise && root.charging && root.randomTrigger !== 0
        interval: Math.max(1, root.randomInterval) * 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.rollEffects()
    }

    readonly property bool boltPulsing: charging && boltPulse && effectActive(BatteryIcon.EffectBoltPulse)
    readonly property bool glowing: charging && glow && effectActive(BatteryIcon.EffectGlow)
    readonly property bool bubbling: charging && bubbles && effectActive(BatteryIcon.EffectBubbles)
    readonly property bool energised: charging && energisedWave && effectActive(BatteryIcon.EffectEnergisedWave)

    // The wave runs faster and taller while charging
    readonly property real waveAmplitude: energised ? 0.75 : 0.5
    readonly property int effectiveWaveDuration: energised ? waveDuration / 2 : waveDuration

    // Peak and rhythm per strength setting. Deliberately explicit durations rather than
    // Anim token types - the whole point is not to inherit a duration that fights the
    // intended rhythm, which is what made the first attempt at this invisible.
    readonly property real boltPulsePeak: [1.18, 1.3, 1.45][boltPulseStrength] ?? 1.3
    readonly property int boltPulsePeriod: [800, 600, 500][boltPulseStrength] ?? 600

    // Drivers the per-style visuals feed off. Both must return to their resting value
    // when their animation stops, or the bolt is left shrunk / the glow stuck on.
    property real boltPulseScale: 1
    property real glowAmount: 0

    SequentialAnimation on boltPulseScale {
        running: root.boltPulsing
        loops: Animation.Infinite
        alwaysRunToEnd: true

        NumberAnimation {
            to: root.boltPulsePeak
            duration: root.boltPulsePeriod
            easing.type: Easing.InOutSine
        }

        NumberAnimation {
            to: 1
            duration: root.boltPulsePeriod
            easing.type: Easing.InOutSine
        }

        onStopped: root.boltPulseScale = 1
    }

    SequentialAnimation on glowAmount {
        running: root.glowing
        loops: Animation.Infinite
        alwaysRunToEnd: true

        NumberAnimation {
            to: 1
            duration: 1250
            easing.type: Easing.InOutSine
        }

        NumberAnimation {
            to: 0
            duration: 1250
            easing.type: Easing.InOutSine
        }

        onStopped: root.glowAmount = 0
    }

    // Low battery overrides the fill with the error role
    readonly property bool low: !charging && animPerc <= lowThreshold
    readonly property int lowThreshold: 20
    readonly property color effectiveFillColor: low ? Colours.palette.m3error : fillColor
    readonly property color effectiveOnFillColor: low ? Colours.palette.m3onError : onFillColor

    // The breathing glow is a colour, not an overlay - an overlay rectangle can only
    // cover the flat fill and stops dead at the wave crests, which reads as the fill
    // and the wave being two different colours. Everything that paints the fill binds
    // to this so they breathe as one.
    readonly property color animatedFillColor: glowAmount > 0 ? Qt.lighter(effectiveFillColor, 1 + glowAmount * 0.18) : effectiveFillColor

    property real animPerc: percentage

    // Scale factor for internal elements
    readonly property real contentScale: {
        if (implicitWidth <= 0 || implicitHeight <= 0)
            return 1;
        return Math.max(0.01, Math.min(width / implicitWidth, height / implicitHeight));
    }

    // Layout dimensions
    readonly property int verticalWidth: 180
    readonly property int verticalHeight: 220
    readonly property int horizontalWidth: 240
    readonly property int horizontalHeight: 120
    readonly property int circularSize: 180

    // Battery body dimensions (base values, will be scaled)
    readonly property int bodyWidth: 100
    readonly property int bodyHeight: 160
    readonly property int bodyMargins: 6
    readonly property int bodyMarginDouble: bodyMargins * 2
    readonly property real scaledMargins: bodyMargins * contentScale

    // Horizontal battery dimensions (base values, will be scaled)
    readonly property int hBodyWidth: 200
    readonly property int hBodyHeight: 100

    // Nub dimensions (base values, will be scaled)
    readonly property int nubWidth: 40
    readonly property int nubHeight: 10
    readonly property int nubOffset: 4
    readonly property int hNubWidth: 10
    readonly property int hNubHeight: 40

    // Charging icon offset (base value, will be scaled)
    readonly property int chargingIconOffset: 12

    // Circular progress dimensions (base values, will be scaled)
    readonly property int circularLineWidth: 12
    readonly property int circularRadiusOffset: circularLineWidth

    color: "transparent"
    implicitWidth: style === 1 ? horizontalWidth : style === 2 ? circularSize : verticalWidth
    implicitHeight: style === 1 ? horizontalHeight : style === 2 ? circularSize : verticalHeight

    Behavior on animPerc {
        Anim {}
    }

    // Vertical tank style
    Item {
        anchors.fill: parent
        visible: root.style === 0

        // Battery body background
        StyledRect {
            id: vTankBody

            anchors.centerIn: parent
            width: root.bodyWidth * root.contentScale
            height: root.bodyHeight * root.contentScale
            color: root.trackColor
            radius: Tokens.rounding.extraLarge

            // Battery nub at top - outside the body, so it must stay out of the clip
            StyledRect {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.top
                anchors.bottomMargin: root.nubOffset * root.contentScale
                width: root.nubWidth * root.contentScale
                height: root.nubHeight * root.contentScale
                color: root.trackColor
                radius: Tokens.rounding.small
            }

            // Contents on the track, covered by the fill where it overlaps
            BatteryContents {
                anchors.fill: parent
                textColour: root.onTrackColor
                iconColour: root.onTrackColor
            }

            // Clips the fill and its wave crests to the battery outline
            StyledClippingRect {
                id: vTankInner

                anchors.fill: parent
                anchors.margins: root.scaledMargins
                radius: Tokens.rounding.large

                // Liquid surface. The item's vertical centre sits on the level and its
                // bottom on the tank bottom, so the filled region below the sine is
                // exactly the liquid. Declared before the fill rect so the percentage
                // duplicate stays on top of it. Overhangs sideways so the sine covers
                // the fill's corners instead of stopping short of them.
                Wave {
                    width: parent.width + root.waveOverhang * 2
                    height: 2 * vTankFill.height
                    x: -root.waveOverhang
                    y: parent.height - 2 * vTankFill.height
                    filled: true
                    fullLength: width
                    value: 1
                }

                // Fill level. Painted only when the liquid wave is off; either way it
                // stays present as the clip source for the percentage duplicate.
                StyledClippingRect {
                    id: vTankFill

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: parent.height * root.animPerc / 100
                    color: root.liquidWave ? "transparent" : root.animatedFillColor
                    radius: Tokens.rounding.large

                    Shimmer {
                        vertical: true
                    }

                    Bubbles {}

                    // Duplicate of the track contents, clipped to the fill and aligned
                    // to the body so glyphs switch colour exactly at the fill edge
                    BatteryContents {
                        anchors.left: parent.left
                        anchors.leftMargin: -root.scaledMargins
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: -root.scaledMargins
                        width: vTankBody.width
                        height: vTankBody.height
                        textColour: root.effectiveOnFillColor
                        iconColour: root.effectiveOnFillColor
                    }

                    Behavior on height {
                        Anim {}
                    }
                }
            }
        }
    }

    // Horizontal fill style
    Item {
        anchors.fill: parent
        visible: root.style === 1

        // Battery body background
        StyledRect {
            id: hTankBody

            anchors.centerIn: parent
            width: root.hBodyWidth * root.contentScale
            height: root.hBodyHeight * root.contentScale
            color: root.trackColor
            radius: Tokens.rounding.extraLarge

            // Battery nub at right - outside the body, so it must stay out of the clip
            StyledRect {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.right
                anchors.leftMargin: root.nubOffset * root.contentScale
                width: root.hNubWidth * root.contentScale
                height: root.hNubHeight * root.contentScale
                color: root.trackColor
                radius: Tokens.rounding.small
            }

            // Contents on the track, covered by the fill where it overlaps
            BatteryContents {
                anchors.fill: parent
                horizontal: true
                textColour: root.onTrackColor
                iconColour: root.onTrackColor
            }

            // Clips the fill and its wave crests to the battery outline
            StyledClippingRect {
                id: hTankInner

                anchors.fill: parent
                anchors.margins: root.scaledMargins
                radius: Tokens.rounding.large

                // Liquid leading edge - the same filled wave on its side. rotation: 90
                // maps the item's local down to screen left, so the filled half lands
                // over the battery's left-anchored fill. Rotation is about the centre,
                // so the sine ends up on the vertical line through it. Overhangs past
                // both ends so it covers the fill's corners instead of stopping short.
                Wave {
                    width: parent.height + root.waveOverhang * 2
                    height: 2 * hTankFill.width
                    rotation: 90
                    x: hTankFill.width - width / 2
                    y: parent.height / 2 - height / 2
                    filled: true
                    fullLength: width
                    value: 1
                }

                // Fill level. Painted only when the liquid wave is off; either way it
                // stays present as the clip source for the percentage duplicate.
                StyledClippingRect {
                    id: hTankFill

                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: parent.width * root.animPerc / 100
                    color: root.liquidWave ? "transparent" : root.animatedFillColor
                    radius: Tokens.rounding.large

                    Shimmer {}

                    Bubbles {}

                    // Duplicate of the track contents, clipped to the fill and aligned
                    // to the body so glyphs switch colour exactly at the fill edge
                    BatteryContents {
                        anchors.left: parent.left
                        anchors.leftMargin: -root.scaledMargins
                        anchors.top: parent.top
                        anchors.topMargin: -root.scaledMargins
                        width: hTankBody.width
                        height: hTankBody.height
                        horizontal: true
                        textColour: root.effectiveOnFillColor
                        iconColour: root.effectiveOnFillColor
                    }

                    Behavior on width {
                        Anim {}
                    }
                }
            }
        }
    }

    // Circular progress style
    Item {
        anchors.fill: parent
        visible: root.style === 2

        CircularProgress {
            id: circularProgress

            anchors.centerIn: parent
            width: root.circularSize * root.contentScale
            height: width
            value: root.animPerc / 100
            startAngle: -90
            sweepAngle: 360
            strokeWidth: root.circularLineWidth * root.contentScale
            fgColour: root.animatedFillColor
            bgColour: root.trackColor
            wavy: root.wavy
            wavePaused: root.wavePaused
            waveFrequency: root.waveFrequency
            waveDuration: root.effectiveWaveDuration
            waveAmplitude: root.wavy ? root.waveAmplitude : 0
            hasEndIndicator: false
        }

        // Percentage text in center - sits on the background, not on the arc
        StyledText {
            anchors.centerIn: parent
            text: Math.round(root.animPerc) + "%"
            color: root.labelColor
            font: Tokens.font.clock.size(Tokens.font.headline.large.pointSize * root.contentScale).build()
        }

        // A small badge masks the arc below the glyph so the bolt does not merge into
        // the rounded stroke cap at the top of the circle.
        StyledRect {
            id: circularBolt

            anchors.horizontalCenter: parent.horizontalCenter
            y: circularProgress.y - height / 2 - 20 * root.contentScale
            width: 30 * root.contentScale
            height: width
            radius: Tokens.rounding.full
            color: root.trackColor
            visible: root.charging

            scale: root.charging ? 1 : 0
            opacity: root.charging ? 1 : 0

            MaterialIcon {
                anchors.centerIn: parent
                text: "bolt"
                color: root.animatedFillColor
                fontStyle: Tokens.font.icon.builders.medium.scale(root.contentScale).build()
                fill: 1
            }

            // The pulse rides a transform rather than `scale`: the Behavior below is a
            // 350ms low-pass filter that would swallow it entirely
            transform: Scale {
                origin.x: circularBolt.width / 2
                origin.y: circularBolt.height / 2
                xScale: root.boltPulseScale
                yScale: root.boltPulseScale
            }

            Behavior on scale {
                Anim {
                    type: Anim.FastSpatial
                }
            }

            Behavior on opacity {
                Anim {
                    type: Anim.FastEffects
                }
            }
        }
    }

    // Percentage text + charging bolt, drawn once on the track and once clipped
    // inside the fill so each glyph uses the on-colour of whatever is beneath it
    component BatteryContents: Item {
        id: contents

        required property color textColour
        required property color iconColour
        property bool horizontal: false

        StyledText {
            anchors.centerIn: parent
            text: Math.round(root.animPerc) + "%"
            color: contents.textColour
            font: Tokens.font.clock.size(Tokens.font.headline.medium.pointSize * root.contentScale).build()
        }

        MaterialIcon {
            id: bolt

            x: contents.horizontal ? root.chargingIconOffset * root.contentScale : (contents.width - width) / 2
            y: contents.horizontal ? (contents.height - height) / 2 : contents.height - height - root.scaledMargins
            text: "bolt"
            color: contents.iconColour
            fontStyle: Tokens.font.clock.size(Tokens.font.icon.medium.pointSize * root.contentScale).build()
            fill: 1
            visible: root.charging

            scale: root.charging ? 1 : 0
            opacity: root.charging ? 1 : 0

            // The pulse rides a transform rather than `scale`: the Behavior below is a
            // 350ms low-pass filter that would swallow it entirely
            transform: Scale {
                origin.x: bolt.width / 2
                origin.y: bolt.height / 2
                xScale: root.boltPulseScale
                yScale: root.boltPulseScale
            }

            Behavior on scale {
                Anim {
                    type: Anim.FastSpatial
                }
            }

            Behavior on opacity {
                Anim {
                    type: Anim.FastEffects
                }
            }
        }
    }

    // Shared wave bindings - phase is always running and merely paused, so it is
    // retained across pause/resume, and disabling flattens rather than pops
    component Wave: WavyLine {
        id: wave

        color: root.animatedFillColor
        frequency: root.surfaceWaveFrequency
        lineWidth: root.surfaceWaveWidth * root.contentScale
        amplitudeMultiplier: root.waveAmplitude

        // Fades rather than popping, so it crossfades with the fill rect taking over
        opacity: root.liquidWave ? 1 : 0
        visible: opacity > 0

        Anim on waveProgress {
            running: true
            paused: root.wavePaused || !root.liquidWave
            from: 0
            to: 1
            duration: root.effectiveWaveDuration
            easing.type: Easing.Linear
            loops: Animation.Infinite
        }

        // Gated while glowing: a 300ms CAnim chasing the breath would round its peaks
        Behavior on color {
            enabled: !root.glowing
            CAnim {}
        }

        Behavior on amplitudeMultiplier {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    // Rising bubbles. Lives inside the fill's clipping rect, so bubbles vanish at the
    // liquid surface for free. Positions and timings come from the index rather than
    // Math.random() so the layout is stable across reloads.
    component Bubbles: Item {
        id: bubbleField

        anchors.fill: parent
        visible: root.bubbling

        Repeater {
            model: 6

            delegate: Rectangle {
                id: bubble

                required property int index

                // Low-discrepancy sequences - spread without clustering
                readonly property real seed: (index * 0.6180339887) % 1
                readonly property real seed2: (index * 0.7548776662) % 1
                readonly property real progress: bubbleField.height > 0 ? 1 - (y + height) / bubbleField.height : 0

                width: (3 + seed2 * 3) * root.contentScale
                height: width
                radius: Tokens.rounding.full
                color: Qt.alpha(root.effectiveOnFillColor, 0.3)
                x: seed * Math.max(0, bubbleField.width - width)
                // Fade in off the bottom, fade out approaching the surface
                opacity: Math.min(1, progress * 6) * Math.min(1, (1 - progress) * 3)

                SequentialAnimation {
                    running: root.bubbling
                    loops: Animation.Infinite

                    PauseAnimation {
                        duration: bubble.index * 420
                    }

                    NumberAnimation {
                        target: bubble
                        property: "y"
                        from: bubbleField.height
                        to: -bubble.height
                        duration: 2400 + bubble.seed2 * 1600
                        easing.type: Easing.InOutSine
                    }
                }
            }
        }
    }

    // Charging shimmer - a highlight band sweeping across the fill. Lives inside the
    // fill's clipping rect so it never spills onto the track. Unlike the wave this
    // fades out rather than freezing: a shimmer stopped mid-sweep just reads as a
    // stray bright band.
    component Shimmer: Rectangle {
        id: shimmerBand

        property bool vertical: false

        readonly property real sweepLength: vertical ? parent.height : parent.width
        readonly property real bandLength: sweepLength * 0.35

        // x and y are driven by the sweep animations below, so they are deliberately
        // left unbound - a binding here would conflict with the value sources
        width: vertical ? parent.width : bandLength
        height: vertical ? bandLength : parent.height
        opacity: root.shimmer && !root.wavePaused ? 1 : 0
        visible: opacity > 0

        gradient: Gradient {
            orientation: shimmerBand.vertical ? Gradient.Vertical : Gradient.Horizontal

            GradientStop {
                position: 0
                color: "transparent"
            }

            GradientStop {
                position: 0.5
                color: Qt.alpha(root.effectiveOnFillColor, 0.22)
            }

            GradientStop {
                position: 1
                color: "transparent"
            }
        }

        NumberAnimation on x {
            running: root.shimmer && !shimmerBand.vertical
            from: -shimmerBand.bandLength
            to: shimmerBand.sweepLength
            duration: root.shimmerDuration
            easing.type: Easing.Linear
            loops: Animation.Infinite
        }

        NumberAnimation on y {
            running: root.shimmer && shimmerBand.vertical
            from: shimmerBand.sweepLength
            to: -shimmerBand.bandLength
            duration: root.shimmerDuration
            easing.type: Easing.Linear
            loops: Animation.Infinite
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }
}
