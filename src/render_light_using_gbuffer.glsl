
GLSL_SOURCE(render_light_using_gbuffer_vert,

layout (location = 0) in vec3 in_pos;
layout (location = 2) in vec2 in_tex_coords;

out vec2 tex_coords;

uniform mat4 projection;

void main() {
    tex_coords = in_tex_coords;
    gl_Position = projection * vec4(in_pos, 1.0);
}

); // GLSL_SOURCE

GLSL_SOURCE(render_light_using_gbuffer_frag,

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
/*
    float specular = texture(g_albedospec, tex_coords).a;

    vec3 lighting = diffuse * 0.1;
    vec3 view_dir = normalize(viewer_pos - frag_pos);


*/
    // @Temporary
    vec3 light_pos = vec3(0, 0, 2);
    vec3 frag_pos = texture(g_position, tex_coords).rgb;
    vec3 normal = texture(g_normal, tex_coords).rgb;
    vec3 diffuse = texture(g_albedospec, tex_coords).rgb;
    vec3 light_dir = normalize(light_pos-frag_pos);  
    // @TODO
    float nl = max(dot(normal, light_dir), 0.0);
    frag_color = vec4(diffuse, 1) * nl;
}

); // GLSL_SOURCE

GLSL_SOURCE(render_plain_texture_frag,

out vec4 frag_color;

in vec2 tex_coords;

uniform sampler2D in_texture;

void main() {

    frag_color = texture(in_texture, tex_coords);
}

); // GLSL_SOURCE