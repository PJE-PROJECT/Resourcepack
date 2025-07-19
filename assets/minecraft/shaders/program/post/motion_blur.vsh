#version 330

uniform sampler2D DataSampler;
uniform sampler2D HDataSampler;

out vec2 texCoord;
flat out mat4 invProjMat;
flat out mat4 prevProjMat;
flat out vec3 cameraOffset;
flat out int hasData;

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

mat4 getProjMat(sampler2D samp) {
    vec3 c0 = texelFetch(samp, ivec2(2, 40), 0).rgb;
    vec3 c1 = texelFetch(samp, ivec2(2, 41), 0).rgb;
    vec3 c2 = texelFetch(samp, ivec2(2, 42), 0).rgb;
    vec3 c3 = texelFetch(samp, ivec2(2, 43), 0).rgb;
    vec3 c4 = texelFetch(samp, ivec2(2, 44), 0).rgb;
    vec3 c5 = texelFetch(samp, ivec2(2, 45), 0).rgb;
    vec3 c6 = texelFetch(samp, ivec2(2, 46), 0).rgb;
    vec3 c7 = texelFetch(samp, ivec2(2, 47), 0).rgb;
    vec3 c8 = texelFetch(samp, ivec2(2, 48), 0).rgb;
    vec3 c9 = texelFetch(samp, ivec2(2, 49), 0).rgb;
    vec3 c10 = texelFetch(samp, ivec2(2, 50), 0).rgb;
    vec3 c11 = texelFetch(samp, ivec2(2, 51), 0).rgb;
    vec3 c12 = texelFetch(samp, ivec2(2, 52), 0).rgb;
    vec3 c13 = texelFetch(samp, ivec2(2, 53), 0).rgb;
    vec3 c14 = texelFetch(samp, ivec2(2, 54), 0).rgb;
    vec3 c15 = texelFetch(samp, ivec2(2, 55), 0).rgb;
    vec3 c16 = texelFetch(samp, ivec2(2, 56), 0).rgb;
    vec3 c17 = texelFetch(samp, ivec2(2, 57), 0).rgb;
    vec3 c18 = texelFetch(samp, ivec2(2, 58), 0).rgb;
    vec3 c19 = texelFetch(samp, ivec2(2, 59), 0).rgb;
    vec3 c20 = texelFetch(samp, ivec2(2, 60), 0).rgb;
    vec3 c21 = texelFetch(samp, ivec2(2, 61), 0).rgb;

    return mat4(
        decodeFloat(vec4(c0.xyz, c1.x)), decodeFloat(vec4(c1.yz, c2.xy)), decodeFloat(vec4(c2.z, c3.xyz)), decodeFloat(vec4(c4.xyz, c5.x)),
        decodeFloat(vec4(c5.yz, c6.xy)), decodeFloat(vec4(c6.z, c7.xyz)), decodeFloat(vec4(c8.xyz, c9.x)), decodeFloat(vec4(c9.yz, c10.xy)),
        decodeFloat(vec4(c10.z, c11.xyz)), decodeFloat(vec4(c12.xyz, c13.x)), decodeFloat(vec4(c13.yz, c14.xy)), decodeFloat(vec4(c14.z, c15.xyz)),
        decodeFloat(vec4(c16.xyz, c17.x)), decodeFloat(vec4(c17.yz, c18.xy)), decodeFloat(vec4(c18.z, c19.xyz)), decodeFloat(vec4(c20.xyz, c21.x))
    );
}

void main() {
    gl_Position = screenquad[gl_VertexID];
    texCoord = gl_Position.xy * 0.5 + 0.5;

    hasData = int(
        round(texelFetch(HDataSampler, ivec2(2, 69), 0).rgb * 255.0) == vec3(191.0, 32.0, 4.0) &&
        round(texelFetch(DataSampler, ivec2(2, 69), 0).rgb * 255.0) == vec3(191.0, 32.0, 4.0) &&
        round(texelFetch(DataSampler, ivec2(1, 69), 0).rgb * 255.0) != vec3(191.0, 32.0, 1.0) &&
        round(texelFetch(HDataSampler, ivec2(0, 0), 0).rg * 255.0) != vec2(254.0, 253.0)
    );

    invProjMat = inverse(getProjMat(DataSampler));
    prevProjMat = getProjMat(HDataSampler);

    vec3 p1 = texelFetch(DataSampler, ivec2(2, 62), 0).rgb;
    vec3 p2 = texelFetch(DataSampler, ivec2(2, 63), 0).rgb;
    vec3 p3 = texelFetch(DataSampler, ivec2(2, 64), 0).rgb;
    vec3 p4 = texelFetch(DataSampler, ivec2(2, 65), 0).rgb;

    cameraOffset.x = decodeFloat(vec4(p1.rgb, p2.r));
    cameraOffset.y = decodeFloat(vec4(p2.gb, p3.rg));
    cameraOffset.z = decodeFloat(vec4(p3.b, p4.rgb));

    p1 = texelFetch(HDataSampler, ivec2(2, 62), 0).rgb;
    p2 = texelFetch(HDataSampler, ivec2(2, 63), 0).rgb;
    p3 = texelFetch(HDataSampler, ivec2(2, 64), 0).rgb;
    p4 = texelFetch(HDataSampler, ivec2(2, 65), 0).rgb;

    cameraOffset.x -= decodeFloat(vec4(p1.rgb, p2.r));
    cameraOffset.y -= decodeFloat(vec4(p2.gb, p3.rg));
    cameraOffset.z -= decodeFloat(vec4(p3.b, p4.rgb));
}
