#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float progress;
    float aspectRatio;
    vec2 centre;
    vec4 params; // x: origin corner (0 tl, 1 tr, 2 bl, 3 br)
    vec4 fillColor;
};

layout(binding = 1) uniform sampler2D fromTex;
layout(binding = 2) uniform sampler2D toTex;

const float MS = 0.05;

void main() {
    vec4 c1 = texture(fromTex, qt_TexCoord0);
    vec4 c2 = texture(toTex, qt_TexCoord0);

    // Use fillColor for transparent/empty textures
    vec4 fromColor = (c1.a == 0.0) ? fillColor : c1;
    vec4 toColor = (c2.a == 0.0) ? fillColor : c2;

    // 45° (pixel-space) front sweeping from the chosen origin corner
    float d1 = (qt_TexCoord0.x * aspectRatio + qt_TexCoord0.y) / (aspectRatio + 1.0);
    float d2 = ((1.0 - qt_TexCoord0.x) * aspectRatio + qt_TexCoord0.y) / (aspectRatio + 1.0);
    int c = int(params.x + 0.5);
    float coord;
    if (c == 0)
        coord = d1;
    else if (c == 1)
        coord = d2;
    else if (c == 2)
        coord = 1.0 - d2;
    else
        coord = 1.0 - d1;

    float ep = progress * (1.0 + 2.0 * MS) - MS;
    float factor = 1.0 - smoothstep(ep - MS, ep + MS, coord);
    fragColor = mix(fromColor, toColor, factor) * qt_Opacity;
}
