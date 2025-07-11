#version 330

uniform sampler2D DepthSampler;
uniform sampler2D TranslucentSampler;

uniform vec2 InSize;

in vec2 texCoord;
flat in mat4 invProjMat;
flat in int hasData;

out vec4 fragColor;

vec3 unprojectScreenSpace(vec2 texCoord, float depth) {
    vec4 h = invProjMat * (vec4(texCoord, depth, 1.0) * 2.0 - 1.0);
    return h.xyz / h.w;
}

vec3 reconstructNormal(vec2 coord) {
    float depthCenter = texture(DepthSampler, coord).r;
    vec3 positionCenter = unprojectScreenSpace(coord, depthCenter);

    vec4 horizontal = vec4(
        texture(DepthSampler, coord + vec2(-2.0, 0.0) / InSize).r,
        texture(DepthSampler, coord + vec2(+2.0, 0.0) / InSize).r,
        texture(DepthSampler, coord + vec2(-4.0, 0.0) / InSize).r,
        texture(DepthSampler, coord + vec2(+4.0, 0.0) / InSize).r
    );

    vec4 vertical = vec4(
        texture(DepthSampler, coord + vec2(0.0, -2.0) / InSize).r,
        texture(DepthSampler, coord + vec2(0.0, +2.0) / InSize).r,
        texture(DepthSampler, coord + vec2(0.0, -4.0) / InSize).r,
        texture(DepthSampler, coord + vec2(0.0, +4.0) / InSize).r
    );

    vec3 positionLeft  = unprojectScreenSpace(coord + vec2(-2.0, 0.0) / InSize, horizontal.x);
    vec3 positionRight = unprojectScreenSpace(coord + vec2(+2.0, 0.0) / InSize, horizontal.y);
    vec3 positionDown  = unprojectScreenSpace(coord + vec2(0.0, -2.0) / InSize, vertical.x);
    vec3 positionUp    = unprojectScreenSpace(coord + vec2(0.0, +2.0) / InSize, vertical.y);

    vec3 left  = positionCenter - positionLeft;
    vec3 right = positionRight  - positionCenter;
    vec3 down  = positionCenter - positionDown;
    vec3 up    = positionUp     - positionCenter;

    vec2 he = abs((2.0 * horizontal.xy - horizontal.zw) - depthCenter);
    vec2 ve = abs((2.0 * vertical.xy - vertical.zw) - depthCenter);

    vec3 horizontalDeriv = he.x < he.y ? left : right;
    vec3 verticalDeriv = ve.x < ve.y ? down : up;

    return normalize(cross(horizontalDeriv, verticalDeriv));
}

void main() {
    fragColor = vec4(0.0);
    
    float depth = texture(DepthSampler, texCoord).r;
    if (hasData == 0 || depth == 1.0) {
        return;
    }

    vec3 normal;
    if (texture(TranslucentSampler, texCoord).rgb != vec3(0.0)) {
        normal = vec3(0.0, 1.0, 0.0);
    } else {
        normal = reconstructNormal(texCoord);
    }

    fragColor = vec4(normal * 0.5 + 0.5, 1.0);
}
