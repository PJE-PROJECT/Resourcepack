#version 330

uniform sampler2D DiffuseSampler;
uniform sampler2D DepthSampler;

uniform vec2 InSize;

in vec2 texCoord;
flat in mat4 invProjMat;
flat in mat4 prevProjMat;
flat in vec3 cameraOffset;
flat in int hasData;

out vec4 fragColor;

struct prng_state {
    vec3 seed;
};

prng_state global_prngState;

prng_state initLocalPRNG(vec2 texcoord, int frame) {
    return prng_state(vec3(texcoord, float(frame)));
}

void initGlobalPRNG(vec2 texcoord, int frame) {
    global_prngState = prng_state(vec3(texcoord, float(frame)));
}

uint hash(uint x) {
    x += (x << 10u);
    x ^= (x >> 6u);
    x += (x << 3u);
    x ^= (x >> 11u);
    x += (x << 15u);
    return x;
}

uint hash(uvec3 v) {
    return hash(v.x ^ hash(v.y) ^ hash(v.z));
}

float floatConstruct(uint m) {
    const uint ieeeMantissa = 0x007FFFFFu;
    const uint ieeeOne = 0x3F800000u;

    m &= ieeeMantissa;
    m |= ieeeOne;

    float f = uintBitsToFloat(m);
    return fract(f - 1.0);
}

void advancePRNG(inout prng_state state) {
    state.seed += 1.0;
}

uint hashPRNG(prng_state state) {
    return hash(floatBitsToUint(state.seed));
}

float random1(inout prng_state state) {
    advancePRNG(state);
    return floatConstruct(hashPRNG(state));
}
float random1() {
    return random1(global_prngState);
}

vec3 toWorldSpace(vec2 uv, float z) {
    vec4 position = invProjMat * (vec4(uv, z, 1.0) * 2.0 - 1.0);
    return position.xyz / position.w;
}

vec2 toScreenSpace(vec3 position) {
    vec4 clip = prevProjMat * vec4(position, 1.0);
    return clip.xy / clip.w * 0.5 + 0.5;
}

int sdt(ivec2 coord) {
    return (coord.x + coord.y) & 1;
}

void main() {
    float depth = texture(DepthSampler, texCoord).r;

    gl_FragDepth = depth;
    fragColor = texture(DiffuseSampler, texCoord);
    
    if (hasData == 0 || depth == 1.0) {
        return;
    }

    initGlobalPRNG(texCoord, 0);

    const int numSamples = 12;
    const float strength = 0.05;

    vec3 worldSpace = toWorldSpace(texCoord, depth);
    vec2 prevPos = toScreenSpace(worldSpace - cameraOffset);

    vec2 velocity = texCoord - prevPos;
    velocity /= 1.0 + length(velocity);
    velocity *= strength;

    vec3 color = vec3(0.0);
    vec2 sampleCoord = texCoord - velocity * 0.5 * float(numSamples);
    sampleCoord += velocity * random1();

    int sdtRef = sdt(ivec2(gl_FragCoord.xy));
    for (int i = 0; i < numSamples; ++i, sampleCoord += velocity) {
        vec2 currentCoord = clamp(sampleCoord, 0.0, 1.0);
        ivec2 pixelCoord = ivec2(currentCoord * InSize);
        if (sdtRef != sdt(pixelCoord)) {
            pixelCoord.x += 1;
        }

        pixelCoord = clamp(pixelCoord, ivec2(0, 0), ivec2(InSize) - 1);
        vec4 currentColor = texelFetch(DiffuseSampler, pixelCoord, 0);
        color += currentColor.rgb;
    }

    fragColor = vec4(color / float(numSamples), 1.0);
}
