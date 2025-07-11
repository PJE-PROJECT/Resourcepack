#version 150

#moj_import <light.glsl>
#moj_import <fog.glsl>
#moj_import <portal_projection.glsl>

in vec3 Position;
in vec4 Color;
in vec2 UV0;
in ivec2 UV2;
in vec3 Normal;

uniform sampler2D Sampler0;
uniform sampler2D Sampler2;

uniform int FogShape;
uniform mat4 ModelViewMat;
uniform mat3 IViewRotMat;
uniform float GameTime;
uniform vec2 ScreenSize;

uniform vec3 Light0_Direction;
uniform vec3 Light1_Direction;

out float vertexDistance;
out vec4 vertexColor;
out vec4 lightColor;
out vec4 overlayColor;
out vec2 texCoord;
out vec2 texCoord2;
out vec3 Pos;
out float transition;
out vec3 pnormal;
out vec2 pcorner;
flat out vec2 fcorner;
out vec3 Pos1;
out vec3 Pos2;
out vec3 Pos4;
flat out vec3 Pos3;
flat out vec4 col;
flat out mat4 IProjViewMat;
flat out vec2 Rotation;
out vec3 texBound0;
out vec3 texBound1;
out vec3 texBound2;

flat out int isCustom;
flat out int isGUI;
flat out int isHand;
flat out int noshadow;

#moj_import <objmc.tools>

void main() {
    Pos = Position;
    texCoord = UV0;
    overlayColor = vec4(1.0);
    lightColor = minecraft_sample_lightmap(Sampler2, UV2);
    vertexColor = minecraft_mix_light(Light0_Direction, Light1_Direction, Normal, Color);
    vec3 normal = (getProjMat() * ModelViewMat * vec4(Normal, 0.0)).rgb;

    texBound0 = vec3(0.0);
    texBound1 = vec3(0.0);
    texBound2 = vec3(0.0);

    //objmc
    #define ENTITY
    #moj_import <objmc.main>

    gl_Position = getProjMat() * ModelViewMat * (vec4(Pos, 1.0));

    const vec2[4] cornersD = vec2[4](vec2(0.0), vec2(0.0, 1.0), vec2(1.0), vec2(1.0, 0.0));
    vec2 cornerPos = cornersD[gl_VertexID % 4];
    cornerPos.x = 1.0 - cornerPos.x;

    if (texture(Sampler0, UV0).rg == vec2(254.0, 253.0) / 255.0) {
        gl_Position = vec4(cornerPos / ScreenSize * 2.0 - 1.0, -1.0, 1.0);
        vertexColor = vec4(1.0);
        return;
    } else if (texture(Sampler0, UV0).rg == vec2(253.0, 253.0) / 255.0) { // PAUSE BLUR
        gl_Position = vec4((cornerPos + vec2(0.0, 1.0)) / ScreenSize * 2.0 - 1.0, -1.0, 1.0);
        vertexColor = Color;
        return;
    } else if (texture(Sampler0, UV0).rg == vec2(253.0, 252.0) / 255.0) { // Goo reflections
        gl_Position = vec4((cornerPos * vec2(1.0, 38.0) + vec2(1.0, 0.0)) / ScreenSize * 2.0 - 1.0, -1.0, 1.0);
        vertexColor = Color;
        return;
    } else if (texture(Sampler0, UV0).rgba == vec4(252.0, 253.0, 5.0, 10.0) / 255.0) { // Volumetrics
        gl_Position = vec4((cornerPos * vec2(1.0, 1.0) + vec2(1.0, 72.0)) / ScreenSize * 2.0 - 1.0, -1.0, 1.0);
        return;
    } else if (texture(Sampler0, UV0).rgba == vec4(252.0, 253.0, 4.0, 10.0) / 255.0) { // Motion Blur
        gl_Position = vec4((cornerPos * vec2(1.0, 30.0) + vec2(2.0, 40.0)) / ScreenSize * 2.0 - 1.0, -1.0, 1.0);
        return;
    } else if (texture(Sampler0, UV0).rgba == vec4(252.0, 253.0, 3.0, 10.0) / 255.0) { // Shadows
        gl_Position = vec4((cornerPos * vec2(1.0, 1.0) + vec2(1.0, 71.0)) / ScreenSize * 2.0 - 1.0, -1.0, 1.0);
        return;
    } else if (texture(Sampler0, UV0).rgba == vec4(252.0, 253.0, 2.0, 10.0) / 255.0) { // Shadows
        gl_Position = vec4((cornerPos * vec2(1.0, 1.0) + vec2(1.0, 70.0)) / ScreenSize * 2.0 - 1.0, -1.0, 1.0);
        return;
    } else if (texture(Sampler0, UV0).rga == vec3(252.0, 253.0, 10.0) / 255.0) { // Shadows
        gl_Position = vec4((cornerPos * vec2(1.0, 30.0) + vec2(1.0, 40.0)) / ScreenSize * 2.0 - 1.0, -1.0, 1.0);
        return;
    } else if (texture(Sampler0, UV0).rg == vec2(252.0, 251.0) / 255.0) { // NO F5
        gl_Position = vec4(cornerPos * 2.0 - 1.0, -1.0, 1.0);
        vertexColor = Color;
        return;
    } else if (texture(Sampler0, UV0).rg == vec2(250.0, 249.0) / 255.0) { /// Custom Loading Images
        gl_Position = vec4((cornerPos + vec2(0.0, 4.0)) / ScreenSize * 2.0 - 1.0, -1, 1);
        vertexColor = Color;
        return;
    } else if (texture(Sampler0, UV0).rg == vec2(254.0, 252.0) / 255.0) { /// Portal information
        IProjViewMat = inverse(getProjMat() * ModelViewMat);
        
        float yaw = atan(Normal.x, Normal.z);
        float pitch = atan(Normal.y, length(Normal.xz));
        Rotation = vec2(yaw, pitch);
        Pos3 = Position;

        // Encode 16 floats (IProjViewMat) + 5*2 floats (2 portals with yaw,pitch,pxyz)
        // 1 float has 4 bytes, 1 pixel covers 3 bytes.
        // 16 floats -> 64 bytes -> 66/3=22 pixels
        // 5 floats -> 20 bytes -> 20/3=7 pixels
        // Total: 36 pixels
        gl_Position = vec4((cornerPos * vec2(1.0, 36.0) + vec2(0.0, 5.0)) / ScreenSize * 2.0 - 1.0, -1.0, 1.0);
        vertexColor = Color;
        return;
    }
    
    vertexDistance = fog_distance(Pos, FogShape);
    pnormal = Normal * IViewRotMat;
    int quadID = gl_VertexID % 4;

    col = Color;

    Pos3 = Pos4 = Position * IViewRotMat;
    Pos1 = Pos2 = vec3(0.0);

    if (quadID == 0) {
        Pos1 = Position * IViewRotMat;
    } if (quadID == 2) {
        Pos2 = Position * IViewRotMat;
    }

    pcorner = fcorner = cornersD[gl_VertexID % 4];

    if ((gl_VertexID % 4) == 0) {
        texBound0 = vec3(texCoord, 1.0);
    } else if ((gl_VertexID % 4) == 2) {
        texBound2 = vec3(texCoord, 1.0);
    } else {
        texBound1 = vec3(texCoord, 1.0);
    }
}