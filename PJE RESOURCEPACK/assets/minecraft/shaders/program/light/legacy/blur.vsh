#version 150

uniform vec2 InSize;

out vec2 texCoord;
out vec2 oneTexel;

const mat4 screenquad = mat4(
    vec4(-1.0, -1.0, 0.0, 1.0),
    vec4(1.0, -1.0, 0.0, 1.0),
    vec4(1.0, 1.0, 0.0, 1.0),
    vec4(-1.0, 1.0, 0.0, 1.0)
);

void main(){
    gl_Position = screenquad[gl_VertexID];

    texCoord = gl_Position.xy * 0.5 + 0.5;
    oneTexel = 1.0 / InSize;
}
