#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float progress;
    float aspectRatio;
    vec2 centre; // reveal origin in texture coords
    vec4 params; // x: hex cell size (texture-height units)
    vec4 fillColor;
};

layout(binding = 1) uniform sampler2D fromTex;
layout(binding = 2) uniform sampler2D toTex;

const float SQRT3 = 1.73205080757;

// Convert cartesian to axial hex coordinates and round to nearest hex center
vec2 hexRound(vec2 axial) {
    float x = axial.x;
    float z = axial.y;
    float y = -x - z;

    float rx = round(x);
    float ry = round(y);
    float rz = round(z);

    float dx = abs(rx - x);
    float dy = abs(ry - y);
    float dz = abs(rz - z);

    if (dx > dy && dx > dz)
        rx = -ry - rz;
    else if (dy > dz)
        ry = -rx - rz;
    else
        rz = -rx - ry;

    return vec2(rx, rz);
}

void main() {
    vec4 c1 = texture(fromTex, qt_TexCoord0);
    vec4 c2 = texture(toTex, qt_TexCoord0);

    // Use fillColor for transparent/empty textures
    vec4 fromColor = (c1.a == 0.0) ? fillColor : c1;
    vec4 toColor = (c2.a == 0.0) ? fillColor : c2;

    // Aspect-correct the UV for the hex grid so cells appear as regular hexagons
    vec2 aspectUV = vec2(qt_TexCoord0.x * aspectRatio, qt_TexCoord0.y);

    float size = max(params.x, 0.01);
    float q = (aspectUV.x * (2.0 / 3.0)) / size;
    float r = ((-aspectUV.x / 3.0) + (SQRT3 / 3.0) * aspectUV.y) / size;

    vec2 hex = hexRound(vec2(q, r));

    vec2 hexCentre;
    hexCentre.x = size * (3.0 / 2.0) * hex.x;
    hexCentre.y = size * (SQRT3 * (hex.y + 0.5 * hex.x));

    vec2 origin = vec2(centre.x * aspectRatio, centre.y);
    float dist = distance(hexCentre, origin);

    float maxDistX = max(centre.x * aspectRatio, (1.0 - centre.x) * aspectRatio);
    float maxDistY = max(centre.y, 1.0 - centre.y);
    float maxDist = length(vec2(maxDistX, maxDistY));

    // Wave expansion: start radius behind the origin so the smoothstep zone is
    // fully off-screen at progress = 0
    float softEdge = 0.15 * maxDist;
    float totalDistance = maxDist + 2.0 * softEdge;
    float radius = -softEdge + progress * totalDistance;

    // factor = 0 inside the wave (revealed), 1 outside (not yet reached)
    float factor = smoothstep(radius - softEdge, radius + softEdge, dist);
    float cellProgress = 1.0 - factor;

    fragColor = mix(fromColor, toColor, cellProgress) * qt_Opacity;
}
