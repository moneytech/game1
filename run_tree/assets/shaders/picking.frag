#version 330 core

// layout (location = 0) flat out uint picking_index;
layout (location = 0) out uint picking_index;

flat in uint out_index;

void main() {
    picking_index = out_index;
}
