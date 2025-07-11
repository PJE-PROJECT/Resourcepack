#version 330

#extension GL_ARB_texture_query_lod : require

vec4 textureBilinear(sampler2D samp, vec2 texCoord, vec3 bound1, vec3 bound2, vec3 bound3) {
    if (bound1.z == 0.0 || bound2.z == 0.0 || bound3.z == 0.0) {
        return texture(samp, texCoord);
    }

    float mipLevel = textureQueryLOD(samp, texCoord).x;

    if (mipLevel >= 1.0) {
        return textureLod(samp, texCoord, mipLevel);
    }

    vec2 texSize = vec2(textureSize(samp, 0).xy);

    texCoord *= texSize;
    texCoord -= 0.5;

    bound1.xy /= bound1.z;
    bound2.xy /= bound2.z;
    bound3.xy /= bound3.z;

    texCoord = clamp(texCoord, min(bound1.xy, min(bound2.xy, bound3.xy)) * texSize, 
                               max(bound1.xy, max(bound2.xy, bound3.xy)) * texSize - 1.0);

    ivec2 coord = ivec2(floor(texCoord));
    vec2 frac = fract(texCoord);

    vec4 color = mix(
        mix(texelFetch(samp, coord + ivec2(0, 0), 0), texelFetch(samp, coord + ivec2(1, 0), 0), frac.x),
        mix(texelFetch(samp, coord + ivec2(0, 1), 0), texelFetch(samp, coord + ivec2(1, 1), 0), frac.x),
        frac.y
    );

    if (mipLevel > 0.0) {
        color = mix(color, textureLod(samp, texCoord, 1.0), mipLevel);
    }

    if (color.a >= 251.0 / 255.0) {
        color.a = 1.0;
    }

    return color;
}