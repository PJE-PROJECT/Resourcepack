#version 330

uniform sampler2D DiffuseSampler;
uniform sampler2D DiffuseDepthSampler;
uniform sampler2D ItemSampler;
uniform sampler2D SavedSampler;
uniform sampler2D SavedDepthSampler;

uniform vec2 OutSize;
uniform float RedCol;

in vec2 texCoord;
flat in mat4 IProjViewMat;
flat in mat3 localMat;
flat in vec3 portalPos;
flat in mat4 PortalProjMat;

out vec4 fragColor;

float decodeColor(vec4 color) {
    uvec4 bits = uvec4(round(color * 255.0)) << uvec4(24, 16, 8, 0);
    return uintBitsToFloat(bits.r | bits.g | bits.b | bits.a);
}

float linearizeDepth(float depth) {
    float near = 0.8; 
    float far  = 1000.0;
    float z = depth * 2.0 - 1.0;
    return (near * far) / (far + near - z * (far - near));    
}

vec3 screenToPos(vec3 screenPos) {
    vec4 h = IProjViewMat * vec4(screenPos * 2.0 - 1.0, 1.0);
    return h.xyz / h.w;
}

vec3 projectPos(vec3 pos) {
    vec4 h = PortalProjMat * vec4(pos, 1.0);
    return h.xyz / h.w * 0.5 + 0.5;
}

vec3 binaryRefinement(vec3 start, vec3 dir, float t0, float t1) {
    vec3 projected, p;
    float t;

    for (int i = 0; i < 5; ++i) {
        t = (t0 + t1) * 0.5;
        p = start + t * dir;
        projected = projectPos(p);
        float d = decodeColor(texture(SavedDepthSampler, projected.xy));
        if (d < projected.z) {
            t1 = t;
        } else {
            t0 = t;
        }
    }

    float d1 = linearizeDepth(decodeColor(texture(SavedDepthSampler, projected.xy)));
    float d2 = linearizeDepth(projected.z);

    p = start + max(0.5 * t, t - min(1.0, abs(d1 - d2))) * dir;
    projected = projectPos(p);

    return texture(SavedSampler, projected.xy).rgb;
}

vec3 raytrace(vec3 start, vec3 dir) {
    float t = 0.1;
    float t0 = 0.1;
    float tStep = 0.1;

    for (int i = 0; i < 30; ++i) {
        t += tStep / -dir.z;
        tStep = 0.1 + 0.035 * t * t * dir.z * dir.z;

        vec3 p = start + t * dir;
        vec3 projected = projectPos(p);

        float d = decodeColor(texture(SavedDepthSampler, projected.xy));
        float skipped = abs(linearizeDepth(projected.z) - linearizeDepth(d));
        if (d < projected.z && !(skipped > tStep * 1.5)) {
            return binaryRefinement(start, dir, t0, t);
        }

        t0 = t;
    }

    return vec3(178.0, 209.0, 255.0) / 255.0;
}


vec3 drawPortal(vec3 nearPos, vec3 rayDir, vec3 pos) {
    nearPos = (nearPos - pos) * localMat;
    rayDir = rayDir * localMat;

    float t = -nearPos.z / rayDir.z;

    vec3 planePos = nearPos + t * rayDir;
    planePos.xy -= vec2(-0.125, 0.5);

    return raytrace(planePos, rayDir);
}

void main() {
    vec4 itemColor = texture(ItemSampler, texCoord);
    vec3 color = texture(DiffuseSampler, texCoord).rgb;

    if (RedCol == round(itemColor.r * 255.0) && itemColor.gb == vec2(0.0)) {
        float depth = decodeColor(texture(DiffuseDepthSampler, texCoord));
        vec3 fragPos = screenToPos(vec3(texCoord, depth));
        vec3 nearPos = screenToPos(vec3(texCoord, 0.0));

        vec3 rayDir = normalize(fragPos - nearPos);
        color = drawPortal(nearPos, rayDir, portalPos);
    }

    fragColor = vec4(color, 1.0);

}
