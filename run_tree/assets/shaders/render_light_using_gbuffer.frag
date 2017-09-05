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
    //frag_color = vec4(1, 0, 0, 1);
}
