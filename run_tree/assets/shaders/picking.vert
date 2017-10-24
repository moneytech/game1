#version 330 core

layout (location = 0) in vec3 in_pos;
layout (location = 1) in vec2 in_pos_in_quad; // the position in the height as if the heightmap were completely flat

out vec2      out_position_quad;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

void main() {
    out_position_quad = in_pos_in_quad;
    gl_Position = projection * view * model * vec4(in_pos, 1);
}
