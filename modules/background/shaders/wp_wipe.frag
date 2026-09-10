#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float progress;
    float aspectRatio;
    vec2 centre;
    vec4 params; // x: direction (0 = left, 1 = right, 2 = top, 3 = bottom), y: smoothness (0..1)
    vec4 fillColor;
};

layout(binding = 1) uniform sampler2D fromTex;
layout(binding = 2) uniform sampler2D toTex;

void main() {
    vec4 c1 = texture(fromTex, qt_TexCoord0);
    vec4 c2 = texture(toTex, qt_TexCoord0);

    // Distance from the edge the incoming wallpaper enters from
    float coord;
    int dir = int(params.x + 0.5);
    if (dir == 0)
        coord = qt_TexCoord0.x;
    else if (dir == 1)
        coord = 1.0 - qt_TexCoord0.x;
    else if (dir == 2)
        coord = qt_TexCoord0.y;
    else
        coord = 1.0 - qt_TexCoord0.y;

    float ms = mix(0.001, 0.5, params.y * params.y);

    // Extended so the soft edge fully clears both endpoints
    float ep = progress * (1.0 + 2.0 * ms) - ms;
    float factor = 1.0 - smoothstep(ep - ms, ep + ms, coord);

    // Use fillColor for transparent/empty textures
    vec4 fromColor = (c1.a == 0.0) ? fillColor : c1;
    vec4 toColor = (c2.a == 0.0) ? fillColor : c2;

    fragColor = mix(fromColor, toColor, factor) * qt_Opacity;
}
