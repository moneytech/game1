
#load "stb.jai";
#import "GL";

#scope_file
using gl;

#scope_export

Rectangle :: struct {
    x: float;
    y: float;
    width: float;
    height: float;
};

Texture :: struct {
    Texture_Type :: enum #complete {
        RGBA;
        RGBA32F;
        DEPTH;
    }
    using Texture_Type;

    type: Texture_Type;
    width: u32;
    height: u32;

    id: u32;

    #destructor delete_texture;
};

Viewport :: struct {
    x: s32;
    y: s32;
    w: u32;
    h: u32;
}

make_Viewport :: (x: s32, y: s32, w: u32, h: u32) -> Viewport {
    v: Viewport = ---;
    v.x = x;
    v.y = y;
    v.w = w;
    v.h = h;
    return v;
}

Frame_Buffer :: struct {
    color_texture: *Texture;
    depth_texture: *Texture;
    id: u32 = xx -1;

    viewport: Viewport;
}

set_frame_buffer_textures :: (fb: *Frame_Buffer, color_texture: *Texture, depth_texture: *Texture) {
    fb.color_texture = color_texture;
    fb.depth_texture = depth_texture;

    glBindFramebuffer(GL_FRAMEBUFFER, fb.id);

    if fb.color_texture {
        glBindTexture(GL_TEXTURE_2D, fb.color_texture.id);
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, fb.color_texture.id, 0);
    }

    if fb.depth_texture {
        glBindTexture(GL_TEXTURE_2D, fb.depth_texture.id);
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_TEXTURE_2D, fb.depth_texture.id, 0);
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_STENCIL_ATTACHMENT, GL_TEXTURE_2D, fb.depth_texture.id, 0);
    }

    if color_texture || depth_texture then assert(glCheckFramebufferStatus(GL_FRAMEBUFFER) == GL_FRAMEBUFFER_COMPLETE);

    tex: *Texture;
    if color_texture tex = color_texture;
    else tex = depth_texture;
    
    if tex set_viewport(fb, make_Viewport(0, 0, tex.width, tex.height));
}

create_frame_buffer_from_textures :: (using rdr: *GL_Renderer, color_texture: *Texture, depth_texture: *Texture) -> Frame_Buffer {
    buf: Frame_Buffer;
    glGenFramebuffers(1, *buf.id);
    glBindFramebuffer(GL_FRAMEBUFFER, buf.id);

    attach: [1] u32 = {:u32: GL_COLOR_ATTACHMENT0 };
    glDrawBuffers(xx attach.count, attach.data);

    set_frame_buffer_textures(*buf, color_texture, depth_texture);
    
    use_frame_buffer(rdr, null);
    return buf;
}

// quickly create a working framebuffer
create_frame_buffer :: (using rdr: *GL_Renderer, width: u32, height: u32) -> Frame_Buffer {
    buf: Frame_Buffer;
    buf.color_texture = New(Texture);
    buf.depth_texture = New(Texture);
    create_texture(buf.color_texture, width, height, null, Texture.RGBA);
    create_texture(buf.depth_texture, width, height, null, Texture.DEPTH);

    glGenFramebuffers(1, *buf.id);
    glBindFramebuffer(GL_FRAMEBUFFER, buf.id);

    attach: [1] u32 = {:u32: GL_COLOR_ATTACHMENT0 };
    glDrawBuffers(xx attach.count, attach.data);

    set_frame_buffer_textures(*buf, buf.color_texture, buf.depth_texture);

    set_viewport(*buf, make_Viewport(0, 0, width, height));

    use_frame_buffer(rdr, null);
    return buf;
}

delete_frame_buffer :: (fb: *Frame_Buffer) {
    glDeleteFramebuffers(1, *fb.id);
    Delete(fb.color_texture);
    Delete(fb.depth_texture);

    fb.id = xx -1;
    fb.color_texture = null;
    fb.depth_texture = null;
}

use_frame_buffer :: (using rdr: *GL_Renderer, fb: *Frame_Buffer) {
    if !fb {
        glBindFramebuffer(GL_FRAMEBUFFER, 0);
        current_frame_buffer = null;
        use_viewport(make_Viewport(0, 0, game.window.width, game.window.height));
        return;
    }

    glBindFramebuffer(GL_FRAMEBUFFER, fb.id);
    use_viewport(fb.viewport);
    current_frame_buffer = fb;
}

Font :: struct {
    id: u32;
    char_height: float;
    bwidth: s16;
    bheight: s16;
    cdata: [96] stbtt_bakedchar; // ASCII 32..126 is 95 glyphs
};

font_get_length :: (using font: Font, str: string) -> float {
    x: float = 0;
    y: float = 0;
    for 0..str.count-1 {
        c := str[it];
        if (c >= 32 && c < 128) {
            q: stbtt_aligned_quad = ---;
            // just run this so we can advance x for this character
            stbtt_GetBakedQuad(cdata.data, bwidth, bheight, c-32, *x, *y, *q,1);
        }
    }
    return x;
}

Color :: struct {
    r: float;
    g: float;
    b: float;
    a: float;
};

make_Color :: (r: float, g: float, b: float, a := 1.0) -> Color {
    c: Color = ---;
    c.r = r;
    c.g = g;
    c.b = b;
    c.a = a;
    return c;
}

MAX_TEXTURES_PER_MESH  :: 4;
TEXTURE_DIFFUSE_INDEX  :: 0;
TEXTURE_NORMAL_INDEX   :: 1;
TEXTURE_SPECULAR_INDEX :: 2;

Material :: struct {
    textures: [MAX_TEXTURES_PER_MESH] *Texture;
    diffuse: Color;
    roughness: float = 0.4;
    metallic: float = 0;
    transparency: float = 1.0;

    // maybe these should be Mesh properties since they're rendering options as opposed to rendering attributes ?
    disable_lighting := false;
    disable_backface_culling := false;
    disable_vertex_colors := false;
    disable_depth_test := false;

    #constructor (using m: *Material) {
        diffuse = make_Color(1.0, 1.0, 1.0);
    }
};

Primitive_Type :: enum u32 #complete {
    TRIANGLES;
    POINTS;
    LINES;
}

Mesh :: struct {
    material: *Material;
    buffer_id: u32;
    element_buffer_id: u32;
    primitive_type: Primitive_Type = Primitive_Type.TRIANGLES;

    buffer_size: s64;

    vertices: [..] Vector3;
    normals: [..] Vector3;
    tangent_normals: [..] Vector3;
    tex_coords: [..] Vector2;
    colors: [..] Color;
    indices: [..] u16; // @Volatile type must match glDrawElements and glBufferData calls

    model_matrix: Matrix4;

    #if DEVELOPER {
        map_position: [..] Vector2;
    }

    #constructor Mesh_con;
}

Mesh_con :: (m: *Mesh) {
    m.model_matrix = matrix_identity();
}

reset_mesh_arrays :: (using m: *Mesh) {
    vertices.count = 0;
    normals.count = 0;
    tangent_normals.count = 0;
    tex_coords.count = 0;
}

Model :: struct {
    using object: Scene_Object;

    meshes: [..] *Mesh;
    model_matrix: Matrix4;
    draw_mode := DRAW_MODE_SOLID;

    #constructor init_model;
};

init_model :: (m: *Model) {
    m.model_matrix = matrix_identity();
}

DRAW_MODE_SOLID     :: 0;
DRAW_MODE_WIREFRAME :: 1;
DRAW_MODE_SOLID_AND_WIREFRAME :: 2;

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
    DIRECTIONAL;
    RADIAL;
};

Light :: struct {
    using object: Scene_Object;

    type: Light_Type;
    direction: Vector3; // used if directional light
    
    radiance: Color;

    radius: float;
};

Shader :: struct {
    id: u32;

    // for hot reloading
    vert_path: string;
    frag_path: string;
};

Camera :: struct {
    using object: Scene_Object;

    // position: Vector3;
    rotation: Quaternion;

    dual_lens := false;
};


#run print("@Incomplete: make a flag on model to differentiate between water and non-water models.\n");

GL_Renderer :: struct {
    game: *Game;

    lights: [] *Light;

    VertexArrayID: u32;
    gbuffer_framebuffer: u32;
    gbuffer_position: u32;
    gbuffer_normal: u32;
    gbuffer_albedo_spec: u32;
    gbuffer_roughness: u32;
    gbuffer_metallic: u32;
    gbuffer_depth: u32;
    gbuffer_viewport: Viewport;

    render_to_gbuffer: *Shader;
    render_light_using_gbuffer: *Shader;
    render_plain_texture: *Shader;
    render_text: *Shader;
    render_rect: *Shader;
    render_water: *Shader;
    render_gamma_correction: *Shader;
    null_shader: *Shader;

    current_frame_buffer: *Frame_Buffer;
    water_reflect_frame_buffer: Frame_Buffer;
    water_refract_frame_buffer: Frame_Buffer;
    scratch_frame_buffer: Frame_Buffer;

    wireframe_material: *Material;
    light_sphere: *Model;

    light_entity_texture: *Texture;

    enable_clip_plane: bool;
    clip_plane: Vector4;
    water_distort_offset: float;

    #if DEVELOPER {
        picking_framebuffer: u32;
        picking_pos_texture: u32;
        picking_depth: u32;
        picking_shader: *Shader;
    }

    camera: Camera;
    projection_matrix: Matrix4;
    view_matrix: Matrix4;
    model_matrix_stack: [..] Matrix4;
}

resize_rendering_buffers :: (using rdr: *GL_Renderer, w: u32, h: u32) {
    gbuffer_viewport = make_Viewport(0, 0, w, h);
    glBindTexture(GL_TEXTURE_2D, gbuffer_position);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB16F, xx w, xx h, 0, GL_RGB, GL_FLOAT, null);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

    glBindTexture(GL_TEXTURE_2D, gbuffer_normal);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB16F, xx w, xx h, 0, GL_RGB, GL_FLOAT, null);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);


    glBindTexture(GL_TEXTURE_2D, gbuffer_albedo_spec);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA32F, xx w, xx h, 0, GL_RGBA, GL_FLOAT, null);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

    glBindTexture(GL_TEXTURE_2D, gbuffer_roughness);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RED, xx w, xx h, 0, GL_RED, GL_FLOAT, null);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

    glBindTexture(GL_TEXTURE_2D, gbuffer_metallic);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RED, xx w, xx h, 0, GL_RED, GL_FLOAT, null);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

    glBindRenderbuffer(GL_RENDERBUFFER, gbuffer_depth);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8, w, h);

    resize_frame_buffer(*water_reflect_frame_buffer, w, h);
    resize_frame_buffer(*water_refract_frame_buffer, w, h);
    resize_frame_buffer(*scratch_frame_buffer, w, h);

    #if DEVELOPER {
        if picking_pos_texture {
            glBindTexture(GL_TEXTURE_2D, picking_pos_texture);
            glTexImage2D(GL_TEXTURE_2D, 0, GL_R32I, xx w, xx h, 0, GL_RED_INTEGER, GL_INT, null);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        }

        if picking_depth {
            glBindRenderbuffer(GL_RENDERBUFFER, picking_depth);
            glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT, w, h);
        }
    }
}

resize_frame_buffer :: (fb: *Frame_Buffer, w: u32, h: u32) {
    resize_texture(fb.color_texture, w, h);
    resize_texture(fb.depth_texture, w, h);
    set_viewport(fb, make_Viewport(0, 0, w, h));
}


debug_callback :: (source: GLenum, type: GLenum, id: GLuint, severity: GLenum, length: GLsizei, message: *u8, userParam: *void) #c_callback {
	pctx := cast(*Context) userParam;
    ctx := <<pctx;
	push_context ctx {
		#if OS_WINDOWS {
			// print("source: %\n", source);
			// print("type: %\n", type);
			// print("id: %\n", id);
			// print("severity: %\n", severity);
			// print("length: %\n", length);
			// print("message: %\n", message);
			// print("userParam: %\n", userParam);
			if type == GL_DEBUG_TYPE_ERROR print("GL Error:%\n", point_at_c_string(message));
		}
	}
}

push_model_matrix :: (using rdr: *GL_Renderer, mat: Matrix4) {
    array_add(*model_matrix_stack, mat);
}

pop_model_matrix :: (using rdr: *GL_Renderer) -> Matrix4 {
    return pop(*model_matrix_stack);
}

current_model_matrix :: (using rdr: GL_Renderer) -> Matrix4 {
    return model_matrix_stack[model_matrix_stack.count-1];
}

init :: (using rdr: *GL_Renderer, width: u32, height: u32) {
    print("rdr: %\n", rdr);
    if GL_VERSION_4_3 {
        glDebugMessageCallback(debug_callback, *context);
    } else if GL_ARB_debug_output {
        glDebugMessageCallbackARB(debug_callback, *context);
    }   
    
    push_model_matrix(rdr, matrix_identity());
    // glBegin(GL_TRIANGLES);
    // glEnd();

    // @Temporary
    // @Temporary
    // @Temporary
    // @Temporary
    // @Temporary
    glGenVertexArrays(1, *rdr.VertexArrayID);
    glBindVertexArray(rdr.VertexArrayID);

    water_reflect_frame_buffer = create_frame_buffer(rdr, width, height);
    water_refract_frame_buffer = create_frame_buffer(rdr, width, height);
    scratch_frame_buffer = create_frame_buffer_from_textures(rdr, create_texture(width, height, null, Texture.RGBA32F), create_texture(width, height, null, Texture.DEPTH));

    glGenFramebuffers(1, *gbuffer_framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, gbuffer_framebuffer);

    glGenTextures(1, *gbuffer_position);
    glGenTextures(1, *gbuffer_normal);
    glGenTextures(1, *gbuffer_albedo_spec);
    glGenTextures(1, *gbuffer_roughness);
    glGenTextures(1, *gbuffer_metallic);    
    glGenRenderbuffers(1, *gbuffer_depth);

    resize_rendering_buffers(rdr, width, height);

    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, gbuffer_position, 0);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT1, GL_TEXTURE_2D, gbuffer_normal, 0);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT2, GL_TEXTURE_2D, gbuffer_albedo_spec, 0);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT3, GL_TEXTURE_2D, gbuffer_roughness, 0);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT4, GL_TEXTURE_2D, gbuffer_metallic, 0);

    attach: [] u32 = {:u32: GL_COLOR_ATTACHMENT0, GL_COLOR_ATTACHMENT1, GL_COLOR_ATTACHMENT2, GL_COLOR_ATTACHMENT3, GL_COLOR_ATTACHMENT4 };
    glDrawBuffers(xx attach.count, attach.data);

    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_STENCIL_ATTACHMENT, GL_RENDERBUFFER, gbuffer_depth);

    assert(glCheckFramebufferStatus(GL_FRAMEBUFFER) == GL_FRAMEBUFFER_COMPLETE);

    #if DEVELOPER {
        // @TODO resizing picking framebuffer
        glGenFramebuffers(1, *picking_framebuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, picking_framebuffer);

        glGenTextures(1, *picking_pos_texture);
        glBindTexture(GL_TEXTURE_2D, picking_pos_texture);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_R32I, xx width, xx height, 0, GL_RED_INTEGER, GL_INT, null);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, picking_pos_texture, 0);

        attach: [1] u32 = {:u32: GL_COLOR_ATTACHMENT0};
        glDrawBuffers(xx attach.count, attach.data);

        glGenRenderbuffers(1, *picking_depth);
        glBindRenderbuffer(GL_RENDERBUFFER, picking_depth);
        glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT, width, height);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, picking_depth);

        assert(glCheckFramebufferStatus(GL_FRAMEBUFFER) == GL_FRAMEBUFFER_COMPLETE);
    }

    use_frame_buffer(rdr, null);


    wireframe_material = New(Material);
    wireframe_material.diffuse = make_Color(1.0, 0.5, 0.0);
    wireframe_material.disable_lighting = true;
    wireframe_material.disable_backface_culling = true;
    wireframe_material.disable_vertex_colors = true;

    light_material := New(Material);
    <<light_material = <<wireframe_material;
    light_material.disable_backface_culling = false;
    light_material.disable_depth_test = true;

    light_sphere = create_sphere(1, 180, 180);
    light_sphere.model_matrix = matrix_identity();
    for light_sphere.meshes
        it.material = light_material;
}

set_clip_plane :: (using rdr: *GL_Renderer, enable: bool, plane: Vector4) {
    rdr.enable_clip_plane = enable;
    rdr.clip_plane = plane;
}

set_clip_plane :: (using rdr: *GL_Renderer, enable: bool) {
    rdr.enable_clip_plane = enable;
}

set_texture :: (tex: *Texture, width: u32, height: u32, texId: GLuint, type := Texture.RGBA) {
    tex.width = width;
    tex.height = height;
    tex.id = texId;
    tex.type = type;
}


update_texture :: (tex: *Texture, data: *void) {
    resize_texture(tex, tex.width, tex.height, data);
}

resize_texture :: (tex: *Texture, width: u32, height: u32, data := null) {
    glBindTexture(GL_TEXTURE_2D, tex.id);
    type := tex.type;

    interal_format: GLint;
    format: GLenum;
    ty: u32 = GL_UNSIGNED_BYTE;

    if type == {
        case Texture.RGBA;
            interal_format = GL_RGBA;
            format = GL_RGBA;
        case Texture.DEPTH;
            interal_format = GL_DEPTH24_STENCIL8;
            format = GL_DEPTH_STENCIL;
            ty = GL_UNSIGNED_INT_24_8;
        case Texture.RGBA32F;
            interal_format = GL_RGBA32F;
            format = GL_RGBA;
            ty = GL_FLOAT;
        case;
            print("Unhandled texture type: %\n", type);
    }

    glTexImage2D(GL_TEXTURE_2D, 0, interal_format, width, height, 0, format, ty, data);
    tex.width = width;
    tex.height = height;
}

create_texture :: (tex: *Texture, width: u32, height: u32, data: *void, type := Texture.RGBA) {
    texId: GLuint;
    glGenTextures(1, *texId);
    tex.type = type;
    tex.width = width;
    tex.height = height;
    tex.id = texId;

    resize_texture(tex, width, height, data);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR); // Linear Filtering
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR); // Linear Filtering
}

create_texture :: (width: u32, height: u32, data: *void, type := Texture.RGBA) -> *Texture {
    tex := New(Texture);
    create_texture(tex, width, height, data, type);
    return tex;
}

set_texture_wrap :: (tex: *Texture, clamp_to_edge: bool) {
    glBindTexture(GL_TEXTURE_2D, tex.id);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glBindTexture(GL_TEXTURE_2D, 0);
}

delete_texture :: (tex: *Texture) {
    glDeleteTextures(1, *tex.id);
    tex.id = 0;
    tex.width = 0;
    tex.height = 0;
}

compile_shader :: (type: GLenum, source: string) -> u32 {
    v := glCreateShader(type);
    length: GLint = xx source.count;
    glShaderSource(v, 1, *source.data, *length);
    glCompileShader(v);

    status: GLint;
    glGetShaderiv(v, GL_COMPILE_STATUS, *status);
    if (status == xx GL_FALSE) {
        len: GLint;
        glGetShaderiv(v, GL_INFO_LOG_LENGTH, *len);
        buf := cast(*u8) alloc(len);
        glGetShaderInfoLog(v, xx len, xx *len, buf);
        print("ERROR: %\n", point_at_c_string(buf));
        free(buf);

        glDeleteShader(v);
        return 0;
    }

    return v;
}

compile_shader_source :: (vertex: string, pixel: string) -> *Shader {
    out := New(Shader);
    compile_shader_source(out, vertex, pixel);
    return out;
}

compile_shader_source :: (out: *Shader, vertex: string, pixel: string) {
    vert := compile_shader(GL_VERTEX_SHADER, vertex);
    frag := compile_shader(GL_FRAGMENT_SHADER, pixel);
    program := glCreateProgram();
    glAttachShader(program, vert);
    glAttachShader(program, frag);
    glLinkProgram(program);

    status: GLint;
    glGetProgramiv(program, GL_LINK_STATUS, *status);
    if (status == xx GL_FALSE) {
        len: GLint;
        glGetProgramiv(program, GL_INFO_LOG_LENGTH, *len);
        buf := cast(*u8) alloc(len);
        glGetProgramInfoLog(program, xx len, xx *len, buf);
        print("ERROR: %\n", point_at_c_string(buf));
        free(buf);

        glDeleteProgram(program);
        glDeleteShader(vert);
        glDeleteShader(frag);
        return ;
    }

    glDetachShader(program, vert);
    glDetachShader(program, frag);

    out.id = program;
}

clear_screen :: (r: float, g: float, b: float, a: float) {
    glClearColor(r, g, b, a);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    glEnable(GL_CULL_FACE);
    glCullFace(GL_BACK);

    // glDepthFunc(GL_LEQUAL);
}

enable_scissor :: (v: Viewport) {
    glEnable(GL_SCISSOR_TEST);
    glScissor(v.x, v.y, xx v.w, xx v.h);
}

disable_scissor :: () {
    glDisable(GL_SCISSOR_TEST);
}

draw_circle :: (using rdr: GL_Renderer, x: float, y: float, radius: float, color: Color) {
    glUseProgram(render_rect.id);
    update_matrices(rdr, matrix_identity(), render_rect);

    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    arr: [..] Vector2;
    defer array_reset(*arr);

    glDisable(GL_CULL_FACE);
    glDisable(GL_DEPTH_TEST);

    NUM_PIECES :: 60;
    step := TAU / cast(float) NUM_PIECES;
    for 0..NUM_PIECES-1 {
        current := it * step;
        x2, y2 := sin(current) * radius + x, cos(current) * radius + y;
        next := current + step;
        x3, y3 := sin(next) * radius + x, cos(next) * radius + y;

        array_add(*arr, make_Vector2(x  + radius, y  + radius));
        array_add(*arr, make_Vector2(x2 + radius, y2 + radius));
        array_add(*arr, make_Vector2(x3 + radius, y3 + radius));
    }

    buf: u32;
    glGenBuffers(1, *buf);
    glBindBuffer(GL_ARRAY_BUFFER, buf);
    glBufferData(GL_ARRAY_BUFFER, arr.count*size_of(Vector2), arr.data, GL_STATIC_DRAW);

    glEnableVertexAttribArray(0);
    glVertexAttrib4f(1, color.r, color.g, color.b, color.a);

    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 0, null);

    glDrawArrays(GL_TRIANGLES, 0, xx arr.count);
    
    glDisableVertexAttribArray(0);
    glDeleteBuffers(1, *buf);

    glDisable(GL_BLEND);
}

draw_line :: (using rdr: GL_Renderer, v1: Vector2, v2: Vector2, color: Color, thickness := 1.0) {
    draw_line(rdr, v1.x, v1.y, v2.x, v2.y, color, thickness);
}

draw_line :: (using rdr: GL_Renderer, x1: float, y1: float, x2: float, y2: float, color: Color, thickness := 1.0) {
    glLineWidth(thickness);

    glUseProgram(render_rect.id);
    update_matrices(rdr, matrix_identity(), render_rect);

    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    arr: [2] Vector2;
    arr[0] = make_Vector2(x1,  y1);
    arr[1] = make_Vector2(x2, y2);


    buf: u32;
    glGenBuffers(1, *buf);
    glBindBuffer(GL_ARRAY_BUFFER, buf);
    glBufferData(GL_ARRAY_BUFFER, arr.count*size_of(Vector2), arr.data, GL_STATIC_DRAW);

    glEnableVertexAttribArray(0);
    glVertexAttrib4f(1, color.r, color.g, color.b, color.a);

    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 0, null);

    glDrawArrays(GL_LINES, 0, xx arr.count);
    
    glDisableVertexAttribArray(0);
    glDeleteBuffers(1, *buf);

    glDisable(GL_BLEND);
}

draw_rect_outline :: (using rdr: GL_Renderer, rect: Rectangle, color: Color) {
    x := rect.x;
    y := rect.y;
    width := rect.width;
    height := rect.height;

    draw_rect(rdr, x, y, width, height, color);
}

draw_rect_outline :: (using rdr: GL_Renderer, x: float, y: float, width: float, height: float, color: Color) {
    glUseProgram(render_rect.id);
    update_matrices(rdr, matrix_identity(), render_rect);

    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    xw := x+width;
    yh := y+height;

    arr: [4] Vector2;
    arr[0] = make_Vector2(x,  y);
    arr[1] = make_Vector2(xw, y);    
    arr[2] = make_Vector2(xw, yh);
    arr[3] = make_Vector2(x, yh);


    buf: u32;
    glGenBuffers(1, *buf);
    glBindBuffer(GL_ARRAY_BUFFER, buf);
    glBufferData(GL_ARRAY_BUFFER, arr.count*size_of(Vector2), arr.data, GL_STATIC_DRAW);

    glEnableVertexAttribArray(0);
    glVertexAttrib4f(1, color.r, color.g, color.b, color.a);

    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 0, null);

    glDrawArrays(GL_LINE_LOOP, 0, xx arr.count);
    
    glDisableVertexAttribArray(0);
    glDeleteBuffers(1, *buf);

    glDisable(GL_BLEND);
}

draw_rect :: (using rdr: GL_Renderer, rect: Rectangle, color: Color) {
    x := rect.x;
    y := rect.y;
    width := rect.width;
    height := rect.height;

    draw_rect(rdr, x, y, width, height, color);
}

draw_rect_multi_color :: (using rdr: GL_Renderer, x: float, y: float, width: float, height: float, left: Color, right: Color, top: Color, bottom: Color) {
    glUseProgram(render_rect.id);
    update_matrices(rdr, matrix_identity(), render_rect);

    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    operator* :: (a: Color, value: float) -> Color {
        o: Color = ---;
        o.r = a.r * value;
        o.g = a.g * value;
        o.b = a.b * value;
        o.a = a.a * value;
        return o;
    }
    operator+ :: (a: Color, b: Color) -> Color {
        o: Color = ---;
        o.r = a.r + b.r;
        o.g = a.g + b.g;
        o.b = a.b + b.b;
        o.a = a.a + b.a;
        return o;
    }
    mix :: (a: Color, b: Color, v := 0.5) -> Color {
        return (a + b) * 0.5;
    }

    // top_left := mix(top, left);
    // bottom_left := mix(bottom, left);
    // top_right := mix(top, right);
    // bottom_right := mix(bottom, right);

    top_left := bottom;
    bottom_left := left;
    top_right := right;
    bottom_right := top;

    xw := x+width;
    yh := y+height;

    Vertex :: struct {
        p: Vector2;
        color: Color;
    }

    arr: [6] Vertex;
    arr[0].p = make_Vector2(xw, yh);    
    arr[1].p = make_Vector2(xw, y);
    arr[2].p = make_Vector2(x,  y);
    arr[3].p = make_Vector2(xw, yh);
    arr[4].p = make_Vector2(x,  y);
    arr[5].p = make_Vector2(x,  yh);

    arr[0].color = top_right;    
    arr[1].color = bottom_right;
    arr[2].color = bottom_left;
    arr[3].color = top_right;
    arr[4].color = bottom_left;
    arr[5].color = top_left;

    // for *arr it.color.a = 1.0; 


    buf: u32;
    glGenBuffers(1, *buf);
    glBindBuffer(GL_ARRAY_BUFFER, buf);
    glBufferData(GL_ARRAY_BUFFER, arr.count*size_of(Vertex), arr.data, GL_STATIC_DRAW);

    glEnableVertexAttribArray(0);
    glEnableVertexAttribArray(1);

    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, size_of(Vertex), null);
    glVertexAttribPointer(1, 4, GL_FLOAT, GL_FALSE, size_of(Vertex), cast(*void) size_of(Vector2));

    glDrawArrays(GL_TRIANGLES, 0, 6);
    
    glDisableVertexAttribArray(0);
    glDisableVertexAttribArray(1);
    glDeleteBuffers(1, *buf);

    glDisable(GL_BLEND);
}

draw_rect :: (using rdr: GL_Renderer, x: float, y: float, width: float, height: float, color: Color, model_matrix: *Matrix4 = null) {
    glUseProgram(render_rect.id);
    if !model_matrix then update_matrices(rdr, matrix_identity(), render_rect);
    else update_matrices(rdr, <<model_matrix, render_rect);

    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    xw := x+width;
    yh := y+height;

    arr: [6] Vector2;
    arr[0] = make_Vector2(xw, yh);    
    arr[1] = make_Vector2(xw, y);
    arr[2] = make_Vector2(x,  y);
    arr[3] = make_Vector2(xw, yh);
    arr[4] = make_Vector2(x,  y);
    arr[5] = make_Vector2(x,  yh);


    buf: u32;
    glGenBuffers(1, *buf);
    glBindBuffer(GL_ARRAY_BUFFER, buf);
    glBufferData(GL_ARRAY_BUFFER, arr.count*size_of(Vector2), arr.data, GL_STATIC_DRAW);

    glEnableVertexAttribArray(0);
    glVertexAttrib4f(1, color.r, color.g, color.b, color.a);

    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 0, null);

    glDrawArrays(GL_TRIANGLES, 0, 6);
    
    glDisableVertexAttribArray(0);
    glDeleteBuffers(1, *buf);

    glDisable(GL_BLEND);
}

draw_textured_rect :: (using rdr: GL_Renderer, tex: *Texture, x: float, y: float, width: float, height: float, shader: *Shader = null, model_matrix: *Matrix4 = null) {
    if tex {
        if !shader then shader = render_plain_texture;

        glUseProgram(shader.id);
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, tex.id);

        in_texture := glGetUniformLocation(shader.id, "in_texture");
        glUniform1i(in_texture, 0);
        if !model_matrix then update_matrices(rdr, matrix_identity(), shader);
        else update_matrices(rdr, <<model_matrix, shader);
    }

    xw := x+width;
    yh := y+height;

    arr: [24] float = {:float:
        -1, -1, 0, 0,
        -1, -1, 1, 0,
        -1, -1, 1, 1,

        -1, -1, 1, 1,
        -1, -1, 0, 1,
        -1, -1, 0, 0,
    };
    arr[0] = x;
    arr[1] = y;
    arr[4] = xw;
    arr[5] = y;
    arr[8] = xw;
    arr[9] = yh;
    arr[12] = xw;
    arr[13] = yh;
    arr[16] = x;
    arr[17] = yh;
    arr[20] = x;
    arr[21] = y;

    buf: u32;
    glGenBuffers(1, *buf);
    glBindBuffer(GL_ARRAY_BUFFER, buf);
    glBufferData(GL_ARRAY_BUFFER, arr.count*size_of(float), arr.data, GL_STATIC_DRAW);

    glEnableVertexAttribArray(0);
    glEnableVertexAttribArray(2);

    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, size_of(float)*4, null);
    glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, size_of(float)*4, cast(*void)(size_of(float)*2));

    glDrawArrays(GL_TRIANGLES, 0, 6);
    
    glDisableVertexAttribArray(0);
    glDisableVertexAttribArray(2);
    glDeleteBuffers(1, *buf);
}

draw_textured_rect :: (using rdr: GL_Renderer, tex: *Texture, rect: Rectangle) {
    draw_textured_rect(rdr, tex, rect.x, rect.y, rect.width, rect.height);
}

draw_sprite :: (sp: Sprite) {
    glBindTexture(GL_TEXTURE_2D, sp.texture.id);

    rect := *sp.dimensions;
    x := rect.x;
    y := rect.y;
    width := rect.width;
    height := rect.height;

    xw := x+width;
    yh := y+height;

    frame := sp.current_frame;
    assert(frame != null);

    tex_coords := *frame.tex_coords;
    tx := tex_coords.x;
    ty := tex_coords.y;
    txw := tx + tex_coords.width;
    tyh := ty + tex_coords.height;
 
    if (frame.flags & BITMAP_FRAME_FLIP_VERTICLE) {
        temp := tx;
        tx = txw;
        txw = temp;
        assert(false);
    }
    if (frame.flags & BITMAP_FRAME_FLIP_HORIZONTAL) {
        temp := ty;
        tx = tyh;
        tyh = temp;
        assert(false);
    }

    // glBegin(GL_QUADS);
    //     glTexCoord2f(tx, tyh);
    //     glVertex2f(x, y);
    //     glTexCoord2f(tx, ty);
    //     glVertex2f(x, yh);
    //     glTexCoord2f(txw, ty);
    //     glVertex2f(xw, yh);
    //     glTexCoord2f(txw, tyh);
    //     glVertex2f(xw, y);
    // glEnd();

    assert(false);
}

create_font :: (font: *Font, bwidth: s16, bheight: s16, data: *void) {
    font.bwidth = bwidth;
    font.bheight = bheight;
    glGenTextures(1, *font.id);
    glBindTexture(GL_TEXTURE_2D, font.id);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_R8, cast(u32) bwidth, cast(u32) bheight, 0, GL_RED, GL_UNSIGNED_BYTE, data);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
}

Temp_Vertex_Array :: struct {
    vertex: Vector2;
    tex_coords: Vector2;
}

make_TVA :: (x: float, y: float, tx: float, ty: float) -> Temp_Vertex_Array {
    tva: Temp_Vertex_Array = ---;
    tva.vertex.x = x;
    tva.vertex.y = y;
    tva.tex_coords.x = tx;
    tva.tex_coords.y = ty;
    return tva;
}

draw_text :: (using rdr: GL_Renderer, font: Font, x: float, y: float, text: string, str_args: .. Any) -> float {
    white := make_Color(1, 1, 1);
    return draw_text(rdr, font, x, y, text, ..str_args, color = white);
}

draw_text :: (using rdr: GL_Renderer, font: Font, x: float, y: float, text: string, str_args: .. Any, color: Color) -> float {
    glUseProgram(rdr.render_text.id);
    update_matrices(rdr, matrix_identity(), render_text);

    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, font.id);
    tex := glGetUniformLocation(render_text.id, "in_texture");
    glUniform1i(tex, 0);

    arr: [..] Temp_Vertex_Array;
    arr.allocator = __temporary_allocator;

    builder: String_Builder;
    print_to_builder(*builder, text, ..str_args);

    text_data: [] u8;
    text_data.count = builder.base_buffer.occupied;
    text_data.data = builder.base_buffer.data.data;
    for c: text_data {
        if (c >= 32 && c < 128) {
            q: stbtt_aligned_quad;
            stbtt_GetBakedQuad(font.cdata.data, font.bwidth, font.bheight, c-32, *x, *y, *q,1);//1=opengl & d3d10+,0=d3d9
            v0 := make_TVA(q.x0,q.y0, q.s0,q.t0);
            v1 := make_TVA(q.x0,q.y1, q.s0,q.t1);
            v2 := make_TVA(q.x1,q.y1, q.s1,q.t1);
            v3 := make_TVA(q.x1,q.y0, q.s1,q.t0);
            add_quad_reverse(*arr, v0, v1, v2, v3);
        }
    }

    buf: u32;
    glGenBuffers(1, *buf);
    glBindBuffer(GL_ARRAY_BUFFER, buf);
    glBufferData(GL_ARRAY_BUFFER, arr.count*size_of(Temp_Vertex_Array), arr.data, GL_STATIC_DRAW);

    glEnableVertexAttribArray(0);
    glEnableVertexAttribArray(1);
    glVertexAttrib4f(2, color.r, color.g, color.b, color.a);

    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, size_of(Temp_Vertex_Array), null);
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, size_of(Temp_Vertex_Array), cast(*void) size_of(Vector2));

    glDrawArrays(GL_TRIANGLES, 0, xx arr.count);
    
    glDisableVertexAttribArray(0);
    glDisableVertexAttribArray(1);
    glDeleteBuffers(1, *buf);

    glDisable(GL_BLEND);

    return x;
}

start_scene :: (using rdr: *GL_Renderer) {
    use_viewport(gbuffer_viewport);
    disable_scissor();
    glBindFramebuffer(GL_FRAMEBUFFER, gbuffer_framebuffer);
    clear_screen(0, 0, 0, 1);

    glUseProgram(render_to_gbuffer.id);

    pos := camera.position;
    view_matrix = matrix_rotate(inverse(camera.rotation)) * matrix_translate(-pos.x, -pos.y, -pos.z);
}

finish_scene :: (using rdr: *GL_Renderer) {
    use_frame_buffer(rdr, current_frame_buffer);
    if current_frame_buffer enable_scissor(current_frame_buffer.viewport);
    else disable_scissor();
    
    clear_screen(0, 0, 0, 1);
    glBindFramebuffer(GL_READ_FRAMEBUFFER, gbuffer_framebuffer);
    assert(current_frame_buffer != null);
    if !current_frame_buffer then glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0);
    else glBindFramebuffer(GL_DRAW_FRAMEBUFFER, current_frame_buffer.id);

    src_vp := gbuffer_viewport;
    dst_vp := make_Viewport(0, 0, game.window.width, game.window.height);
    if current_frame_buffer then dst_vp = current_frame_buffer.viewport;

    glBlitFramebuffer(xx src_vp.x, xx src_vp.y, xx src_vp.w, xx src_vp.h,
            xx dst_vp.x, xx dst_vp.y, xx dst_vp.w, xx dst_vp.h,
            GL_DEPTH_BUFFER_BIT, GL_NEAREST);
    glBindFramebuffer(GL_READ_FRAMEBUFFER, 0);
    glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0);
    use_frame_buffer(rdr, current_frame_buffer);

    glUseProgram(null_shader.id);
    glClear(GL_STENCIL_BUFFER_BIT);
    glDepthMask(GL_FALSE);

    glDisable(GL_CULL_FACE);
    glEnable(GL_STENCIL_TEST);
    glStencilFunc(GL_ALWAYS, 0, 0);
    glStencilOpSeparate(GL_BACK, GL_KEEP, GL_INCR_WRAP, GL_KEEP);

    glEnable(GL_DEPTH_TEST);
    glStencilOpSeparate(GL_FRONT, GL_KEEP, GL_DECR_WRAP, GL_KEEP);

    // render lights stencils
    for lights {
        if it.type == Light_Type.DIRECTIONAL {

        } else {
            model_matrix := light_sphere.model_matrix;
            light_sphere.model_matrix = matrix_translate(it.position.x, it.position.y, it.position.z) * matrix_scale(it.radius, it.radius, it.radius);
            draw_model(rdr, <<light_sphere, null_shader);
            light_sphere.model_matrix = model_matrix;
        }
    }

    glEnable(GL_CULL_FACE);
    glCullFace(GL_BACK);
    glDisable(GL_STENCIL_TEST);
    // simple global ambient contribution

    glDisable(GL_DEPTH_TEST);

    /*
    UseShader(AmbientBaseShader);
    RenderQuad(-1, -1, 2, 2);
    */

    glEnable(GL_STENCIL_TEST);
    glCullFace(GL_FRONT);
    glStencilFunc(GL_NOTEQUAL, 0, 0xFF);

    glEnable(GL_BLEND);
    glBlendEquation(GL_FUNC_ADD);
    glBlendFunc(GL_ONE, GL_ONE);

    // forward render the actual lights

    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, gbuffer_normal);
    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, gbuffer_albedo_spec);
    
    glActiveTexture(GL_TEXTURE3);
    glBindTexture(GL_TEXTURE_2D, gbuffer_roughness);
    glActiveTexture(GL_TEXTURE4);
    glBindTexture(GL_TEXTURE_2D, gbuffer_metallic);
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, gbuffer_position);

    glUseProgram(render_light_using_gbuffer.id);
    proj := glGetUniformLocation(render_light_using_gbuffer.id, "projection");
    tex_normal := glGetUniformLocation(render_light_using_gbuffer.id, "g_normal");
    tex_pos := glGetUniformLocation(render_light_using_gbuffer.id, "g_position");
    tex_albedo := glGetUniformLocation(render_light_using_gbuffer.id, "g_albedospec");
    tex_roughness := glGetUniformLocation(render_light_using_gbuffer.id, "g_roughness");
    tex_metallic := glGetUniformLocation(render_light_using_gbuffer.id, "g_metallic");
    vp := glGetUniformLocation(render_light_using_gbuffer.id, "viewport");

    light_is_directional     := glGetUniformLocation(render_light_using_gbuffer.id, "light.is_directional");
    light_position_direction := glGetUniformLocation(render_light_using_gbuffer.id, "light.position");
    light_radius             := glGetUniformLocation(render_light_using_gbuffer.id, "light.radius");
    light_radiance_color     := glGetUniformLocation(render_light_using_gbuffer.id, "light.radiance_color");

    assert(tex_normal != -1);
    glUniformMatrix4fv(proj, 1, GL_TRUE, projection_matrix.flat.data);
    glUniform1i(tex_pos, 0);
    glUniform1i(tex_normal, 1);
    glUniform1i(tex_albedo, 2);
    glUniform1i(tex_roughness, 3);
    glUniform1i(tex_metallic, 4);
    glUniform4f(vp, cast(float) dst_vp.x, cast(float) dst_vp.y, cast(float) dst_vp.w, cast(float) dst_vp.h);

    // render lights directly
    for lights {
         if it.type == Light_Type.DIRECTIONAL {

        } else {
            model_matrix := light_sphere.model_matrix;
            
            glUniform1i(light_is_directional, 0);
            glUniform3f(light_position_direction, it.position.x, it.position.y, it.position.z);
            glUniform3f(light_radiance_color,     it.radiance.r, it.radiance.g, it.radiance.b);
            glUniform1f(light_radius,             it.radius);
            
            light_sphere.model_matrix = matrix_translate(it.position.x, it.position.y, it.position.z) * matrix_scale(it.radius, it.radius, it.radius);
            draw_model(rdr, <<light_sphere, render_light_using_gbuffer);

            light_sphere.model_matrix = model_matrix;
        }
    }

    // glUseProgram(0);

    disable_scissor();

    glDisable(GL_STENCIL_TEST);
    glDepthMask(GL_TRUE);
    glCullFace(GL_BACK);
    glDisable(GL_BLEND);

    #if DEVELOPER {
        for lights {
            if it.type == Light_Type.DIRECTIONAL {
                // @TODO
            } else {
                mat := matrix_translate(it.position.x, it.position.y, it.position.z) * matrix_rotate((camera.rotation)) * matrix_scale(1, -1, 1);
                // draw_textured_rect(rdr, null, it.position.x, it.position.y, 1.0, 1.0, null, *mat);
                white := make_Color(1, 1, 1);
                // glDisable(GL_DEPTH_TEST);
                glDisable(GL_CULL_FACE);
                glEnable(GL_BLEND);
                glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
                draw_textured_rect(<<rdr, rdr.light_entity_texture, -0.5, -0.5, 1.0, 1.0, null, *mat);

                glDisable(GL_BLEND);
                glEnable(GL_CULL_FACE);
            }
        }
    }
}

draw_cube :: (x: float, y: float, z: float, size: float) {

    glEnable(GL_DEPTH_TEST);

    t := matrix_translate(x, y, z);

    hs := size/2.0;
    // glBegin(GL_QUADS);
    //     glNormal3f(0, 0, 1);
    //     glVertex3f(-hs, hs, hs);
    //     glVertex3f(-hs,-hs, hs);
    //     glVertex3f( hs,-hs, hs);
    //     glVertex3f( hs, hs, hs);

    //     glNormal3f(-1, 0, 0);
    //     glVertex3f(-hs, hs,-hs);
    //     glVertex3f(-hs,-hs,-hs);
    //     glVertex3f(-hs,-hs, hs);
    //     glVertex3f(-hs, hs, hs);

    //     glNormal3f(0, 0, -1);
    //     glVertex3f( hs, hs,-hs);
    //     glVertex3f( hs,-hs,-hs);
    //     glVertex3f(-hs,-hs,-hs);
    //     glVertex3f(-hs, hs,-hs);

    //     glNormal3f(1, 0, 0);
    //     glVertex3f( hs, hs, hs);
    //     glVertex3f( hs,-hs, hs);
    //     glVertex3f( hs,-hs,-hs);
    //     glVertex3f( hs, hs,-hs);

    //     glNormal3f(0, 1, 0);
    //     glVertex3f(-hs, hs,-hs);
    //     glVertex3f(-hs, hs, hs);
    //     glVertex3f( hs, hs, hs);
    //     glVertex3f( hs, hs,-hs);

    //     glNormal3f(0, -1, 0);
    //     glVertex3f( hs,-hs,-hs);
    //     glVertex3f( hs,-hs, hs);
    //     glVertex3f(-hs,-hs, hs);
    //     glVertex3f(-hs,-hs,-hs);

    // glEnd();

    glDisable(GL_DEPTH_TEST);
    assert(false);
}

update_matrices :: (using rdr: GL_Renderer, model_matrix: Matrix4, sh: *Shader) {
    proj := glGetUniformLocation(sh.id, "projection");
    view := glGetUniformLocation(sh.id, "view");
    model := glGetUniformLocation(sh.id, "model");
    glUniformMatrix4fv(proj, 1, GL_TRUE, projection_matrix.flat.data);
    glUniformMatrix4fv(view, 1, GL_TRUE, view_matrix.flat.data);

    t := current_model_matrix(rdr) * model_matrix;
    glUniformMatrix4fv(model, 1, GL_TRUE, t.flat.data);
}

draw_mesh :: (using rdr: GL_Renderer, m: Mesh, shader: *Shader = null) {
    if !shader then shader = render_to_gbuffer;
    glUseProgram(shader.id);

    update_matrices(rdr, m.model_matrix, shader);

    // @Cleanup not used in render_to_gbuffer ??
    viewer_pos := glGetUniformLocation(shader.id, "camera_position");
    glUniform3f(viewer_pos, camera.position.x, camera.position.y, camera.position.z);

    // material
    mat_diffuse := glGetUniformLocation(shader.id, "material.diffuse");
    use_diffuse_map := glGetUniformLocation(shader.id, "use_diffuse_map");
    use_normal_map := glGetUniformLocation(shader.id, "use_normal_map");
    diffuse_map := glGetUniformLocation(shader.id, "diffuse_map");
    normal_map := glGetUniformLocation(shader.id, "normal_map");
    mat_roughness := glGetUniformLocation(shader.id, "material.roughness");
    mat_metallic  := glGetUniformLocation(shader.id, "material.metallic");

    assert(m.material != null);

    mat := m.material;

    if mat.disable_backface_culling then glDisable(GL_CULL_FACE);
    defer if mat.disable_backface_culling then glEnable(GL_CULL_FACE);

    if !mat.disable_depth_test then glEnable(GL_DEPTH_TEST);

    diffuse_tex :=  mat.textures[TEXTURE_DIFFUSE_INDEX];
    normal_tex := mat.textures[TEXTURE_NORMAL_INDEX];

    glUniform1i(use_diffuse_map, xx (diffuse_tex != null));
    if (diffuse_tex) {
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, diffuse_tex.id);
        glUniform1i(diffuse_map, 0);
    }

    glUniform1i(use_normal_map, xx (normal_tex != null));
    if (normal_tex) {
        glActiveTexture(GL_TEXTURE1);
        glBindTexture(GL_TEXTURE_2D, normal_tex.id);
        glUniform1i(normal_map, 1);
    }

    if rdr.enable_clip_plane {
        glEnable(GL_CLIP_DISTANCE0);
        cp := glGetUniformLocation(shader.id, "clip_plane");
        glUniform4f(cp, clip_plane.x, clip_plane.y, clip_plane.z, clip_plane.w);
    }

    glActiveTexture(GL_TEXTURE0);

    diffuse := *mat.diffuse;
    glUniform3f(mat_diffuse, diffuse.r, diffuse.g, diffuse.b);
    glUniform1f(mat_roughness, mat.roughness);
    glUniform1f(mat_metallic,  mat.metallic);

    glBindBuffer(GL_ARRAY_BUFFER, m.buffer_id);

    vertex_size := m.vertices.count * size_of(Vector3);
    normal_size := m.normals.count * size_of(Vector3);
    tex_size    := m.tex_coords.count * size_of(Vector2);
    tangent_size := m.tangent_normals.count * size_of(Vector3);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, cast(*void) 0);
    
    if (tex_size && (diffuse_tex || normal_tex)) {
        glEnableVertexAttribArray(2);
        glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, 0, cast(*void) (vertex_size+normal_size));
    }

    if !mat.disable_lighting {
        if m.normals.count {
            glEnableVertexAttribArray(1);
            glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 0, cast(*void) vertex_size);
        } else {
            glVertexAttrib3f(1, 0, 0, 0);
        }

        if (normal_tex) {
            glEnableVertexAttribArray(3);
            glVertexAttribPointer(3, 3, GL_FLOAT, GL_FALSE, 0, cast(*void) (vertex_size+normal_size+tex_size));
        }
    }

    if m.colors.count && !mat.disable_vertex_colors {
        glEnableVertexAttribArray(4);
        glVertexAttribPointer(4, 4, GL_FLOAT, GL_FALSE, 0, cast(*void) (vertex_size+normal_size+tex_size+tangent_size));
    } else {
        glVertexAttrib3f(4, 1, 1, 1); // this will just get multiplied by the material color
    }

    prim_type: GLenum;

    if m.primitive_type == {
        case Primitive_Type.TRIANGLES;
            prim_type = GL_TRIANGLES;
        case Primitive_Type.POINTS;
            prim_type = GL_POINTS;
        case Primitive_Type.LINES;
            prim_type = GL_LINES;
    }

    if prim_type == GL_TRIANGLES {
        glEnable(GL_POLYGON_OFFSET_FILL);
        glPolygonOffset(1, -1);
    }

    if m.indices.count {
        assert(m.element_buffer_id != 0);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, m.element_buffer_id);
        glDrawElements(prim_type, xx m.indices.count, GL_UNSIGNED_SHORT /* @Volatile must match m.indices type*/, null);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    }
    else glDrawArrays(prim_type, 0, xx m.vertices.count);

    if prim_type == GL_TRIANGLES {
        glDisable(GL_POLYGON_OFFSET_FILL);
    }

    glDisableVertexAttribArray(0);
    glDisableVertexAttribArray(1);
    
    if (tex_size) glDisableVertexAttribArray(2);
    if (normal_tex) glDisableVertexAttribArray(3);
    if m.colors.count glDisableVertexAttribArray(4);

    glDisable(GL_DEPTH_TEST);

    if rdr.enable_clip_plane {
        glDisable(GL_CLIP_DISTANCE0);
    }
}

draw_water :: (using rdr: GL_Renderer, dudv_texture: *Texture, water_height: float) {
    reflect_texture := water_reflect_frame_buffer.color_texture;
    refract_texture := water_refract_frame_buffer.color_texture;
    glEnable(GL_DEPTH_TEST);
    glUseProgram(render_water.id);

    // model_matrix := matrix_translate(0, water_height, 0);
    model_matrix: Matrix4;

    update_matrices(rdr, model_matrix, render_water);

    reflect_id := glGetUniformLocation(render_water.id, "reflect_texture");
    refract_id := glGetUniformLocation(render_water.id, "refract_texture");
    dudv_id := glGetUniformLocation(render_water.id, "dudv_texture");
    offset_id := glGetUniformLocation(render_water.id, "distort_offset");
    viewer_pos := glGetUniformLocation(render_water.id, "camera_position");
    glUniform3f(viewer_pos, camera.position.x, camera.position.y, camera.position.z);

    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, reflect_texture.id);
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, refract_texture.id);
    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, dudv_texture.id);
    glActiveTexture(GL_TEXTURE0);

    glUniform1i(reflect_id, 0);
    glUniform1i(refract_id, 1);
    glUniform1i(dudv_id, 2);
    glUniform1f(offset_id, water_distort_offset);

    // @TODO specify water height through uniform or vertex attrib

    x := -9.0;
    y := -4.0; // z
    width := 8;
    height := 8;
    xw := x+width;
    yh := y+height;

    arr: [..] Temp_Vertex_Array;
    arr.allocator = __temporary_allocator;
    v0 := make_TVA(x, y, 0, 0);
    v1 := make_TVA(xw, y, 1, 0);
    v2 := make_TVA(xw, yh, 1, 1);
    v3 := make_TVA(x, yh, 0, 1);
    add_quad(*arr, v0, v1, v2, v3);

    glEnable(GL_POLYGON_OFFSET_FILL);
    glPolygonOffset(1, -1);

    buf: u32;
    glGenBuffers(1, *buf);
    glBindBuffer(GL_ARRAY_BUFFER, buf);
    glBufferData(GL_ARRAY_BUFFER, arr.count*size_of(Temp_Vertex_Array), arr.data, GL_STATIC_DRAW);

    glEnableVertexAttribArray(0);
    glEnableVertexAttribArray(1);
    glVertexAttrib3f(2, 1.0, 1.0, 1.0);

    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, size_of(Temp_Vertex_Array), null);
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, size_of(Temp_Vertex_Array), cast(*void) size_of(Vector2));

    glDrawArrays(GL_TRIANGLES, 0, xx arr.count);
    
    glDisableVertexAttribArray(0);
    glDisableVertexAttribArray(1);  

    glDisable(GL_DEPTH_TEST);

    glDeleteBuffers(1, *buf);
}

set_viewport :: (fb: *Frame_Buffer, v: Viewport) {
    fb.viewport = v;
}

use_viewport :: (v: Viewport) {
    glViewport(v.x, v.y, v.w, v.h);
    assert(v.w > 0 && v.h > 0);
}

#if DEVELOPER {
    draw_picking_model :: (rdr: *GL_Renderer, m: Model, pick_id: s32 = -1) {
        push_model_matrix(rdr, m.model_matrix);
        for m.meshes {
            if m.draw_mode == {
                case DRAW_MODE_SOLID_AND_WIREFRAME; #through;
                case DRAW_MODE_SOLID; draw_picking_mesh(<<rdr, << it, rdr.picking_shader, pick_id);
                // case DRAW_MODE_WIREFRAME; draw_mesh_wireframe(<<rdr, << it);
            }
        }
        pop_model_matrix(rdr);
    }


    draw_picking_mesh :: (using rdr: GL_Renderer, m: Mesh, sh: *Shader, pick_id: s32 = -1) {
        glEnable(GL_DEPTH_TEST);

        update_matrices(rdr, m.model_matrix, sh);
        glBindBuffer(GL_ARRAY_BUFFER, m.buffer_id);

        vertex_size := m.vertices.count * size_of(Vector3);
        normal_size := m.normals.count * size_of(Vector3);
        tex_size    := m.tex_coords.count * size_of(Vector2);
        tangent_size := m.tangent_normals.count * size_of(Vector3);
        color_size := m.colors.count * size_of(Color);
        glEnableVertexAttribArray(0);
        glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, cast(*void) 0);
        glVertexAttribI1i(1, pick_id);

        assert(m.primitive_type == Primitive_Type.TRIANGLES);
        if m.indices.count {
            assert(m.element_buffer_id != 0);
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, m.element_buffer_id);
            glDrawElements(GL_TRIANGLES, xx m.indices.count, GL_UNSIGNED_SHORT /* @Volatile must match m.indices type*/, null);
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
        }
        else glDrawArrays(GL_TRIANGLES, 0, xx m.vertices.count);

        glDisableVertexAttribArray(0);

        glDisable(GL_DEPTH_TEST);
    }

    start_picking :: (using rdr: *GL_Renderer) {
        glBindFramebuffer(GL_FRAMEBUFFER, picking_framebuffer);
        glClearColor(1, 0, 0, 0);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        value: GLint = -1;
        glClearBufferiv(GL_COLOR, 0, *value);

        pos := camera.position;
        view_matrix = matrix_rotate(inverse(camera.rotation)) * matrix_translate(-pos.x, -pos.y, -pos.z);
        glUseProgram(picking_shader.id);
    }

    finish_picking :: (using rdr: *GL_Renderer) {
        use_frame_buffer(rdr, current_frame_buffer);
        glUseProgram(0);
    }

    get_picking_position_data :: (using rdr: GL_Renderer, data: *s32) {
        glBindTexture(GL_TEXTURE_2D, picking_pos_texture);
        glGetTexImage(GL_TEXTURE_2D, 0, GL_RED_INTEGER, GL_INT, data);
    }
} // DEVELOPER

draw_mesh_wireframe :: (rdr: GL_Renderer, m: Mesh) {
    glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
    draw_mesh(rdr, m);
    glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
}

store_mesh_in_buffer :: (m: *Mesh, dynamic := false, update_vertices := true, update_normals := true, update_others := true) {
    vertex_size := m.vertices.count * size_of(Vector3);
    normal_size := m.normals.count * size_of(Vector3);
    tex_size    := m.tex_coords.count * size_of(Vector2);
    tangent_size := m.tangent_normals.count * size_of(Vector3);
    color_size := m.colors.count * size_of(Color);
    total_size := vertex_size + tex_size + normal_size + tangent_size + color_size;

    if !m.buffer_id {
        glGenBuffers(1, *m.buffer_id);
    }

    glBindBuffer(GL_ARRAY_BUFFER, m.buffer_id);
    if total_size > m.buffer_size {
        if m.buffer_size {
            print("resizing buffer: %\n", total_size);
        }
        m.buffer_size = total_size;
        if dynamic glBufferData(GL_ARRAY_BUFFER, total_size, null, GL_DYNAMIC_DRAW);
        else glBufferData(GL_ARRAY_BUFFER, total_size, null, GL_STATIC_DRAW);
    }

    ptr := glMapBuffer(GL_ARRAY_BUFFER, GL_WRITE_ONLY);

    if update_vertices memcpy(ptr+(0), m.vertices.data, vertex_size);
    if update_normals memcpy(ptr+(vertex_size), m.normals.data, normal_size);

    if update_others {
        memcpy(ptr+(vertex_size+normal_size), m.tex_coords.data, tex_size);
        memcpy(ptr+(vertex_size+normal_size+tex_size), m.tangent_normals.data, tangent_size);
        memcpy(ptr+(vertex_size+normal_size+tex_size+tangent_size), m.colors.data, color_size);
    }

    glUnmapBuffer(GL_ARRAY_BUFFER);

    if !m.indices.count return;

    if !m.element_buffer_id {
        glGenBuffers(1, *m.element_buffer_id);
    }
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, m.element_buffer_id);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, xx m.indices.count * size_of(u16), m.indices.data, GL_STATIC_DRAW);
}

draw_model :: (rdr: *GL_Renderer, m: Model, shader: *Shader = null) {
    push_model_matrix(rdr, m.model_matrix);
    for m.meshes {
        if m.draw_mode == {
            case DRAW_MODE_SOLID; draw_mesh(<<rdr, << it, shader);
            case DRAW_MODE_SOLID_AND_WIREFRAME;
                draw_mesh(<<rdr, << it, shader);
                #through;
            case DRAW_MODE_WIREFRAME;
                mat := it.material;
                defer it.material = mat;

                it.material = rdr.wireframe_material;
                draw_mesh_wireframe(<<rdr, << it);
        }
    }
    pop_model_matrix(rdr);
}

get_sphere_vertex :: (theta: float, phi: float) -> Vector3 {
    v: Vector3 = ---;
    v.x = sin(theta * PI * 2) * cos(phi * TAU);
    v.z = cos(theta * PI * 2);
    v.y = sin(theta * PI * 2) * sin(phi * TAU);
    return v;
}

create_sphere :: (radius: float, latitude_slices: int, longitude_slices: int) -> *Model {
    return create_capsule(radius, latitude_slices, longitude_slices, 0);
}

create_capsule :: (radius: float, latitude_slices: int, longitude_slices: int, length: float = 1.0) -> *Model {
    mod := New(Model);
    m := New(Mesh);
    array_add(*mod.meshes, m);

    xstep: float = 1.0 / cast(float) longitude_slices;
    ystep := (1.0 / cast(float) latitude_slices) / 2;
    half_height := length / 2.0;

    for xa: 0..(longitude_slices/2)-1 {
        theta: float = cast(float) xa * xstep;

        for ya: 0..latitude_slices-1 {
            phi: float = cast(float) ya * ystep;
            v0 := get_sphere_vertex(theta,         phi);
            v1 := get_sphere_vertex(theta + xstep, phi);
            v2 := get_sphere_vertex(theta + xstep, phi + ystep);
            v3 := get_sphere_vertex(theta,         phi + ystep);

            v0.y += half_height;
            v1.y += half_height;
            v2.y += half_height;
            v3.y += half_height;

            array_add(*m.vertices, v0);
            array_add(*m.normals, normalize(v0));
            array_add(*m.vertices, v1);
            array_add(*m.normals, normalize(v1));
            array_add(*m.vertices, v2);
            array_add(*m.normals, normalize(v2));

            array_add(*m.vertices, v0);
            array_add(*m.normals, normalize(v0));
            array_add(*m.vertices, v2);
            array_add(*m.normals, normalize(v2));
            array_add(*m.vertices, v3);
            array_add(*m.normals, normalize(v3));
        }
    }

    if length > 0 {
        for xa: 0..longitude_slices-1 {
            theta: float = cast(float) xa * xstep;

            v0 := get_sphere_vertex(theta,         0);
            v1 := get_sphere_vertex(theta + xstep, 0);
            v2 := v1;
            v3 := v0;

            v0.y -= half_height;
            v1.y -= half_height;
            v2.y += half_height;
            v3.y += half_height;

            array_add(*m.vertices, v0);
            array_add(*m.normals, normalize(v0));
            array_add(*m.vertices, v1);
            array_add(*m.normals, normalize(v1));
            array_add(*m.vertices, v2);
            array_add(*m.normals, normalize(v2));

            array_add(*m.vertices, v0);
            array_add(*m.normals, normalize(v0));
            array_add(*m.vertices, v2);
            array_add(*m.normals, normalize(v2));
            array_add(*m.vertices, v3);
            array_add(*m.normals, normalize(v3));
        }
    }

    for xa: (longitude_slices/2)..longitude_slices-1 {
        theta: float = cast(float) xa * xstep;

        for ya: 0..latitude_slices-1 {
            phi: float = cast(float) ya * ystep;
            v0 := get_sphere_vertex(theta,         phi);
            v1 := get_sphere_vertex(theta + xstep, phi);
            v2 := get_sphere_vertex(theta + xstep, phi + ystep);
            v3 := get_sphere_vertex(theta,         phi + ystep);

            v0.y -= half_height;
            v1.y -= half_height;
            v2.y -= half_height;
            v3.y -= half_height;

            array_add(*m.vertices, v2);
            array_add(*m.normals, normalize(v2));
            array_add(*m.vertices, v1);
            array_add(*m.normals, normalize(v1));
            array_add(*m.vertices, v0);
            array_add(*m.normals, normalize(v0));

            array_add(*m.vertices, v3);
            array_add(*m.normals, normalize(v3));
            array_add(*m.vertices, v2);
            array_add(*m.normals, normalize(v2));
            array_add(*m.vertices, v0);
            array_add(*m.normals, normalize(v0));
        }
    }

    for * m.vertices {
        <<it *= radius;
    }

    store_mesh_in_buffer(m);
    return mod;
}

set_point_size :: (using rdr: GL_Renderer, size: float) {
    glPointSize(size);
}

Height_Map :: struct {
    map: [..] float;
    vertices: [..] Vector3;
    width: int;
    height: int;
}

height_lookup :: inline (map: Height_Map, x: int, y: int) -> float {
    assert(x >= 0 && x < map.width);
    assert(y >= 0 && y < map.height);
    return map.map[y * map.width + x];
}

add_quad :: (arr: *[..] $T, v0: T, v1: T, v2: T, v3: T) {
    array_add(arr, v2);
    array_add(arr, v1);
    array_add(arr, v0);

    array_add(arr, v3);
    array_add(arr, v2);
    array_add(arr, v0);
}

add_quad_reverse :: (arr: *[..] $T, v0: T, v1: T, v2: T, v3: T) {
    array_add(arr, v0);
    array_add(arr, v1);
    array_add(arr, v2);

    array_add(arr, v0);
    array_add(arr, v2);
    array_add(arr, v3);
}

generate_heightmap_vertex_data :: (map: *Height_Map) {
    for y: 0..map.height-1 {
        for x: 0..map.width-1 {
            v0 := make_Vector3(xx x, height_lookup(<<map, x, y), xx y);
            array_add(*map.vertices, v0);
        }
    }
}

generate_terrain_mesh :: (map: Height_Map, m: *Mesh) {
    width := map.width;
    height := map.height;

    reset_mesh_arrays(m);
    m.vertices = map.vertices;

    array_reserve(*m.normals, map.vertices.count);

    for y: 0..height-1 {
        for x: 0..width-1 {
            normal: Vector3 = make_Vector3(0, 1, 0);

            if x > 0 && x < width-1 && y > 0 && y < height-1 {
                in0 := x + y * width;
                in1 := x + (y+1) * width;
                in2 := x + (y-1) * width;
                v0 := map.vertices[in0];
                e1 := normalize(map.vertices[in0 - 1] - v0);
                e2 := normalize(map.vertices[in1] - v0);
                e3 := normalize(map.vertices[in0 + 1] - v0);
                e4 := normalize(map.vertices[in2] - v0);

                n12 := (cross(e1, e2));
                n23 := (cross(e2, e3));
                n34 := (cross(e3, e4));
                n41 := (cross(e4, e1));

                normal = normalize(n12 + n23 + n34 + n41);
            }
            array_add(*m.normals, normal);
        }
    }

    update_others := false;
    // we shouldn't have to update the indices because the triangles never change, just their vertex positions do
    if !m.indices.count {
        update_others = true;

        add_quad_index :: (arr: *[..] $T, i: T) {
            array_add(arr, i);
            array_add(arr, i);
            array_add(arr, i);

            array_add(arr, i);
            array_add(arr, i);
            array_add(arr, i);
        }

        for y: 0..height-2 {
            for x: 0..width-2 {
                in0: u16 = xx (y * width + x);
                in1: u16 = xx (y * width + (x + 1));
                in2: u16 = xx ((y + 1) * width + (x + 1));
                in3: u16 = xx ((y + 1) * width + x);

                add_quad(*m.indices, in0, in1, in2, in3);
            }
        }
    }

    if !m.tex_coords.count {
        update_others = true;

        w := cast(float) (width - 1);
        h := cast(float) (height - 1);

        for y: 0..height-1 {
            for x: 0..width-1 {
                array_add(*m.tex_coords, make_Vector2(cast(float) x / w, cast(float) y / h));
            }
        }
    }

    #if DEVELOPER {
        if !m.map_position.count {
            update_others = true;

            for y: 0..height-1 {
                for x: 0..width-1 {
                    array_add(*m.map_position, make_Vector2(cast(float) x, cast(float) y));
                }
            }
        }
    }

    store_mesh_in_buffer(m, true, true, true, update_others);
}

generate_terrain_mesh :: (map: Height_Map) -> Mesh {
    m: Mesh;
    generate_terrain_mesh(map, *m);

    mat := New(Material);
    mat.diffuse = make_Color(1, 1, 1);
    m.material = mat;
    return m;
}

generate_terrain_line_mesh :: (map: Height_Map, m: *Mesh) {
    width := map.width;
    height := map.height;

    reset_mesh_arrays(m);
    m.vertices = map.vertices;

    if !m.indices.count {

        for y: 0..height-2 {
            for x: 0..width-2 {
                in0: u16 = xx (y * width + x);
                in1: u16 = xx (y * width + (x + 1));
                in2: u16 = xx ((y + 1) * width + (x + 1));
                in3: u16 = xx ((y + 1) * width + x);

                array_add(*m.indices, in0);
                array_add(*m.indices, in1);

                array_add(*m.indices, in3);
                array_add(*m.indices, in0);
            }
        }
    }

    store_mesh_in_buffer(m, true, true, false, false);
}

generate_terrain_line_mesh :: (map: Height_Map) -> Mesh {
    m: Mesh;
    m.primitive_type = Primitive_Type.LINES;
    generate_terrain_line_mesh(map, *m);

    mat := New(Material);
    mat.diffuse = make_Color(1, 1, 1);
    m.material = mat;
    return m;
}