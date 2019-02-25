#include "common.glh"

INOUT vec4 view_space_frag_pos;

uniform Light light;

#if FRAGMENT_SHADER
void main() {
    // @TODO perhaps info on the far plane/veiw frustum whoud be passed in and used here
    // but for a point light, this should be the same information
    if (light.is_directional == 0) {
        // gl_FragDepth = length(view_space_frag_pos.xyz) / light.radius;
    } else {
        // use default fragment depth;
        gl_FragDepth = view_space_frag_pos.z*0.5 + 0.5;
    }
}
#endif // FRAGMENT_SHADER

#if VERTEX_SHADER
layout (location = 0) in vec3 in_pos;

uniform vec4 clip_plane;

void main() {
    gl_Position = projection * view * model * vec4(in_pos, 1);
    view_space_frag_pos = projection * view * model * vec4(in_pos, 1);
}

#endif // VERTEX_SHADER