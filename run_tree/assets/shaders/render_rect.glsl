
#if FRAGMENT_SHADER
out vec4 frag_color;

in vec4 rect_color;

void main() {
    frag_color = rect_color;
}
#endif // FRAGMENT_SHADER

#if VERTEX_SHADER

layout (location = 0) in vec2 in_pos;
layout (location = 1) in vec4 in_color;

out vec4 rect_color;

uniform mat4 projection;
uniform mat4 model;
uniform mat4 view;

void main() {
    rect_color = in_color;
    gl_Position = projection * view * model * vec4(in_pos, 0, 1.0);
}

#endif // VERTEX_SHADER