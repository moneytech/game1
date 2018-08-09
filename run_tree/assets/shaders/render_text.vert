#version 330 core

layout (location = 0) in vec2 in_pos;
layout (location = 1) in vec2 in_tex_coords;
layout (location = 2) in vec4 in_color;

out vec2 tex_coords;
out vec4 text_color;

uniform mat4 projection;

void main() {
    text_color = in_color;
    tex_coords = in_tex_coords;
    gl_Position = projection * vec4(in_pos, 0, 1.0);
}
