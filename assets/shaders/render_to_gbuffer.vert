#version 330 core

layout (location = 0) in vec3 in_pos;
layout (location = 1) in vec3 in_normal;
layout (location = 2) in vec2 in_tex_coords;

out vec2 tex_coords;
out vec3 frag_pos;
out vec3 normal;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

void main() {
    vec4 world_pos = model * vec4(in_pos, 1.0);
    frag_pos = world_pos.xyz;
    tex_coords = in_tex_coords;

    mat3 normal_matrix = transpose(inverse(mat3(model)));
    normal = normal_matrix * in_normal;

    gl_Position = projection * view * model * vec4(in_pos, 1);
}
