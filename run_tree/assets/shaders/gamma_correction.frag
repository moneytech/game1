#version 330 core

out vec4 frag_color;

in vec2 tex_coords;

uniform sampler2D in_texture;

void main() {
    vec4 orig_color = texture(in_texture, tex_coords);
    frag_color.rgb = pow(orig_color.rgb, vec3(1/2.2));
}
