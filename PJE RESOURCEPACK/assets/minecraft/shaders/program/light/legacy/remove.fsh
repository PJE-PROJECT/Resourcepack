#version 150

uniform sampler2D DiffuseSampler;

in vec2 texCoord;

out vec4 fragColor;

void main() {
    vec4 color = texture(DiffuseSampler, texCoord);
    
    if (floor(color.rgb * 255.0) == vec3(255.0, 254.0, 0.0)) {
        color = vec4(0.0);
    }
    
    fragColor = color;
}
