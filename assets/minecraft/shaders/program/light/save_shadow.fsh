#version 330

uniform sampler2D DiffuseSampler;
uniform sampler2D DepthSampler;
uniform sampler2D SavedSampler;
uniform sampler2D SavedDepthSampler;

in vec2 texCoord;
flat in int save;

out vec4 fragColor;

float decodeFloat(vec4 color) {
    uvec4 bits = uvec4(round(color * 255.0)) << uvec4(24, 16, 8, 0);
    return uintBitsToFloat(bits.r | bits.g | bits.b | bits.a);
}

void main() {
    if (save == 1) {
        fragColor = texture(DiffuseSampler, texCoord);
        gl_FragDepth = decodeFloat(texture(DepthSampler, texCoord));
    } else {
        fragColor = texture(SavedSampler, texCoord);
        gl_FragDepth = texture(SavedDepthSampler, texCoord).r;
    }
}
