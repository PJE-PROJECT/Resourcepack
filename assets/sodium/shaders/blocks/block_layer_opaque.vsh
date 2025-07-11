#version 330 core

#import <sodium:include/fog.glsl>
#import <sodium:include/chunk_vertex.glsl>
#import <sodium:include/chunk_matrices.glsl>
#import <sodium:include/chunk_material.glsl>
#import <sodium:include/portal_projection.glsl>

out vec4 v_Color;
out vec2 v_TexCoord;

out vec3 texBound0;
out vec3 texBound1;
out vec3 texBound2;

out float v_MaterialMipBias;
#ifdef USE_FRAGMENT_DISCARD
out float v_MaterialAlphaCutoff;
#endif

#ifdef USE_FOG
out float v_FragDistance;
#endif

uniform int u_FogShape;
uniform vec3 u_RegionOffset;

uniform sampler2D u_LightTex; // The light map texture sampler
uniform sampler2D u_BlockTex; // The block texture


#define NCOLOR normalize(vec3(1.0, 1.0, 1.0))
#define DCOLOR normalize(vec3(1.0, 1.0, 1.0))

float getSun(sampler2D lightMap) {
    vec3 sunlight = normalize(texture(lightMap, vec2(1.0, 1.0)).rgb);
    return clamp(pow(length(sunlight - NCOLOR) / length(DCOLOR - NCOLOR), 4.0), 0.0, 1.0);
}

vec4 _sample_lightmap(sampler2D lightMap, ivec2 uv) {
    float sun = 1.0 - uv.y / 256.0 * getSun(lightMap);

    vec4 original = texture(lightMap, clamp(uv / 256.0, vec2(0.8 / 16.0), vec2(15.5 / 16.0))); // �������� ������������ ���� ��������
    float d = (original.r + original.b + original.g)/3.0; // ��������� �������
    vec4 lightponmap = vec4(d, d, d, original.a);
    return lightponmap; // x is torch, y is sun
}

uvec3 _get_relative_chunk_coord(uint pos) {
    // Packing scheme is defined by LocalSectionIndex
    return uvec3(pos) >> uvec3(5u, 0u, 2u) & uvec3(7u, 3u, 7u);
}

vec3 _get_draw_translation(uint pos) {
    return _get_relative_chunk_coord(pos) * vec3(16.0);
}

void main() {
    _vert_init();

    texBound0 = vec3(0.0);
    texBound1 = vec3(0.0);
    texBound2 = vec3(0.0);

    // Transform the chunk-local vertex position into world model space
    vec3 translation = u_RegionOffset + _get_draw_translation(_draw_id);
    vec3 position = _vert_position + translation;

#ifdef USE_FOG
    v_FragDistance = getFragDistance(u_FogShape, position);
#endif

    // Transform the vertex position into model-view-projection space
    gl_Position = getProjMat() * u_ModelViewMatrix * vec4(position, 1.0);

    // Add the light color to the vertex color, and pass the texture coordinates to the fragment shader
    v_Color = _vert_color * _sample_lightmap(u_LightTex, _vert_tex_light_coord);
    v_TexCoord = _vert_tex_diffuse_coord;

    v_MaterialMipBias = _material_mip_bias(_material_params);
#ifdef USE_FRAGMENT_DISCARD
    v_MaterialAlphaCutoff = _material_alpha_cutoff(_material_params);
#endif

    const vec2[4] corners = vec2[4](vec2(0.0), vec2(0.0, 1.0), vec2(1.0), vec2(1.0, 0.0));
    vec2 corner = corners[(gl_VertexID) % 4];
    vec2 texSize = textureSize(u_BlockTex, 0);
    _vert_tex_diffuse_coord -= corner / texSize;

    if (round(texture(u_BlockTex, _vert_tex_diffuse_coord) * 255.0) == vec4(52.0, 52.0, 52.0, 250.0)) {
        if (position.y > 0.0) {
            corner = corner.yx;
        }
        v_TexCoord += (mod(_vert_position.xz - corner, 4.0) * 128.0 - corner * (512.0 - 128.0)) / texSize;
        v_Color = vec4(0.4, 0.4, 0.4, 1.0);
    }

    if ((gl_VertexID % 4) == 0) {
        texBound0 = vec3(v_TexCoord, 1.0);
    } else if ((gl_VertexID % 4) == 2) {
        texBound2 = vec3(v_TexCoord, 1.0);
    } else {
        texBound1 = vec3(v_TexCoord, 1.0);
    }
}
