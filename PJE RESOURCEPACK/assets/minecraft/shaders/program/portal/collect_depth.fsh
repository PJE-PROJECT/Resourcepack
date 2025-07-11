#version 330

in vec2 texCoord;

uniform sampler2D DiffuseDepthSampler;
uniform sampler2D TranslucentDepthSampler;
uniform sampler2D ItemEntityDepthSampler;
uniform sampler2D ParticlesDepthSampler;
uniform sampler2D WeatherDepthSampler;
uniform sampler2D CloudsDepthSampler;

out vec4 fragColor;

vec4 encodeFloat(float value) {
    uint bits = floatBitsToUint(value);
    return vec4(
        bits >> 24u, (bits >> 16u) & 0xFFu, 
        (bits >> 8u) & 0xFFu, bits & 0xFFu
    ) / 255.0;
}

void main() {
    ivec2 coords = ivec2(gl_FragCoord.xy);

    float depth = texelFetch(DiffuseDepthSampler, coords, 0).x;
    depth = min(depth, texelFetch(TranslucentDepthSampler, coords, 0).x);
    depth = min(depth, texelFetch(ItemEntityDepthSampler, coords, 0).x);
    depth = min(depth, texelFetch(ParticlesDepthSampler, coords, 0).x);
    depth = min(depth, texelFetch(WeatherDepthSampler, coords, 0).x);

    vec4 color = encodeFloat(depth);
    fragColor = vec4(color.rgb, 1.0);
}