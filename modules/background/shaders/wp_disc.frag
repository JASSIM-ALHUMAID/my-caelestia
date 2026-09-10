#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float progress;
    float aspectRatio;
    vec2 centre; // disc origin in texture coords
    vec4 params; // x: invert (0 = grow outward, 1 = outer: reveal edges inward), y: smoothness (0..1)
    vec4 fillColor;
};

layout(binding = 1) uniform sampler2D fromTex;
layout(binding = 2) uniform sampler2D toTex;

void main() {
    vec4 c1 = texture(fromTex, qt_TexCoord0);
    vec4 c2 = texture(toTex, qt_TexCoord0);

    // Use fillColor for transparent/empty textures
    vec4 fromColor = (c1.a == 0.0) ? fillColor : c1;
    vec4 toColor = (c2.a == 0.0) ? fillColor : c2;

    // Aspect-corrected distance from the centre
    vec2 p = vec2(qt_TexCoord0.x * aspectRatio, qt_TexCoord0.y);
    vec2 c = vec2(centre.x * aspectRatio, centre.y);
    float dist = distance(p, c);

    // Distance from the centre to the farthest corner
    float dx = max(c.x, aspectRatio - c.x);
    float dy = max(c.y, 1.0 - c.y);
    float maxDist = length(vec2(dx, dy));

    vec4 result;
    if (params.x > 0.5) {
        // Outer: DMS portal math — the old wallpaper collapses into the centre
        float edgeSoft = mix(0.001, 0.45, params.y * params.y);
        float pr = progress;
        pr = pr * pr * (3.0 - 2.0 * pr);
        float radius = (1.0 - pr) * (maxDist + edgeSoft) - edgeSoft;
        float t = smoothstep(radius - edgeSoft, radius + edgeSoft, dist);
        result = mix(fromColor, toColor, t);
        if (progress <= 0.0)
            result = fromColor;
        if (progress >= 1.0)
            result = toColor;
    } else {
        // Grow: DMS disc math — the incoming wallpaper expands outward from the centre
        float mapped = mix(0.001, 0.5, params.y * params.y);
        float adjustedSmoothness = mapped * max(1.0, aspectRatio);
        float radius = progress * (maxDist + adjustedSmoothness);
        float factor = smoothstep(radius - adjustedSmoothness, radius + adjustedSmoothness, dist);
        result = mix(toColor, fromColor, factor);
        if (progress <= 0.0)
            result = fromColor;
    }

    fragColor = result * qt_Opacity;
}
