#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float progress;
    float aspectRatio;
    vec2 centre; // iris origin in texture coords (fixed at 0.5, 0.5)
    vec4 params; // x: smoothness (0..1)
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

    float edgeSoft = mix(0.001, 0.45, params.x * params.x);

    vec2 acUv = vec2(qt_TexCoord0.x * aspectRatio, qt_TexCoord0.y);
    vec2 acCentre = vec2(centre.x * aspectRatio, centre.y);
    vec2 q = acUv - acCentre;

    float maxX = max(centre.x * aspectRatio, (1.0 - centre.x) * aspectRatio);
    float maxY = max(centre.y, 1.0 - centre.y);
    float maxDist = length(vec2(maxX, maxY));

    float p = progress;
    p = p * p * (3.0 - 2.0 * p);

    float radius = p * maxDist;

    // Squash factor for the "eye" slit
    float squash = mix(0.2, 1.0, p);
    q.y /= squash;

    float dist = length(q);
    float t = smoothstep(radius - edgeSoft, radius + edgeSoft, dist);

    vec4 result = mix(toColor, fromColor, t);

    if (progress <= 0.0)
        result = fromColor;
    if (progress >= 1.0)
        result = toColor;

    fragColor = result * qt_Opacity;
}
