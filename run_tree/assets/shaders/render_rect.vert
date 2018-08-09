#version 330 core

layout (location = 0) in vec2 in_pos;
layout (location = 1) in vec4 in_color;

out vec4 rect_color;

uniform mat4 projection;

void main() {
    rect_color = in_color;
    gl_Position = projection * vec4(in_pos, 0, 1.0);
}
