#version 330 core

out vec4 frag_color;

uniform sampler2D g_position;
uniform sampler2D g_normal;
uniform sampler2D g_albedospec; // base color
uniform sampler2D g_roughness;
uniform sampler2D g_metallic;

uniform vec4 viewport;

vec2 get_ndc_position() {
    return gl_FragCoord.xy / viewport.zw;
}

// match Light in renderer.jai
struct Light {
    int is_directional;
    vec3 position; // if this is a directional light, position is the direction the light is heading
    vec3 radiance_color;
    float radius;

    // int use_shadow_cubemap;
    // samplerCube shadow_cube_map;

    // @TODO we probably want information on things like spherical lights and area lights
};

uniform Light light;
uniform vec3 camera_position;


vec3 schlick_fresnel(vec3 F0, float v_dot_h) {
    return F0 + (1.0 - F0) * pow(2, ((-5.55473 * v_dot_h)-6.98316) * v_dot_h);
}


#define PI 3.14159265358979323846264338327950288
float distrubtion_ggx(float n_dot_h, float a) {
    float a2 = a*a;
    float factor = (n_dot_h*n_dot_h)*(a2 - 1) + 1;
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
    return numer / max(denom, 0.001);
}

float saturate(float value) {
    return clamp(value, 0.0, 1.0);
}

void main() {
    vec2 tex_coords = get_ndc_position();

    // float specular_exp = texture(g_albedospec, tex_coords).a;
    vec3 frag_pos = texture(g_position, tex_coords).rgb;
    vec3 normal = texture(g_normal, tex_coords).rgb;
    vec3 in_diffuse = texture(g_albedospec, tex_coords).rgb;
    float Roughness = texture(g_roughness, tex_coords).r;
    float Metallic = texture(g_metallic, tex_coords).r;

    if (length(normal) < 0.5) {
        frag_color = vec4(in_diffuse, 1);
        return;
    }

    // if (light.use_shadow_cubemap != 0) {
    //     float dist = texture(light.shadow_cube_map, (frag_pos-light.position)).r * 100.0;
    //     if ((dist + 0.10) < (length(frag_pos-light.position))) {
    //         frag_color = vec4(0);
    //         return;
    //     }
    // }

    vec3 N = normalize(normal);

    vec3 F0 = vec3(0.04);
    F0 = mix(F0, in_diffuse, vec3(Metallic));

    // ambient light will be set by ambient shader
    // vec3 ambient = vec3(0.01) * in_diffuse;

    vec3 L = vec3(0);
    if (light.is_directional != 0) {
        L = normalize(-light.position);
    } else {
        L = normalize(light.position-frag_pos);
    }

    vec3 V = normalize(camera_position-frag_pos);
    vec3 H = normalize((L + V));
    vec3 ks = microfacet_brdf(N, L, H, V, Roughness, F0);
    vec3 kd = vec3(1.0) - ks;

    kd *= 1.0 - Metallic;

    vec3 radiance = light.radiance_color * light.radius;
    float falloff = 1.0;
    // calculate falloff
    if (light.is_directional == 0) {
        float dist = length(light.position - frag_pos);
        float sat = saturate(1.0 - pow(dist / light.radius, 4.0));
        float numer = pow(sat, 2.0);
        float denom = dist*dist + 1;
        falloff = numer / denom;
        // radiance *= falloff;
    }

    float n_dot_l = max(0.0, dot(N, L));

    vec3 diff = (in_diffuse / PI) * kd;
    vec3 Lo = (diff + ks) * radiance * n_dot_l * falloff;
    frag_color = vec4(Lo, 1.0);
}
