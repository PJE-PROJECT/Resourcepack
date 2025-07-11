#version 330

uniform sampler2D DiffuseSampler;
uniform sampler2D DepthSampler;
uniform sampler2D ItemDepthSampler;
uniform sampler2D TranslucentSampler;
uniform sampler2D EmissiveSampler;
uniform sampler2D ShadowDepthSampler;
uniform sampler2D DataSampler;
uniform sampler2D NormalSampler;

uniform vec2 InSize;

in vec2 texCoord;
flat in mat4 invProjMat;
flat in mat4 shadowProjMat;
flat in vec3 cameraOffset;
flat in vec3 sunDirection;
flat in vec3 lightColor;
flat in int hasData;
flat in int hasVolumetrics;
flat in vec4 zeroLogLuv;

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

vec3 unprojectScreenSpace(vec2 texCoord, float depth) {
    vec4 h = invProjMat * (vec4(texCoord, depth, 1.0) * 2.0 - 1.0);
    return h.xyz / h.w;
}

vec3 getNormal(vec2 texCoord) {
    return texture(NormalSampler, texCoord).rgb * 2.0 - 1.0;
}

bool isShadowed(vec3 position, vec3 normal) {
    vec4 lightSpace = shadowProjMat * vec4(position + cameraOffset, 1.0);

    vec3 proj = lightSpace.xyz * 0.5 + 0.5;
    if (clamp(proj, 0.0, 1.0) == proj) {
        float closestDepth = texture(ShadowDepthSampler, proj.xy).r;
        return proj.z - 2.0 / InSize.x > closestDepth;
    } else {
        return true;
    }
}

void buildOrthonormalBasis(vec3 n, out vec3 b1, out vec3 b2) {
    if (n.z < -0.9999999) {
        b1 = vec3(0.0, -1.0, 0.0);
        b2 = vec3(-1.0, 0.0, 0.0);
    } else {
        float a = 1.0 / (1.0 + n.z);
        float b = -n.x * n.y * a;
        b1 = vec3(1.0 - n.x * n.x * a, b, -n.x);
        b2 = vec3(b, 1.0 - n.y * n.y * a, -n.y);
    }
}

float getShadowing(vec3 position, vec3 normal) {
    vec3 b1, b2;
    buildOrthonormalBasis(normal, b1, b2);

    float sum = 0.0;
    float weightSum = 0.0;

    for (float x = -0.075; x <= 0.075; x += 0.025) {
        for (float y = -0.075; y <= 0.075; y += 0.025) {
            sum += float(isShadowed(position + b1 * (x + random1() * 0.025) + b2 * (y + random1() * 0.025), normal));
            weightSum += 1.0;
        }
    }

    return sum / weightSum;
}

vec3 TMO(vec3 x) {
    return x / (1.0 + x);
}

vec3 InverseTMO(vec3 x) {
    return x / (1.00001 - x);
}

#define PI 3.14159265

float henyeyGreenstein(float cosTheta, float g) {
    return 1.0 / (4.0 * PI) * (1.0 - g * g) / pow(1.0 + g * g - 2.0 * g * cosTheta, 1.5);
}

void main() {
    fragColor = texture(DataSampler, texCoord);

    vec4 color = texture(DiffuseSampler, texCoord);
    float depth = texture(DepthSampler, texCoord).r;

    bool isEmissive = round(texture(EmissiveSampler, texCoord) * 255.0) != round(zeroLogLuv * 255.0);

    float itemDepth = texture(ItemDepthSampler, texCoord).r;
    vec3 itemData = round(texture(DataSampler, texCoord).rgb * 255.0);
    bool isPortal = itemDepth <= depth && (itemData.r == 1.0 || itemData.r == 3.0) && itemData.gb == vec2(0.0);
    bool inControl = gl_FragCoord.x < 4.0 && gl_FragCoord.y < 100.0;

    gl_FragDepth = min(depth, itemDepth);
    fragColor = color;
    
    vec3 position = unprojectScreenSpace(texCoord, depth);
    if (hasData == 0 || depth == 1.0 || isEmissive || dot(position, position) > 64.0 * 64.0) {
        if (!inControl && !isPortal && texture(ItemDepthSampler, texCoord).r < depth) {
            vec4 itemTexture = texture(DataSampler, texCoord);
            fragColor.rgb = fragColor.rgb * (1.0 - itemTexture.a) + itemTexture.rgb;
        }
        return;
    }

    initGlobalPRNG(texCoord, 0);

    vec3 normal = getNormal(texCoord);

    fragColor.rgb = InverseTMO(pow(color.rgb, vec3(2.2)));

    if (!isPortal) {
        float shadowing = 1.0;

        const float threshold = 0.03;
        if (dot(normal, sunDirection) >= threshold &&
            dot(getNormal(texCoord + vec2(2.0, 0.0) / InSize), sunDirection) >= threshold &&
            dot(getNormal(texCoord + vec2(0.0, 2.0) / InSize), sunDirection) >= threshold &&
            dot(getNormal(texCoord - vec2(2.0, 0.0) / InSize), sunDirection) >= threshold &&
            dot(getNormal(texCoord - vec2(0.0, 2.0) / InSize), sunDirection) >= threshold) {
            shadowing = getShadowing(position, normal);
        }

        fragColor.rgb = fragColor.rgb * 0.8 + (1.0 - shadowing) * fragColor.rgb * lightColor * 10.0 * dot(normal, sunDirection);
    }

    if (!inControl && !isPortal && texture(ItemDepthSampler, texCoord).r < depth) {
        vec4 itemTexture = texture(DataSampler, texCoord);
        fragColor.rgb = fragColor.rgb * (1.0 - itemTexture.a) + pow(itemTexture.rgb, vec3(2.2)) * 2.0;
    }

    const int samples = 16;
    const float scattering = 0.015;
    const float density = scattering;

    if (hasVolumetrics > 0) {
        float transmittance = 1.0;
        float volumetric = 0.0;
        float tStep = length(position) / float(samples + 1);
        vec3 direction = normalize(position);
        float phase = henyeyGreenstein(dot(direction, sunDirection), 0.08);
        for (int i = 0; i < samples; i++) {
            float t = (float(i) + random1()) * tStep;

            transmittance *= exp(-density * tStep);
            if (!isShadowed(direction * t, vec3(0.0))) {
                volumetric += transmittance * scattering * tStep * phase;
            }
        }

        fragColor.rgb = fragColor.rgb * transmittance + volumetric * lightColor;
    }

    fragColor.rgb = TMO(pow(fragColor.rgb, vec3(1.0 / 2.2)));
}
