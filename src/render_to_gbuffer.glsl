
GLSL_SOURCE(render_to_gbuffer_vert,

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

); // GLSL_SOURCE

GLSL_SOURCE(render_to_gbuffer_frag,

layout (location = 0) out vec3 g_position;
layout (location = 1) out vec3 g_normal;
layout (location = 2) out vec4 g_albedospec;

in vec2 tex_coords;
in vec3 frag_pos;
in vec3 normal;

uniform sampler2D diffuse_texture;
uniform sampler2D specular_texture;

void main() {
    g_position = frag_pos;
    g_normal = normalize(normal);
    //g_albedospec.rgb = texture(diffuse_texture, tex_coords).rgb;
    //g_albedospec.a = texture(specular_texture, tex_coords).r;
    g_albedospec = vec4(1, 0, 0, 1);
}

); // GLSL_SOURCE