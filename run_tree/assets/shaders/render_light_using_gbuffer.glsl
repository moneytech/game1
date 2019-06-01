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
uniform mat4 camera_view_matrix;
uniform int debug_csm_selection;

float get_shadow_distance(mat4 LS_matrix, vec3 WS_frag_pos, float n_dot_l, int index, vec2 texcoord_offset) {
    vec4 LS_frag_pos = (LS_matrix * vec4(WS_frag_pos, 1));
    LS_frag_pos = LS_frag_pos * 0.5 + 0.5;
    LS_frag_pos.xyz /= LS_frag_pos.w;

    LS_frag_pos.xy += texcoord_offset;

    const float EPSILON = 0.00008;
    float bias = max(EPSILON * (1.0 - n_dot_l), 0.00005);
    bias = 0.0001;
    vec2 coord = saturate(LS_frag_pos.xy);

    coord.x = (coord.x * 0.25) + (0.25 * index);
    // coord.y = 1.0 - coord.y;

    return (texture(light.csm_shadow_map, coord).r + bias) - LS_frag_pos.z;
}

bool is_in_map(mat4 LS_matrix, vec3 WS_frag_pos, vec2 texcoord_offset) {
    vec4 LS_frag_pos = (LS_matrix * vec4(WS_frag_pos, 1));
    LS_frag_pos = LS_frag_pos * 0.5 + 0.5;
    LS_frag_pos.xyz /= LS_frag_pos.w;

    LS_frag_pos.xy += texcoord_offset;

    if (LS_frag_pos.x <= 0.01 || LS_frag_pos.x >= 0.99) return false;
    if (LS_frag_pos.y <= 0.01 || LS_frag_pos.y >= 0.99) return false;

    return true;
}

int get_split_index(vec3 WS_frag_pos, vec2 texcoord_offset) {
    for (int i = 0; i < 4; ++i) {
        if (is_in_map(light.csm_matrices[i], WS_frag_pos, texcoord_offset)) return i;
    }

    return -1;
}

float sample_csm_distance(vec3 WS_frag_pos, float n_dot_l, vec2 offset) {
    vec4 VS_frag_pos = camera_view_matrix * vec4(WS_frag_pos, 1);

    float d = abs(VS_frag_pos.z);
    if (is_in_map(light.csm_matrices[0], WS_frag_pos, offset)) {
        return get_shadow_distance(light.csm_matrices[0], WS_frag_pos, n_dot_l, 0, offset);
    }
    if (is_in_map(light.csm_matrices[1], WS_frag_pos, offset)) {
        return get_shadow_distance(light.csm_matrices[1], WS_frag_pos, n_dot_l, 1, offset);
    }
    if (is_in_map(light.csm_matrices[2], WS_frag_pos, offset)) {
        return get_shadow_distance(light.csm_matrices[2], WS_frag_pos, n_dot_l, 2, offset);
    }
    if (is_in_map(light.csm_matrices[3], WS_frag_pos, offset)) {
        return get_shadow_distance(light.csm_matrices[3], WS_frag_pos, n_dot_l, 3, offset);
    }
    return 1;
}

vec4 get_csm_debug_color(vec3 WS_frag_pos) {
    int index = get_split_index(WS_frag_pos, vec2(0));
    if (index == 0) {
        return vec4(1, 1, 0, 1);
    }
    if (index == 1) {
        return vec4(0, 1, 0, 1);
    }
    if (index == 2) {
        return vec4(0, 0, 1, 1);
    }
    if (index == 3) {
        return vec4(0.1, 0.1, 0.1, 1);
    }
    return vec4(0, 0, 0, 1);
}

float sample_shadow_distribution(vec3 WS_frag_pos, float n_dot_l) {
    float dist = sample_csm_distance(WS_frag_pos, n_dot_l, vec2(0, 0));
    return (dist < 0) ? 1.0 : 0.0;

    // float distribution = 0.0;
    // int size = 4;
    // float TEXEL_SIZE = (1.0 / 1024.0);

    // for (int x = -size; x <= size; ++ x) {
    //     for (int y = -size; y <= size; ++y) {
    //         vec2 offset = vec2(TEXEL_SIZE * x, TEXEL_SIZE * y);
    //         int index = get_split_index(WS_frag_pos, offset);

    //         float dist = get_shadow_distance(light.csm_matrices[index], WS_frag_pos, n_dot_l, index, offset);
    //         float weight = 1;

    //         if (dist < 0) {
    //             distribution += 0.8 * weight;
    //         }
    //     }
    // }

    // return distribution / ((size*2+1)*(size*2+1));
}

void main() {
    vec2 tex_coords = get_ndc_position();

    vec3 frag_pos = texture(g_position, tex_coords).rgb;
    vec3 normal = texture(g_normal, tex_coords).rgb;
    vec3 in_diffuse = texture(g_albedospec, tex_coords).rgb;

    vec2 roughness_metallic = texture(g_roughness, tex_coords).rg;
    float Roughness = roughness_metallic.r;
    float Metallic  = roughness_metallic.g;

    if (length(normal) < 0.5) {
        frag_color = vec4(in_diffuse, 1);
        return;
    }

  vec3 N = normalize(normal);

    vec3 L = vec3(0);
    if (light.is_directional != 0) {
        L = normalize(-light.position);
    } else {
        L = normalize(light.position-frag_pos);
    }

    float shadow_distribution = 0;
    vec4 csm_color = vec4(1);

    if (light.use_shadow_cubemap != 0) {
        float dist = texture(light.shadow_cube_map, (frag_pos-light.position)).r * light.radius;
        if ((dist + 0.1) < (length(frag_pos-light.position))) {
            shadow_distribution = 1.0;
        }
    } else if (light.use_csm_shadow_map != 0) {
        vec3 VS_frag_pos = (view * vec4(frag_pos, 1.0)).xyz;

        float n_dot_l = dot(N, L);

        if (n_dot_l > 0) {
            float distrib = sample_shadow_distribution(frag_pos, n_dot_l);
            shadow_distribution = distrib;

            if (debug_csm_selection != 0) {
                csm_color = get_csm_debug_color(frag_pos);
            }
        }
    }

    vec3 F0 = vec3(0.04);
    F0 = mix(F0, in_diffuse, vec3(Metallic));

    // ambient light will be set by ambient shader
    vec3 ambient = vec3(0.01) * in_diffuse;

    

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
    vec3 Lo = (diff + ks) * radiance * n_dot_l * falloff * (1.0 - shadow_distribution) + ambient;
    vec4 final_color = vec4(Lo, 1.0);
    frag_color = csm_color * final_color;
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
