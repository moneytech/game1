
#import "GL";

Rectangle :: struct {
    x: float;
    y: float;
    width: float;
    height: float;
};

Texture :: struct {
    width: u16;
    height: u16;

    id: u32;
};

Font :: struct {
    id: u32;
    bwidth: u32;
    bheight: u16;
    cdata: [96] stbtt_bakedchar; // ASCII 32..126 is 95 glyphs
};

font_get_length :: (using font: *Font, str: string) -> float {
    x: float = 0;
    y: float = 0;
    for 0..str.count-1 {
        c := str[it_index];
        if (c >= 32 && c < 128) {
            q: stbtt_aligned_quad = ---;
            // just run this so we can advance x for this character
            stbtt_GetBakedQuad(cdata, bwidth, bheight, c-32, *x, *y, *q,1);
        }
    }
    return x;
}

Color :: struct {
    r: float;
    g: float;
    b: float;
};

MAX_TEXTURES_PER_MESH  :: 4;
TEXTURE_DIFFUSE_INDEX  :: 0;
TEXTURE_NORMAL_INDEX   :: 1;
TEXTURE_SPECULAR_INDEX :: 2;

Material :: struct {
    textures: [MAX_TEXTURES_PER_MESH] *Texture;
    specular_exp: float;
    ambient: Color;
    diffuse: Color;
    specular: Color;
    emissive: Color;
    transparency: float;
};

Mesh :: struct {
    material: *Material;
    buffer_id: u32;

    vertices: [..] Vector3;
    normals: [..] Vector3;
    tangent_normals: [..] Vector3;
    tex_coords: [..] Vector2;
};

Model :: struct {
    meshes: [..] *Mesh;
};

BITMAP_FRAME_FLIP_VERTICLE   :: (1 << 0);
BITMAP_FRAME_FLIP_HORIZONTAL :: (1 << 1);

Bitmap_Frame :: struct {
    tex_coords: Rectangle;
    duration: float;
    flags: u32;
};

SPRITE_ANIMATION_REPEAT :: (1 << 0);

Sprite_Animation :: struct {
    frames: [..] Bitmap_Frame;
    current_frame: u8;
    time_elapsed: float;
    flags: u32;
};

Sprite :: struct {
    texture: *Texture;
    current_frame: *Bitmap_Frame;
    dimensions: Rectangle;
    animations: [..] Sprite_Animation;
    current_animation: u8;
};


Light_Type :: enum {
    DIRECTIONAL,
    RADIAL
};

Light :: struct {
    type: Light_Type;
    position: Vector3;
    ambient: Color;
    diffuse: Color;
    specular: Color;

    linear: float;
    quadratic: float;
};

struct Shader {
    id: u32;

    // for hot reloading
    vert_path: string;
    frag_path: string;
};

struct Camera {
    position: Vector3;
    rotation: Quaternion;
};

struct GL_Renderer {
    game: *Game;

    lights: [..] Light;

    gbuffer_framebuffer: u32;
    gbuffer_position: u32;
    gbuffer_normal: u32;
    gbuffer_albedo_spec: u32;
    gbuffer_depth: u32;

    render_to_gbuffer: *Shader;
    render_light_using_gbuffer: *Shader;
    render_plain_texture: *Shader;

    projection_matrix: Matrix4;
    view_matrix: Matrix4;
}

/*
    void init(int width, int height);

    void create_texture(Texture *tex, u16 width, u16 height, void *data);
    void delete_texture(Texture *tex);
    Shader *compile_shader_source(const char *vertex, const char* pixel);
    void compile_shader_source(Shader *sh, const char *vertex, const char *pixel);
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

*/