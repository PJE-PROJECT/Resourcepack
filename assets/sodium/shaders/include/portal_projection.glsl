uniform float u_FogStart;
uniform float u_FogEnd;
uniform vec4 u_FogColor;

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
    return u_FogEnd > 4.0 && u_FogEnd < 32.0 && u_FogColor.rgb == vec3(0.0) && u_ProjectionMatrix[2][3] != 0.0 && u_FogStart < 1000000.0;
}

bool isPortalProj() {
    return (abs(u_FogEnd - u_FogStart * 10.0) < 0.5 || (abs(u_FogEnd - 96.0) < 0.5 && abs(u_FogStart - 86.4) > 0.5)) && abs(u_ProjectionMatrix[3][3]) < 0.5;
}

mat4 getProjMat() {
    if (isPortalProj()) {
        return getPortalProjMat();
    } else if (isShadowProj()) {
        return getShadowProjMat();
    }
    return u_ProjectionMatrix;
}
