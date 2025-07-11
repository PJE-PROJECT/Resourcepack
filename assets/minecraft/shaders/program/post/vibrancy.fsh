#version 150

const float vibrancy = 2.0;
const vec4 coefficients = vec4(0.15, 0.15, 0.15, 0.0);

uniform sampler2D DiffuseSampler;

in vec2 texCoord;

out vec4 fragColor;

void main() {
    vec4 color = texture(DiffuseSampler, texCoord);
    float luma = dot(color, coefficients);

    vec4 mask = color - vec4(luma);
    mask = clamp(mask, 0.0, 1.0);

    float lumMask = dot(coefficients, mask);
    lumMask = 1.0 - lumMask;
    
    fragColor = mix(vec4(luma), color, 1.0 + vibrancy * lumMask);
}
