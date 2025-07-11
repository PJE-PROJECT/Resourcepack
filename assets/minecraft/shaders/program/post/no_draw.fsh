#version 150

uniform sampler2D DiffuseSampler;
uniform sampler2D ControlSampler;
uniform sampler2D SavedSampler;
uniform sampler2D DepthSampler;

uniform vec4 ColorModulate;

in vec2 texCoord;

out vec4 fragColor;

void main() {
    bool isShadowmap = round(texelFetch(ControlSampler, ivec2(1, 69), 0).rgb * 255.0) == vec3(191.0, 32.0, 1.0);
    if (texture(DepthSampler, texCoord).r == 1.0 && !isShadowmap) {
        fragColor = texture(DiffuseSampler, texCoord) * ColorModulate;
    } else {
        fragColor = texture(SavedSampler, texCoord) * ColorModulate;
    }
}
