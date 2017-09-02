
GLSL_SOURCE(render_light_using_gbuffer_vert,

layout (location = 0) in vec3 in_pos;
layout (location = 1) in vec2 in_tex_coords;

out vec2 tex_coords;

void main() {
    tex_coords = in_tex_coords;
    gl_Position = vec4(in_pos, 1.0);
}

); // GLSL_SOURCE

GLSL_SOURCE(render_point_light_using_gbuffer_frag,

out vec4 frag_color;

in vec2 tex_coords;

uniform sampler2D g_position;
uniform sampler2D g_normal;
uniform sampler2D g_albedospec;


// match Light in renderer.h
struct Light {
    vec3 position;
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;

    float linear;
    float quadratic;
};

uniform Light light;
uniform vec3 viewer_pos;

void main() {
    vec3 frag_pos = texture(g_position, tex_coords).rgb;
    vec3 normal = texture(g_normal, tex_coords).rgb;
    vec3 diffuse = texture(g_albedospec, tex_coords).rgb;
    float specular = texture(g_albedospec, tex_coords).a;

    vec3 lighting = diffuse * 0.1;
    vec3 view_dir = normalize(viewer_pos - frag_pos);



    // @TODO
    frag_color = vec3(1, 0, 0);
}

); // GLSL_SOURCE