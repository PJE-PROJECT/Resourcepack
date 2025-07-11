#version 150

uniform sampler2D DiffuseSampler;

in vec2 texCoord;
in vec2 oneTexel;

uniform vec2 BlurDir;
uniform float Radius;

out vec4 fragColor;

void main() {
    vec4 sum = vec4(0.0);
    
    vec2 rbo = Radius * BlurDir * oneTexel;
    sum += texture(DiffuseSampler, texCoord - 2.0 * rbo);
    sum += texture(DiffuseSampler, texCoord - 1.0 * rbo);
    sum += texture(DiffuseSampler, texCoord);
    sum += texture(DiffuseSampler, texCoord + 1.0 * rbo);
    sum += texture(DiffuseSampler, texCoord + 2.0 * rbo);

    fragColor = sum * 0.2;
}
