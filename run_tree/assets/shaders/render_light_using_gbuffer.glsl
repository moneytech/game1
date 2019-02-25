#include "common.glh"

#if FRAGMENT_SHADER

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

uniform Light light;
uniform vec3 camera_position;

float get_shadow_distance(mat4 LS_matrix, vec3 WS_frag_pos, int index) {
    vec4 LS_frag_pos = (LS_matrix * vec4(WS_frag_pos, 1));
    LS_frag_pos = LS_frag_pos * 0.5 + 0.5;
    LS_frag_pos.xyz /= LS_frag_pos.w;

    const float EPSILON = 0.001;
    if (LS_frag_pos.x >= 0 && LS_frag_pos.x <= 1 && LS_frag_pos.y <= 1 && LS_frag_pos.y >= 0) {
        vec2 coord = LS_frag_pos.xy;
        coord.x = (coord.x / 4) + (0.25 * index);
        // coord.y = 1.0 - coord.y;
        return (texture(light.csm_shadow_map, coord).r + EPSILON) - LS_frag_pos.z;
    } else {
        return 0;
    }
}

void main() {
    vec2 tex_coords = get_ndc_position();

    vec3 frag_pos = texture(g_position, tex_coords).rgb;
    vec3 normal = texture(g_normal, tex_coords).rgb;
    vec3 in_diffuse = texture(g_albedospec, tex_coords).rgb;
    float Roughness = texture(g_roughness, tex_coords).r;
    float Metallic = texture(g_metallic, tex_coords).r;

    if (length(normal) < 0.5) {
        frag_color = vec4(in_diffuse, 1);
        return;
    }

    if (light.use_shadow_cubemap != 0) {
        float dist = texture(light.shadow_cube_map, (frag_pos-light.position)).r * light.radius;
        if ((dist + 0.1) < (length(frag_pos-light.position))) {
            frag_color = vec4(0);
            return;
        }
    } else if (light.use_csm_shadow_map != 0) {
        float parts[4] = light.csm_parts;

        vec3 VS_frag_pos = (view * vec4(frag_pos, 1.0)).xyz;

        float dist_from_camera = abs(VS_frag_pos.z);
        float dist = 0;
        dist = get_shadow_distance(light.csm_matrices[0], frag_pos, 0);
        if (dist == 0) dist = get_shadow_distance(light.csm_matrices[1], frag_pos, 1);
        if (dist == 0) dist = get_shadow_distance(light.csm_matrices[2], frag_pos, 2);
        if (dist == 0) dist = get_shadow_distance(light.csm_matrices[3], frag_pos, 3);

        if (dist < 0) {
            frag_color = vec4(0);
            return;
        }
    }

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

    vec3 radiance = light.radiance_color;
    float falloff = 1.0;
    // calculate falloff
    if (light.is_directional == 0) {
        float dist = length(light.position - frag_pos);
        float sat = saturate(1.0 - pow(dist / light.radius, 4.0));
        float numer = pow(sat, 2.0);
        float denom = dist*dist + 1;
        falloff = numer / denom;
        radiance *= light.radius;
    }

    float n_dot_l = max(0.0, dot(N, L));

    vec3 diff = (in_diffuse / PI) * kd;
    vec3 Lo = (diff + ks) * radiance * n_dot_l * falloff;
    frag_color = vec4(Lo, 1.0);
}

#endif // FRAGMENT_SHADER

#if VERTEX_SHADER

layout (location = 0) in vec3 in_pos;
layout (location = 1) in vec3 in_normal;
layout (location = 2) in vec2 in_tex_coords;
layout (location = 3) in vec3 in_tangent_normal;
layout (location = 4) in vec3 in_color;

void main() {
    gl_Position = projection * view * model * vec4(in_pos, 1.0);
}


#endif // VERTEX_SHADER
