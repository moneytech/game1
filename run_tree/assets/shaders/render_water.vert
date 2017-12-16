#version 330 core

layout (location = 0) in vec2 in_pos;
layout (location = 1) in vec2 in_tex_coords;
out vec3 frag_pos;
out vec4 clip_space;
out vec2 dudv_tex_coords;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

void main() {
    vec4 world_pos = model * vec4(in_pos.x, -1.0, in_pos.y, 1.0);
    frag_pos = world_pos.xyz;

    clip_space = projection * view * model * vec4(in_pos.x, 0.05, in_pos.y, 1);
    gl_Position = clip_space;
    dudv_tex_coords = in_tex_coords;
}
