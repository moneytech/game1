#version 330 core

layout (location = 0) in vec3 in_pos;
layout (location = 2) in vec2 in_tex_coords;

out vec2 tex_coords;

uniform mat4 projection;

void main() {
    tex_coords = in_tex_coords;
    gl_Position = projection * vec4(in_pos, 1.0);
}
