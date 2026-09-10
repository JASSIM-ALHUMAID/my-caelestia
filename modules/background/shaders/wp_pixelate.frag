#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float progress;
    float aspectRatio;
    vec2 centre; // unused
    vec4 params; // x: smoothness (0..1, starting block size), z: screen width px, w: screen height px
    vec4 fillColor;
};

layout(binding = 1) uniform sampler2D fromTex;
layout(binding = 2) uniform sampler2D toTex;

vec2 quantizeUV(vec2 uv, float cellPx) {
    vec2 screenSize = vec2(max(1.0, params.z), max(1.0, params.w));
    float cell = max(1.0, ceil(cellPx));
    vec2 grid = floor(uv * screenSize / cell) * cell + 0.5 * cell;
    return grid / screenSize;
}

void main() {
    vec2 uv = qt_TexCoord0;

    vec4 c1 = texture(fromTex, uv);
    vec4 oldColor = (c1.a == 0.0) ? fillColor : c1;

    float p = clamp(progress, 0.0, 1.0);
    float pe = p * p * (3.0 - 2.0 * p); // smootherstep for opacity

    // Screen-relative starting cell size:
    // smoothness=0 -> ~10% of min(screen), smoothness=1 -> ~80% of min(screen)
    float s = clamp(params.x, 0.0, 1.0);
    float minSide = min(max(1.0, params.z), max(1.0, params.w));
    float startPx = mix(minSide * 0.10, minSide * 0.80, s);

    // Cell size shrinks continuously from startPx -> 1 as progress grows
    float cellPx = mix(startPx, 1.0, p);

    // Sample incoming wallpaper as a pixelated overlay
    vec2 uvq = quantizeUV(uv, cellPx);
    vec4 c2q = texture(toTex, uvq);
    vec4 newPix = (c2q.a == 0.0) ? fillColor : c2q;

    // As we approach the end, sharpen the incoming wallpaper from pixelated to full-res
    float sharpen = smoothstep(0.75, 1.0, p);
    vec4 c2 = texture(toTex, uv);
    vec4 newFull = (c2.a == 0.0) ? fillColor : c2;
    vec4 newColor = mix(newPix, newFull, sharpen);

    vec4 result = mix(oldColor, newColor, pe);

    if (p <= 0.0)
        result = oldColor;
    if (p >= 1.0)
        result = newFull;

    fragColor = result * qt_Opacity;
}
