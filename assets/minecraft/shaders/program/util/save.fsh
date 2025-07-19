#version 150

uniform sampler2D DiffuseSampler;
uniform sampler2D SavedSampler;

in vec2 texCoord;
flat in int save;

out vec4 fragColor;

void main() {
    if (save == 1) {
        fragColor = texture(DiffuseSampler, texCoord);
    } else {
        fragColor = texture(SavedSampler, texCoord);
    }
}
