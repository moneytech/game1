
#include "general.h"
#include "renderer.h"
#include "os_api.h"

#include <GL/gl.h>
#include "glext.h"

#include <cstdio>
void APIENTRY debug_callback(GLenum source, GLenum type, GLuint id, GLenum severity, GLsizei length, const GLchar *message, const void *userParam) {
    printf("DEBUG:%s\n", message);
}

void GL_Renderer::init(int screen_width, int screen_height) {
#ifdef WIN32
    #define LOAD(type, name) (name = (type)os_load_gl_func(#name))
    LOAD(PFNGLGENFRAMEBUFFERSPROC, glGenFramebuffers);
    LOAD(PFNGLDELETEFRAMEBUFFERSPROC, glDeleteFramebuffers);
    LOAD(PFNGLBINDFRAMEBUFFERPROC, glBindFramebuffer);
    LOAD(PFNGLFRAMEBUFFERTEXTURE2DPROC, glFramebufferTexture2D);
    LOAD(PFNGLFRAMEBUFFERRENDERBUFFERPROC, glFramebufferRenderbuffer);

    LOAD(PFNGLDRAWBUFFERSPROC, glDrawBuffers);

    LOAD(PFNGLGENRENDERBUFFERSPROC, glGenRenderbuffers);
    LOAD(PFNGLDELETERENDERBUFFERSPROC, glDeleteRenderbuffers);
    LOAD(PFNGLBINDRENDERBUFFERPROC, glBindRenderbuffer);
    LOAD(PFNGLRENDERBUFFERSTORAGEPROC, glRenderbufferStorage);
    LOAD(PFNGLCHECKFRAMEBUFFERSTATUSPROC, glCheckFramebufferStatus);

    LOAD(PFNGLACTIVETEXTUREPROC, glActiveTexture);

    LOAD(PFNGLCREATEPROGRAMPROC, glCreateProgram);
    LOAD(PFNGLDELETEPROGRAMPROC, glDeleteProgram);
    LOAD(PFNGLCREATESHADERPROC, glCreateShader);
    LOAD(PFNGLDELETESHADERPROC, glDeleteShader);
    LOAD(PFNGLATTACHSHADERPROC, glAttachShader);
    LOAD(PFNGLDETACHSHADERPROC, glDetachShader);
    LOAD(PFNGLCOMPILESHADERPROC, glCompileShader);
    LOAD(PFNGLLINKPROGRAMPROC, glLinkProgram);
    LOAD(PFNGLSHADERSOURCEPROC, glShaderSource);
    LOAD(PFNGLUSEPROGRAMPROC, glUseProgram);

    LOAD(PFNGLGETSHADERIVPROC, glGetShaderiv);
    LOAD(PFNGLGETSHADERINFOLOGPROC, glGetShaderInfoLog);
    LOAD(PFNGLGETPROGRAMIVPROC, glGetProgramiv);
    LOAD(PFNGLGETPROGRAMINFOLOGPROC, glGetProgramInfoLog);

    LOAD(PFNGLUNIFORM1FPROC, glUniform1f);
    LOAD(PFNGLUNIFORM2FPROC, glUniform2f);
    LOAD(PFNGLUNIFORM3FPROC, glUniform3f);
    LOAD(PFNGLUNIFORM4FPROC, glUniform4f);
    LOAD(PFNGLUNIFORM1IPROC, glUniform1i);
    LOAD(PFNGLUNIFORM2IPROC, glUniform2i);
    LOAD(PFNGLUNIFORM3IPROC, glUniform3i);
    LOAD(PFNGLUNIFORM4IPROC, glUniform4i);
    LOAD(PFNGLUNIFORM1FVPROC, glUniform1fv);
    LOAD(PFNGLUNIFORM2FVPROC, glUniform2fv);
    LOAD(PFNGLUNIFORM3FVPROC, glUniform3fv);
    LOAD(PFNGLUNIFORM4FVPROC, glUniform4fv);
    LOAD(PFNGLUNIFORM1IVPROC, glUniform1iv);
    LOAD(PFNGLUNIFORM2IVPROC, glUniform2iv);
    LOAD(PFNGLUNIFORM3IVPROC, glUniform3iv);
    LOAD(PFNGLUNIFORM4IVPROC, glUniform4iv);
    LOAD(PFNGLUNIFORMMATRIX2FVPROC, glUniformMatrix2fv);
    LOAD(PFNGLUNIFORMMATRIX3FVPROC, glUniformMatrix3fv);
    LOAD(PFNGLUNIFORMMATRIX4FVPROC, glUniformMatrix4fv);

    LOAD(PFNGLGETUNIFORMLOCATIONPROC, glGetUniformLocation);
    LOAD(PFNGLGETUNIFORMFVPROC, glGetUniformfv);
    LOAD(PFNGLGETUNIFORMIVPROC, glGetUniformiv);
    LOAD(PFNGLGETACTIVEUNIFORMPROC, glGetActiveUniform);

    LOAD(PFNGLBINDBUFFERPROC, glBindBuffer);
    LOAD(PFNGLDELETEBUFFERSPROC, glDeleteBuffers);
    LOAD(PFNGLGENBUFFERSPROC, glGenBuffers);
    LOAD(PFNGLISBUFFERPROC, glIsBuffer);
    LOAD(PFNGLBUFFERDATAPROC, glBufferData);
    LOAD(PFNGLBUFFERSUBDATAPROC, glBufferSubData);
    LOAD(PFNGLGETBUFFERSUBDATAPROC, glGetBufferSubData);

    LOAD(PFNGLDISABLEVERTEXATTRIBARRAYPROC, glDisableVertexAttribArray);
    LOAD(PFNGLENABLEVERTEXATTRIBARRAYPROC, glEnableVertexAttribArray);
    LOAD(PFNGLVERTEXATTRIBPOINTERPROC, glVertexAttribPointer);

    LOAD(PFNGLGENVERTEXARRAYSPROC, glGenVertexArrays);
    LOAD(PFNGLDELETEVERTEXARRAYSPROC, glDeleteVertexArrays);
    LOAD(PFNGLBINDVERTEXARRAYPROC, glBindVertexArray);

    PFNGLDEBUGMESSAGECALLBACKPROC glDebugMessageCallback;
    LOAD(PFNGLDEBUGMESSAGECALLBACKPROC, glDebugMessageCallback);
    #undef LOAD
#endif

    glDebugMessageCallback(debug_callback, nullptr);

    // @Temporary
    // @Temporary
    // @Temporary
    // @Temporary
    // @Temporary
    GLuint VertexArrayID;
    glGenVertexArrays(1, &VertexArrayID);
    glBindVertexArray(VertexArrayID);

    glGenFramebuffers(1, &gbuffer_framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, gbuffer_framebuffer);

    glGenTextures(1, &gbuffer_position);
    glGenTextures(1, &gbuffer_normal);
    glGenTextures(1, &gbuffer_albedo_spec);

    glBindTexture(GL_TEXTURE_2D, gbuffer_position);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB16F, screen_width, screen_height, 0, GL_RGB, GL_FLOAT, nullptr);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, gbuffer_position, 0);

    glBindTexture(GL_TEXTURE_2D, gbuffer_normal);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB16F, screen_width, screen_height, 0, GL_RGB, GL_FLOAT, nullptr);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT1, GL_TEXTURE_2D, gbuffer_normal, 0);

    glBindTexture(GL_TEXTURE_2D, gbuffer_albedo_spec);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, screen_width, screen_height, 0, GL_RGBA, GL_UNSIGNED_BYTE, nullptr);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT2, GL_TEXTURE_2D, gbuffer_albedo_spec, 0);

    u32 attach[3] = { GL_COLOR_ATTACHMENT0, GL_COLOR_ATTACHMENT1, GL_COLOR_ATTACHMENT2 };
    glDrawBuffers(3, attach);

    glGenRenderbuffers(1, &gbuffer_depth);
    glBindRenderbuffer(GL_RENDERBUFFER, gbuffer_depth);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT, screen_width, screen_height);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, gbuffer_depth);

    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) assert(0);

    glBindFramebuffer(GL_FRAMEBUFFER, 0);
}

void GL_Renderer::create_texture(Texture *tex, u16 width, u16 height, void *data) {
    GLuint texId;
    glGenTextures(1, &texId);
    glBindTexture(GL_TEXTURE_2D, texId);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR); // Linear Filtering
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR); // Linear Filtering
    tex->width = width;
    tex->height = height;
    tex->id = texId;
}

void GL_Renderer::delete_texture(Texture *tex) {
    glDeleteTextures(1, &tex->id);
}

#include <cstdio>

static u32 compile_shader(GL_Renderer *gl, GLenum type, const char *source) {
    u32 v = gl->glCreateShader(type);
    gl->glShaderSource(v, 1, &source, 0);
    gl->glCompileShader(v);

    GLint status;
    gl->glGetShaderiv(v, GL_COMPILE_STATUS, &status);
    if (status == GL_FALSE) {
        GLint len;
        gl->glGetShaderiv(v, GL_INFO_LOG_LENGTH, &len);
        char *buf = (char *)GET_MEMORY_SIZED(len);
        gl->glGetShaderInfoLog(v, len, &len, &buf[0]);
        printf("ERROR: %s\n", buf);
        FREE_MEMORY(buf);

        gl->glDeleteShader(v);
        return 0;
    }

    return v;
}

Shader *GL_Renderer::compile_shader_source(const char *vertex, const char* pixel) {
    Shader *out = GET_MEMORY(Shader);
    u32 vert = compile_shader(this, GL_VERTEX_SHADER, vertex);
    u32 frag = compile_shader(this, GL_FRAGMENT_SHADER, pixel);
    u32 program = glCreateProgram();
    glAttachShader(program, vert);
    glAttachShader(program, frag);
    glLinkProgram(program);

    GLint status;
    glGetProgramiv(program, GL_LINK_STATUS, &status);
    if (status == GL_FALSE) {
        GLint len;
        glGetProgramiv(program, GL_INFO_LOG_LENGTH, &len);
        char *buf = (char *)GET_MEMORY_SIZED(len);
        glGetProgramInfoLog(program, len, &len, &buf[0]);
        printf("ERROR: %s\n", buf);
        FREE_MEMORY(buf);

        glDeleteProgram(program);
        glDeleteShader(vert);
        glDeleteShader(frag);

        FREE_MEMORY(out);
        return nullptr;
    }

    glDetachShader(program, vert);
    glDetachShader(program, frag);

    out->id = program;
    return out;
}

void GL_Renderer::compile_shader_source(Shader *out, const char *vertex, const char *pixel) {
    u32 vert = compile_shader(this, GL_VERTEX_SHADER, vertex);
    u32 frag = compile_shader(this, GL_FRAGMENT_SHADER, pixel);
    u32 program = glCreateProgram();
    glAttachShader(program, vert);
    glAttachShader(program, frag);
    glLinkProgram(program);

    GLint status;
    glGetProgramiv(program, GL_LINK_STATUS, &status);
    if (status == GL_FALSE) {
        GLint len;
        glGetProgramiv(program, GL_INFO_LOG_LENGTH, &len);
        char *buf = (char *)GET_MEMORY_SIZED(len);
        glGetProgramInfoLog(program, len, &len, &buf[0]);
        printf("ERROR: %s\n", buf);
        FREE_MEMORY(buf);

        glDeleteProgram(program);
        glDeleteShader(vert);
        glDeleteShader(frag);
        return ;
    }

    glDetachShader(program, vert);
    glDetachShader(program, frag);

    out->id = program;
}

void GL_Renderer::set_projection_ortho(float l, float r, float t, float b, float n, float f) {
    projection_matrix = Matrix4::ortho(l, r, t, b, n, f);
}


void GL_Renderer::set_projection_frustum(float l, float r, float b, float t, float n, float f) {
    projection_matrix = Matrix4::frustum(l, r, b, t, n, f);
}
void GL_Renderer::set_projection_fov(float fov, float aspect, float n, float f) {
    float t = tan(fov * 3.14159f / 360.0f) * n;
    float b = -t;
    float l = aspect * b;
    float r = aspect * t;
    GL_Renderer::set_projection_frustum(l, r, b, t, n, f);
}

void GL_Renderer::clear_screen(float r, float g, float b, float a) {
    glClearColor(r, g, b, a);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    // glEnable(GL_CULL_FACE);
    // glCullFace(GL_BACK);
}

void GL_Renderer::draw_rect(Rectangle &rect) {
    float x = rect.x;
    float y = rect.y;
    float width = rect.width;
    float height = rect.height;

    float xw = x+width;
    float yh = y+height;
    glBegin(GL_QUADS);
        glVertex2f(x, y);
        glVertex2f(x, yh);
        glVertex2f(xw, yh);
        glVertex2f(xw, y);
    glEnd();
}

void GL_Renderer::draw_rect(float x, float y, float width, float height) {
    glColor3f(1.0, 0.0, 0.0);
    float xw = x+width;
    float yh = y+height;
    glBegin(GL_QUADS);
        glVertex2f(x, y);
        glVertex2f(x, yh);
        glVertex2f(xw, yh);
        glVertex2f(xw, y);
    glEnd();
}

void GL_Renderer::draw_textured_rect(Texture *tex, float x, float y, float width, float height) {
    if (tex) {
        glUseProgram(render_plain_texture->id);
        glBindTexture(GL_TEXTURE_2D, tex->id);
    }

    float xw = x+width;
    float yh = y+height;

    float arr[] = {
        x, y, 0, 0,
        xw, y, 1, 0,
        xw, yh, 1, 1,

        xw, yh, 1, 1,
        x, yh, 0, 1,
        x, y, 0, 0,
    };

    u32 buf;
    glGenBuffers(1, &buf);
    glBindBuffer(GL_ARRAY_BUFFER, buf);
    glBufferData(GL_ARRAY_BUFFER, sizeof(arr), &arr[0], GL_STATIC_DRAW);

    glEnableVertexAttribArray(0);
    glEnableVertexAttribArray(2);

    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, sizeof(float)*4, 0);
    glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, sizeof(float)*4, (void *)(sizeof(float)*2));

    glDrawArrays(GL_TRIANGLES, 0, 6);
    
    glDisableVertexAttribArray(0);
    glDisableVertexAttribArray(2);
    glDeleteBuffers(1, &buf);
}

void GL_Renderer::draw_textured_rect(Texture *tex, Rectangle &rect) {
    draw_textured_rect(tex, rect.x, rect.y, rect.width, rect.height);
}

void GL_Renderer::draw_sprite(Sprite *sp) {
    glEnable(GL_TEXTURE_2D);
    glBindTexture(GL_TEXTURE_2D, sp->texture->id);
    glColor3f(1.0, 1.0, 1.0);

    Rectangle &rect = sp->dimensions;
    float x = rect.x;
    float y = rect.y;
    float width = rect.width;
    float height = rect.height;

    float xw = x+width;
    float yh = y+height;

    Bitmap_Frame *frame = sp->current_frame;
    assert(frame);

    Rectangle &tex_coords = frame->tex_coords;
    float tx = tex_coords.x;
    float ty = tex_coords.y;
    float txw = tx + tex_coords.width;
    float tyh = ty + tex_coords.height;
 
    if (frame->flags & BITMAP_FRAME_FLIP_VERTICLE) {
        float temp = tx;
        tx = txw;
        txw = temp;
        assert(0);
    }
    if (frame->flags & BITMAP_FRAME_FLIP_HORIZONTAL) {
        float temp = ty;
        tx = tyh;
        tyh = temp;
        assert(0);
    }

    glBegin(GL_QUADS);
        glTexCoord2f(tx, tyh);
        glVertex2f(x, y);
        glTexCoord2f(tx, ty);
        glVertex2f(x, yh);
        glTexCoord2f(txw, ty);
        glVertex2f(xw, yh);
        glTexCoord2f(txw, tyh);
        glVertex2f(xw, y);
    glEnd();

    glDisable(GL_TEXTURE_2D);
}

float Font::get_length(const char *text) {
    float x = 0;
    float y = 0;
    while (*text) {
        if (*text >= 32 && *text < 128) {
            stbtt_aligned_quad q;
            // just run this so we can advance x for this character
            stbtt_GetBakedQuad(cdata, bwidth, bheight, *text-32, &x,&y,&q,1);
        }
        ++text;
    }
    return x;
}

void GL_Renderer::create_font(Font *font, u16 bwidth, u16 bheight, void *data) {
    font->bwidth = bwidth;
    font->bheight = bheight;
    glGenTextures(1, &font->id);
    glBindTexture(GL_TEXTURE_2D, font->id);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_ALPHA, bwidth, bheight, 0, GL_ALPHA, GL_UNSIGNED_BYTE, data);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
}

float GL_Renderer::draw_text(Font *font, const char *text, float x, float y) {
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    glEnable(GL_TEXTURE_2D);
    glBindTexture(GL_TEXTURE_2D, font->id);
    glBegin(GL_QUADS);
    while (*text) {
        if (*text >= 32 && *text < 128) {
            stbtt_aligned_quad q;
            stbtt_GetBakedQuad(font->cdata, font->bwidth, font->bheight, *text-32, &x,&y,&q,1);//1=opengl & d3d10+,0=d3d9
            glTexCoord2f(q.s0,q.t0); glVertex2f(q.x0,q.y0);
            glTexCoord2f(q.s0,q.t1); glVertex2f(q.x0,q.y1);
            glTexCoord2f(q.s1,q.t1); glVertex2f(q.x1,q.y1);
            glTexCoord2f(q.s1,q.t0); glVertex2f(q.x1,q.y0);
        }
        ++text;
    }
    glEnd();
    glDisable(GL_TEXTURE_2D);
    glDisable(GL_BLEND);

    return x;
}

void GL_Renderer::start_scene() {
    glBindFramebuffer(GL_FRAMEBUFFER, gbuffer_framebuffer);
    clear_screen(0, 0, 0, 1);

    glUseProgram(render_to_gbuffer->id);
    view_matrix = Matrix4::translate(0, 0, -1);
}

void GL_Renderer::finish_scene() {
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    clear_screen(0, 0, 0, 1);

    set_projection_ortho(0, 1, 0, 1, -1, 1);
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, gbuffer_normal);
    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, gbuffer_albedo_spec);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, gbuffer_position);

    glUseProgram(render_light_using_gbuffer->id);
    GLint proj = glGetUniformLocation(render_light_using_gbuffer->id, "projection");
    GLint tex_normal = glGetUniformLocation(render_light_using_gbuffer->id, "g_normal");
    GLint tex_pos = glGetUniformLocation(render_light_using_gbuffer->id, "g_position");
    GLint tex_albedo = glGetUniformLocation(render_light_using_gbuffer->id, "g_albedospec");
    glUniformMatrix4fv(proj, 1, GL_TRUE, &projection_matrix[0]);
    glUniform1i(tex_pos, 0);
    glUniform1i(tex_normal, 1);
    glUniform1i(tex_albedo, 2);
    draw_textured_rect(nullptr, 0, 0, 1, 1);

    for (int i = 0; i < lights.count; ++i) {

    }

    glUseProgram(0);
}

void GL_Renderer::draw_cube(float x, float y, float z, float size) {

    glEnable(GL_DEPTH_TEST);

    Matrix4 t = Matrix4::translate(x, y, z);

    float hs = size/2.0f;
    glBegin(GL_QUADS);
        glNormal3f(0, 0, 1);
        glVertex3f(-hs, hs, hs);
        glVertex3f(-hs,-hs, hs);
        glVertex3f( hs,-hs, hs);
        glVertex3f( hs, hs, hs);

        glNormal3f(-1, 0, 0);
        glVertex3f(-hs, hs,-hs);
        glVertex3f(-hs,-hs,-hs);
        glVertex3f(-hs,-hs, hs);
        glVertex3f(-hs, hs, hs);

        glNormal3f(0, 0, -1);
        glVertex3f( hs, hs,-hs);
        glVertex3f( hs,-hs,-hs);
        glVertex3f(-hs,-hs,-hs);
        glVertex3f(-hs, hs,-hs);

        glNormal3f(1, 0, 0);
        glVertex3f( hs, hs, hs);
        glVertex3f( hs,-hs, hs);
        glVertex3f( hs,-hs,-hs);
        glVertex3f( hs, hs,-hs);

        glNormal3f(0, 1, 0);
        glVertex3f(-hs, hs,-hs);
        glVertex3f(-hs, hs, hs);
        glVertex3f( hs, hs, hs);
        glVertex3f( hs, hs,-hs);

        glNormal3f(0, -1, 0);
        glVertex3f( hs,-hs,-hs);
        glVertex3f( hs,-hs, hs);
        glVertex3f(-hs,-hs, hs);
        glVertex3f(-hs,-hs,-hs);

    glEnd();

    glDisable(GL_DEPTH_TEST);
}

void GL_Renderer::draw_mesh(Mesh *m) {
    glEnable(GL_DEPTH_TEST);

    static float r = 0;
    r += 0.001f;
    Quaternion q;
    q.set_angle_vector(0, 1, 0, 0);
    Quaternion b;
    b.set_angle_vector(3.14f, 1, 0, 0);
    Matrix4 t =  Matrix4::rotate(nlerp(clamp(r, 0, 1), q, b));

    GLint proj = glGetUniformLocation(render_to_gbuffer->id, "projection");
    GLint view = glGetUniformLocation(render_to_gbuffer->id, "view");
    GLint model = glGetUniformLocation(render_to_gbuffer->id, "model");
    glUniformMatrix4fv(proj, 1, GL_TRUE, &projection_matrix[0]);
    glUniformMatrix4fv(view, 1, GL_TRUE, &view_matrix[0]);
    glUniformMatrix4fv(model, 1, GL_TRUE, &t[0]);

    // material
    GLint mat_diffuse = glGetUniformLocation(render_to_gbuffer->id, "material.diffuse");
    GLint mat_spec_exp = glGetUniformLocation(render_to_gbuffer->id, "material.specular_exp");
    GLint use_diffuse_map = glGetUniformLocation(render_to_gbuffer->id, "use_diffuse_map");
    GLint use_normal_map = glGetUniformLocation(render_to_gbuffer->id, "use_normal_map");
    GLint diffuse_map = glGetUniformLocation(render_to_gbuffer->id, "diffuse_map");

    assert(m->material);
    Material *mat = m->material;
    Texture *diffuse_tex =  mat->textures[TEXTURE_DIFFUSE_INDEX];
    glUniform1i(use_diffuse_map, diffuse_tex ? 1 : 0);
    if (diffuse_tex) {
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, diffuse_tex->id);
        glUniform1i(diffuse_map, 0);
    }

    Color &diffuse = mat->diffuse;
    glUniform3f(mat_diffuse, diffuse.r, diffuse.g, diffuse.b);
    glUniform1f(mat_spec_exp, mat->specular_exp);

    glBindBuffer(GL_ARRAY_BUFFER, m->buffer_id);
    glEnableVertexAttribArray(0);
    glEnableVertexAttribArray(1);
    glEnableVertexAttribArray(2);

    u64 vertex_size = m->vertices.count * sizeof(Vector3);
    u64 normal_size = m->normals.count * sizeof(Vector3);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, (void*)0);
    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 0, (void*)vertex_size);
    glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, 0, (void*)(vertex_size+normal_size));

    glDrawArrays(GL_TRIANGLES, 0, m->vertices.count);

    glDisableVertexAttribArray(0);
    glDisableVertexAttribArray(1);
    glDisableVertexAttribArray(2);

    glDisable(GL_DEPTH_TEST);
}

void GL_Renderer::store_mesh_in_buffer(Mesh *m) {
    glGenBuffers(1, &m->buffer_id);
    glBindBuffer(GL_ARRAY_BUFFER, m->buffer_id);

    u32 vertex_size = m->vertices.count * sizeof(Vector3);
    u32 normal_size = m->normals.count * sizeof(Vector3);
    u32 tex_size    = m->tex_coords.count * sizeof(Vector2);
    u32 total_size = vertex_size + tex_size + normal_size;

    glBufferData(GL_ARRAY_BUFFER, total_size, nullptr, GL_STATIC_DRAW);
    glBufferSubData(GL_ARRAY_BUFFER, 0, vertex_size, m->vertices.data);
    glBufferSubData(GL_ARRAY_BUFFER, vertex_size, normal_size, m->normals.data);
    glBufferSubData(GL_ARRAY_BUFFER, vertex_size+normal_size, tex_size, m->tex_coords.data);
}

void GL_Renderer::draw_model(Model *m) {
    for (int i = 0; i < m->meshes.count; ++i) {
        auto mesh = m->meshes[i];
        draw_mesh(mesh);
    }
}