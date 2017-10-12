#version 330 core

// layout (location = 0) flat out uint picking_index;
layout (location = 0) out uint picking_index;
layout (location = 1) out vec2 out_quad_pos;


flat in uint out_index;
in vec2 out_position_quad;

void main() {
    out_quad_pos = out_position_quad;
    picking_index = out_index;
}
