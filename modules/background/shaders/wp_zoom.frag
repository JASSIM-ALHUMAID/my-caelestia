#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float progress;
    float aspectRatio;
    vec2 centre;
    vec4 params;
    vec4 fillColor;
};

layout(binding = 1) uniform sampler2D fromTex;
layout(binding = 2) uniform sampler2D toTex;

const float ZOOM = 0.15;

void main() {
    // Outgoing zooms in while the incoming settles from zoomed-in to rest;
    // both scales stay >= 1 so sampling never leaves the texture
    float s1 = 1.0 + ZOOM * progress;
    float s2 = 1.0 + ZOOM * (1.0 - progress);
    vec2 uv1 = (qt_TexCoord0 - 0.5) / s1 + 0.5;
    vec2 uv2 = (qt_TexCoord0 - 0.5) / s2 + 0.5;

    vec4 c1 = texture(fromTex, uv1);
    vec4 c2 = texture(toTex, uv2);

    // Use fillColor for transparent/empty textures
    vec4 fromColor = (c1.a == 0.0) ? fillColor : c1;
    vec4 toColor = (c2.a == 0.0) ? fillColor : c2;

    fragColor = mix(fromColor, toColor, progress) * qt_Opacity;
}
