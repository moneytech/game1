#version 330 core

layout (location = 0) in vec3 in_pos;
layout (location = 1) in uint in_index;

flat out uint out_index;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

void main() {
    out_index = in_index;
    gl_Position = projection * view * model * vec4(in_pos, 1);
}
