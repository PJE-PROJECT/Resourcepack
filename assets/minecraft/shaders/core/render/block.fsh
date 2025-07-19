#version 150

#moj_import <bilinear.glsl>
#moj_import <portal_projection.glsl>
#moj_import <light.glsl>
#moj_import <fog.glsl>

uniform sampler2D Sampler0;

uniform vec4 ColorModulator;

in float vertexDistance;
in vec4 vertexColor;
in vec4 lightColor;
in vec2 texCoord;
in vec2 texCoord2;
in vec3 Pos;
in float transition;
in vec3 texBound0;
in vec3 texBound1;
in vec3 texBound2;

flat in int isCustom;
flat in int noshadow;

out vec4 fragColor;

vec3 TMO(vec3 x) {
    return x / (1.0 + x);
}

void main() {
    vec4 color = textureBilinear(Sampler0, texCoord, texBound0, texBound1, texBound2);

    //custom lighting
    #define BLOCK
    #moj_import<objmc.light>

    if (color.a < 0.01) {
        discard;
    }
    
    color.rgb *= 5.0;

    if (isPortalProj()) {
        fragColor = linear_fog(color, vertexDistance, FogStart, FogEnd * 1.9, FogColor);
    } else if (isShadowProj()) {
        fragColor = color;
    } else {
        fragColor = exponentialFog(color, vertexDistance, FogColor, FogStart, FogEnd);
    }

    fragColor.rgb = TMO(pow(fragColor.rgb, vec3(2.2)));
    fragColor.rgb = pow(fragColor.rgb, vec3(1.0 / 2.2));
}