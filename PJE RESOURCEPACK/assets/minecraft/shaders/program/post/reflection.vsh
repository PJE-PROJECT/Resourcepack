#version 330

uniform sampler2D ControlSampler;

out vec2 texCoord;
flat out int hasReflections;
flat out mat4 projMat;
flat out mat4 invProjMat;
flat out vec3 worldPosition;
flat out float gameTime;
flat out mat3 tbnMatrix;

const mat4 screenquad = mat4(
    vec4(-1.0, -1.0, 0.0, 1.0),
    vec4(1.0, -1.0, 0.0, 1.0),
    vec4(1.0, 1.0, 0.0, 1.0),
    vec4(-1.0, 1.0, 0.0, 1.0)
);

int decodeInt(vec3 ivec) {
    ivec *= 255.0;
    int s = ivec.b >= 128.0 ? -1 : 1;
    return s * (int(ivec.r) + int(ivec.g) * 256 + (int(ivec.b) - 64 + s * 64) * 256 * 256);
}

float decodeFloat3(vec3 ivec) {
    int v = decodeInt(ivec);
    return float(v) / 40000.0;
}

float decodeFloat(vec4 color) {
    uvec4 bits = uvec4(round(color * 255.0)) << uvec4(24, 16, 8, 0);
    return uintBitsToFloat(bits.r | bits.g | bits.b | bits.a);
}

void main() {
    gl_Position = screenquad[gl_VertexID];
    texCoord = gl_Position.xy * 0.5 + 0.5;

    vec4 control = texelFetch(ControlSampler, ivec2(1, 21), 0);
    hasReflections = int(round(control.rg * 255.0) == vec2(190.0, 32.0));

    for (int i = 0; i < 16; i++) {
        vec4 color = texelFetch(ControlSampler, ivec2(1, i), 0);
        projMat[i / 4][i % 4] = decodeFloat3(color.rgb);
    }

    invProjMat = inverse(projMat);

    vec3 time = texelFetch(ControlSampler, ivec2(1, 20), 0).rgb;
    gameTime = decodeFloat(vec4(time, control.b));

    vec3 p1 = texelFetch(ControlSampler, ivec2(1, 16), 0).rgb;
    vec3 p2 = texelFetch(ControlSampler, ivec2(1, 17), 0).rgb;
    vec3 p3 = texelFetch(ControlSampler, ivec2(1, 18), 0).rgb;
    vec3 p4 = texelFetch(ControlSampler, ivec2(1, 19), 0).rgb;

    worldPosition.x = decodeFloat(vec4(p1.rgb, p2.r));
    worldPosition.y = decodeFloat(vec4(p2.gb, p3.rg));
    worldPosition.z = decodeFloat(vec4(p3.b, p4.rgb));

    for (int i = 0; i < 9; i++) {
        vec4 color = texelFetch(ControlSampler, ivec2(1, i + 22), 0);
        tbnMatrix[i / 3][i % 3] = decodeFloat3(color.rgb);
    }
}
