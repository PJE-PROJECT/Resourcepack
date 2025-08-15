#version 330

uniform sampler2D DiffuseSampler;
uniform sampler2D BlurSampler;

uniform float Iteration;
uniform vec2 OutSize;

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
    
    vec3 a = decodeLogLuv(texture(DiffuseSampler, vec2(texCoord.x - x, texCoord.y + y)));
    vec3 b = decodeLogLuv(texture(DiffuseSampler, vec2(texCoord.x,     texCoord.y + y)));
    vec3 c = decodeLogLuv(texture(DiffuseSampler, vec2(texCoord.x + x, texCoord.y + y)));
    vec3 d = decodeLogLuv(texture(DiffuseSampler, vec2(texCoord.x - x, texCoord.y    )));
    vec3 e = decodeLogLuv(texture(DiffuseSampler, vec2(texCoord.x,     texCoord.y    )));
    vec3 f = decodeLogLuv(texture(DiffuseSampler, vec2(texCoord.x + x, texCoord.y    )));
    vec3 g = decodeLogLuv(texture(DiffuseSampler, vec2(texCoord.x - x, texCoord.y - y)));
    vec3 h = decodeLogLuv(texture(DiffuseSampler, vec2(texCoord.x,     texCoord.y - y)));
    vec3 i = decodeLogLuv(texture(DiffuseSampler, vec2(texCoord.x + x, texCoord.y - y)));

    vec3 color = e * 4.0;
    color += (b + d + f + h) * 2.0;
    color += (a + c + g + i);
    color *= 1.0 / 16.0;

    color += decodeLogLuv(texture(BlurSampler, texCoord * (vec2(outRes) / vec2(inRes))));

    fragColor = encodeLogLuv(color);
}