#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float progress;
    float aspectRatio;
    vec2 centre;
    vec4 params; // x: wave amplitude, y: wavelength (both in screen-height units), w: sweep angle (radians)
    vec4 fillColor;
};

layout(binding = 1) uniform sampler2D fromTex;
layout(binding = 2) uniform sampler2D toTex;

const float TAU = 6.28318530718;
const float AA = 0.003;

void main() {
    vec4 c1 = texture(fromTex, qt_TexCoord0);
    vec4 c2 = texture(toTex, qt_TexCoord0);

    // Use fillColor for transparent/empty textures
    vec4 fromColor = (c1.a == 0.0) ? fillColor : c1;
    vec4 toColor = (c2.a == 0.0) ? fillColor : c2;

    float amp = params.x;
    float wl = max(params.y, 0.001);
    vec2 d = vec2(cos(params.w), sin(params.w));

    // Centred, aspect-corrected coordinates; the wave is a pure sine in
    // physical units (awww-style) so the scallops stay round in any direction
    vec2 p = vec2(qt_TexCoord0.x * aspectRatio, qt_TexCoord0.y) - 0.5 * vec2(aspectRatio, 1.0);
    float coord = dot(p, d);
    float along = dot(p, vec2(-d.y, d.x));
    float wave = sin(along * TAU / wl) * amp;

    // Sweep the front across the screen's projected extent for this angle,
    // clearing amplitude + AA at both ends
    float ext = 0.5 * (abs(d.x) * aspectRatio + abs(d.y));
    float m = amp + AA;
    float s = mix(-ext - m, ext + m, progress);

    float factor = 1.0 - smoothstep(-AA, AA, coord - (wave + s));
    fragColor = mix(fromColor, toColor, factor) * qt_Opacity;
}
