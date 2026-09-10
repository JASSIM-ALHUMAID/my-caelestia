#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;
    float pixelSize;
    float aspectRatio;
    vec4 tintColor;
};

layout(binding = 1) uniform sampler2D sourceTex;

float hash(vec2 value) {
    return fract(sin(dot(value, vec2(127.1, 311.7))) * 43758.5453);
}

void main() {
    vec2 uv = qt_TexCoord0;
    vec2 texturePixels = vec2(textureSize(sourceTex, 0));
    texturePixels = max(texturePixels, vec2(1.0));

    float tick = floor(time * 7.0);
    float band = floor(uv.y * 30.0);
    float burst = step(0.91, hash(vec2(band, tick)));
    float horizontalShift = (hash(vec2(tick, band + 4.0)) - 0.5) * 0.09 * burst;
    vec2 shiftedUv = clamp(uv + vec2(horizontalShift, 0.0), vec2(0.0), vec2(1.0));

    float breathing = 0.84 + sin(time * 0.65) * 0.16;
    float cell = max(4.0, pixelSize * breathing);
    vec2 block = floor(shiftedUv * texturePixels / cell);
    vec2 quantizedUv = (block * cell + cell * 0.5) / texturePixels;
    quantizedUv = clamp(quantizedUv, vec2(0.0), vec2(1.0));

    vec4 colour = texture(sourceTex, quantizedUv);
    if (burst > 0.5) {
        vec2 channelOffset = vec2(cell / texturePixels.x * 0.75, 0.0);
        colour.r = texture(sourceTex, clamp(quantizedUv + channelOffset, vec2(0.0), vec2(1.0))).r;
        colour.b = texture(sourceTex, clamp(quantizedUv - channelOffset, vec2(0.0), vec2(1.0))).b;
    }

    vec2 withinCell = fract(shiftedUv * texturePixels / cell);
    float edge = step(withinCell.x, 0.055) + step(withinCell.y, 0.055);
    colour.rgb *= 1.0 - min(1.0, edge) * 0.18;

    float scanline = 0.95 + 0.05 * sin(uv.y * texturePixels.y * 1.45 + time * 5.0);
    float vignette = smoothstep(0.9, 0.18, length((uv - 0.5) * vec2(aspectRatio, 1.0)));
    colour.rgb *= scanline * mix(0.62, 1.0, vignette);
    colour.rgb = mix(colour.rgb, colour.rgb * tintColor.rgb, 0.14);

    fragColor = vec4(colour.rgb, 1.0) * qt_Opacity;
}
