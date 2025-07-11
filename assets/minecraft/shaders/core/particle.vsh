#version 150

#moj_import <fog.glsl>
#moj_import <portal_projection.glsl>

in vec3 Position;
in vec2 UV0;
in vec4 Color;
in ivec2 UV2;

uniform sampler2D Sampler0;
uniform sampler2D Sampler2;

uniform mat4 ModelViewMat;
uniform int FogShape;

out float vertexDistance;
out vec2 texCoord0;
out vec4 lightColor;
out vec4 tintColor;

void main() {
    vec4 Pos = ModelViewMat * vec4(Position, 1.0);

    vec4 col = round(texture(Sampler0, UV0) * 255.0);
    // if (col == vec4(56.0, 176.0, 119.0, 54.0)) {
    //     Pos.z += 1.0;
    // }

    gl_Position = getProjMat() * Pos;
    if (isShadowProj()) {
        gl_Position = vec4(2.0, 2.0, 2.0, 1.0);
    }

    vertexDistance = fog_distance_old(ModelViewMat, Position, FogShape);
    texCoord0 = UV0;
    tintColor = Color;
    lightColor = texelFetch(Sampler2, UV2 / 16, 0);
}
