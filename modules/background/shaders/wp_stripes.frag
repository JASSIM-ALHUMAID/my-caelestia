#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float progress;
    float aspectRatio;
    vec2 centre;
    vec4 params; // x: stripe count, y: angle (radians), z: edge smoothness (0..1)
    vec4 fillColor;
};

layout(binding = 1) uniform sampler2D fromTex;
layout(binding = 2) uniform sampler2D toTex;

void main() {
    vec4 c1 = texture(fromTex, qt_TexCoord0);
    vec4 c2 = texture(toTex, qt_TexCoord0);

    bool oob = qt_TexCoord0.x < 0.0 || qt_TexCoord0.x > 1.0 || qt_TexCoord0.y < 0.0 || qt_TexCoord0.y > 1.0;
    vec4 fromColor = oob ? fillColor : c1;
    vec4 toColor = oob ? fillColor : c2;

    vec2 uv = qt_TexCoord0;

    float count = max(params.x, 1.0);
    float cosA = cos(params.y);
    float sinA = sin(params.y);

    // Project the UV position onto the stripe direction (band selection)
    float stripeCoord = uv.x * cosA + uv.y * sinA;

    // Perpendicular coordinate (the reveal edge sweeps along this, lengthwise)
    float perpCoord = -uv.x * sinA + uv.y * cosA;

    // Range of perpCoord across the unit square, from its 4 corners
    float minPerp = min(min(-0.0 * sinA + 0.0 * cosA, -1.0 * sinA + 0.0 * cosA),
                       min(-0.0 * sinA + 1.0 * cosA, -1.0 * sinA + 1.0 * cosA));
    float maxPerp = max(max(-0.0 * sinA + 0.0 * cosA, -1.0 * sinA + 0.0 * cosA),
                       max(-0.0 * sinA + 1.0 * cosA, -1.0 * sinA + 1.0 * cosA));

    // Which stripe are we in
    float stripePos = stripeCoord * count;
    float stripeIndex = floor(stripePos);
    bool isOddStripe = mod(stripeIndex, 2.0) != 0.0;

    // Per-stripe stagger: all stripes finish together at progress = 1
    float normalizedStripePos = clamp(stripePos / count, 0.0, 1.0);
    float maxDelay = 0.1;
    float stripeDelay = normalizedStripePos * maxDelay;

    float stripeProgress;
    if (progress <= stripeDelay) {
        stripeProgress = 0.0;
    } else if (progress >= (stripeDelay + (1.0 - maxDelay))) {
        stripeProgress = 1.0;
    } else {
        float activeStart = stripeDelay;
        float activeEnd = stripeDelay + (1.0 - maxDelay);
        stripeProgress = (progress - activeStart) / (activeEnd - activeStart);
    }

    // Smootherstep easing
    stripeProgress = stripeProgress * stripeProgress * (3.0 - 2.0 * stripeProgress);

    // Edge smoothness: map 0..1 to a sharp..soft range
    float edgeSmooth = mix(0.001, 0.3, params.z * params.z);

    float perpRange = maxPerp - minPerp;
    float margin = edgeSmooth * 2.0;
    float edgePosition;
    if (isOddStripe) {
        // Odd stripes: edge moves from max to min
        edgePosition = maxPerp + margin - stripeProgress * (perpRange + margin * 2.0);
    } else {
        // Even stripes: edge moves from min to max
        edgePosition = minPerp - margin + stripeProgress * (perpRange + margin * 2.0);
    }

    float mask;
    if (isOddStripe) {
        mask = smoothstep(edgePosition - edgeSmooth, edgePosition + edgeSmooth, perpCoord);
    } else {
        mask = 1.0 - smoothstep(edgePosition - edgeSmooth, edgePosition + edgeSmooth, perpCoord);
    }

    fragColor = mix(fromColor, toColor, mask);

    // Force exact values at start and end to prevent any bleed-through
    if (progress <= 0.0) {
        fragColor = fromColor;
    } else if (progress >= 1.0) {
        fragColor = toColor;
    } else {
        // Manga-style edge shadow only during the transition
        float edgeDist = abs(perpCoord - edgePosition);
        float shadowStrength = 1.0 - smoothstep(0.0, edgeSmooth * 2.5, edgeDist);
        shadowStrength *= 0.2 * (1.0 - abs(stripeProgress - 0.5) * 2.0);
        fragColor.rgb *= (1.0 - shadowStrength);

        // Slight vignette during transition for dramatic effect
        float vignette = 1.0 - progress * 0.1 * (1.0 - abs(stripeProgress - 0.5) * 2.0);
        fragColor.rgb *= vignette;
    }

    fragColor *= qt_Opacity;
}
