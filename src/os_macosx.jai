
#import "Objective_C";
#import "Window_Creation";

OS_Window :: *NSWindow; // X11 window
OS_GL_Context :: *NSOpenGLContext;

os_init_platform :: () {
}

os_create_gl_context :: (win: *NSWindow) -> OS_GL_Context {
	gl_create_context(win, 4, 1);

	gl_load(*gl);

	view := NSWindow.contentView(win);
    if !view return null;
    if class(view) != class(OpenGL_View) return null;

    glview := cast(*OpenGL_View) view;
	return glview.gl_context;
}

os_get_window_dimensions :: (win: OS_Window) -> s32, s32 {
    view := NSWindow.contentView(win);
    if !view return -1, -1;

    frame := view.frame(view);

    return cast(s32) frame.size.width, cast(s32) frame.size.height;
}

os_make_current :: (win: OS_Window, glc: OS_GL_Context) {
	NSOpenGLContext.makeCurrentContext(glc);
}

os_set_vsync :: (on: bool) {

}

os_close_window :: (win: OS_Window) {
	NSWindow.performClose(win, win);
}

 os_pump_input :: () {
    update_window_events();

    array_reset(*joysticks);
    // @TODO joysticks
}

os_watch_dir :: (path: string)  {
    
}

os_pump_file_notifications :: (callback: FILE_NOTIF_FUNC, userdata: *void) {
    array_reset(*file_changes);
}