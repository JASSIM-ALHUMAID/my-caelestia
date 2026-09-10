import QtQuick

Item {
    id: root

    readonly property int ribbonCount: 4

    property real phase: 0

    function fract(value: real): real {
        return value - Math.floor(value);
    }

    function noise(seed: real): real {
        return root.fract(Math.sin(seed * 12.9898) * 43758.5453);
    }

    function paintRibbon(ctx: var, index: int): void {
        const palette = [
            ["rgba(26,255,166,0.00)", "rgba(26,255,166,0.26)", "rgba(38,214,255,0.04)"],
            ["rgba(61,190,255,0.00)", "rgba(61,190,255,0.20)", "rgba(145,92,255,0.03)"],
            ["rgba(126,255,207,0.00)", "rgba(126,255,207,0.17)", "rgba(33,182,255,0.03)"],
            ["rgba(169,94,255,0.00)", "rgba(169,94,255,0.14)", "rgba(31,255,190,0.02)"]
        ][index];
        const base = root.height * (0.22 + index * 0.105);
        const thickness = root.height * (0.17 + index * 0.025);
        const speed = root.phase * (0.7 + index * 0.13);
        const step = Math.max(12, root.width / 72);

        ctx.beginPath();
        ctx.moveTo(0, root.height);
        for (let x = 0; x <= root.width + step; x += step) {
            const normalX = x / Math.max(1, root.width);
            const wave = Math.sin(normalX * Math.PI * (2.1 + index * 0.28) + speed) * root.height * 0.085;
            const detail = Math.sin(normalX * Math.PI * 7.4 - speed * 1.7 + index) * root.height * 0.022;
            ctx.lineTo(x, base + wave + detail);
        }
        for (let x = root.width + step; x >= 0; x -= step) {
            const normalX = x / Math.max(1, root.width);
            const wave = Math.sin(normalX * Math.PI * (2.1 + index * 0.28) + speed + 0.42) * root.height * 0.07;
            const detail = Math.sin(normalX * Math.PI * 5.8 - speed * 1.2 + index * 0.8) * root.height * 0.018;
            ctx.lineTo(x, base + thickness + wave + detail);
        }
        ctx.closePath();

        const gradient = ctx.createLinearGradient(0, base - thickness * 0.3, 0, base + thickness * 1.4);
        gradient.addColorStop(0, palette[0]);
        gradient.addColorStop(0.38, palette[1]);
        gradient.addColorStop(1, palette[2]);
        ctx.fillStyle = gradient;
        ctx.shadowBlur = 26;
        ctx.shadowColor = index % 2 === 0 ? "#24ffad" : "#546dff";
        ctx.fill();
    }

    Rectangle {
        anchors.fill: parent

        color: "#020713"
    }

    Canvas {
        id: canvas

        anchors.fill: parent
        antialiasing: true

        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);

            ctx.shadowBlur = 0;
            for (let i = 0; i < 70; i++) {
                const x = root.noise(i + 2.1) * width;
                const y = root.noise(i + 18.7) * height * 0.72;
                const shimmer = 0.35 + Math.sin(root.phase * 2 + i) * 0.2;
                ctx.globalAlpha = shimmer;
                ctx.fillStyle = i % 7 === 0 ? "#9fc8ff" : "#ffffff";
                ctx.fillRect(x, y, i % 9 === 0 ? 1.5 : 1, i % 9 === 0 ? 1.5 : 1);
            }

            ctx.globalCompositeOperation = "lighter";
            for (let i = root.ribbonCount - 1; i >= 0; i--)
                root.paintRibbon(ctx, i);
            ctx.globalCompositeOperation = "source-over";
            ctx.shadowBlur = 0;

            const veil = ctx.createLinearGradient(0, height * 0.45, 0, height);
            veil.addColorStop(0, "rgba(2,7,19,0)");
            veil.addColorStop(1, "rgba(2,7,19,0.78)");
            ctx.globalAlpha = 1;
            ctx.fillStyle = veil;
            ctx.fillRect(0, height * 0.45, width, height * 0.55);
        }
    }

    Timer {
        interval: 40
        repeat: true
        running: true

        onTriggered: {
            root.phase += 0.018;
            canvas.requestPaint();
        }
    }
}
