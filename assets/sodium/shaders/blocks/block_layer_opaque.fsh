#version 330 core

#import <sodium:include/bilinear.glsl>
#import <sodium:include/chunk_matrices.glsl>
#import <sodium:include/portal_projection.glsl>
#import <sodium:include/fog.glsl>

in vec4 v_Color; // The interpolated vertex color
in vec2 v_TexCoord; // The interpolated block texture coordinates
in float v_FragDistance; // The fragment's distance from the camera

in float v_MaterialMipBias;
in float v_MaterialAlphaCutoff;

in vec3 texBound0;
in vec3 texBound1;
in vec3 texBound2;

uniform sampler2D u_BlockTex; // The block texture

out vec4 fragColor; // The output fragment for the color framebuffer

vec3 TMO(vec3 x) {
    return x / (1.0 + x);
}

void main() {
    vec4 diffuseColor = textureBilinear(u_BlockTex, v_TexCoord, texBound0, texBound1, texBound2);
    if (diffuseColor.rgb * 255.0 == vec3(253.0, 253.0, 253.0)) {
        fragColor = vec4(254.0, 254.0, 250.0, 255.0) / 255.0;
    } else {
#ifdef USE_FRAGMENT_DISCARD
        if (diffuseColor.a < v_MaterialAlphaCutoff) {
            discard;
        }
#endif

        const mat4 ditherMatrix = mat4(
            0.0, 12.0, 3.0, 15.0,
            8.0, 4.0, 11.0, 7.0,
            2.0, 14.0, 1.0, 13.0,
            10.0, 6.0, 9.0, 5.0
        ) / 16.0;

        float ditherValue = ditherMatrix[int(gl_FragCoord.x) & 3][int(gl_FragCoord.y) & 3];
        vec3 dither = vec3(ditherValue) * 0.06 - 0.03;

        diffuseColor.rgb *= v_Color.rgb + dither;
        diffuseColor.rgb *= v_Color.a;
        
        if (isPortalProj()) {
            fragColor = _linearFog(diffuseColor, v_FragDistance, u_FogColor, u_FogStart, u_FogEnd * 1.9);
        } else if (isShadowProj()) {
            fragColor = diffuseColor;
        } else {
            fragColor = exponentialFog(diffuseColor, v_FragDistance, u_FogColor, u_FogStart, u_FogEnd);
        }

        fragColor.rgb = TMO(pow(fragColor.rgb, vec3(2.2)));
        fragColor.rgb = pow(fragColor.rgb, vec3(1.0 / 2.2));
    }
}