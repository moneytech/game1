#version 330 core

layout (location = 0) out vec3 g_position;
layout (location = 1) out vec3 g_normal;
layout (location = 2) out vec4 g_albedospec;

in vec3 frag_pos;
in vec4 clip_space;
in vec2 dudv_tex_coords;

uniform sampler2D reflect_texture;
uniform sampler2D refract_texture;
uniform sampler2D dudv_texture;

uniform vec3 camera_position;
uniform float distort_offset;

void main() {
    g_position = frag_pos;
    g_normal = vec3(0, 0, 0);

    vec2 tex_coords = (clip_space.xy / clip_space.w) * 0.5 + 0.5;
    vec2 t2 = tex_coords;
    // t2.y = -t2.y;

    vec2 d1 = (texture(dudv_texture, vec2(dudv_tex_coords.x + distort_offset, dudv_tex_coords.y)).rg * 2.0 - 1.0) * 0.006;
    vec2 d2 = (texture(dudv_texture, vec2(-dudv_tex_coords.x + distort_offset, dudv_tex_coords.y + distort_offset)).rg * 2.0 - 1.0) * 0.006;
    // vec2 d2 = vec2(0, 0);
    vec2 distort = d1 + d2; 

    tex_coords += distort * 0.2;
    t2 += distort * 0.5;

    tex_coords = clamp(tex_coords, 0.001, 0.999);
    t2.x = clamp(t2.x, 0.001, 0.999);
    t2.y = clamp(t2.y, 0.001, 0.999);
    t2.y = -t2.y;

    vec3 view = normalize(camera_position - frag_pos);
    float refract = dot(view, vec3(0, 1, 0));

    g_albedospec.rgb = mix(texture(reflect_texture, t2), texture(refract_texture, tex_coords), refract).rgb;
    g_albedospec.rgb = mix(g_albedospec.rgb, vec3(0.0, 0.3, 0.5), 0.2);
}
