#version 330 core

out vec4 frag_color;

uniform sampler2D g_position;
uniform sampler2D g_normal;
uniform sampler2D g_albedospec;

uniform vec4 viewport;

vec2 get_ndc_position() {
    return gl_FragCoord.xy / viewport.zw;
}

// match Light in renderer.jai
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


vec3 schlick_fresnel(vec3 F0, float v_dot_h) {
    return F0 + (1.0 - F0) * pow(2, ((-5.55473 * v_dot_h)-6.98316) * v_dot_h);
}


#define PI 3.14159265358979323846264338327950288
float distrubtion_ggx(float n_dot_h, float a) {
    float a2 = a*a;
    float factor = ((n_dot_h*n_dot_h)*(a2 - 1) + 1);
    float denom = PI * factor*factor;
    return a2 / denom;
}

float geometric_ggx_sub(float n_dot_v, float k) {
    float denom = n_dot_v * (1 - k) + k;
    return n_dot_v / denom;
}

float geometric_ggx(float n_dot_l, float n_dot_v, float Roughness) {
    float r = Roughness + 1;
    float k = (r * r) / 8;
    return geometric_ggx_sub(n_dot_l, k) * geometric_ggx_sub(n_dot_v, k);
}

vec3 microfacet_brdf(vec3 N, vec3 L, vec3 H, vec3 V, float Roughness, vec3 F0) {
    float n_dot_v = max(0.0, dot(N, V));
    float n_dot_l = max(0.0, dot(N, L));
    float v_dot_h = max(0.0, dot(V, H));
    float n_dot_h = max(0.0, dot(N, H));

    vec3 numer = distrubtion_ggx(n_dot_h, Roughness*Roughness) *
                    schlick_fresnel(F0, v_dot_h) *
                    geometric_ggx(n_dot_l, n_dot_v, Roughness);
    float denom = 4 * n_dot_l * n_dot_v;
    return numer / denom;
}

void main() {
    vec2 tex_coords = get_ndc_position();

    // float specular_exp = texture(g_albedospec, tex_coords).a;
    vec3 frag_pos = texture(g_position, tex_coords).rgb;
    vec3 normal = texture(g_normal, tex_coords).rgb;
    vec3 in_diffuse = texture(g_albedospec, tex_coords).rgb;
    if (length(normal) < 0.5) {
        frag_color = vec4(in_diffuse, 1);
        return;
    }

    normal = normalize(normal);

    vec3 F0 = vec3(0.04);
    float metallic = 0;
    F0 = mix(F0, in_diffuse, vec3(metallic));

    vec3 ambient = vec3(0.03) * in_diffuse;
    
    // @Temporary
    vec3 light_pos = vec3(-20, 20, 10);

    vec3 light_dir = normalize(light_pos-frag_pos);
    vec3 view_dir = normalize(camera_position-frag_pos);
    vec3 halfway_dir = normalize((light_dir + view_dir));
    vec3 ks = microfacet_brdf(normal, light_dir, halfway_dir, view_dir, 0.5, F0);
    vec3 kd = 1.0 - ks;

    vec3 light_specular = vec3(1.0, 1.0, 1.0);
    vec3 specular = light_specular * ks;

    vec3 diff = (in_diffuse / PI) * kd;
    frag_color = vec4(diff + specular + ambient, 1.0);
}
