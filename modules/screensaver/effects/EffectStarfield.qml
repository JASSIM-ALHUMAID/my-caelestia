import QtQuick

Item {
    id: root

    readonly property int starCount: Math.max(90, Math.min(260, Math.round(width * height / 5200)))
    readonly property real depth: Math.max(width, height)
    readonly property real focalLength: Math.min(width, height) * 0.9

    property var stars: []

    function resetStar(star: var, randomDepth: bool): void {
        star.x = (Math.random() - 0.5) * root.width * 1.7;
        star.y = (Math.random() - 0.5) * root.height * 1.7;
        star.z = randomDepth ? 20 + Math.random() * root.depth : root.depth;
        star.velocity = 2.2 + Math.random() * 3.4;
        star.tone = Math.random();
    }

    function rebuildStars(): void {
        const out = [];
        for (let i = 0; i < root.starCount; i++) {
            const star = {};
            root.resetStar(star, true);
            out.push(star);
        }
        root.stars = out;
    }

    onWidthChanged: {
        root.stars = [];
        canvas.requestPaint();
    }
    onHeightChanged: {
        root.stars = [];
        canvas.requestPaint();
    }

    Rectangle {
        anchors.fill: parent

        color: "#02040c"
    }

    Canvas {
        id: canvas

        anchors.fill: parent
        antialiasing: true

        onPaint: {
            if (root.stars.length !== root.starCount)
                root.rebuildStars();

            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            ctx.lineCap = "round";

            const centreX = width / 2;
            const centreY = height / 2;
            for (const star of root.stars) {
                star.z -= star.velocity;
                if (star.z <= 6)
                    root.resetStar(star, false);

                const scale = root.focalLength / star.z;
                const approach = 1 - Math.min(1, star.z / root.depth);
                const trailDepth = Math.min(root.depth, star.z + star.velocity * (4 + approach * 10));
                const previousScale = root.focalLength / trailDepth;
                const x = centreX + star.x * scale;
                const y = centreY + star.y * scale;
                const previousX = centreX + star.x * previousScale;
                const previousY = centreY + star.y * previousScale;

                if (x < -30 || x > width + 30 || y < -30 || y > height + 30) {
                    root.resetStar(star, false);
                    continue;
                }

                ctx.globalAlpha = 0.22 + approach * 0.78;
                ctx.strokeStyle = star.tone > 0.75 ? "#b8d4ff" : star.tone > 0.38 ? "#dff7ff" : "#ffffff";
                ctx.lineWidth = 0.6 + approach * 2.1;
                ctx.beginPath();
                ctx.moveTo(previousX, previousY);
                ctx.lineTo(x, y);
                ctx.stroke();

                ctx.fillStyle = "#ffffff";
                ctx.beginPath();
                ctx.arc(x, y, 0.7 + approach * 1.6, 0, Math.PI * 2);
                ctx.fill();
            }
            ctx.globalAlpha = 1;
        }
    }

    Timer {
        interval: 33
        repeat: true
        running: true

        onTriggered: canvas.requestPaint()
    }
}
