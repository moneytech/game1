#version 330 core

layout (location = 0) out vec2 out_quad_pos;

in vec2 out_position_quad;

void main() {
    out_quad_pos = out_position_quad;
}
