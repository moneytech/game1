#include "common.glh"

#if FRAGMENT_SHADER
layout (location = 0) out vec3 g_position;
layout (location = 1) out vec3 g_normal;
layout (location = 2) out vec4 g_albedospec;
layout (location = 3) out vec2 g_roughness;

in vec2 tex_coords;
in vec3 frag_pos;
in vec4 view_space_frag_pos;
in vec3 normal;
in vec3 vertex_color;
in mat3 TBN;

uniform sampler2D diffuse_map;
uniform sampler2D normal_map;

struct Material {
    vec3 diffuse;
    float roughness;
    float metallic;
};

uniform Material material;
uniform bool use_diffuse_map;
uniform bool use_normal_map;

void main() {
    g_position = frag_pos;

    if (use_normal_map) {
        vec3 out_normal = texture(normal_map, tex_coords).rgb;
        //vec3 out_normal = vec3(0, 1, 0);
        out_normal = normalize(out_normal * 2.0 - 1.0);
        out_normal = normalize(TBN * out_normal);
        g_normal = out_normal;
    } else {
        if (length(normal) > 0) g_normal = normalize(normal);
        else g_normal = vec3(0, 0, 0);
    }

    if (use_diffuse_map) {
        // i think this is right...
        g_albedospec.rgb = material.diffuse.rgb * texture(diffuse_map, tex_coords).rgb * vertex_color;
    } else {
    	g_albedospec.rgb = material.diffuse.rgb * vertex_color;
    }

    g_albedospec.a = 1; // @Cleanup really shouldnt need to set this at all

    g_roughness.r = material.roughness;
    g_roughness.g = material.metallic;

    // gl_FragDepth = length(view_space_frag_pos.xyz) / 100.0;
}
#endif // FRAGMENT_SHADER

#if VERTEX_SHADER

layout (location = 0) in vec3 in_pos;
layout (location = 1) in vec3 in_normal;
layout (location = 2) in vec2 in_tex_coords;
layout (location = 3) in vec3 in_tangent_normal;
layout (location = 4) in vec3 in_color;

out vec2 tex_coords;
out vec3 frag_pos;
// out vec4 view_space_frag_pos;
out vec3 normal;
out vec3 vertex_color;
out mat3 TBN;

uniform bool use_normal_map;

uniform vec4 clip_plane;

void main() {
    vertex_color = in_color;

    vec4 world_pos = model * vec4(in_pos, 1.0);
    frag_pos = world_pos.xyz;
    tex_coords = in_tex_coords;

    gl_ClipDistance[0] = dot(world_pos, clip_plane);

    mat3 normal_matrix = transpose(inverse(mat3(model)));

    normal = normal_matrix * in_normal;
    if (use_normal_map) {
        vec3 T = normalize(vec3(model * vec4(in_tangent_normal, 0.0)));
        vec3 N = normalize(vec3(model * vec4(in_normal, 0.0)));
        vec3 B = cross(T, N);
        TBN = inverse(transpose(mat3(T, B, N)));
    }

    gl_Position = projection * view * model * vec4(in_pos, 1);
    // view_space_frag_pos = view * model * vec4(in_pos, 1);
}

#endif // VERTEX_SHADER