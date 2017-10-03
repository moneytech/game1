
#import "Basic";
#import "GL";
#import "Compiler";

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
    assert(gl_lib != null); // we should really send an error here to the user, maybe...

    init_global_display();

    dummy := os_create_window(50, 50, "");
    XUnmapWindow(x_global_display, dummy);
    glc := os_create_gl_context(dummy);
    os_make_current(dummy, glc);

    // wglChoosePixelFormatARB = xx os_load_gl_func("wglChoosePixelFormatARB");
    // wglCreateContextAttribsARB = xx os_load_gl_func("wglCreateContextAttribsARB");

    init_gl_extensions(*gl_30_api);

    glXMakeCurrent(x_global_display, None, null);
    os_close_window(dummy);
}

os_create_window :: (width: s32, height: s32, title: string) -> OS_Window {
	return create_window(width, height, title);
}

os_create_gl_context :: (win: Window) -> OS_GL_Context {
	XLockDisplay(x_global_display);

    attr := {:s32:
        GLX_RGBA, GLX_DEPTH_SIZE, 24, GLX_DOUBLEBUFFER, None
    };
    vi := glXChooseVisual(x_global_display, 0, attr.data);

    glc := glXCreateContext(x_global_display, vi, null, GL_TRUE);
    glXMakeCurrent(x_global_display, win, glc);
    gwa: XWindowAttributes;
    XGetWindowAttributes(x_global_display, win, *gwa);
    glViewport(0, 0, xx gwa.width, xx gwa.height);

    XUnlockDisplay(x_global_display);
	return glc;
}

os_make_current :: (win: Window, glc: OS_GL_Context) {
	glXMakeCurrent(x_global_display, win, glc);
}

os_set_vsync :: (on: bool) {

}

os_close_window :: (win: OS_Window) {
	XDestroyWindow(x_global_display, win);
}

 os_pump_input :: () {
    update_window_events();

    array_reset(*joysticks);
    // @TODO joysticks
}

os_pump_file_notifications :: (callback: FILE_NOTIF_FUNC, userdata: *void) {
    array_reset(*file_changes);

    // @TODO 
    /*
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
    */
}
