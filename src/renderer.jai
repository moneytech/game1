
#load "stb.jai";
#load "math.jai";
#import "GL";

#scope_file
using gl_30_api;
#scope_export

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
    bwidth: s16;
    bheight: s16;
    cdata: [96] stbtt_bakedchar; // ASCII 32..126 is 95 glyphs
};

font_get_length :: (using font: *Font, str: string) -> float {
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
};

make_Color :: (r: float, g: float, b: float) -> Color {
    c: Color = ---;
    c.r = r;
    c.g = g;
    c.b = b;
    return c;
}

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

Shader :: struct {
    id: u32;

    // for hot reloading
    vert_path: string;
    frag_path: string;
};

Camera :: struct {
    position: Vector3;
    rotation: Quaternion;
};

GL_Renderer :: struct {
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

    camera: Camera;
    projection_matrix: Matrix4;
    view_matrix: Matrix4;
}


debug_callback :: (source: GLenum, type: GLenum, id: GLuint, severity: GLenum, length: GLsizei, message: *u8, userParam: *void) #c_callback {
    print("DEBUG:%\n", point_at_c_string(message));
}

init :: (using rdr: *GL_Renderer, screen_width: u32, screen_height: u32) {
    glDebugMessageCallback(debug_callback, null);

    // @Temporary
    // @Temporary
    // @Temporary
    // @Temporary
    // @Temporary
    VertexArrayID: GLuint;
    glGenVertexArrays(1, *VertexArrayID);
    glBindVertexArray(VertexArrayID);

    glGenFramebuffers(1, *gbuffer_framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, gbuffer_framebuffer);

    glGenTextures(1, *gbuffer_position);
    glGenTextures(1, *gbuffer_normal);
    glGenTextures(1, *gbuffer_albedo_spec);

    glBindTexture(GL_TEXTURE_2D, gbuffer_position);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB16F, xx screen_width, xx screen_height, 0, GL_RGB, GL_FLOAT, null);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, gbuffer_position, 0);

    glBindTexture(GL_TEXTURE_2D, gbuffer_normal);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB16F, xx screen_width, xx screen_height, 0, GL_RGB, GL_FLOAT, null);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT1, GL_TEXTURE_2D, gbuffer_normal, 0);

    glBindTexture(GL_TEXTURE_2D, gbuffer_albedo_spec);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, xx screen_width, xx screen_height, 0, GL_RGBA, GL_UNSIGNED_BYTE, null);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT2, GL_TEXTURE_2D, gbuffer_albedo_spec, 0);

    attach: [3] u32 = {:u32: GL_COLOR_ATTACHMENT0, GL_COLOR_ATTACHMENT1, GL_COLOR_ATTACHMENT2 };
    glDrawBuffers(3, attach.data);

    glGenRenderbuffers(1, *gbuffer_depth);
    glBindRenderbuffer(GL_RENDERBUFFER, gbuffer_depth);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT, screen_width, screen_height);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, gbuffer_depth);

    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) assert(false);

    glBindFramebuffer(GL_FRAMEBUFFER, 0);
}

create_texture :: (tex: *Texture, width: u16, height: u16, data: *void) {
    texId: GLuint;
    glGenTextures(1, *texId);
    glBindTexture(GL_TEXTURE_2D, texId);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR); // Linear Filtering
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR); // Linear Filtering
    tex.width = width;
    tex.height = height;
    tex.id = texId;
}

delete_texture :: (tex: *Texture) {
    glDeleteTextures(1, *tex.id);
    tex.id = 0;
}

compile_shader :: (type: GLenum, source: string) -> u32 {
    v := glCreateShader(type);
    length: GLint = xx source.count;
    glShaderSource(v, 1, *source.data, *length);
    glCompileShader(v);

    status: GLint;
    glGetShaderiv(v, GL_COMPILE_STATUS, *status);
    if (status == GL_FALSE) {
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
    if (status == GL_FALSE) {
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
}

draw_rect :: (rect: Rectangle) {
    x := rect.x;
    y := rect.y;
    width := rect.width;
    height := rect.height;

    draw_rect(x, y, width, height);
}

draw_rect :: (x: float, y: float, width: float, height: float) {
    xw := x+width;
    yh := y+height;
    // glBegin(GL_QUADS);
    //     glVertex2f(x, y);
    //     glVertex2f(x, yh);
    //     glVertex2f(xw, yh);
    //     glVertex2f(xw, y);
    // glEnd();

    assert(false);
}

draw_textured_rect :: (using rdr: GL_Renderer, tex: *Texture, x: float, y: float, width: float, height: float) {
    if (tex) {
        glUseProgram(render_plain_texture.id);
        glBindTexture(GL_TEXTURE_2D, tex.id);
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
    glTexImage2D(GL_TEXTURE_2D, 0, GL_ALPHA, bwidth, bheight, 0, GL_ALPHA, GL_UNSIGNED_BYTE, data);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
}

draw_text :: (font: Font, text: string, x: float, y: float) -> x {
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    glBindTexture(GL_TEXTURE_2D, font.id);
    // glBegin(GL_QUADS);
    // while (*text) {
    //     if (*text >= 32 && *text < 128) {
    //         stbtt_aligned_quad q;
    //         stbtt_GetBakedQuad(font->cdata, font->bwidth, font->bheight, *text-32, &x,&y,&q,1);//1=opengl & d3d10+,0=d3d9
    //         glTexCoord2f(q.s0,q.t0); glVertex2f(q.x0,q.y0);
    //         glTexCoord2f(q.s0,q.t1); glVertex2f(q.x0,q.y1);
    //         glTexCoord2f(q.s1,q.t1); glVertex2f(q.x1,q.y1);
    //         glTexCoord2f(q.s1,q.t0); glVertex2f(q.x1,q.y0);
    //     }
    //     ++text;
    // }
    // glEnd();

    glDisable(GL_BLEND);
    assert(false);

    return x;
}

start_scene :: (using rdr: GL_Renderer) {
    glBindFramebuffer(GL_FRAMEBUFFER, gbuffer_framebuffer);
    clear_screen(0, 0, 0, 1);

    glUseProgram(render_to_gbuffer.id);

    pos := camera.position;
    view_matrix = matrix_translate(-pos.x, -pos.y, -pos.z);
}

finish_scene :: (using rdr: GL_Renderer) {
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    clear_screen(0, 0, 0, 1);

    projection_matrix = matrix_ortho(0, 1, 0, 1, -1, 1);
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, gbuffer_normal);
    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, gbuffer_albedo_spec);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, gbuffer_position);

    glUseProgram(render_light_using_gbuffer.id);
    proj := glGetUniformLocation(render_light_using_gbuffer.id, "projection");
    tex_normal := glGetUniformLocation(render_light_using_gbuffer.id, "g_normal");
    tex_pos := glGetUniformLocation(render_light_using_gbuffer.id, "g_position");
    tex_albedo := glGetUniformLocation(render_light_using_gbuffer.id, "g_albedospec");
    glUniformMatrix4fv(proj, 1, GL_TRUE, projection_matrix.flat.data);
    glUniform1i(tex_pos, 0);
    glUniform1i(tex_normal, 1);
    glUniform1i(tex_albedo, 2);
    draw_textured_rect(rdr, null, 0, 0, 1, 1);

    for lights {

    }

    glUseProgram(0);
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

r: float;

draw_mesh :: (using rdr: GL_Renderer, m: Mesh) {
    glEnable(GL_DEPTH_TEST);

    r += 0.01;
    q := set_angle_vector(0, 1, 0, 0);
    b := set_angle_vector(3.14, 0, 1, 0);
    t := matrix_rotate(slerp(clamp(r, 0, 1), q, b));
    // t := matrix_identity();

    proj := glGetUniformLocation(render_to_gbuffer.id, "projection");
    view := glGetUniformLocation(render_to_gbuffer.id, "view");
    model := glGetUniformLocation(render_to_gbuffer.id, "model");
    glUniformMatrix4fv(proj, 1, GL_TRUE, projection_matrix.flat.data);
    glUniformMatrix4fv(view, 1, GL_TRUE, view_matrix.flat.data);
    glUniformMatrix4fv(model, 1, GL_TRUE, t.flat.data);

    viewer_pos := glGetUniformLocation(render_to_gbuffer.id, "camera_position");
    glUniform3f(viewer_pos, camera.position.x, camera.position.y, camera.position.z);

    // material
    mat_diffuse := glGetUniformLocation(render_to_gbuffer.id, "material.diffuse");
    mat_spec_exp := glGetUniformLocation(render_to_gbuffer.id, "material.specular_exp");
    use_diffuse_map := glGetUniformLocation(render_to_gbuffer.id, "use_diffuse_map");
    use_normal_map := glGetUniformLocation(render_to_gbuffer.id, "use_normal_map");
    use_specular_map := glGetUniformLocation(render_to_gbuffer.id, "use_specular_map");
    diffuse_map := glGetUniformLocation(render_to_gbuffer.id, "diffuse_map");
    normal_map := glGetUniformLocation(render_to_gbuffer.id, "normal_map");
    specular_map := glGetUniformLocation(render_to_gbuffer.id, "specular_map");

    assert(m.material != null);
    mat := m.material;
    diffuse_tex :=  mat.textures[TEXTURE_DIFFUSE_INDEX];
    normal_tex := mat.textures[TEXTURE_NORMAL_INDEX];
    spec_tex := mat.textures[TEXTURE_SPECULAR_INDEX];

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

    glUniform1i(use_specular_map, xx (spec_tex != null));
    if (spec_tex) {
        glActiveTexture(GL_TEXTURE2);
        glBindTexture(GL_TEXTURE_2D, spec_tex.id);
        glUniform1i(specular_map, 2);
    }

    glActiveTexture(GL_TEXTURE0);

    diffuse := *mat.diffuse;
    glUniform3f(mat_diffuse, diffuse.r, diffuse.g, diffuse.b);
    glUniform1f(mat_spec_exp, mat.specular_exp);

    glBindBuffer(GL_ARRAY_BUFFER, m.buffer_id);

    vertex_size := m.vertices.count * size_of(Vector3);
    normal_size := m.normals.count * size_of(Vector3);
    tex_size    := m.tex_coords.count * size_of(Vector2);
    glEnableVertexAttribArray(0);
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, cast(*void) 0);
    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 0, cast(*void) vertex_size);

    if (tex_size) {
        glEnableVertexAttribArray(2);
        glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, 0, cast(*void) (vertex_size+normal_size));
    }

    if (normal_tex) {
        glEnableVertexAttribArray(3);
        glVertexAttribPointer(3, 3, GL_FLOAT, GL_FALSE, 0, cast(*void) (vertex_size+normal_size+tex_size));
    }

    glDrawArrays(GL_TRIANGLES, 0, xx m.vertices.count);

    glDisableVertexAttribArray(0);
    glDisableVertexAttribArray(1);
    
    if (tex_size) glDisableVertexAttribArray(2);
    if (normal_tex) glDisableVertexAttribArray(3);

    glDisable(GL_DEPTH_TEST);
}

store_mesh_in_buffer :: (m: *Mesh) {
    glGenBuffers(1, *m.buffer_id);
    glBindBuffer(GL_ARRAY_BUFFER, m.buffer_id);

    vertex_size := m.vertices.count * size_of(Vector3);
    normal_size := m.normals.count * size_of(Vector3);
    tex_size    := m.tex_coords.count * size_of(Vector2);
    tangent_size := m.tangent_normals.count * size_of(Vector3);
    total_size := vertex_size + tex_size + normal_size + tangent_size;

    glBufferData(GL_ARRAY_BUFFER, total_size, null, GL_STATIC_DRAW);
    glBufferSubData(GL_ARRAY_BUFFER, 0, vertex_size, m.vertices.data);
    glBufferSubData(GL_ARRAY_BUFFER, vertex_size, normal_size, m.normals.data);
    glBufferSubData(GL_ARRAY_BUFFER, vertex_size+normal_size, tex_size, m.tex_coords.data);
    glBufferSubData(GL_ARRAY_BUFFER, vertex_size+normal_size+tex_size, tangent_size, m.tangent_normals.data);
}

draw_model :: (rdr: GL_Renderer, m: Model) {
    for m.meshes {
        draw_mesh(rdr, << it);
    }
}

PI :: 3.14159;

get_sphere_vertex :: (theta: float, phi: float) -> Vector3 {
    v: Vector3 = ---;
    v.x = sin(theta * PI * 2) * cos(phi * PI * 2);
    v.y = cos(theta * PI * 2);
    v.z = sin(theta * PI * 2) * sin(phi * PI * 2);
    return v;
}

create_sphere :: (radius: float, latitude_slices: int, longitude_slices: int) -> *Model {
    mod := New(Model);
    m := New(Mesh);
    array_add(*mod.meshes, m);

    xstep: float = 1.0 / cast(float) longitude_slices;
    ystep := (1.0 / cast(float) latitude_slices) / 2;

    for xa: 0..(longitude_slices/2)-1 {
        theta: float = cast(float) xa * xstep;

        for ya: 0..latitude_slices-1 {
            phi: float = cast(float) ya * ystep;
            v0 := get_sphere_vertex(theta,         phi);
            v1 := get_sphere_vertex(theta + xstep, phi);
            v2 := get_sphere_vertex(theta + xstep, phi + ystep);
            v3 := get_sphere_vertex(theta,         phi + ystep);

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

    store_mesh_in_buffer(m);
    return mod;
}
