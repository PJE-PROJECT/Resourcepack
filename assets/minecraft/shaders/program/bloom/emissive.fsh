#version 150

uniform sampler2D DiffuseSampler;
uniform sampler2D ItemSampler;
uniform sampler2D DepthSampler;
uniform sampler2D ItemDepthSampler;

in vec2 texCoord;

out vec4 fragColor;

const vec4 controlColors[] = vec4[](
    //   Color          Intensity
    vec4(255, 255, 255,    2.0   ),
    vec4(240, 144, 0  ,    5.0   ),
    vec4(0,   100, 255,    5.0   ),
    vec4(252, 252, 252,    5.0   ),
    vec4(255, 0,   0  ,    5.0   ),
    vec4(255, 100, 0  ,    5.0   ),
    vec4(255, 229, 255,    5.0   ),
    vec4(255, 142, 154,   15.0   ),
    vec4(254, 0,   0  ,    5.0   ),
    vec4(219, 219, 203,    5.0   ),
    vec4(226, 228, 167,    5.0   ),
    vec4(200, 223, 247,    1.0   ),
    vec4(255, 253, 228,    1.0   )
);

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

void main() {
    vec4 color = texture(DiffuseSampler, texCoord);

    if (texture(ItemDepthSampler, texCoord).r < texture(DepthSampler, texCoord).r) {
        color = texture(ItemSampler, texCoord);
    }

    vec3 rgb = floor(color.rgb * 255.0);

    fragColor = encodeLogLuv(vec3(0.0));

    for(int i = 0; i < controlColors.length(); i++) {
        if (rgb == controlColors[i].rgb) {
            fragColor = encodeLogLuv(pow(color.rgb, vec3(2.2)) * controlColors[i].a);
            break;
        }
    }
}
