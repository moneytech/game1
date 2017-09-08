#version 330 core

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

    float specular_exp = texture(g_albedospec, tex_coords).a;
    vec3 frag_pos = texture(g_position, tex_coords).rgb;
    vec3 normal = normalize(texture(g_normal, tex_coords).rgb);
    vec3 in_diffuse = texture(g_albedospec, tex_coords).rgb;
    
    // @Temporary
    vec3 light_pos = vec3(0, 4, 10);

    vec3 light_dir = normalize(light_pos-frag_pos);
    vec3 view_dir = normalize(viewer_pos-frag_pos);
    vec3 halfway_dir = normalize(light_dir + view_dir);
    float spec = pow(max(dot(normal, halfway_dir), 0.0), 16.0);

    vec3 light_specular = vec3(0.5, 0.5, 0.5);
    vec3 specular = light_specular * spec * specular_exp;

    float nl = max(dot(normal, light_dir), 0.0);
    vec3 diffuse = in_diffuse * nl;
    frag_color = vec4(diffuse + specular, 1.0);
}
