#version 150

#moj_import <light.glsl>
#moj_import <fog.glsl>
#moj_import <portal_projection.glsl>

in vec3 Position;
in vec4 Color;
in vec2 UV0;
in vec2 UV1;
in ivec2 UV2;
in vec3 Normal;

uniform sampler2D Sampler2;

uniform mat4 ModelViewMat;
uniform mat3 IViewRotMat;
uniform int FogShape;

uniform vec3 Light0_Direction;
uniform vec3 Light1_Direction;

out float vertexDistance;
out vec4 vertexColor;
out vec2 texCoord0;
out vec2 texCoord1;
out vec2 texCoord2;
out vec3 normal;
out vec2 corner;
flat out vec2 fcorner;
out vec3 Pos1;
out vec3 Pos2;
flat out vec3 Pos3;
flat out vec4 col;

void main() {
    gl_Position = getProjMat() * ModelViewMat * vec4(Position, 1.0);

    vertexDistance = fog_distance_old(ModelViewMat, IViewRotMat * Position, FogShape);
    vertexColor = minecraft_mix_light(Light0_Direction, Light1_Direction, Normal, Color) * texelFetch(Sampler2, UV2 / 16, 0);
    texCoord0 = UV0;
    texCoord1 = UV1;
    texCoord2 = UV2;
    normal = Normal * IViewRotMat;

    int quadID = gl_VertexID % 4;
    
    col = Color;

    Pos3 = Position * IViewRotMat;
    Pos1 = Pos2 = vec3(0.0);

    if (quadID == 0) {
        Pos1 = Position * IViewRotMat;
    } if (quadID == 2) {
        Pos2 = Position * IViewRotMat;
    }

    const vec2[4] corners = vec2[4](vec2(0.0), vec2(0.0, 1.0), vec2(1.0), vec2(1.0, 0.0));
    corner = fcorner = corners[gl_VertexID % 4];
}
