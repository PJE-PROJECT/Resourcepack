#version 150

uniform sampler2D ControllerSampler;

uniform vec2 InSize;

out vec2 texCoord;
out float aspectRatio;
out float radius;
out vec2 oneTexel;

const mat4 screenquad = mat4(
    vec4(-1.0, -1.0, 0.0, 1.0),
    vec4(1.0, -1.0, 0.0, 1.0),
    vec4(1.0, 1.0, 0.0, 1.0),
    vec4(-1.0, 1.0, 0.0, 1.0)
);

#define RADIUS 90.0

void main() {
    gl_Position = screenquad[gl_VertexID];

    aspectRatio = InSize.x / InSize.y;
    texCoord = gl_Position.xy * 0.5 + 0.5;
    oneTexel = 1.0 / InSize;

    vec4 controller = texelFetch(ControllerSampler, ivec2(0, 1), 0);
    radius = round(controller.rg * 255.0) == vec2(253.0) ? max(controller.b * RADIUS, 1.0) : -1.0;
}
