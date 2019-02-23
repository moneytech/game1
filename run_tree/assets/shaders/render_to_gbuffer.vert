#version 330 core

layout (location = 0) in vec3 in_pos;
layout (location = 1) in vec3 in_normal;
layout (location = 2) in vec2 in_tex_coords;
layout (location = 3) in vec3 in_tangent_normal;
layout (location = 4) in vec3 in_color;

out vec2 tex_coords;
out vec3 frag_pos;
// out vec4 view_space_frag_pos;
out vec3 normal;
out vec3 vertex_color;
out mat3 TBN;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

uniform bool use_normal_map;

uniform vec4 clip_plane;

void main() {
    vertex_color = in_color;

    vec4 world_pos = model * vec4(in_pos, 1.0);
    frag_pos = world_pos.xyz;
    tex_coords = in_tex_coords;

    gl_ClipDistance[0] = dot(world_pos, clip_plane);

    mat3 normal_matrix = transpose(inverse(mat3(model)));

	normal = normal_matrix * in_normal;
    if (use_normal_map) {
    	vec3 T = normalize(vec3(model * vec4(in_tangent_normal, 0.0)));
        vec3 N = normalize(vec3(model * vec4(in_normal, 0.0)));
    	vec3 B = cross(T, N);
    	TBN = inverse(transpose(mat3(T, B, N)));
	}

    gl_Position = projection * view * model * vec4(in_pos, 1);
    // view_space_frag_pos = view * model * vec4(in_pos, 1);
}
