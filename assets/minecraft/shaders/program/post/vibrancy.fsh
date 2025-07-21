#version 150

#define MODE 0

uniform sampler2D DiffuseSampler;
uniform sampler2D Lut1Sampler;
uniform sampler2D Lut2Sampler;

in vec2 texCoord;

out vec4 fragColor;

vec3 TMO(vec3 x) {
    return x / (1.0 + x);
}

vec3 InverseTMO(vec3 x) {
    return x / (1.00001 - x);
}


const mat3 acesInputMat = mat3(
    0.59719, 0.07600, 0.02840,
    0.35458, 0.90834, 0.13383,
    0.04823, 0.01566, 0.83777
);

const mat3 acesOutputMat = mat3(
    1.60475, -0.10208, -0.00327,
    -0.53108, 1.10813, -0.07276,
    -0.07367, -0.00605, 1.07602
);

vec3 RRTandODTfit(vec3 v) {
    vec3 a = v * (v + 0.0245786) - 0.000090537;
    vec3 b = v * (0.983729 * v + 0.4329510) + 0.238081;
    return a / b;
}

vec3 acesFitted(vec3 color) {
    color = acesInputMat * color;
    color = RRTandODTfit(color);
    color = acesOutputMat * color;
    return clamp(color, 0.0, 1.0);
}

void main() {
    fragColor = texture(DiffuseSampler, texCoord);

#if (MODE == 0)
    ivec3 rgb = ivec3(fragColor.rgb * 255.0);
    int zx = rgb.b % 16;
    int zy = rgb.b / 16;

    fragColor.rgb = texelFetch(Lut1Sampler, ivec2(zx * 256 + rgb.r, zy * 256 + rgb.g), 0).rgb;
#elif (MODE == 1)
    fragColor.rgb = pow(fragColor.rgb, vec3(2.2));
    fragColor.rgb = InverseTMO(fragColor.rgb);
    fragColor.rgb *= 6.0;
    fragColor.rgb = mix(acesFitted(fragColor.rgb), TMO(fragColor.rgb), 0.4);

    float x = fragColor.g * (31.0 / 1024.0) + 0.5 / 1024.0;
    float y = fragColor.b * (31.0 / 32.0) + 0.5 / 32.0;
    float z1 = floor(fragColor.r * 31.0) / 32.0;
    float z2 = ceil(fragColor.r * 31.0) / 32.0;

    vec3 cc1 = texture(Lut2Sampler, vec2(x + z1, y)).rgb;
    vec3 cc2 = texture(Lut2Sampler, vec2(x + z2, y)).rgb;
    float t = (z2 == z1) ? 0.0 : (fragColor.r * 31.0 / 32.0 - z1) / (z2 - z1);

    fragColor.rgb = mix(cc1, cc2, t);
    fragColor.rgb = pow(fragColor.rgb, vec3(1.0 / 2.2));
#endif
}
