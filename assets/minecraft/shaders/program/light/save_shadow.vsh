#version 150

uniform sampler2D DiffuseSampler;

out vec2 texCoord;
flat out int save;

const mat4 screenquad = mat4(
    vec4(-1.0, -1.0, 0.0, 1.0),
    vec4(1.0, -1.0, 0.0, 1.0),
    vec4(1.0, 1.0, 0.0, 1.0),
    vec4(-1.0, 1.0, 0.0, 1.0)
);

void main() {
    gl_Position = screenquad[gl_VertexID];
    texCoord = gl_Position.xy * 0.5 + 0.5;

    save = int(round(texelFetch(DiffuseSampler, ivec2(1, 69), 0).rgb * 255.0) == vec3(191.0, 32.0, 1.0));
}
