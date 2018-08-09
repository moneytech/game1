#version 330 core

out vec4 frag_color;

in vec4 rect_color;

void main() {
    frag_color = rect_color;
}
