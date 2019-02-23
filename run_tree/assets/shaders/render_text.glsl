#if FRAGMENT_SHADER
out vec4 frag_color;

in vec2 tex_coords;
in vec4 text_color;

uniform sampler2D in_texture;

void main() {
    float alpha = texture(in_texture, tex_coords).r;
    frag_color = vec4(text_color.rgb, text_color.a * alpha);
}
#endif // FRAGMENT_SHADER

#if VERTEX_SHADER

layout (location = 0) in vec2 in_pos;
layout (location = 1) in vec2 in_tex_coords;
layout (location = 2) in vec4 in_color;

out vec2 tex_coords;
out vec4 text_color;

uniform mat4 projection;

void main() {
    text_color = in_color;
    tex_coords = in_tex_coords;
    gl_Position = projection * vec4(in_pos, 0, 1.0);
}

#endif // VERTEX_SHADER