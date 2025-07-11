#version 150

#moj_import <fog.glsl>

uniform sampler2D Sampler0;

uniform vec4 ColorModulator;
uniform float FogStart;
uniform float FogEnd;
uniform vec4 FogColor;

in float vertexDistance;
in vec2 texCoord0;
in vec4 lightColor;
in vec4 tintColor;

out vec4 fragColor;

void main() {
    vec4 col = texture(Sampler0, texCoord0);
    // if (round(col * 255.0) == vec4(56.0, 176.0, 119.0, 54.0)) {
    //     discard;
    // }

    if (col.a == 250.0 / 255.0) {
        fragColor = col;
        fragColor.a = 1.0;
    } else {
        col *= ColorModulator * tintColor;
        if (col.a < 0.1) {
            discard;
        }

        fragColor = linear_fog(col, vertexDistance, FogStart, FogEnd, FogColor);
    }
}
