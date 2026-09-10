.pragma library

// Curve points are stored exactly as AnimTokens::buildCurve reads them
// (plugin/src/Caelestia/Config/anim.cpp): 6 values per cubic segment, laid out
// c1x, c1y, c2x, c2y, endX, endY. The implicit start of the first segment is
// (0, 0) and the final endpoint must be (1, 1) for QEasingCurve to accept it.
function segments(points) {
    const segs = [];
    for (let i = 0; i + 5 < points.length; i += 6)
        segs.push({
            c1: { x: points[i], y: points[i + 1] },
            c2: { x: points[i + 2], y: points[i + 3] },
            end: { x: points[i + 4], y: points[i + 5] }
        });
    return segs;
}

// Start point of segment `index` -- (0, 0) for the first, else the previous end.
function startOf(segs, index) {
    return index === 0 ? { x: 0, y: 0 } : segs[index - 1].end;
}

function pointAt(p0, c1, c2, p3, t) {
    const u = 1 - t;
    const uu = u * u;
    const tt = t * t;
    return {
        x: uu * u * p0.x + 3 * uu * t * c1.x + 3 * u * tt * c2.x + tt * t * p3.x,
        y: uu * u * p0.y + 3 * uu * t * c1.y + 3 * u * tt * c2.y + tt * t * p3.y
    };
}

// Eased output for a time in [0, 1]. Bisects on the x component rather than using
// Newton, which diverges on the overshooting expressive curves (cp y up to 1.67).
function valueAt(points, x) {
    const segs = segments(points);
    if (!segs.length)
        return x;

    x = Math.max(0, Math.min(1, x));

    let index = segs.length - 1;
    for (let i = 0; i < segs.length; i++)
        if (x <= segs[i].end.x) {
            index = i;
            break;
        }

    const seg = segs[index];
    const p0 = startOf(segs, index);

    let lo = 0;
    let hi = 1;
    let t = 0.5;
    for (let i = 0; i < 32; i++) {
        t = (lo + hi) / 2;
        if (pointAt(p0, seg.c1, seg.c2, seg.end, t).x < x)
            lo = t;
        else
            hi = t;
    }

    return pointAt(p0, seg.c1, seg.c2, seg.end, t).y;
}

// Vertical extent to plot. Expressive curves overshoot well past 1, so the axis has
// to grow to keep the whole curve on screen instead of clipping it at the top.
function yRange(points) {
    let min = 0;
    let max = 1;
    for (let i = 1; i < points.length; i += 2) {
        min = Math.min(min, points[i]);
        max = Math.max(max, points[i]);
    }
    const pad = (max - min) * 0.08;
    return { min: min - pad, max: max + pad };
}

// True when the curve leaves the 0..1 output range. A cubic bezier is contained in the
// convex hull of its control points, so checking the control points is sufficient.
//
// This matters for the wallpaper transitions: wp_fade.frag and wp_zoom.frag both do
// mix(fromColor, toColor, progress), and GLSL mix extrapolates outside 0..1 rather than
// clamping, so an overshooting curve pushes colour past the target image.
function overshoots(points) {
    for (let i = 1; i < points.length; i += 2)
        if (points[i] < 0 || points[i] > 1)
            return true;
    return false;
}

// Indices into the flat point list that the user may drag. Every control point is
// editable except the final endpoint, which QEasingCurve requires to stay at (1, 1).
function draggableIndices(points) {
    const out = [];
    const count = Math.floor(points.length / 2);
    for (let i = 0; i < count; i++)
        if (i !== count - 1)
            out.push(i);
    return out;
}
