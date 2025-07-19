const int FOG_SHAPE_SPHERICAL = 0;
const int FOG_SHAPE_CYLINDRICAL = 1;

vec4 _linearFog(vec4 fragColor, float fragDistance, vec4 fogColor, float fogStart, float fogEnd) {
#ifdef USE_FOG
    fogEnd *= 1.15;

    if (abs(fogStart + 8.0) < 0.5) {
        fogEnd = 3.0;
        fogColor = vec4(0.156, 0.105, 0.070, 1.0);
    }
    
    fogStart *= 0.05;
    if (fragDistance <= fogStart) {
        return fragColor;
    }
    
    float factor = fragDistance < fogEnd ? smoothstep(fogStart, fogEnd, fragDistance) : 1.0; // alpha value of fog is used as a weight
    vec3 blended = mix(fragColor.rgb, fogColor.rgb, factor * fogColor.a);

    return vec4(blended, fragColor.a); // alpha value of fragment cannot be modified
#else
    return fragColor;
#endif
}

vec4 exponentialFog(vec4 fragColor, float fragDistance, vec4 fogColor, float fogStart, float fogEnd) {
#ifdef USE_FOG
    const float density = 0.013;

    if (abs(fogStart + 8.0) < 0.5) {
        return _linearFog(fragColor, fragDistance, fogColor, fogStart, fogEnd);
    }

    float transmittance = exp(-density * fragDistance * fogColor.a);
    return vec4(mix(fogColor.rgb, fragColor.rgb, transmittance), fragColor.a);
#else
    return fragColor;
#endif
}

float getFragDistance(int fogShape, vec3 position) {
    return length(position);
}