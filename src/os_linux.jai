
#import "Basic";
#import "GL";
#import "Compiler";

#load "gl_api.jai";
#load "os_api.jai";

#scope_file
libdl :: #foreign_system_library "dl";

RTLD_LAZY          :: 0x00001;
RTLD_NOW           :: 0x00002;
RTLD_BINDING_MASK  :: 0x3;
RTLD_NOLOAD        :: 0x00004;
RTLD_DEEPBIND      :: 0x00008;

RTLD_GLOBAL        :: 0x00100;
RTLD_LOCAL         :: 0;

RTLD_NODELETE      :: 0x01000;

dlopen :: (filename: *u8, flags: s32) -> *void #foreign libdl;
dlclose :: (handle: *void) -> s32 #foreign libdl;

dlopen :: (filename: string, flags: s32 = RTLD_LAZY) -> *void {
	c_name := to_c_string(filename);
	defer free(c_name);
	out := dlopen(c_name, flags);
	return out;
}

#scope_export

OS_Window :: Window; // X11 window
OS_GL_Context :: GLXContext;

gl_lib: *void;

os_init_platform :: () {
    gl_lib = dlopen("libGL.so", RTLD_LAZY);
    // assert(gl_lib != 0);

    // dummy := os_create_window(50, 50, "");
    // ShowWindow(dummy, SW_HIDE);
    // glc := os_create_gl_context(dummy);
    // os_make_current(dummy, glc);

    // wglChoosePixelFormatARB = xx os_load_gl_func("wglChoosePixelFormatARB");
    // wglCreateContextAttribsARB = xx os_load_gl_func("wglCreateContextAttribsARB");

    // init_gl_extensions(*gl_30_api);

    // wglMakeCurrent(0, 0);
    // wglDeleteContext(glc);
    // os_close_window(dummy);
}
