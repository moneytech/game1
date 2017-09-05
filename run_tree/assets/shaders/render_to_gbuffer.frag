#version 330 core

layout (location = 0) out vec3 g_position;
layout (location = 1) out vec3 g_normal;
layout (location = 2) out vec4 g_albedospec;

in vec2 tex_coords;
in vec3 frag_pos;
in vec3 normal;

uniform sampler2D diffuse_texture;
uniform sampler2D specular_texture;

struct Material {
    vec3 diffuse;
    float specular_exp;
};

uniform Material material;
uniform bool use_diffuse_map;
uniform bool use_normal_map;

void main() {
    g_position = frag_pos;
    g_normal = normalize(normal);


    if (use_diffuse_map) {
        // i think this is right...
        g_albedospec.rgb = material.diffuse.rgb * texture(diffuse_texture, tex_coords).rgb;
        g_albedospec.a = material.specular_exp; // not sure what to do here, especially if we dont have a spec map
    } else {
    	g_albedospec.rgb = material.diffuse.rgb;
        g_albedospec.a = 1;
    }
}