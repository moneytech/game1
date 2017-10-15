#version 330 core

out vec4 frag_color;

in vec2 tex_coords;
in vec3 text_color;

uniform sampler2D in_texture;

void main() {
    float alpha = texture(in_texture, tex_coords).r;
    frag_color = vec4(text_color, alpha);
}
