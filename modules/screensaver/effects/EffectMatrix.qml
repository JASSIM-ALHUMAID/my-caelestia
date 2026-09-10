import QtQuick
import Caelestia.Config
import qs.services

Item {
    id: root

    readonly property var glyphs: "アイウエオカキクケコサシスセソタチツテトナニヌネノ0123456789".split("")
    readonly property int minimumTrailLength: 9
    readonly property int maximumTrailLength: 16
    readonly property int glyphSize: Math.max(20, Math.round(fm.height * 1.1))
    readonly property real columnGap: Math.max(5, root.cellWidth * 0.28)
    readonly property real rowGap: Math.max(2, root.cellHeight * 0.08)
    readonly property real columnPitch: root.cellWidth + root.columnGap
    readonly property real rowPitch: root.cellHeight + root.rowGap
    readonly property string fontSpec: `${root.glyphSize}px "${fm.font.family}"`
    readonly property color backgroundColour: "#020604"
    readonly property color headColour: "#e7fff0"
    readonly property color leadColour: "#7dffad"
    readonly property color trailColour: "#26d96d"
    readonly property color glowColour: "#37ff82"

    property var drops: []
    property real cellWidth: 0
    property real cellHeight: 0
    property int frame: 0

    function randomGlyph(): string {
        return root.glyphs[Math.floor(Math.random() * root.glyphs.length)];
    }

    function createGlyphs(length: int): var {
        const out = [];
        for (let i = 0; i < length; i++)
            out.push(root.randomGlyph());
        return out;
    }

    function wantedColumnCount(): int {
        if (root.cellWidth <= 0)
            return 0;
        return Math.max(1, Math.floor((root.width + root.columnGap) / root.columnPitch));
    }

    function rebuildDrops(): void {
        const ctx = canvas.getContext("2d");
        if (!ctx)
            return;

        ctx.font = root.fontSpec;
        let widestGlyph = 0;
        for (const glyph of root.glyphs)
            widestGlyph = Math.max(widestGlyph, ctx.measureText(glyph).width);

        root.cellWidth = Math.max(1, Math.ceil(widestGlyph));
        root.cellHeight = root.glyphSize;

        const columns = root.wantedColumnCount();
        const rows = Math.ceil(root.height / root.rowPitch);
        const out = [];
        for (let i = 0; i < columns; i++) {
            const length = root.minimumTrailLength + Math.floor(Math.random() * (root.maximumTrailLength - root.minimumTrailLength + 1));
            out.push({
                head: Math.random() * (rows + length) - length,
                speed: 0.14 + Math.random() * 0.24,
                length,
                glyphs: root.createGlyphs(length),
                mutationCountdown: 4 + Math.floor(Math.random() * 12),
                brightness: 0.78 + Math.random() * 0.22,
                phase: Math.random() * Math.PI * 2
            });
        }
        root.drops = out;
    }

    FontMetrics {
        id: fm

        font: Tokens.font.mono.builders.medium.build()
    }

    Rectangle {
        anchors.fill: parent

        color: root.backgroundColour
    }

    Canvas {
        id: canvas

        anchors.fill: parent
        antialiasing: true

        onPaint: {
            const ctx = getContext("2d");
            if (root.cellWidth <= 0 || root.drops.length !== root.wantedColumnCount())
                root.rebuildDrops();
            if (root.drops.length === 0)
                return;

            ctx.clearRect(0, 0, width, height);
            ctx.font = root.fontSpec;
            ctx.textAlign = "center";
            ctx.textBaseline = "top";
            root.frame++;

            for (let i = 0; i < root.drops.length; i++) {
                const drop = root.drops[i];
                drop.head += drop.speed;
                if ((drop.head - drop.length) * root.rowPitch > root.height)
                    drop.head = -1 - Math.random() * Math.max(drop.length, root.height / root.rowPitch * 0.65);

                drop.mutationCountdown--;
                if (drop.mutationCountdown <= 0) {
                    const mutationIndex = Math.floor(Math.random() * drop.length);
                    drop.glyphs[mutationIndex] = root.randomGlyph();
                    drop.mutationCountdown = 4 + Math.floor(Math.random() * 12);
                }

                const x = root.columnGap / 2 + root.cellWidth / 2 + i * root.columnPitch;
                const pulse = 0.92 + Math.sin(root.frame * 0.055 + drop.phase) * 0.08;
                for (let j = 0; j < drop.length; j++) {
                    const y = (drop.head - j) * root.rowPitch;
                    if (y > root.height)
                        continue;
                    if (y < -root.cellHeight)
                        break;

                    if (j === 0) {
                        ctx.globalAlpha = 0.98 * drop.brightness * pulse;
                        ctx.fillStyle = root.headColour;
                        ctx.shadowBlur = 9;
                        ctx.shadowColor = root.glowColour;
                    } else if (j < 3) {
                        ctx.globalAlpha = (0.92 - j * 0.16) * drop.brightness;
                        ctx.fillStyle = root.leadColour;
                        ctx.shadowBlur = 0;
                    } else {
                        const trailProgress = j / (drop.length - 1);
                        ctx.globalAlpha = Math.pow(1 - trailProgress, 1.35) * 0.72 * drop.brightness;
                        ctx.fillStyle = root.trailColour;
                        ctx.shadowBlur = 0;
                    }

                    ctx.fillText(drop.glyphs[j], x, y);
                }
            }
            ctx.globalAlpha = 1.0;
            ctx.shadowBlur = 0;
        }
    }

    Timer {
        interval: 50
        repeat: true
        running: true

        onTriggered: canvas.requestPaint()
    }
}
