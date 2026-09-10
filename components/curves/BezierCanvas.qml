pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common
import "bezier.js" as Bezier

StyledRect {
    id: root

    property list<real> controlPoints: [0.2, 0, 0, 1, 1, 1]
    property color curveColor: Colours.palette.m3primary
    property real canvasSize: 200
    property real padding: Tokens.padding.large

    property bool interactive: true
    property bool showGrid: true
    property bool showDiagonal: true
    property bool showHandles: true

    // Time position of the tracer dot, or -1 to hide it
    property real progress: -1

    // Emitted on drag rather than writing back into controlPoints, which would form a
    // binding loop with whatever feeds the property.
    signal pointsEdited(points: list<real>)

    color: Colours.tPalette.m3surfaceContainer
    radius: Tokens.rounding.large
    implicitWidth: canvasSize + padding * 2
    implicitHeight: canvasSize + padding * 2

    readonly property var yRange: Bezier.yRange(root.controlPoints)

    function toPixel(x: real, y: real): var {
        const r = root.yRange;
        return {
            x: x * plot.width,
            y: plot.height * (1 - (y - r.min) / (r.max - r.min))
        };
    }

    function fromPixel(px: real, py: real): var {
        const r = root.yRange;
        return {
            x: px / plot.width,
            y: r.min + (1 - py / plot.height) * (r.max - r.min)
        };
    }

    onControlPointsChanged: plot.requestPaint()
    onProgressChanged: plot.requestPaint()
    onCurveColorChanged: plot.requestPaint()

    Canvas {
        id: plot

        anchors.fill: parent
        anchors.margins: root.padding

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        Component.onCompleted: requestPaint()

        onPaint: {
            const ctx = getContext("2d");
            const w = width;
            const h = height;
            ctx.reset();

            if (w <= 0 || h <= 0)
                return;

            const segs = Bezier.segments(root.controlPoints);
            if (!segs.length)
                return;

            if (root.showGrid) {
                ctx.strokeStyle = Qt.alpha(Colours.palette.m3outline, 0.18);
                ctx.lineWidth = 1;
                for (let i = 0; i <= 4; i++) {
                    const x = (i / 4) * w;
                    const y = (i / 4) * h;
                    ctx.beginPath();
                    ctx.moveTo(x, 0);
                    ctx.lineTo(x, h);
                    ctx.stroke();
                    ctx.beginPath();
                    ctx.moveTo(0, y);
                    ctx.lineTo(w, y);
                    ctx.stroke();
                }
            }

            // The 0 and 1 output levels, which only coincide with the box edges when
            // the curve doesn't overshoot
            if (root.showGrid) {
                ctx.strokeStyle = Qt.alpha(Colours.palette.m3outline, 0.45);
                ctx.lineWidth = 1;
                for (const level of [0, 1]) {
                    const p = root.toPixel(0, level);
                    ctx.beginPath();
                    ctx.moveTo(0, p.y);
                    ctx.lineTo(w, p.y);
                    ctx.stroke();
                }
            }

            if (root.showDiagonal) {
                const a = root.toPixel(0, 0);
                const b = root.toPixel(1, 1);
                ctx.strokeStyle = Qt.alpha(Colours.palette.m3outline, 0.35);
                ctx.setLineDash([4, 4]);
                ctx.beginPath();
                ctx.moveTo(a.x, a.y);
                ctx.lineTo(b.x, b.y);
                ctx.stroke();
                ctx.setLineDash([]);
            }

            // Handle tethers, drawn under the curve so the curve stays legible
            if (root.showHandles) {
                ctx.strokeStyle = Qt.alpha(root.curveColor, 0.45);
                ctx.lineWidth = 1;
                for (let i = 0; i < segs.length; i++) {
                    const seg = segs[i];
                    const from = Bezier.startOf(segs, i);
                    const a = root.toPixel(from.x, from.y);
                    const c1 = root.toPixel(seg.c1.x, seg.c1.y);
                    const b = root.toPixel(seg.end.x, seg.end.y);
                    const c2 = root.toPixel(seg.c2.x, seg.c2.y);
                    ctx.beginPath();
                    ctx.moveTo(a.x, a.y);
                    ctx.lineTo(c1.x, c1.y);
                    ctx.stroke();
                    ctx.beginPath();
                    ctx.moveTo(b.x, b.y);
                    ctx.lineTo(c2.x, c2.y);
                    ctx.stroke();
                }
            }

            // Curve
            const origin = root.toPixel(0, 0);
            ctx.strokeStyle = root.curveColor;
            ctx.lineWidth = root.showHandles ? 3 : 2;
            ctx.lineCap = "round";
            ctx.beginPath();
            ctx.moveTo(origin.x, origin.y);
            for (const seg of segs) {
                const c1 = root.toPixel(seg.c1.x, seg.c1.y);
                const c2 = root.toPixel(seg.c2.x, seg.c2.y);
                const end = root.toPixel(seg.end.x, seg.end.y);
                ctx.bezierCurveTo(c1.x, c1.y, c2.x, c2.y, end.x, end.y);
            }
            ctx.stroke();

            // Tracer riding the curve, in step with the motion strip
            if (root.progress >= 0) {
                const t = Math.max(0, Math.min(1, root.progress));
                const p = root.toPixel(t, Bezier.valueAt(root.controlPoints, t));
                ctx.fillStyle = Colours.palette.m3tertiary;
                ctx.beginPath();
                ctx.arc(p.x, p.y, 5, 0, Math.PI * 2);
                ctx.fill();
            }

            if (!root.showHandles)
                return;

            for (const i of Bezier.draggableIndices(root.controlPoints)) {
                const p = root.toPixel(root.controlPoints[i * 2], root.controlPoints[i * 2 + 1]);
                ctx.fillStyle = root.curveColor;
                ctx.beginPath();
                ctx.arc(p.x, p.y, 7, 0, Math.PI * 2);
                ctx.fill();
                ctx.fillStyle = Colours.palette.m3surface;
                ctx.beginPath();
                ctx.arc(p.x, p.y, 3.5, 0, Math.PI * 2);
                ctx.fill();
            }
        }
    }

    MouseArea {
        anchors.fill: plot
        enabled: root.interactive
        cursorShape: dragIndex >= 0 ? Qt.ClosedHandCursor : Qt.ArrowCursor

        property int dragIndex: -1

        onPressed: mouse => {
            dragIndex = -1;
            let best = 20; // Grab radius, generous enough for a trackpad
            for (const i of Bezier.draggableIndices(root.controlPoints)) {
                const p = root.toPixel(root.controlPoints[i * 2], root.controlPoints[i * 2 + 1]);
                const d = Math.hypot(mouse.x - p.x, mouse.y - p.y);
                if (d < best) {
                    best = d;
                    dragIndex = i;
                }
            }
            mouse.accepted = dragIndex >= 0;
        }

        onPositionChanged: mouse => {
            if (dragIndex < 0)
                return;

            const v = root.fromPixel(mouse.x, mouse.y);
            const next = [...root.controlPoints];
            // x stays inside the time axis; y is left free so overshoot stays editable
            next[dragIndex * 2] = Math.max(0, Math.min(1, v.x));
            next[dragIndex * 2 + 1] = v.y;
            root.pointsEdited(next);
        }

        onReleased: dragIndex = -1
        onCanceled: dragIndex = -1
    }
}
