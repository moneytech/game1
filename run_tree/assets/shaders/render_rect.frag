#version 330 core

out vec4 frag_color;

in vec3 rect_color;

uniform float alpha;

void main() {
    frag_color = vec4(rect_color, alpha);
}
