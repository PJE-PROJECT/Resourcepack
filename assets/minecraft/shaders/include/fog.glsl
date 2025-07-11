#version 150

#ifndef _FOG_GLSL
#define _FOG_GLSL

vec4 linear_fog(vec4 inColor, float vertexDistance, float fogStart, float fogEnd, vec4 fogColor) {
    fogEnd *= 1.4;

    if (abs(fogStart + 8.0) < 0.5) {
        fogEnd = 3.0;
        fogColor = vec4(0.156, 0.105, 0.070, 1.0);
    }
    
    fogStart *= 0.05;

    if (vertexDistance <= fogStart) {
        return inColor;
    }

    float fogValue = vertexDistance < fogEnd ? smoothstep(fogStart, fogEnd, vertexDistance) : 1.0;
    return vec4(mix(inColor.rgb, fogColor.rgb, fogValue * fogColor.a), inColor.a);
}

vec4 exponentialFog(vec4 fragColor, float fragDistance, vec4 fogColor, float fogStart, float fogEnd) {
    const float density = 0.013;

    if (fogStart > 1000.0) {
        return fragColor;
    }

    if (abs(fogStart + 8.0) < 0.5) {
        return linear_fog(fragColor, fragDistance, fogStart, fogEnd, fogColor);
    }

    float transmittance = exp(-density * fragDistance * fogColor.a);
    return vec4(mix(fogColor.rgb, fragColor.rgb, transmittance), fragColor.a);
}

float linear_fog_fade(float vertexDistance, float fogStart, float fogEnd) {
    if (vertexDistance <= fogStart) {
        return 1.0;
    } else if (vertexDistance >= fogEnd) {
        return 0.0;
    }

    return smoothstep(fogEnd, fogStart, vertexDistance);
}

float fog_distance_old(mat4 modelViewMat, vec3 pos, int shape) {
    if (shape == 0) {
        return length((modelViewMat * vec4(pos, 1.0)).xyz);
    } else {
        float distXZ = length((modelViewMat * vec4(pos.x, 0.0, pos.z, 1.0)).xyz);
        float distY = length((modelViewMat * vec4(0.0, pos.y, 0.0, 1.0)).xyz);
        return max(distXZ, distY);
    }
}

float fog_distance(vec3 pos, int shape) {
    return length(pos);
}

//backwards compatibility for pre 1.18.2 fog
float cylindrical_distance(mat4 modelViewMat, vec3 pos) {
    float distXZ = length((modelViewMat * vec4(pos.x, 0.0, pos.z, 1.0)).xyz);
    float distY = length((modelViewMat * vec4(0.0, pos.y, 0.0, 1.0)).xyz);
    return max(distXZ, distY);
}

#endif