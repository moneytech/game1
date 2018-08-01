#version 330 core

layout (location = 0) out int out_quad_pos;

flat in int out_position_quad;

void main() {
    out_quad_pos = out_position_quad;
}
