
#import "Basic";
#import "GL";
#import "Compiler";

strtoull :: (start: *u8, endptr: **u8, base: s32) -> u64 #foreign crt "_strtoui64";
strtod :: (start: *u8, endptr: **u8) -> float64 #foreign crt;

#scope_file
User32   :: #foreign_system_library "user32";
Kernel32 :: #foreign_system_library "kernel32";
crt :: #foreign_system_library "msvcrt";

strstr :: (a: *u8, b: *u8) -> *u8 #foreign crt;
BOOL :: s32;
GetOverlappedResult :: (hFile: HANDLE, lpOverlapped: *OVERLAPPED, lpNumberOfBytesTrasferred: *s32, bWait: BOOL) -> BOOL #foreign Kernel32;
LoadLibraryA :: (lpFileName: *u8) -> HMODULE #foreign Kernel32;
LoadLibraryA :: (name: string) -> HMODULE {
    c_name := to_c_string(name);
    ret := LoadLibraryA(c_name);
    free(c_name);
    return ret;
}

GetProcAddress :: (hModule: HMODULE, lpProcName: *u8) -> *void #foreign Kernel32;
GetProcAddress :: (hModule: HMODULE, name: string) -> *void {
    c_name := to_c_string(name);
    ret := GetProcAddress(hModule, c_name);
    free(c_name);
    return ret;
}

DestroyWindow :: (hWnd: HWND) -> BOOL #foreign User32;
CreateFileA :: (lpFileName: *u8, dwDesiredAccess: s32, dwShareMode: s32, sec: *void, dwCreationDisposition: s32, dwFlags: s32, hTemplate: *void) -> HANDLE #foreign Kernel32;
GetModuleHandleA :: (lpModuleName: *u8) -> HMODULE #foreign Kernel32;
GetModuleFileNameA :: (hModule: HMODULE, lpFileName: *u8, nSize: s32) -> s32 #foreign Kernel32;
ReadDirectoryChangesW :: (hd: HANDLE, lpBuf: *void, nbuflen: s32, bwatchsub: BOOL, notiffilt: s32, bytes_ret: *s32, over: *OVERLAPPED, complete: *void) -> BOOL #foreign Kernel32;

FILE_NOTIFY_CHANGE_FILE_NAME   :: 0x0000001;
FILE_NOTIFY_CHANGE_DIR_NAME    :: 0x0000002;
FILE_NOTIFY_CHANGE_ATTRIBUTES  :: 0x0000004;
FILE_NOTIFY_CHANGE_SIZE        :: 0x0000008;
FILE_NOTIFY_CHANGE_LAST_WRITE  :: 0x0000010;
FILE_NOTIFY_CHANGE_LAST_ACCESS :: 0x0000020;
FILE_NOTIFY_CHANGE_CREATION    :: 0x0000040;
FILE_NOTIFY_CHANGE_SECURITY    :: 0x0000100;

FILE_LIST_DIRECTORY :: 1;

WGL_DRAW_TO_WINDOW_ARB        :: 0x2001;
WGL_SUPPORT_OPENGL_ARB        :: 0x2010;
WGL_DOUBLE_BUFFER_ARB         :: 0x2011;
WGL_PIXEL_TYPE_ARB            :: 0x2013;
WGL_TYPE_RGBA_ARB             :: 0x202B;
WGL_COLOR_BITS_ARB            :: 0x2014;
WGL_DEPTH_BITS_ARB            :: 0x2022;
WGL_STENCIL_BITS_ARB          :: 0x2023;

OVERLAPPED :: struct {
    Internal: u64;
    InternalHigh: u64;

    Offset: s32;
    OffsetHigh: s32;
    #place Offset;

    Pointer: *void;

    hEvent: HANDLE;
}

FILE_NOTIFY_INFORMATION :: struct {
    NextEntryOffset: s32;
    Action: s32;
    FileNameLength: s32;
    FileName: [1] s16;
}

HMODULE :: HANDLE;

STATUS_PENDING       : s32 : 0x00000103;

// Okay, this is scary...

HasOverlappedIoCompleted :: inline (overlapped: OVERLAPPED) -> bool {
    return (cast (s32) overlapped.Internal) != STATUS_PENDING;
}

#scope_export

OS_Window :: HWND;
OS_GL_Context :: HGLRC;

File_Notification :: struct {
    type: s16;
    name: string;
};

FILE_NOTIF_FUNC :: #type (notif: *File_Notification, data: *void);

JOYSTICK_BUTTON_A       :: (1 << 0);
JOYSTICK_BUTTON_B       :: (1 << 1);
JOYSTICK_BUTTON_X       :: (1 << 2);
JOYSTICK_BUTTON_Y       :: (1 << 3);
JOYSTICK_BUTTON_DUP     :: (1 << 4);
JOYSTICK_BUTTON_DDOWN   :: (1 << 5);
JOYSTICK_BUTTON_DLEFT   :: (1 << 6);
JOYSTICK_BUTTON_DRIGHT  :: (1 << 7);
JOYSTICK_BUTTON_LBUMPER :: (1 << 8);
JOYSTICK_BUTTON_RBUMPER :: (1 << 9);
JOYSTICK_BUTTON_LSTICK  :: (1 << 10);
JOYSTICK_BUTTON_RSTICK  :: (1 << 11);
JOYSTICK_BUTTON_START   :: (1 << 12);
JOYSTICK_BUTTON_BACK    :: (1 << 13);

Joystick :: struct {
    buttons: u16;

    Axis :: struct {
        x: float;
        #place x;
        left: float;

        y: float;
        #place y;
        right: float;
    }

    triggers, left_thumb, right_thumb: Axis;
};

joysticks: [..] Joystick;
file_changes: [..] File_Notification;

GL_BLEND_EQUATION_RGB             :: 0x8009;
GL_VERTEX_ATTRIB_ARRAY_ENABLED    :: 0x8622;
GL_VERTEX_ATTRIB_ARRAY_SIZE       :: 0x8623;
GL_VERTEX_ATTRIB_ARRAY_STRIDE     :: 0x8624;
GL_VERTEX_ATTRIB_ARRAY_TYPE       :: 0x8625;
GL_VERTEX_PROGRAM_POINT_SIZE      :: 0x8642;
GL_VERTEX_ATTRIB_ARRAY_POINTER    :: 0x8645;
GL_STENCIL_BACK_FUNC              :: 0x8800;
GL_STENCIL_BACK_FAIL              :: 0x8801;
GL_STENCIL_BACK_PASS_DEPTH_FAIL   :: 0x8802;
GL_STENCIL_BACK_PASS_DEPTH_PASS   :: 0x8803;
GL_MAX_DRAW_BUFFERS               :: 0x8824;
GL_DRAW_BUFFER0                   :: 0x8825;
GL_DRAW_BUFFER1                   :: 0x8826;
GL_DRAW_BUFFER2                   :: 0x8827;
GL_DRAW_BUFFER3                   :: 0x8828;
GL_DRAW_BUFFER4                   :: 0x8829;
GL_DRAW_BUFFER5                   :: 0x882A;
GL_DRAW_BUFFER6                   :: 0x882B;
GL_DRAW_BUFFER7                   :: 0x882C;
GL_DRAW_BUFFER8                   :: 0x882D;
GL_DRAW_BUFFER9                   :: 0x882E;
GL_DRAW_BUFFER10                  :: 0x882F;
GL_DRAW_BUFFER11                  :: 0x8830;
GL_DRAW_BUFFER12                  :: 0x8831;
GL_DRAW_BUFFER13                  :: 0x8832;
GL_DRAW_BUFFER14                  :: 0x8833;
GL_DRAW_BUFFER15                  :: 0x8834;
GL_BLEND_EQUATION_ALPHA           :: 0x883D;
GL_MAX_VERTEX_ATTRIBS             :: 0x8869;
GL_VERTEX_ATTRIB_ARRAY_NORMALIZED :: 0x886A;
GL_MAX_TEXTURE_IMAGE_UNITS        :: 0x8872;
GL_MAX_FRAGMENT_UNIFORM_COMPONENTS :: 0x8B49;
GL_MAX_VERTEX_UNIFORM_COMPONENTS  :: 0x8B4A;
GL_MAX_VARYING_FLOATS             :: 0x8B4B;
GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS :: 0x8B4C;
GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS :: 0x8B4D;
GL_SHADER_TYPE                    :: 0x8B4F;
GL_FLOAT_VEC2                     :: 0x8B50;
GL_FLOAT_VEC3                     :: 0x8B51;
GL_FLOAT_VEC4                     :: 0x8B52;
GL_INT_VEC2                       :: 0x8B53;
GL_INT_VEC3                       :: 0x8B54;
GL_INT_VEC4                       :: 0x8B55;
GL_BOOL                           :: 0x8B56;
GL_BOOL_VEC2                      :: 0x8B57;
GL_BOOL_VEC3                      :: 0x8B58;
GL_BOOL_VEC4                      :: 0x8B59;
GL_FLOAT_MAT2                     :: 0x8B5A;
GL_FLOAT_MAT3                     :: 0x8B5B;
GL_FLOAT_MAT4                     :: 0x8B5C;
GL_SAMPLER_1D                     :: 0x8B5D;
GL_SAMPLER_2D                     :: 0x8B5E;
GL_SAMPLER_3D                     :: 0x8B5F;
GL_SAMPLER_CUBE                   :: 0x8B60;
GL_SAMPLER_1D_SHADOW              :: 0x8B61;
GL_SAMPLER_2D_SHADOW              :: 0x8B62;
GL_DELETE_STATUS                  :: 0x8B80;
GL_COMPILE_STATUS                 :: 0x8B81;
GL_LINK_STATUS                    :: 0x8B82;
GL_VALIDATE_STATUS                :: 0x8B83;
GL_INFO_LOG_LENGTH                :: 0x8B84;
GL_ATTACHED_SHADERS               :: 0x8B85;
GL_ACTIVE_UNIFORMS                :: 0x8B86;
GL_ACTIVE_UNIFORM_MAX_LENGTH      :: 0x8B87;
GL_SHADER_SOURCE_LENGTH           :: 0x8B88;
GL_ACTIVE_ATTRIBUTES              :: 0x8B89;
GL_ACTIVE_ATTRIBUTE_MAX_LENGTH    :: 0x8B8A;
GL_FRAGMENT_SHADER_DERIVATIVE_HINT :: 0x8B8B;
GL_SHADING_LANGUAGE_VERSION       :: 0x8B8C;
GL_CURRENT_PROGRAM                :: 0x8B8D;
GL_POINT_SPRITE_COORD_ORIGIN      :: 0x8CA0;
GL_LOWER_LEFT                     :: 0x8CA1;
GL_UPPER_LEFT                     :: 0x8CA2;
GL_STENCIL_BACK_REF               :: 0x8CA3;
GL_STENCIL_BACK_VALUE_MASK        :: 0x8CA4;
GL_STENCIL_BACK_WRITEMASK         :: 0x8CA5;
GL_VERTEX_PROGRAM_TWO_SIDE        :: 0x8643;
GL_POINT_SPRITE                   :: 0x8861;
GL_COORD_REPLACE                  :: 0x8862;
GL_MAX_TEXTURE_COORDS             :: 0x8871;

GL_RGB16F                         :: 0x881B;

GL_COLOR_ATTACHMENT1              :: 0x8CE1;
GL_COLOR_ATTACHMENT2              :: 0x8CE2;
GL_COLOR_ATTACHMENT3              :: 0x8CE3;
GL_COLOR_ATTACHMENT4              :: 0x8CE4;
GL_COLOR_ATTACHMENT5              :: 0x8CE5;
GL_COLOR_ATTACHMENT6              :: 0x8CE6;
GL_COLOR_ATTACHMENT7              :: 0x8CE7;
GL_COLOR_ATTACHMENT8              :: 0x8CE8;
GL_COLOR_ATTACHMENT9              :: 0x8CE9;
GL_COLOR_ATTACHMENT10             :: 0x8CEA;
GL_COLOR_ATTACHMENT11             :: 0x8CEB;
GL_COLOR_ATTACHMENT12             :: 0x8CEC;
GL_COLOR_ATTACHMENT13             :: 0x8CED;
GL_COLOR_ATTACHMENT14             :: 0x8CEE;
GL_COLOR_ATTACHMENT15             :: 0x8CEF;
GL_COLOR_ATTACHMENT16             :: 0x8CF0;
GL_COLOR_ATTACHMENT17             :: 0x8CF1;
GL_COLOR_ATTACHMENT18             :: 0x8CF2;
GL_COLOR_ATTACHMENT19             :: 0x8CF3;
GL_COLOR_ATTACHMENT20             :: 0x8CF4;
GL_COLOR_ATTACHMENT21             :: 0x8CF5;
GL_COLOR_ATTACHMENT22             :: 0x8CF6;
GL_COLOR_ATTACHMENT23             :: 0x8CF7;
GL_COLOR_ATTACHMENT24             :: 0x8CF8;
GL_COLOR_ATTACHMENT25             :: 0x8CF9;
GL_COLOR_ATTACHMENT26             :: 0x8CFA;
GL_COLOR_ATTACHMENT27             :: 0x8CFB;
GL_COLOR_ATTACHMENT28             :: 0x8CFC;
GL_COLOR_ATTACHMENT29             :: 0x8CFD;
GL_COLOR_ATTACHMENT30             :: 0x8CFE;
GL_COLOR_ATTACHMENT31             :: 0x8CFF;

GL_FRAMEBUFFER_BINDING            :: 0x8CA6;
GL_DRAW_FRAMEBUFFER_BINDING       :: 0x8CA6;
GL_RENDERBUFFER_BINDING           :: 0x8CA7;
GL_READ_FRAMEBUFFER               :: 0x8CA8;
GL_DRAW_FRAMEBUFFER               :: 0x8CA9;
GL_READ_FRAMEBUFFER_BINDING       :: 0x8CAA;
GL_RENDERBUFFER_SAMPLES           :: 0x8CAB;
GL_FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE :: 0x8CD0;
GL_FRAMEBUFFER_ATTACHMENT_OBJECT_NAME :: 0x8CD1;
GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL :: 0x8CD2;
GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE :: 0x8CD3;
GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_LAYER :: 0x8CD4;
GL_FRAMEBUFFER_COMPLETE           :: 0x8CD5;
GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT :: 0x8CD6;
GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT :: 0x8CD7;
GL_FRAMEBUFFER_INCOMPLETE_DRAW_BUFFER :: 0x8CDB;
GL_FRAMEBUFFER_INCOMPLETE_READ_BUFFER :: 0x8CDC;
GL_FRAMEBUFFER_UNSUPPORTED        :: 0x8CDD;

GL_RED                           :: 0x1903;
GL_R32UI                         :: 0x8236;
GL_RED_INTEGER                   :: 0x8D94;
GL_RGBA32UI                      :: 0x8D70;
GL_RGBA_INTEGER                  :: 0x8D99;
GL_UNSIGNED_INT_8_8_8_8          :: 0x8035;

GL_POINTS                        :: 0x0000;

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

    glDeleteTextures: (n: GLsizei, textures: *GLuint) #foreign;

    glVertexAttrib3f: (index: GLuint, x: GLfloat, y: GLfloat, z: GLfloat) #foreign;
    // glGetnTexImage: (target: GLenum, level: GLint, format: GLenum, type: GLenum, bufSize: GLsizei, pixels: *void) #foreign;
}

GL :: #foreign_system_library "opengl32";
glCullFace :: (mode: GLenum) #foreign GL;
glGetTexImage :: (target: GLenum, level: GLint, format: GLenum, type: GLenum, pixels: *void) #foreign GL;
glPointSize :: (size: GLfloat) #foreign GL;
glReadBuffer: (mode: GLenum) #foreign GL;
glReadPixels: (x: GLint, y: GLint, width: GLsizei, height: GLsizei, format: GLenum, type: GLenum, data: *GLvoid) #foreign GL;

glGetUniformLocation :: (program: GLuint, name: string) -> GLint {
    using gl_30_api;
    c_name := to_c_string(name);
    ret := glGetUniformLocation(program, c_name);
    free(c_name);
    return ret;
}

GLDEBUGPROC :: #type (source: GLenum, type: GLenum, id: GLuint, severity: GLenum, length: GLsizei, message: *u8, userParam: *void) #c_callback;

gl_30_api: GL_3_0_API;

XINPUT_GAMEPAD :: struct {
    wButtons: s16;
    bLeftTrigger: s8;
    bRightTrigger: s8;
    sThumbLX: s16;
    sThumbLY: s16;
    sThumbRX: s16;
    sThumbRY: s16;
}

XINPUT_STATE :: struct {
    dwPacketNumber: s32;
    Gamepad: XINPUT_GAMEPAD;
}

XINPUT_VIBRATION :: struct {
    wLeftMotorSpeed: s16;
    wRightMotorSpeed: s16;
}

XINPUT_BATTERY_INFORMATION :: struct {
    BatteryType: s8;
    BatteryLevel: s8;
}

XINPUT_CAPABILITIES :: struct {
    Type: s8;
    SubType: s8;
    Flags: s16;
    Gamepad: XINPUT_GAMEPAD;
    Vibration: XINPUT_VIBRATION;
}

XINPUT_GAMEPAD_DPAD_UP        :: 0x0001;
XINPUT_GAMEPAD_DPAD_DOWN      :: 0x0002;
XINPUT_GAMEPAD_DPAD_LEFT      :: 0x0004;
XINPUT_GAMEPAD_DPAD_RIGHT     :: 0x0008;
XINPUT_GAMEPAD_START          :: 0x0010;
XINPUT_GAMEPAD_BACK           :: 0x0020;
XINPUT_GAMEPAD_LEFT_THUMB     :: 0x0040;
XINPUT_GAMEPAD_RIGHT_THUMB    :: 0x0080;
XINPUT_GAMEPAD_LEFT_SHOULDER  :: 0x0100;
XINPUT_GAMEPAD_RIGHT_SHOULDER :: 0x0200;
XINPUT_GAMEPAD_A              :: 0x1000;
XINPUT_GAMEPAD_B              :: 0x2000;
XINPUT_GAMEPAD_X              :: 0x4000;
XINPUT_GAMEPAD_Y              :: 0x8000;

XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE  :: 7849;
XINPUT_GAMEPAD_RIGHT_THUMB_DEADZONE :: 8689;
XINPUT_GAMEPAD_TRIGGER_THRESHOLD    :: 30;

BATTERY_TYPE_DISCONNECTED     ::  0x00;
BATTERY_TYPE_WIRED            ::  0x01;
BATTERY_TYPE_ALKALINE         ::  0x02;
BATTERY_TYPE_NIMH             ::  0x03;
BATTERY_TYPE_UNKNOWN          ::  0xFF;

BATTERY_LEVEL_EMPTY           :: 0x00;
BATTERY_LEVEL_LOW             :: 0x01;
BATTERY_LEVEL_MEDIUM          :: 0x02;
BATTERY_LEVEL_FULL            :: 0x03;

XUSER_MAX_COUNT               :: 4;

XUSER_INDEX_ANY               :: 0x000000FF;

ERROR_DEVICE_NOT_CONNECTED :: 1167;
ERROR_INSUFFICIENT_BUFFER :: 122;
ERROR_SUCCESS :: 0;

XInputGetStateStub :: (dwUserIndex: s32, pState: *XINPUT_STATE) -> s32 #c_callback {
    return ERROR_DEVICE_NOT_CONNECTED;
}

XInputSetStateStub :: (dwUserIndex: s32, pState: *XINPUT_VIBRATION) -> s32 #c_callback {
    return ERROR_DEVICE_NOT_CONNECTED;
}

__XInputGetState: (dwUserIndex: s32, pState: *XINPUT_STATE) -> s32 #foreign;
__XInputSetState: (dwUserIndex: s32, pState: *XINPUT_VIBRATION) -> s32 #foreign;

wglChoosePixelFormatARB: (hDC: HDC, piAttribIList: *s32, pfAttribFList: *float, nMaxFormats: u32, piFormats: *s32, nNumFormats: *u32) -> BOOL #foreign;
wglCreateContextAttribsARB: (hDC: HDC, hShareContext: HGLRC, attribList: *s32) -> HGLRC #foreign;

os_create_window :: (width: s32, height: s32, title: string) -> OS_Window {
    if (!window_class_initted) {
        init_window_class();
    }

    hInstance := GetModuleHandleA(null);
    c_title := to_c_string(title);
    ret := CreateWindowExA(0, WINDOW_CLASS_NAME.data, c_title, WS_OVERLAPPEDWINDOW | WS_VISIBLE, 0, 0, width, height, 0, 0, hInstance, null);
    free(c_title);
    return ret;
}


os_create_gl_context :: (win: OS_Window) -> OS_GL_Context {
    hdc := GetDC(win);

    if (wglChoosePixelFormatARB) {
        int_attribs := {:s32:
            WGL_DRAW_TO_WINDOW_ARB, GL_TRUE,
            WGL_SUPPORT_OPENGL_ARB, GL_TRUE,
            WGL_DOUBLE_BUFFER_ARB, GL_TRUE,
            WGL_PIXEL_TYPE_ARB, WGL_TYPE_RGBA_ARB,
            WGL_COLOR_BITS_ARB, 32,
            WGL_DEPTH_BITS_ARB, 24,
            WGL_STENCIL_BITS_ARB, 8,
            0,
        };

        float_attribs := {:float: 0};
        num_formats: u32;
        format: s32;
        res := wglChoosePixelFormatARB(hdc, int_attribs.data, float_attribs.data, 1, *format, *num_formats);
        if (res) {
            pfd: PIXELFORMATDESCRIPTOR;
            DescribePixelFormat(hdc, format, size_of(PIXELFORMATDESCRIPTOR), *pfd);
            SetPixelFormat(hdc, format, *pfd);
        } else {
            print("%\n", GetLastError());
            assert(false);
        }
    } else {
        pfd: PIXELFORMATDESCRIPTOR;
        pfd.nSize = size_of(PIXELFORMATDESCRIPTOR);
        pfd.nVersion = 1;
        pfd.dwFlags = PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL | PFD_DOUBLEBUFFER;
        pfd.iPixelType = PFD_TYPE_RGBA;
        pfd.cColorBits = 32;
        pfd.cDepthBits = 24;
        pfd.cStencilBits = 8;
        pfd.iLayerType = PFD_MAIN_PLANE;

        cpf := ChoosePixelFormat(hdc, *pfd);
        DescribePixelFormat(hdc, cpf, size_of(PIXELFORMATDESCRIPTOR), *pfd);
        SetPixelFormat(hdc, cpf, *pfd);
    }

    if (wglCreateContextAttribsARB) {
        #if DEBUG {
            attribs := {:s32:
                WGL_CONTEXT_MAJOR_VERSION_ARB, 3,
                WGL_CONTEXT_MINOR_VERSION_ARB, 0,
                WGL_CONTEXT_FLAGS_ARB, cast(s32) (WGL_CONTEXT_FORWARD_COMPATIBLE_BIT_ARB | WGL_CONTEXT_DEBUG_BIT_ARB),
                // WGL_CONTEXT_PROFILE_MASK_ARB, WGL_CONTEXT_COMPATIBILITY_PROFILE_BIT_ARB,
                WGL_CONTEXT_PROFILE_MASK_ARB, WGL_CONTEXT_CORE_PROFILE_BIT_ARB,
                0,
            };
        } else {
            attribs: [] s16 = {:s16:
                    WGL_CONTEXT_MAJOR_VERSION_ARB, 3,
                    WGL_CONTEXT_MINOR_VERSION_ARB, 0,
                    WGL_CONTEXT_FLAGS_ARB, WGL_CONTEXT_FORWARD_COMPATIBLE_BIT_ARB,
                    // WGL_CONTEXT_PROFILE_MASK_ARB, WGL_CONTEXT_COMPATIBILITY_PROFILE_BIT_ARB,
                    WGL_CONTEXT_PROFILE_MASK_ARB, WGL_CONTEXT_CORE_PROFILE_BIT_ARB,
                    0,
            };
        }
        return wglCreateContextAttribsARB(hdc, 0, attribs.data);
    } else {
       return wglCreateContext(hdc);
    }
}

os_close_window :: (win: OS_Window) {
    DestroyWindow(win);
}

os_swap_buffers :: (win: OS_Window) {
    SwapBuffers(GetDC(win));
}

wglSwapIntervalStub :: (interval: s16) -> s16 #c_callback {
    assert(false);
    return 0;
}

os_set_vsync :: (on: bool) {
    // @Cleanup we should query these at startup
    wglSwapIntervalEXT : (interval: s16) -> s16 #foreign = xx wglSwapIntervalStub;
    wglGetExtensionsStringEXT: () -> *u8 #foreign = xx os_load_gl_func("wglGetExtensionsStringEXT");

    if (strstr(wglGetExtensionsStringEXT(), to_c_string("EXT_swap_control"))) {
        wglSwapIntervalEXT = xx os_load_gl_func("wglSwapIntervalEXT");
        assert(wglSwapIntervalEXT != null);
    }

    if (on) wglSwapIntervalEXT(1);
    else wglSwapIntervalEXT(0);
}

 os_pump_input :: () {
    update_window_events();

    array_reset(*joysticks);
    for 0..XUSER_MAX_COUNT-1 {
        st: XINPUT_STATE;
        if (__XInputGetState(xx it, *st) == ERROR_SUCCESS) {
            joy: Joystick;
            pad := *st.Gamepad;

            buttons: u16;
            if (pad.wButtons & XINPUT_GAMEPAD_DPAD_UP) buttons |= JOYSTICK_BUTTON_DUP;
            if (pad.wButtons & XINPUT_GAMEPAD_DPAD_DOWN) buttons |= JOYSTICK_BUTTON_DDOWN;
            if (pad.wButtons & XINPUT_GAMEPAD_DPAD_LEFT) buttons |= JOYSTICK_BUTTON_DLEFT;
            if (pad.wButtons & XINPUT_GAMEPAD_DPAD_RIGHT) buttons |= JOYSTICK_BUTTON_DRIGHT;

            if (pad.wButtons & XINPUT_GAMEPAD_START) buttons |= JOYSTICK_BUTTON_START;
            if (pad.wButtons & XINPUT_GAMEPAD_BACK) buttons |= JOYSTICK_BUTTON_BACK;

            if (pad.wButtons & XINPUT_GAMEPAD_LEFT_THUMB) buttons |= JOYSTICK_BUTTON_LSTICK;
            if (pad.wButtons & XINPUT_GAMEPAD_RIGHT_THUMB) buttons |= JOYSTICK_BUTTON_RSTICK;

            if (pad.wButtons & XINPUT_GAMEPAD_LEFT_SHOULDER) buttons |= JOYSTICK_BUTTON_LBUMPER;
            if (pad.wButtons & XINPUT_GAMEPAD_RIGHT_SHOULDER) buttons |= JOYSTICK_BUTTON_RBUMPER;

            if (pad.wButtons & XINPUT_GAMEPAD_A) buttons |= JOYSTICK_BUTTON_A;
            if (pad.wButtons & XINPUT_GAMEPAD_B) buttons |= JOYSTICK_BUTTON_B;
            if (pad.wButtons & XINPUT_GAMEPAD_X) buttons |= JOYSTICK_BUTTON_X;
            if (pad.wButtons & XINPUT_GAMEPAD_Y) buttons |= JOYSTICK_BUTTON_Y;

            joy.buttons = buttons;
            joy.triggers.left = (cast(float)pad.bLeftTrigger) / 255.0;
            joy.triggers.right = (cast(float)pad.bRightTrigger) / 255.0;

            if (pad.sThumbLX < -XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE || pad.sThumbLX > XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE)
                joy.left_thumb.x = (cast(float)pad.sThumbLX) / 32767.0;
            if (pad.sThumbLY < -XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE || pad.sThumbLY > XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE)
                joy.left_thumb.y = (cast(float)pad.sThumbLY) / 32767.0;

            if (pad.sThumbRX < -XINPUT_GAMEPAD_RIGHT_THUMB_DEADZONE || pad.sThumbRX > XINPUT_GAMEPAD_RIGHT_THUMB_DEADZONE)
                joy.right_thumb.x = (cast(float)pad.sThumbRX) / 32767.0;
            if (pad.sThumbRY < -XINPUT_GAMEPAD_RIGHT_THUMB_DEADZONE || pad.sThumbRY > XINPUT_GAMEPAD_RIGHT_THUMB_DEADZONE)
                joy.right_thumb.y = (cast(float)pad.sThumbRY) / 32767.0;
            
            array_add(*joysticks, joy);
        }
    }
}

os_make_current :: (win: OS_Window, ctx: OS_GL_Context) {
    wglMakeCurrent(GetDC(win), ctx);
}

os_get_window_dimensions :: (win: OS_Window, width: *s32, height: *s32) {
    rect: RECT;
    GetWindowRect(win, *rect);
    <<width = (rect.right - rect.left);
    <<height = (rect.bottom - rect.top);
}

os_get_mouse_position :: (win: OS_Window, x: *s32, y: *s32) -> bool {
    rect: RECT;
    GetWindowRect(win, *rect);
    pt: POINT;
    GetCursorPos(*pt);
    <<x = (pt.x - rect.left);
    <<y = (pt.y - rect.top);
    return true;
}

gl_lib: HMODULE;

os_init_platform :: () {
    xinput := LoadLibraryA("xinput1_3.dll");
    if (xinput) {
        __XInputGetState = xx GetProcAddress(xinput, "XInputGetState");
        __XInputSetState = xx GetProcAddress(xinput, "XInputSetState");
    } else {
        __XInputGetState = xx XInputGetStateStub;
        __XInputSetState = xx XInputSetStateStub;
    }

    gl_lib = LoadLibraryA("opengl32.dll");
    assert(gl_lib != 0);

    dummy := os_create_window(50, 50, "");
    ShowWindow(dummy, SW_HIDE);
    glc := os_create_gl_context(dummy);
    os_make_current(dummy, glc);

    wglChoosePixelFormatARB = xx os_load_gl_func("wglChoosePixelFormatARB");
    wglCreateContextAttribsARB = xx os_load_gl_func("wglCreateContextAttribsARB");

    init_gl_extensions(*gl_30_api);

    wglMakeCurrent(0, 0);
    wglDeleteContext(glc);
    os_close_window(dummy);
}

find_and_truncate_character_from_right :: (s: string, c: int) -> string {
    cursor := s.count - 1;
    while cursor >= 0 {
        if s[cursor] == c  return substring(s, 0, cursor); // @TODO -1 ?
        cursor -= 1;
    }

    return "";
}

os_get_executable_path :: () -> string {
    module := GetModuleHandleA(null);
    FSIZE :: 512;
    filename: [FSIZE] u8;
    size := GetModuleFileNameA(module, filename.data, FSIZE);
    assert(GetLastError() != ERROR_INSUFFICIENT_BUFFER);
    fname := point_at_c_string(filename.data);
    path := find_and_truncate_character_from_right(fname, #char "\\");
    return copy_string(path);
}

os_load_gl_func :: (name: string) -> *void {
    c_name := to_c_string(name);
    defer free(c_name);

    p := wglGetProcAddress(c_name);
    if(p == cast(*void)0 || (p == cast(*void)0x1) || (p == cast(*void)0x2) || (p == cast(*void)0x3) || (p == cast(*void)-1) ) {
        p = GetProcAddress(gl_lib, c_name);
        if (!p) print("Couldnt load func %\n", name);
    }
    return p;
}

Watch_Direct :: struct {
    handle: HANDLE;
    overlapped: OVERLAPPED;
    notif_data: *u8;
    notif_bytes: s32;
    name: string;
};

directs: [..] Watch_Direct;

read_dir_changes :: (dir: *Watch_Direct) {
    dir.notif_bytes = 0;

    status := ReadDirectoryChangesW(dir.handle, dir.notif_data, 0x8000, 1,
                    FILE_NOTIFY_CHANGE_FILE_NAME | FILE_NOTIFY_CHANGE_ATTRIBUTES |
                    FILE_NOTIFY_CHANGE_SIZE | FILE_NOTIFY_CHANGE_LAST_WRITE | FILE_NOTIFY_CHANGE_SECURITY,
                    *dir.notif_bytes, *dir.overlapped, null);
}

os_watch_dir :: (path: string)  {
    dir: Watch_Direct;

    c_path := to_c_string(path);
    defer free(c_path);

    dir.handle = CreateFileA(c_path, FILE_LIST_DIRECTORY, FILE_SHARE_READ | FILE_SHARE_DELETE | FILE_SHARE_WRITE,
                            null, OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS | FILE_FLAG_OVERLAPPED, null);
    if (dir.handle == INVALID_HANDLE_VALUE) {
        print("ERROR: Couldnt open '%' for watching\n", path);
        return;
    }

    dir.overlapped.hEvent = CreateEventA(null, 0, 0, null);
    dir.overlapped.Offset = 0;

    if (dir.overlapped.hEvent == INVALID_HANDLE_VALUE) {
        CloseHandle(dir.handle);
        print("Couldn't create event for watching '%'\n", path);
        return;
    }

    dir.name = copy_string(path);
    convert_slashes(dir.name);
    if (dir.name[path.count-1] != #char "/") {
        n := dir.name;
        dir.name = concatenate(n, "/");
        free(n);
    }
    dir.notif_data = alloc(0x8000);
    array_add(*directs, dir);
    read_dir_changes(*directs[directs.count-1]);
}

os_pump_file_notifications :: (callback: FILE_NOTIF_FUNC, userdata: *void) {
    array_reset(*file_changes);
    for directs {
        if (!HasOverlappedIoCompleted(it.overlapped)) continue;

        count: s32;
        GetOverlappedResult(it.handle, *it.overlapped, *count, 0);
        read_dir_changes(*it);
        if (!count) continue;

        print("%\n", count);

        info := cast(*FILE_NOTIFY_INFORMATION) it.notif_data;
        while (true) {
            buf: [1000] u8;
            len := WideCharToMultiByte(CP_ACP, WC_NO_BEST_FIT_CHARS, info.FileName.data, info.FileNameLength/2, buf.data, 1000, null, null);
            buf[len] = 0;

            path := concatenate(it.name, point_at_c_string(buf.data));
            convert_slashes(path);
            print("%\n", path);
            f: File_Notification;
            f.name = path;

            array_add(*file_changes, f);

            if (info.NextEntryOffset) {
                data := cast(*u8) info;
                data += info.NextEntryOffset;
                info = cast(*FILE_NOTIFY_INFORMATION) data;
            } else {
                break;
            }
        }
    }
}
