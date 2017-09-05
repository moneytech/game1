
#pragma once

#include "general.h"
#include "stb_truetype.h"

struct Rectangle {
    float x;
    float y;
    float width;
    float height;
};

struct Texture {
    u16 width;
    u16 height;

    u32 id;
};

struct Font {
    u32 id;
    u16 bwidth;
    u16 bheight;
    stbtt_bakedchar cdata[96]; // ASCII 32..126 is 95 glyphs

    float get_length(const char *str);
};

struct Color {
    float r;
    float g;
    float b;
};

struct Material {
    float specular_exp;
    Color ambient;
    Color diffuse;
    Color specular;
    Color emissive;
    float transparency;
};

const int MAX_TEXTURES_PER_MESH = 4;

struct Mesh {
    Texture *textures[MAX_TEXTURES_PER_MESH];
    Material *material;
    u32 buffer_id;
    Array<Vector3> vertices;
    Array<Vector3> normals;
    Array<Vector2> tex_coords;
};

struct Model {
    Array<Mesh *> meshes;
};

const u32 BITMAP_FRAME_FLIP_VERTICLE   = (1 << 0);
const u32 BITMAP_FRAME_FLIP_HORIZONTAL = (1 << 1);

struct Bitmap_Frame {
    Rectangle tex_coords;
    float duration;
    u32 flags;
};

const u32 SPRITE_ANIMATION_REPEAT = (1 << 0);

struct Sprite_Animation {
    Array<Bitmap_Frame> frames;
    u8 current_frame;
    float time_elapsed;
    u32 flags;
};

struct Sprite {
    Texture *texture;
    Bitmap_Frame *current_frame;
    Rectangle dimensions;
    Array<Sprite_Animation> animations;
    u8 current_animation;
};


enum Light_Type {
    DIRECTIONAL,
    RADIAL
};

struct Light {
    Light_Type type;
    Vector3 position;
    Color ambient;
    Color diffuse;
    Color specular;

    float linear;
    float quadratic;
};

struct Shader {
    u32 id;
};

struct Camera {
    Vector3 position;
    Quaternion rotation;
};


#ifdef WIN32
// for function pointer types, gl functions should never be called outside renderer_gl.cpp!
#include <GL/gl.h>
#include "glext.h"
#endif

struct GL_Renderer {
    Array<Light> lights;

    u32 gbuffer_framebuffer;
    u32 gbuffer_position;
    u32 gbuffer_normal;
    u32 gbuffer_albedo_spec;
    u32 gbuffer_depth;

    Shader *render_to_gbuffer;
    Shader *render_light_using_gbuffer;
    Shader *render_plain_texture;

    Matrix4 projection_matrix;
    Matrix4 view_matrix;

    #ifdef WIN32
    // GL API

    PFNGLGENFRAMEBUFFERSPROC glGenFramebuffers;
    PFNGLDELETEFRAMEBUFFERSPROC glDeleteFramebuffers;
    PFNGLBINDFRAMEBUFFERPROC glBindFramebuffer;
    PFNGLFRAMEBUFFERTEXTURE2DPROC glFramebufferTexture2D;
    PFNGLFRAMEBUFFERRENDERBUFFERPROC glFramebufferRenderbuffer;

    PFNGLDRAWBUFFERSPROC glDrawBuffers;

    PFNGLGENRENDERBUFFERSPROC glGenRenderbuffers;
    PFNGLDELETERENDERBUFFERSPROC glDeleteRenderbuffers;
    PFNGLBINDRENDERBUFFERPROC glBindRenderbuffer;
    PFNGLRENDERBUFFERSTORAGEPROC glRenderbufferStorage;
    PFNGLCHECKFRAMEBUFFERSTATUSPROC glCheckFramebufferStatus;

    PFNGLACTIVETEXTUREPROC glActiveTexture;

    PFNGLCREATEPROGRAMPROC glCreateProgram;
    PFNGLDELETEPROGRAMPROC glDeleteProgram;
    PFNGLCREATESHADERPROC glCreateShader;
    PFNGLDELETESHADERPROC glDeleteShader;
    PFNGLATTACHSHADERPROC glAttachShader;
    PFNGLDETACHSHADERPROC glDetachShader;
    PFNGLCOMPILESHADERPROC glCompileShader;
    PFNGLLINKPROGRAMPROC glLinkProgram;
    PFNGLSHADERSOURCEPROC glShaderSource;
    PFNGLUSEPROGRAMPROC glUseProgram;

    PFNGLGETSHADERIVPROC glGetShaderiv;
    PFNGLGETSHADERINFOLOGPROC glGetShaderInfoLog;
    PFNGLGETPROGRAMIVPROC glGetProgramiv;
    PFNGLGETPROGRAMINFOLOGPROC glGetProgramInfoLog;

    PFNGLUNIFORM1FPROC glUniform1f;
    PFNGLUNIFORM2FPROC glUniform2f;
    PFNGLUNIFORM3FPROC glUniform3f;
    PFNGLUNIFORM4FPROC glUniform4f;
    PFNGLUNIFORM1IPROC glUniform1i;
    PFNGLUNIFORM2IPROC glUniform2i;
    PFNGLUNIFORM3IPROC glUniform3i;
    PFNGLUNIFORM4IPROC glUniform4i;
    PFNGLUNIFORM1FVPROC glUniform1fv;
    PFNGLUNIFORM2FVPROC glUniform2fv;
    PFNGLUNIFORM3FVPROC glUniform3fv;
    PFNGLUNIFORM4FVPROC glUniform4fv;
    PFNGLUNIFORM1IVPROC glUniform1iv;
    PFNGLUNIFORM2IVPROC glUniform2iv;
    PFNGLUNIFORM3IVPROC glUniform3iv;
    PFNGLUNIFORM4IVPROC glUniform4iv;
    PFNGLUNIFORMMATRIX2FVPROC glUniformMatrix2fv;
    PFNGLUNIFORMMATRIX3FVPROC glUniformMatrix3fv;
    PFNGLUNIFORMMATRIX4FVPROC glUniformMatrix4fv;

    PFNGLGETUNIFORMLOCATIONPROC glGetUniformLocation;
    PFNGLGETUNIFORMFVPROC glGetUniformfv;
    PFNGLGETUNIFORMIVPROC glGetUniformiv;
    PFNGLGETACTIVEUNIFORMPROC glGetActiveUniform;

    PFNGLBINDBUFFERPROC glBindBuffer;
    PFNGLDELETEBUFFERSPROC glDeleteBuffers;
    PFNGLGENBUFFERSPROC glGenBuffers;
    PFNGLISBUFFERPROC glIsBuffer;
    PFNGLBUFFERDATAPROC glBufferData;
    PFNGLBUFFERSUBDATAPROC glBufferSubData;
    PFNGLGETBUFFERSUBDATAPROC glGetBufferSubData;

    PFNGLDISABLEVERTEXATTRIBARRAYPROC glDisableVertexAttribArray;
    PFNGLENABLEVERTEXATTRIBARRAYPROC glEnableVertexAttribArray;

    PFNGLVERTEXATTRIBPOINTERPROC glVertexAttribPointer;

    PFNGLGENVERTEXARRAYSPROC glGenVertexArrays;
    PFNGLDELETEVERTEXARRAYSPROC glDeleteVertexArrays;
    PFNGLBINDVERTEXARRAYPROC glBindVertexArray;

    #endif

    void init(int width, int height);

    void create_texture(Texture *tex, u16 width, u16 height, void *data);
    void delete_texture(Texture *tex);
    Shader *compile_shader_source(const char *vertex, const char* pixel);
    void store_mesh_in_buffer(Mesh *m);

    void set_projection_ortho(float l, float r, float t, float b, float n, float f);

    void set_projection_frustum(float l, float r, float b, float t, float n, float f);
    void set_projection_fov(float fov, float aspect, float n, float f);

    void clear_screen(float r, float g, float b, float a);

    // 2D API

    void draw_rect(Rectangle &rect);
    void draw_rect(float x, float y, float width, float height);
    void draw_textured_rect(Texture *tex, float x, float y, float width, float height);
    void draw_textured_rect(Texture *tex, Rectangle &rect);
    void draw_sprite(Sprite *sp);
    void create_font(Font *font, u16 bmap_width, u16 bmap_height, void *data);
    float draw_text(Font *font, const char *text, float x, float y);

    // 3D API

    void start_scene();
    void finish_scene();

    void draw_cube(float x, float y, float z, float size);
    void draw_mesh(Mesh *m);
    void draw_model(Model *m);
};

