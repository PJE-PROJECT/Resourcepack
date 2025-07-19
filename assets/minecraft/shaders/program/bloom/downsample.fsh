#version 330

uniform sampler2D DiffuseSampler;

uniform vec2 OutSize;
uniform float Iteartion;

flat in ivec2 inRes;
flat in ivec2 outRes;

out vec4 fragColor;

const mat3 LOGLUV_M = mat3(
    0.2209, 0.1138, 0.0102,
    0.3390, 0.6780, 0.1130,
    0.4184, 0.7319, 0.2969
);

const mat3 LOGLUV_INV_M = mat3(
    6.0013, -1.332, 0.3007,
    -2.700, 3.1029, -1.088,
    -1.7995, -5.7720, 5.6268
);

vec4 encodeLogLuv(vec3 rgb) {
    vec4 result;
    vec3 Xp_Y_XYZp = rgb * LOGLUV_M;
    Xp_Y_XYZp = max(Xp_Y_XYZp, vec3(1.0e-6));
    result.xy = Xp_Y_XYZp.xy / Xp_Y_XYZp.z;
    float Le = 2.0 * log2(Xp_Y_XYZp.y) + 127.0;
    result.w = fract(Le);
    result.z = (Le - (floor(result.w * 255.0)) / 255.0) / 255.0;
    return result;
}

vec3 decodeLogLuv(vec4 logLuv) {
    float Le = logLuv.z * 255.0 + logLuv.w;
    vec3 Xp_Y_XYZp;
    Xp_Y_XYZp.y = exp2((Le - 127.0) / 2.0);
    Xp_Y_XYZp.z = Xp_Y_XYZp.y / logLuv.y;
    Xp_Y_XYZp.x = logLuv.x * Xp_Y_XYZp.z;
    vec3 rgb = Xp_Y_XYZp * LOGLUV_INV_M;
    return max(rgb, 0.0);
}

vec3 sampleTexture(vec2 coord) {
    coord = clamp(coord, 1.5 / OutSize, 1.0 - 1.5 / OutSize);
    return decodeLogLuv(texture(DiffuseSampler, coord));
}

void main() {
    ivec2 coord = ivec2(gl_FragCoord.xy);
    if (coord.x >= outRes.x || coord.y >= outRes.y) {
        fragColor = vec4(0.0);
        return;
    }

    vec2 texCoord = gl_FragCoord.xy / vec2(outRes);
    texCoord *= vec2(inRes) / OutSize;

    float x = 1.0 / OutSize.x;
    float y = 1.0 / OutSize.y;

    vec3 a = sampleTexture(vec2(texCoord.x - 2.0 * x, texCoord.y + 2.0 * y));
    vec3 b = sampleTexture(vec2(texCoord.x,           texCoord.y + 2.0 * y));
    vec3 c = sampleTexture(vec2(texCoord.x + 2.0 * x, texCoord.y + 2.0 * y));

    vec3 d = sampleTexture(vec2(texCoord.x - 2.0 * x, texCoord.y));
    vec3 e = sampleTexture(vec2(texCoord.x,           texCoord.y));
    vec3 f = sampleTexture(vec2(texCoord.x + 2.0 * x, texCoord.y));

    vec3 g = sampleTexture(vec2(texCoord.x - 2.0 * x, texCoord.y - 2.0 * y));
    vec3 h = sampleTexture(vec2(texCoord.x,           texCoord.y - 2.0 * y));
    vec3 i = sampleTexture(vec2(texCoord.x + 2.0 * x, texCoord.y - 2.0 * y));

    vec3 j = sampleTexture(vec2(texCoord.x - x, texCoord.y + y));
    vec3 k = sampleTexture(vec2(texCoord.x + x, texCoord.y + y));
    vec3 l = sampleTexture(vec2(texCoord.x - x, texCoord.y - y));
    vec3 m = sampleTexture(vec2(texCoord.x + x, texCoord.y - y));

    vec3 color = e * 0.125;
    color += (a + c + g + i) * 0.03125;
    color += (b + d + f + h) * 0.0625;
    color += (j + k + l + m) * 0.125;

    fragColor = encodeLogLuv(color);
}