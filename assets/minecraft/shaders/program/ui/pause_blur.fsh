#version 150

uniform sampler2D DiffuseSampler;

in vec2 texCoord;
in vec2 oneTexel;
in float radius;

uniform vec2 InSize;
uniform vec2 BlurDir;

out vec4 fragColor;

float grayscale(vec3 color) {
    vec3 linear = pow(color, vec3(2.2));
    float luma = dot(linear, vec3(0.2126, 0.7152, 0.0722));
    return pow(luma, 1.0 / 2.2);
}

void main() {
    vec4 sum = vec4(0.0);
    float weightSum = 0.0;

    if (radius != -1.0) {
        for (float r = -radius; r <= radius; r += 1.0) {
            float weight = radius - abs(r);
            vec4 value = texture(DiffuseSampler, texCoord + oneTexel * r * BlurDir);

            weightSum += weight;
            sum += value * weight;
        }
        
        vec4 color = sum / weightSum;
        float gs = grayscale(color.rgb);
        fragColor = mix(color, vec4(vec3(gs), 1.0), radius * 0.25); 
    } else {
        fragColor = texture(DiffuseSampler, texCoord);
    }
}
