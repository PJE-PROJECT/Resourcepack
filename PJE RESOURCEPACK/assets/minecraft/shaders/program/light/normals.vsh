#version 330

uniform sampler2D DataSampler;

out vec2 texCoord;
flat out mat4 invProjMat;
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
    vec3 c0 = texelFetch(samp, ivec2(1, 40), 0).rgb;
    vec3 c1 = texelFetch(samp, ivec2(1, 41), 0).rgb;
    vec3 c2 = texelFetch(samp, ivec2(1, 42), 0).rgb;
    vec3 c3 = texelFetch(samp, ivec2(1, 43), 0).rgb;
    vec3 c4 = texelFetch(samp, ivec2(1, 44), 0).rgb;
    vec3 c5 = texelFetch(samp, ivec2(1, 45), 0).rgb;
    vec3 c6 = texelFetch(samp, ivec2(1, 46), 0).rgb;
    vec3 c7 = texelFetch(samp, ivec2(1, 47), 0).rgb;
    vec3 c8 = texelFetch(samp, ivec2(1, 48), 0).rgb;
    vec3 c9 = texelFetch(samp, ivec2(1, 49), 0).rgb;
    vec3 c10 = texelFetch(samp, ivec2(1, 50), 0).rgb;
    vec3 c11 = texelFetch(samp, ivec2(1, 51), 0).rgb;
    vec3 c12 = texelFetch(samp, ivec2(1, 52), 0).rgb;
    vec3 c13 = texelFetch(samp, ivec2(1, 53), 0).rgb;
    vec3 c14 = texelFetch(samp, ivec2(1, 54), 0).rgb;
    vec3 c15 = texelFetch(samp, ivec2(1, 55), 0).rgb;
    vec3 c16 = texelFetch(samp, ivec2(1, 56), 0).rgb;
    vec3 c17 = texelFetch(samp, ivec2(1, 57), 0).rgb;
    vec3 c18 = texelFetch(samp, ivec2(1, 58), 0).rgb;
    vec3 c19 = texelFetch(samp, ivec2(1, 59), 0).rgb;
    vec3 c20 = texelFetch(samp, ivec2(1, 60), 0).rgb;
    vec3 c21 = texelFetch(samp, ivec2(1, 61), 0).rgb;

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
        round(texelFetch(DataSampler, ivec2(1, 69), 0).rg * 255.0) == vec2(191.0, 32.0)
    );

    invProjMat = inverse(getProjMat(DataSampler));
}
