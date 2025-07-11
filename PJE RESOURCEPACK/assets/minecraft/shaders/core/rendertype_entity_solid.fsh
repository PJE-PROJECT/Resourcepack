#version 150

#moj_import <fog.glsl>

#define EYE_SIZE 0.03

uniform sampler2D Sampler0;

uniform vec4 ColorModulator;
uniform float FogStart;
uniform float FogEnd;
uniform vec4 FogColor;
uniform vec2 ScreenSize;

in float vertexDistance;
in vec4 vertexColor;
in vec4 lightMapColor;
in vec4 overlayColor;
in vec2 texCoord0;
in vec4 normal;

out vec4 fragColor;

bool isRect(vec2 val, vec2 p1, vec2 p2) {
    return val.x >= p1.x && val.y >= p1.y && val.x <= p2.x && val.y <= p2.y;
}

void main() {
    ivec2 pCoord = ivec2(texCoord0 * 16.0);
    vec2 inpC = texCoord0 * 16.0 - vec2(pCoord);

    vec2 coord = texCoord0;
    vec4 color = texture(Sampler0, coord) * vertexColor * ColorModulator;

    if (pCoord == ivec2(7, 7) && textureSize(Sampler0, 0) == ivec2(256) && (isRect(inpC, vec2(3, 6) / 16, vec2(5, 8) / 16) || isRect(inpC, vec2(7, 6) / 16, vec2(9, 8) / 16))) {
        color = vec4(0.0, 0.0, 0.0, 1.0);

        vec2 offs = (gl_FragCoord.xy / ScreenSize - 0.5 + normal.xy / 2.0) * vec2(1.0, -1.0);

        vec2 a = abs(inpC - vec2(4.0, 7.0) / 16.0 + offs / 10.0);
        if (a.x <= EYE_SIZE && a.y <= EYE_SIZE) {
            color = vec4(0.8, 0.0, 0.0, 1.0);
        }

        a = abs(inpC - vec2(8.0, 7.0) / 16.0 + offs / 10.0);
        if (a.x <= EYE_SIZE && a.y <= EYE_SIZE) {
            color = vec4(0.8, 0.0, 0.0, 1.0);
        }
    }

    color.rgb = mix(overlayColor.rgb, color.rgb, overlayColor.a);
    color *= lightMapColor;

    if (color.a == 0.0) {
        discard;
    }

    fragColor = linear_fog(color, vertexDistance, FogStart, FogEnd, FogColor);
}
