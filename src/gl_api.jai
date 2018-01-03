
GL_3_0_API :: struct {
    glGenFramebuffers: (n: GLsizei, framebuffers: *GLuint) #foreign;
    glDeleteFramebuffers: (n: GLsizei, framebuffers: *GLuint) #foreign;
    glBindFramebuffer: (target: GLenum, framebuffer: GLuint) #foreign;
    glFramebufferTexture2D: (target: GLenum, attachment: GLenum, textarget: GLenum, texture: GLuint, level: GLint) #foreign;
    glFramebufferRenderbuffer: (target: GLenum, attachment: GLenum, renderbuffertarget: GLenum, renderbuffer: GLuint) #foreign;

    glDrawBuffers: (n: GLsizei, bufs: *GLenum) #foreign;

    glGenRenderbuffers: (n: GLsizei, renderbuffers: *GLuint) #foreign;
    glDeleteRenderbuffers: (n: GLsizei, renderbuffers: *GLuint) #foreign;
    glBindRenderbuffer: (target: GLenum, renderbuffer: GLuint) #foreign;
    glRenderbufferStorage: (target: GLenum, internalformat: GLenum, width: GLsizei, height: GLsizei) #foreign;
    glCheckFramebufferStatus: (target: GLenum) -> GLenum #foreign;

    glActiveTexture: (texture: GLenum) #foreign;

    glCreateProgram: () -> GLuint #foreign;
    glDeleteProgram: (program: GLuint) #foreign;
    glCreateShader: (type: GLenum) -> GLuint #foreign;
    glDeleteShader: (shader: GLuint) #foreign;
    glAttachShader: (program: GLuint, shader: GLuint) #foreign;
    glDetachShader: (program: GLuint, shader: GLuint) #foreign;
    glCompileShader: (shader: GLuint) #foreign;
    glLinkProgram: (program: GLuint) #foreign;
    glShaderSource: (shader: GLuint, count: GLsizei, c_string: **GLchar, length: *GLint) #foreign;
    glUseProgram: (program: GLuint) #foreign;

    glGetShaderiv: (shader: GLuint, pname: GLenum, params: *GLint) #foreign;
    glGetShaderInfoLog: (shader: GLuint, bufSize: GLsizei, length: *GLsizei, infoLog: *GLchar) #foreign;
    glGetProgramiv: (program: GLuint, pname: GLenum, params: *GLint) #foreign;
    glGetProgramInfoLog: (program: GLuint, bufSize: GLsizei, length: *GLsizei, infoLog: *GLchar) #foreign;

    glUniform1f: (location: GLint, v0: GLfloat) #foreign;
    glUniform2f: (location: GLint, v0: GLfloat, v1: GLfloat) #foreign;
    glUniform3f: (location: GLint, v0: GLfloat, v1: GLfloat, v2: GLfloat) #foreign;
    glUniform4f: (location: GLint, v0: GLfloat, v1: GLfloat, v2: GLfloat, v3: GLfloat) #foreign;
    glUniform1i: (location: GLint, v0: GLint) #foreign;
    glUniform2i: (location: GLint, v0: GLint, v1: GLint) #foreign;
    glUniform3i: (location: GLint, v0: GLint, v1: GLint, v2: GLint) #foreign;
    glUniform4i: (location: GLint, v0: GLint, v1: GLint, v2: GLint, v3: GLint) #foreign;

    glUniform1fv: (location: GLint, count: GLsizei, value: *GLfloat) #foreign;
    glUniform2fv: (location: GLint, count: GLsizei, value: *GLfloat) #foreign;
    glUniform3fv: (location: GLint, count: GLsizei, value: *GLfloat) #foreign;
    glUniform4fv: (location: GLint, count: GLsizei, value: *GLfloat) #foreign;
    glUniform1iv: (location: GLint, count: GLsizei, value: *GLint) #foreign;
    glUniform2iv: (location: GLint, count: GLsizei, value: *GLint) #foreign;
    glUniform3iv: (location: GLint, count: GLsizei, value: *GLint) #foreign;
    glUniform4iv: (location: GLint, count: GLsizei, value: *GLint) #foreign;
    glUniformMatrix2fv: (location: GLint, count: GLsizei, transpose: GLboolean, value: *GLfloat) #foreign;
    glUniformMatrix3fv: (location: GLint, count: GLsizei, transpose: GLboolean, value: *GLfloat) #foreign;
    glUniformMatrix4fv: (location: GLint, count: GLsizei, transpose: GLboolean, value: *GLfloat) #foreign;

    glGetUniformLocation: (program: GLuint, name: *GLchar) -> GLint #foreign;
    glGetUniformfv: (program: GLuint, location: GLint, params: *GLfloat) #foreign;
    glGetUniformiv: (program: GLuint, location: GLint, params: *GLint) #foreign;
    glGetActiveUniform: (program: GLuint, index: GLuint, bufSize: GLsizei, length: *GLsizei, size: *GLint, type: *GLenum, name: *GLchar) #foreign;

    glBindBuffer: (target: GLenum, buffer: GLuint) #foreign;
    glDeleteBuffers: (n: GLsizei, buffers: *GLuint) #foreign;
    glGenBuffers: (n: GLsizei, buffers: *GLuint) #foreign;
    glIsBuffer: (buffer: GLuint) -> GLboolean #foreign;
    glBufferData: (target: GLenum, size: GLsizeiptr, data: *void, usage: GLenum) #foreign;
    glBufferSubData: (target: GLenum, offset: GLintptr, size: GLsizeiptr, data: *void) #foreign;
    glGetBufferSubData: (target: GLenum, offset: GLintptr, size: GLsizeiptr, data: *void) #foreign;

    glDisableVertexAttribArray: (index: GLuint) #foreign;
    glEnableVertexAttribArray: (index: GLuint) #foreign;

    glVertexAttribPointer: (index: GLuint, size: GLint, type: GLenum, normalized: GLboolean, stride: GLsizei, pointer: *void) #foreign;
    glVertexAttribIPointer: (index: GLuint, size: GLint, type: GLenum, stride: GLsizei, pointer: *void) #foreign;

    glGenVertexArrays: (n: GLsizei, arrays: *GLuint) #foreign;
    glDeleteVertexArrays: (n: GLsizei, arrays: *GLuint) #foreign;
    glBindVertexArray: (array: GLuint) #foreign;

    glDebugMessageCallback: (callback: GLDEBUGPROC, userParam: *void) #foreign;

    glVertexAttrib3f: (index: GLuint, x: GLfloat, y: GLfloat, z: GLfloat) #foreign;
    // glGetnTexImage: (target: GLenum, level: GLint, format: GLenum, type: GLenum, bufSize: GLsizei, pixels: *void) #foreign;

    glMapBuffer: (target: GLenum, access: GLenum) -> *void #foreign;
    glUnmapBuffer: (target: GLenum) -> GLboolean #foreign;
}

#if OS_WINDOWS {
    GL :: #foreign_system_library "opengl32";
} else {
    GL :: #foreign_system_library "GL";
}

glCullFace :: (mode: GLenum) #foreign GL;
glGetTexImage :: (target: GLenum, level: GLint, format: GLenum, type: GLenum, pixels: *void) #foreign GL;
glPointSize :: (size: GLfloat) #foreign GL;
glReadBuffer: (mode: GLenum) #foreign GL;
glReadPixels: (x: GLint, y: GLint, width: GLsizei, height: GLsizei, format: GLenum, type: GLenum, data: *GLvoid) #foreign GL;

glDeleteTextures :: (n: GLsizei, textures: *GLuint) #foreign GL;

glTexSubImage2D :: (target: GLenum,  level: GLint, xoffset: GLint, yoffset: GLint, width: GLsizei, height: GLsizei, format: GLenum, type: GLenum, data: *GLvoid) #foreign GL;

glGetUniformLocation :: (program: GLuint, name: string) -> GLint {
    using gl_30_api;
    c_name := to_c_string(name);
    ret := glGetUniformLocation(program, c_name);
    free(c_name);
    return ret;
}

GLDEBUGPROC :: #type (source: GLenum, type: GLenum, id: GLuint, severity: GLenum, length: GLsizei, message: *u8, userParam: *void) #c_callback;

gl_30_api: GL_3_0_API;