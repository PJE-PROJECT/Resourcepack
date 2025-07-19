#version 150

in vec4 Position;

uniform sampler2D ParticlesSampler;

uniform mat4 ProjMat;
uniform vec2 InSize;
uniform vec2 OutSize;

uniform vec3 Color;
uniform float Offset;
uniform float PixelX;

out vec2 texCoord;
flat out int save;

void main() {
    vec4 outPos = ProjMat * vec4(Position.xy, 0.0, 1.0);
    gl_Position = vec4(outPos.xy, 0.2, 1.0);

    vec2 oneTexel = 1.0 / InSize;
    texCoord = Position.xy / OutSize;

    vec3 col = round(texelFetch(ParticlesSampler, ivec2(PixelX, Offset), 0).rgb * 255.0);
    if (Color.r == -1.0) col.r = Color.r;
    if (Color.g == -1.0) col.g = Color.g;
    if (Color.b == -1.0) col.b = Color.b;

    save = int(col == Color);
}
