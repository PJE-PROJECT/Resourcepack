#version 150

uniform sampler2D DiffuseSampler;
uniform sampler2D LightSampler;

in vec2 texCoord;

out vec4 fragColor;

vec3 TMO(vec3 x) {
    return x / (1.0 + x);
}

vec3 InverseTMO(vec3 x) {
    return x / (1.00001 - x);
}

void main() {
    vec4 color = texture(DiffuseSampler, texCoord);
    vec4 light = texture(LightSampler, texCoord);

    fragColor.rgb = InverseTMO(pow(color.rgb, vec3(2.2)));
    fragColor.rgb += color.rgb * 1.1 * light.a * light.a;
    fragColor.rgb = TMO(pow(fragColor.rgb, vec3(1.0 / 2.2)));
    fragColor.a = color.a;
}
