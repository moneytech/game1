#version 330 core

layout (location = 0) out vec3 g_position;
layout (location = 1) out vec3 g_normal;
layout (location = 2) out vec4 g_albedospec;
layout (location = 3) out float g_roughness;
layout (location = 4) out float g_metallic;

in vec2 tex_coords;
in vec3 frag_pos;
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
uniform bool use_specular_map;

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

    g_roughness = material.roughness;
    g_metallic  = material.metallic;
}