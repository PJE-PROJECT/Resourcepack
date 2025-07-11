#version 330

uniform sampler2D ItemSampler;

in vec4 Position;

uniform float RedCol;
uniform mat4 ProjMat;
uniform vec2 OutSize;

out vec2 texCoord;
flat out mat4 IProjViewMat;
flat out mat3 localMat;
flat out vec3 portalPos;
flat out mat4 PortalProjMat;

float decodeColor(vec4 color) {
    uvec4 bits = uvec4(round(color * 255.0)) << uvec4(24, 16, 8, 0);
    return uintBitsToFloat(bits.r | bits.g | bits.b | bits.a);
}

mat4 getPortalProjMat() {
    float FOV = radians(150.0);
    float S = 1.0 / tan(FOV * 0.5);
    float f = 1000.0;
    float n = 1.0;

    mat4 projection = mat4(
        S, 0.0, 0.0, 0.0,
        0.0, S, 0.0, 0.0,
        0.0, 0.0, -f / (f - n), -1.0,
        0.0, 0.0, -f * n / (f - n), 0.0
    );

    mat4 translation = mat4(
        1.0, 0.0, 0.0, 0.0,
        0.0, 1.0, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0,
        0.0, -0.3, -0.5, 1.0
    );

    return projection * translation;
}

void getIProjViewMat() {
    vec3 c0 = texelFetch(ItemSampler, ivec2(0, 5), 0).rgb;
    vec3 c1 = texelFetch(ItemSampler, ivec2(0, 6), 0).rgb;
    vec3 c2 = texelFetch(ItemSampler, ivec2(0, 7), 0).rgb;
    vec3 c3 = texelFetch(ItemSampler, ivec2(0, 8), 0).rgb;
    vec3 c4 = texelFetch(ItemSampler, ivec2(0, 9), 0).rgb;
    vec3 c5 = texelFetch(ItemSampler, ivec2(0, 10), 0).rgb;
    vec3 c6 = texelFetch(ItemSampler, ivec2(0, 11), 0).rgb;
    vec3 c7 = texelFetch(ItemSampler, ivec2(0, 12), 0).rgb;
    vec3 c8 = texelFetch(ItemSampler, ivec2(0, 13), 0).rgb;
    vec3 c9 = texelFetch(ItemSampler, ivec2(0, 14), 0).rgb;
    vec3 c10 = texelFetch(ItemSampler, ivec2(0, 15), 0).rgb;
    vec3 c11 = texelFetch(ItemSampler, ivec2(0, 16), 0).rgb;
    vec3 c12 = texelFetch(ItemSampler, ivec2(0, 17), 0).rgb;
    vec3 c13 = texelFetch(ItemSampler, ivec2(0, 18), 0).rgb;
    vec3 c14 = texelFetch(ItemSampler, ivec2(0, 19), 0).rgb;
    vec3 c15 = texelFetch(ItemSampler, ivec2(0, 20), 0).rgb;
    vec3 c16 = texelFetch(ItemSampler, ivec2(0, 21), 0).rgb;
    vec3 c17 = texelFetch(ItemSampler, ivec2(0, 22), 0).rgb;
    vec3 c18 = texelFetch(ItemSampler, ivec2(0, 23), 0).rgb;
    vec3 c19 = texelFetch(ItemSampler, ivec2(0, 24), 0).rgb;
    vec3 c20 = texelFetch(ItemSampler, ivec2(0, 25), 0).rgb;
    vec3 c21 = texelFetch(ItemSampler, ivec2(0, 26), 0).rgb;

    IProjViewMat = mat4(
        decodeColor(vec4(c0.xyz, c1.x)), decodeColor(vec4(c1.yz, c2.xy)), decodeColor(vec4(c2.z, c3.xyz)), decodeColor(vec4(c4.xyz, c5.x)),
        decodeColor(vec4(c5.yz, c6.xy)), decodeColor(vec4(c6.z, c7.xyz)), decodeColor(vec4(c8.xyz, c9.x)), decodeColor(vec4(c9.yz, c10.xy)),
        decodeColor(vec4(c10.z, c11.xyz)), decodeColor(vec4(c12.xyz, c13.x)), decodeColor(vec4(c13.yz, c14.xy)), decodeColor(vec4(c14.z, c15.xyz)),
        decodeColor(vec4(c16.xyz, c17.x)), decodeColor(vec4(c17.yz, c18.xy)), decodeColor(vec4(c18.z, c19.xyz)), decodeColor(vec4(c20.xyz, c21.x))
    );
}

void getPortalMat(int y) {
    vec3 c0 = texelFetch(ItemSampler, ivec2(0, 27 + 7*y), 0).rgb;
    vec3 c1 = texelFetch(ItemSampler, ivec2(0, 28 + 7*y), 0).rgb;
    vec3 c2 = texelFetch(ItemSampler, ivec2(0, 29 + 7*y), 0).rgb;
    vec3 c3 = texelFetch(ItemSampler, ivec2(0, 30 + 7*y), 0).rgb;
    vec3 c4 = texelFetch(ItemSampler, ivec2(0, 31 + 7*y), 0).rgb;
    vec3 c5 = texelFetch(ItemSampler, ivec2(0, 32 + 7*y), 0).rgb;
    vec3 c6 = texelFetch(ItemSampler, ivec2(0, 33 + 7*y), 0).rgb;
    float yaw = decodeColor(vec4(c0.xyz, c1.x));
    float pitch = decodeColor(vec4(c1.yz, c2.xy)) - 0.1;
    portalPos = vec3(
        decodeColor(vec4(c2.z, c3.xyz)),
        decodeColor(vec4(c4.xyz, c5.x)),
        decodeColor(vec4(c5.yz, c6.xy))
    );
    float cy = cos(yaw);
    float sy = sin(yaw);
    float cp = cos(pitch);
    float sp = sin(pitch);
    localMat = mat3(
        cy, 0,-sy,
         0, 1, 0,
        sy, 0, cy
    ) * mat3(
        1,  0,  0,
        0, cp,-sp,
        0, sp, cp
    );
}

void main(){
    PortalProjMat = getPortalProjMat();
    
    getIProjViewMat();

    if (RedCol == 3.0) {
        getPortalMat(0);
    } else {
        getPortalMat(1);
    }

    vec4 outPos = ProjMat * vec4(Position.xy, 0.0, 1.0);
    gl_Position = vec4(outPos.xy, 0.2, 1.0);

    texCoord = Position.xy / OutSize;
}
