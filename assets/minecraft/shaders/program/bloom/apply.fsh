#version 150

uniform sampler2D DiffuseSampler;
uniform sampler2D BloomSampler;

in vec2 texCoord;

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

vec3 TMO(vec3 x) {
    return x / (1.0 + x);
}

vec3 InverseTMO(vec3 x) {
    return x / (1.00001 - x);
}

const mat4 ditherMatrix = mat4(
    0.0, 12.0, 3.0, 15.0,
    8.0, 4.0, 11.0, 7.0,
    2.0, 14.0, 1.0, 13.0,
    10.0, 6.0, 9.0, 5.0
) / 16.0;

void main() {
    vec3 color = texture(DiffuseSampler, texCoord).rgb;
    vec3 bloom = decodeLogLuv(texture(BloomSampler, texCoord));

    float ditherValue = ditherMatrix[int(gl_FragCoord.x) & 3][int(gl_FragCoord.y) & 3];
    bloom += -vec3(sign(bloom)) * ditherValue * 0.005;
    bloom = max(bloom, vec3(0.0));

    vec3 linear = InverseTMO(pow(color, vec3(2.2))) + bloom * 0.05;
    fragColor = vec4(pow(TMO(linear), vec3(1.0 / 2.2)), 1.0);
}
