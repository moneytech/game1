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
uniform vec3 camera_position;


vec3 schlick(float F0, vec3 l, vec3 h) {
    return vec3(F0, F0, F0) + (1 - F0) * pow(cos(max(dot(l, h), 0.0)), 5.0);
}

void main() {

    float specular_exp = texture(g_albedospec, tex_coords).a;
    vec3 frag_pos = texture(g_position, tex_coords).rgb;
    vec3 normal = normalize(texture(g_normal, tex_coords).rgb);
    vec3 in_diffuse = texture(g_albedospec, tex_coords).rgb;
    if (length(normal) < 0.5) {
        frag_color = vec4(in_diffuse, 1);
        return;
    }
    
    // @Temporary
    vec3 light_pos = vec3(64, 1000, -64);

    vec3 light_dir = normalize(light_pos-frag_pos);
    vec3 view_dir = normalize(camera_position-frag_pos);
    vec3 halfway_dir = normalize(light_dir + view_dir);
    float spec = pow(max(dot(light_dir, normal), 0.0), 96.0);

    vec3 light_specular = vec3(0.0, 0.0, 0.0);
    vec3 specular = light_specular * spec * specular_exp;

    float nl = max(dot(normal, light_dir), 0.0);
    vec3 diff = in_diffuse * nl;
    frag_color = vec4(diff, 1.0);
}
