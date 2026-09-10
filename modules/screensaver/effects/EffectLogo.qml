import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.nexus.common

Item {
    id: root

    readonly property int starCount: Math.max(48, Math.min(100, Math.round(width * height / 9000)))

    property var stars: []
    property real starPhase: 0

    function rebuildStars(): void {
        const out = [];
        const orbitCount = Math.max(10, Math.round(root.starCount * 0.2));
        for (let i = 0; i < root.starCount; i++) {
            let nx;
            let ny;
            if (i < orbitCount) {
                const angle = Math.PI * 2 * i / orbitCount + (Math.random() - 0.5) * 0.22;
                nx = 0.5 + Math.cos(angle) * (0.19 + Math.random() * 0.045);
                ny = 0.46 + Math.sin(angle) * (0.27 + Math.random() * 0.045);
            } else {
                do {
                    nx = 0.04 + Math.random() * 0.92;
                    ny = 0.05 + Math.random() * 0.9;
                } while (Math.pow((nx - 0.5) / 0.18, 2) + Math.pow((ny - 0.46) / 0.25, 2) < 1);
            }

            out.push({
                x: nx,
                y: ny,
                radius: 0.65 + Math.random() * 1.55,
                phase: Math.random() * Math.PI * 2,
                speed: 0.65 + Math.random() * 1.25,
                drift: 0.5 + Math.random() * 1.8,
                tone: Math.random(),
                flare: Math.random() > 0.84
            });
        }
        root.stars = out;
    }

    onWidthChanged: {
        root.stars = [];
        starCanvas.requestPaint();
    }
    onHeightChanged: {
        root.stars = [];
        starCanvas.requestPaint();
    }

    Canvas {
        id: starCanvas

        anchors.fill: parent
        antialiasing: true

        onPaint: {
            if (root.stars.length !== root.starCount)
                root.rebuildStars();

            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            ctx.lineCap = "round";

            for (const star of root.stars) {
                const wave = Math.sin(root.starPhase * star.speed + star.phase);
                const pulse = 0.5 + wave * 0.5;
                const x = star.x * width + Math.sin(root.starPhase * 0.38 + star.phase) * star.drift;
                const y = star.y * height + Math.cos(root.starPhase * 0.31 + star.phase) * star.drift;
                const colour = star.tone > 0.72 ? "#d9ccff" : star.tone > 0.35 ? "#b9e7ff" : "#ffffff";
                const radius = star.radius * (0.72 + pulse * 0.38);

                ctx.globalAlpha = 0.34 + pulse * 0.62;
                ctx.shadowBlur = 5 + radius * 5 + pulse * 4;
                ctx.shadowColor = colour;
                ctx.fillStyle = colour;
                ctx.beginPath();
                ctx.arc(x, y, radius, 0, Math.PI * 2);
                ctx.fill();

                if (star.flare && pulse > 0.42) {
                    const ray = radius * (2.6 + pulse * 2.6);
                    ctx.globalAlpha = (pulse - 0.25) * 0.7;
                    ctx.lineWidth = Math.max(0.55, radius * 0.38);
                    ctx.strokeStyle = colour;
                    ctx.beginPath();
                    ctx.moveTo(x - ray, y);
                    ctx.lineTo(x + ray, y);
                    ctx.moveTo(x, y - ray);
                    ctx.lineTo(x, y + ray);
                    ctx.stroke();
                }
            }
            ctx.globalAlpha = 1;
            ctx.shadowBlur = 0;
        }
    }

    ColumnLayout {
        id: content

        anchors.centerIn: parent
        spacing: Tokens.spacing.large

        AnimatedLogo {
            id: logo

            Layout.alignment: Qt.AlignHCenter

            skipIntroAnimation: true
            width: Math.min(root.width, root.height) * 0.35
            height: logo.width * (logo.implicitHeight / logo.implicitWidth)
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter

            text: "CAELESTIA"
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.title.builders.large.letterSpacing(4).build()
            opacity: 0.7
        }
    }

    SequentialAnimation {
        running: true
        loops: Animation.Infinite

        ParallelAnimation {
            SequentialAnimation {
                NumberAnimation {
                    target: logo
                    property: "scale"
                    from: 1.0
                    to: 1.03
                    duration: 3500
                    easing.type: Easing.InOutSine
                }

                NumberAnimation {
                    target: logo
                    property: "scale"
                    from: 1.03
                    to: 1.0
                    duration: 3500
                    easing.type: Easing.InOutSine
                }
            }

            SequentialAnimation {
                NumberAnimation {
                    target: logo
                    property: "rotation"
                    from: 0
                    to: 2
                    duration: 5000
                    easing.type: Easing.InOutSine
                }

                NumberAnimation {
                    target: logo
                    property: "rotation"
                    from: 2
                    to: 0
                    duration: 5000
                    easing.type: Easing.InOutSine
                }
            }
        }
    }

    Timer {
        interval: 50
        repeat: true
        running: true

        onTriggered: {
            root.starPhase += 0.035;
            starCanvas.requestPaint();
        }
    }
}
