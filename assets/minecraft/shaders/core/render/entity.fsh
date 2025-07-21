#version 330

#moj_import <bilinear.glsl>
#moj_import <portal_projection.glsl>
#moj_import <light.glsl>
#moj_import <fog.glsl>
#moj_import <matf.glsl>

uniform sampler2D Sampler0;

uniform vec4 ColorModulator;
uniform mat3 IViewRotMat;
uniform mat4 ModelViewMat;
uniform float GameTime;

uniform vec3 Light0_Direction;
uniform vec3 Light1_Direction;

in float vertexDistance;
in vec4 vertexColor;
in vec4 lightColor;
in vec4 overlayColor;
in vec2 texCoord;
in vec2 texCoord2;
in vec3 Pos;
in float transition;
in vec3 pnormal;
in vec2 pcorner;
flat in vec2 fcorner;
in vec3 Pos1;
in vec3 Pos2;
in vec3 Pos4;
flat in vec3 Pos3;
flat in vec4 col;
in vec3 texBound0;
in vec3 texBound1;
in vec3 texBound2;

flat in int isCustom;
flat in int isGUI;
flat in int isHand;
flat in int noshadow;
flat in mat4 IProjViewMat;
flat in vec2 Rotation;

out vec4 fragColor;

vec4 encodeFloat(float value) {
    uint iValue = floatBitsToUint(value);
    return vec4(
        iValue >> 24u,
        iValue >> 16u & 0xffu,
        iValue >>  8u & 0xffu,
        iValue        & 0xffu
    ) / 255.0;
}

vec4 encodeInt(int i) {
    int s = int(i < 0) * 128;
    i = abs(i);
    int r = i % 256;
    i = i / 256;
    int g = i % 256;
    i = i / 256;
    int b = i % 256;
    return vec4(float(r) / 255.0, float(g) / 255.0, float(b + s) / 255.0, 1.0);
}

vec4 encodeFloat3(float v) {
    v *= 40000.0;
    v = floor(v);
    return encodeInt(int(v));
}

vec3 TMO(vec3 x) {
    return x / (1.0 + x);
}

void main() {
    vec4 color = textureBilinear(Sampler0, texCoord, texBound0, texBound1, texBound2);
    vec4 control = texture(Sampler0, texCoord);

    bool set = false;
    if (round(control.a * 255.0) == 252.0) { // PORTALS
        color = vec4(control.r, 0.0, 0.0, 1.0);
        set = true;
    } else if (round(control.a * 255.0) == 253.0) { // SCREEN-DOOR TRANSPARENCY
        int index = int(gl_FragCoord.x) + int(gl_FragCoord.y);
        if ((index & 1) == 0 && !isPortalProj()) {
            discard;
        } else {
            color *= 1.5;
            color.a = 0.5;
        }
        set = false;
    } else if (floor(control.a * 255.0) == 254.0) { // EMISSIVE
        set = true;
    } else if (control.rg == vec2(254.0, 253.0) / 255.0 || control.rg == vec2(255.0, 254.0) / 255.0) {
        set = true;
    } else if (control.rg == vec2(253.0, 253.0) / 255.0) {
        color = vec4(control.rg, vertexColor.b, 1.0);
        set = true;
    } else if (control.rg == vec2(253.0, 252.0) / 255.0) { // Goo reflections
        int index = int(gl_FragCoord.y);

        if (index < 16) {
            color = encodeFloat3(ProjMat[index / 4][index % 4]);
        } else if (index < 20) {
            index -= 16;
            if (index == 0) {
                color = vec4(encodeFloat(Pos.x).rgb, 1.0);
            } else if (index == 1) {
                color = vec4(encodeFloat(Pos.x).a, encodeFloat(Pos.y).rg, 1.0);
            } else if (index == 2) {
                color = vec4(encodeFloat(Pos.y).ba, encodeFloat(Pos.z).r, 1.0);
            } else if (index == 3) {
                color = vec4(encodeFloat(Pos.z).gba, 1.0);
            }
        } else if (index == 20) {
            color = vec4(encodeFloat(GameTime).rgb, 1.0);
        } else if (index == 21) {
            color = vec4(190.0, 32.0, encodeFloat(GameTime).a, 255.0) / 255.0;
        } else if (index < 31) {
            index -= 22;
            color = encodeFloat3(ModelViewMat[index / 3][index % 3]);
        } else {
            discard;
        }

        set = true;
    } else if (round(control.rgba * 255.0) == vec4(252.0, 253.0, 5.0, 10.0)) { // Volumetrics
        color = vec4(191.0, 32.0, 5.0, 255.0) / 255.0;
        set = true;
    } else if (round(control.rgba * 255.0) == vec4(252.0, 253.0, 4.0, 10.0)) { // Shadows
        int index = int(gl_FragCoord.y) - 40;

        if (index < 22) { 
            mat4 projMat = ProjMat * ModelViewMat;
            if (index == 21) { // Same as below
                color.r = encodeFloat(projMat[3][3]).a;
                color.gb = vec2(0.0);
            } else if (index*3 % 4 == 0) { // y*3/4 == (y*3+2)/4
                color.rgb = encodeFloat(projMat[index*3/16][(index*3/4)%4]).rgb;
            } else if (index*3 % 4 == 1) { // y*3/4 == (y*3+2)/4
                color.rgb = encodeFloat(projMat[index*3/16][(index*3/4)%4]).gba;
            } else if (index*3 % 4 == 2) { // y*3/4 != (y*3+2)/4
                color.rg = encodeFloat(projMat[index*3/16][(index*3/4)%4]).ba;
                color.b = encodeFloat(projMat[(index*3+2)/16][((index*3+2)/4)%4]).r;
            } else { // y*3/4 != (y*3+2)/4
                color.r = encodeFloat(projMat[index*3/16][(index*3/4)%4]).a;
                color.gb = encodeFloat(projMat[(index*3+2)/16][((index*3+2)/4)%4]).rg;
            }
        } else if (index < 26) {
            index -= 22;
            if (index == 0) {
                color = vec4(encodeFloat(Pos.x).rgb, 1.0);
            } else if (index == 1) {
                color = vec4(encodeFloat(Pos.x).a, encodeFloat(Pos.y).rg, 1.0);
            } else if (index == 2) {
                color = vec4(encodeFloat(Pos.y).ba, encodeFloat(Pos.z).r, 1.0);
            } else if (index == 3) {
                color = vec4(encodeFloat(Pos.z).gba, 1.0);
            }
        } else if (index == 29) {
            color = vec4(191.0, 32.0, 4.0, 255.0) / 255.0;
        } else {
            discard;
        }

        set = true;
    } else if (round(control.rgba * 255.0) == vec4(252.0, 253.0, 3.0, 10.0)) {
        color = vec4(191.0, 32.0, 3.0, 255.0) / 255.0;
        set = true;
    } else if (round(control.rgba * 255.0) == vec4(252.0, 253.0, 2.0, 10.0)) {
        color = vec4(191.0, 32.0, 2.0, 255.0) / 255.0;
        set = true;
    } else if (round(control.rga * 255.0) == vec3(252.0, 253.0, 10.0)) { // Shadows
        int index = int(gl_FragCoord.y) - 40;

        if (index < 22) { 
            mat4 projMat = getProjMat() * ModelViewMat;
            if (index == 21) { // Same as below
                color.r = encodeFloat(projMat[3][3]).a;
                color.gb = vec2(0.0);
            } else if (index*3 % 4 == 0) { // y*3/4 == (y*3+2)/4
                color.rgb = encodeFloat(projMat[index*3/16][(index*3/4)%4]).rgb;
            } else if (index*3 % 4 == 1) { // y*3/4 == (y*3+2)/4
                color.rgb = encodeFloat(projMat[index*3/16][(index*3/4)%4]).gba;
            } else if (index*3 % 4 == 2) { // y*3/4 != (y*3+2)/4
                color.rg = encodeFloat(projMat[index*3/16][(index*3/4)%4]).ba;
                color.b = encodeFloat(projMat[(index*3+2)/16][((index*3+2)/4)%4]).r;
            } else { // y*3/4 != (y*3+2)/4
                color.r = encodeFloat(projMat[index*3/16][(index*3/4)%4]).a;
                color.gb = encodeFloat(projMat[(index*3+2)/16][((index*3+2)/4)%4]).rg;
            }
        } else if (index < 26) {
            index -= 22;
            if (index == 0) {
                color = vec4(encodeFloat(Pos.x).rgb, 1.0);
            } else if (index == 1) {
                color = vec4(encodeFloat(Pos.x).a, encodeFloat(Pos.y).rg, 1.0);
            } else if (index == 2) {
                color = vec4(encodeFloat(Pos.y).ba, encodeFloat(Pos.z).r, 1.0);
            } else if (index == 3) {
                color = vec4(encodeFloat(Pos.z).gba, 1.0);
            }
        } else if (index < 29) {
            index -= 26;
            color = encodeFloat3(ModelViewMat[index][2]);
        } else if (index == 29) {
            color = vec4(191.0, 32.0, control.b * 255.0, 255.0) / 255.0;
        } else {
            discard;
        }

        set = true;
    } else if (control.rg == vec2(252.0, 251.0) / 255.0) { // NO F5
        color = vec4(0.0, 0.0, 0.0, 255.0) / 255;
        set = true;
    } else if (control.rg == vec2(250.0, 249.0) / 255.0) { // CUSTOM LOADING IMAGES
        color = vec4(control.rg, vertexColor.b, 1.0);
        set = true;
    } else if ((control.rgb == vec3(255.0, 0.0, 0.0) / 255.0) || (control.rgb == vec3(254.0, 0.0, 0.0) / 255.0)) { // LASER BLOOM
        set = true;
    } else if (control.rg == vec2(254.0, 252.0) / 255.0) { // Portal information
        color.a = 1.0;
        // Encode 16 floats (IProjViewMat) + 2*2 floats (2 portals with yaw,pitch)
        // 1 float has 4 bytes, 1 pixel covers 3 bytes.
        // 16 floats -> 64 bytes -> 66/3=22 pixels
        // 2 floats -> 8 bytes -> 9/3=3 pixels
        // Total: 28 pixels
        int y = int(gl_FragCoord.y) - 5;
        if (y < 22) { // Draw IProjViewMat
            // Draw bytes y*3 to y*3+2
            // byte b is on matrix entry b / 4
            // MatrixList[i] = Matrix[i/4][i%4]
            // bytes[b] = MatrixList[b/4].toBytes()[b%4]
            //          = Matrix[b/16][(b/4)%4].toBytes()[b%4]
            
            if (y == 21) {
                // Only draw byte y*3=63
                color.r = encodeFloat(IProjViewMat[3][3]).a;
                // Pause screen if bossbar fog:
                if (abs(FogEnd - FogStart * 10.0) < 0.5 || (abs(FogEnd - 96.0) < 0.5 && abs(FogStart - 86.4) > 0.5)) {
                    color.gb = vec2(254.0, 253.0) / 255.0;
                }
            } else if (y*3 % 4 == 0) { // y*3/4 == (y*3+2)/4
                color.rgb = encodeFloat(IProjViewMat[y*3/16][(y*3/4)%4]).rgb;
            } else if (y*3 % 4 == 1) { // y*3/4 == (y*3+2)/4
                color.rgb = encodeFloat(IProjViewMat[y*3/16][(y*3/4)%4]).gba;
            } else if (y*3 % 4 == 2) { // y*3/4 != (y*3+2)/4
                color.rg = encodeFloat(IProjViewMat[y*3/16][(y*3/4)%4]).ba;
                color.b = encodeFloat(IProjViewMat[(y*3+2)/16][((y*3+2)/4)%4]).r;
            } else { // y*3/4 != (y*3+2)/4
                color.r = encodeFloat(IProjViewMat[y*3/16][(y*3/4)%4]).a;
                color.gb = encodeFloat(IProjViewMat[(y*3+2)/16][((y*3+2)/4)%4]).rg;
            }
            fragColor = color;
            return;
        }
        y -= 22;
        if (control.b > 0.0) y -= 7;
        if (y < 0 || y >= 7) {
            discard;
        }
        // Draw portal rotation and position
        if (y == 0) {
            color.rgb = encodeFloat(Rotation.x).rgb;
        } else if (y == 1) {
            color.r = encodeFloat(Rotation.x).a;
            color.gb = encodeFloat(Rotation.y).rg;
        } else if (y == 2) {
            color.rg = encodeFloat(Rotation.y).ba;
            color.b = encodeFloat(Pos3.x).r;
        } else if (y == 3) {
            color.rgb = encodeFloat(Pos3.x).gba;
        } else if (y == 4) {
            color.rgb = encodeFloat(Pos3.y).rgb;
        } else if (y == 5) {
            color.r = encodeFloat(Pos3.y).a;
            color.gb = encodeFloat(Pos3.z).rg;
        } else {
            color.rg = encodeFloat(Pos.z).ba;
        }
        fragColor = color;
        return;
    } else {
        //custom lighting
        set = false;

        #define ENTITY
        #moj_import<objmc.light>
    }

    if (color.a < 0.01) {
        discard;
    }

    if (set) {
        fragColor = vec4(color.rgb, 1.0);
        return;
    } else if (isPortalProj()) {
        fragColor = linear_fog(color, vertexDistance, FogStart, FogEnd * 1.9, FogColor);
    } else if (isShadowProj()) {
        fragColor = color;
    } else {
        fragColor = exponentialFog(color, vertexDistance, FogColor, FogStart, FogEnd);
    }
    fragColor *= 1.5;
    fragColor.rgb = TMO(pow(fragColor.rgb, vec3(2.2)));
    fragColor.rgb = pow(fragColor.rgb, vec3(1.0 / 2.2));

#ifdef ITEM_ENTITY
    if (floor(fragColor.r * 255.0) <= 3.0) {
        fragColor.r = 0.0;
    }

    if (gl_FragCoord.x < 3.0 && gl_FragCoord.y < 100.0) {
        discard;
    }
#endif
}