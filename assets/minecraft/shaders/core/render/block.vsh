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

uniform mat4 ModelViewMat;
uniform vec3 ChunkOffset;
uniform int FogShape;
uniform float GameTime;

out float vertexDistance;
out vec4 vertexColor;
out vec4 lightColor;
out vec2 texCoord;
out vec2 texCoord2;
out vec3 Pos;
out float transition;
out vec3 texBound0;
out vec3 texBound1;
out vec3 texBound2;

flat out int isCustom;
flat out int noshadow;

#moj_import <objmc.tools>

void main() {
    //default
    Pos = Position + ChunkOffset;
    texCoord = UV0;
    vertexColor = Color;
    lightColor = minecraft_sample_lightmap(Sampler2, UV2);
    vec3 normal = (getProjMat() * ModelViewMat * vec4(Normal, 0.0)).rgb;

    texBound0 = vec3(0.0);
    texBound1 = vec3(0.0);
    texBound2 = vec3(0.0);

    if (round(texture(Sampler0, UV0) * 255.0) == vec4(52.0, 52.0, 52.0, 250.0)) {
        const vec2[4] corners = vec2[4](vec2(0.0), vec2(0.0, 1.0), vec2(1.0), vec2(1.0, 0.0));
        vec2 corner = corners[(gl_VertexID) % 4];
        vec2 texSize = textureSize(Sampler0, 0);
        if (Pos.y > 0.0) {
            corner = corner.yx;
        }
        texCoord += (mod(Position.xz - corner, 4.0) * 128.0 - corner * (512.0 - 128.0)) / texSize;
        vertexColor = vec4(0.4, 0.4, 0.4, 1.0);
    } else {
        vertexColor = Color * minecraft_sample_lightmap(Sampler2, UV2);
    }

    //objmc
    #define BLOCK
    #moj_import <objmc.main>

    if ((gl_VertexID % 4) == 0) {
        texBound0 = vec3(texCoord, 1.0);
    } else if ((gl_VertexID % 4) == 2) {
        texBound2 = vec3(texCoord, 1.0);
    } else {
        texBound1 = vec3(texCoord, 1.0);
    }

    gl_Position = getProjMat() * ModelViewMat * vec4(Pos, 1.0);
    vertexDistance = fog_distance_old(ModelViewMat, Pos, FogShape);
}