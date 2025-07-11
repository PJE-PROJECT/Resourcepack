
uniform float FogStart;
uniform float FogEnd;
uniform vec4 FogColor;

uniform mat4 ProjMat;

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

mat4 orthographicProjectionMatrix(float left, float right, float bottom, float top, float near, float far) {
    return mat4(
        2.0 / (right - left), 0.0, 0.0, 0.0,
        0.0, 2.0 / (top - bottom), 0.0, 0.0,
        0.0, 0.0, -2.0 / (far - near), 0.0,
        -(right + left) / (right - left), -(top + bottom) / (top - bottom), -(far + near) / (far - near), 1.0
    );
}

mat4 getShadowProjMat() {
    return orthographicProjectionMatrix(-24.0, 24.0, -24.0, 24.0, 0.0, 256.0);
}

bool isShadowProj() {
    return FogEnd > 4.0 && FogEnd < 32.0 && FogColor.rgb == vec3(0.0) && ProjMat[2][3] != 0.0 && FogStart < 1000000.0;
}

bool isPortalProj() {
    return (abs(FogEnd - FogStart * 10.0) < 0.5 || (abs(FogEnd - 96.0) < 0.5 && abs(FogStart - 86.4) > 0.5)) && abs(ProjMat[3][3]) < 0.5;
}

mat4 getProjMat() {
    if (isPortalProj()) {
        return getPortalProjMat();
    } else if (isShadowProj()) {
        return getShadowProjMat();
    }
    return ProjMat;
}
