import QtQuick

Item {
    id: root

    readonly property int particleCount: Math.max(54, Math.min(96, Math.round(width * height / 11000)))
    readonly property real linkDistance: Math.max(112, Math.min(170, Math.min(width, height) * 0.21))

    property var particles: []
    property real phase: 0

    function rebuildParticles(): void {
        const out = [];
        for (let i = 0; i < root.particleCount; i++) {
            const angle = Math.random() * Math.PI * 2;
            const speed = 0.12 + Math.random() * 0.26;
            out.push({
                x: Math.random() * root.width,
                y: Math.random() * root.height,
                vx: Math.cos(angle) * speed,
                vy: Math.sin(angle) * speed,
                radius: 1.2 + Math.random() * 1.8,
                tone: Math.random(),
                phase: Math.random() * Math.PI * 2
            });
        }
        root.particles = out;
    }

    onWidthChanged: {
        root.particles = [];
        canvas.requestPaint();
    }
    onHeightChanged: {
        root.particles = [];
        canvas.requestPaint();
    }

    Rectangle {
        anchors.fill: parent

        color: "#030611"

        gradient: Gradient {
            GradientStop { position: 0; color: "#090b20" }
            GradientStop { position: 0.55; color: "#040817" }
            GradientStop { position: 1; color: "#02040b" }
        }
    }

    Canvas {
        id: canvas

        anchors.fill: parent
        antialiasing: true

        onPaint: {
            if (root.particles.length !== root.particleCount)
                root.rebuildParticles();

            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);

            for (const particle of root.particles) {
                particle.x += particle.vx + Math.sin(root.phase + particle.phase) * 0.035;
                particle.y += particle.vy + Math.cos(root.phase * 0.8 + particle.phase) * 0.025;

                if (particle.x < 0) {
                    particle.x = 0;
                    particle.vx = Math.abs(particle.vx);
                } else if (particle.x > width) {
                    particle.x = width;
                    particle.vx = -Math.abs(particle.vx);
                }
                if (particle.y < 0) {
                    particle.y = 0;
                    particle.vy = Math.abs(particle.vy);
                } else if (particle.y > height) {
                    particle.y = height;
                    particle.vy = -Math.abs(particle.vy);
                }
            }

            ctx.lineWidth = 0.8;
            ctx.strokeStyle = "#7e9dff";
            for (let i = 0; i < root.particles.length; i++) {
                const first = root.particles[i];
                for (let j = i + 1; j < root.particles.length; j++) {
                    const second = root.particles[j];
                    const dx = first.x - second.x;
                    const dy = first.y - second.y;
                    const distance = Math.sqrt(dx * dx + dy * dy);
                    if (distance >= root.linkDistance)
                        continue;

                    ctx.globalAlpha = Math.pow(1 - distance / root.linkDistance, 1.7) * 0.5;
                    ctx.beginPath();
                    ctx.moveTo(first.x, first.y);
                    ctx.lineTo(second.x, second.y);
                    ctx.stroke();
                }
            }

            for (const particle of root.particles) {
                const pulse = 0.84 + Math.sin(root.phase * 1.8 + particle.phase) * 0.16;
                ctx.globalAlpha = pulse;
                ctx.fillStyle = particle.tone > 0.72 ? "#d4c6ff" : particle.tone > 0.35 ? "#8fdcff" : "#ffffff";
                ctx.shadowBlur = 8;
                ctx.shadowColor = particle.tone > 0.72 ? "#a477ff" : "#5ac8ff";
                ctx.beginPath();
                ctx.arc(particle.x, particle.y, particle.radius, 0, Math.PI * 2);
                ctx.fill();
            }
            ctx.globalAlpha = 1;
            ctx.shadowBlur = 0;
        }
    }

    Timer {
        interval: 33
        repeat: true
        running: true

        onTriggered: {
            root.phase += 0.018;
            canvas.requestPaint();
        }
    }
}
