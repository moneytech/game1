

#ifndef OS_API_H
#define OS_API_H
#include <cstring>

#include "general.h"

#ifdef WIN32
typedef HWND OS_Window;
typedef HGLRC OS_GL_Context;
#else
#include <X11/X.h>
#include <GL/glx.h>
typedef Window OS_Window; // X11 Window
typedef GLXContext OS_GL_Context;
#endif


OS_Window os_create_window(s32 width, s32 height, const char *title);
OS_GL_Context os_create_gl_context(OS_Window win);
void os_close_window(OS_Window win);
void os_swap_buffers(OS_Window win);
s32  os_number_open_windows();
void os_pump_input();
void os_make_current(OS_Window win, OS_GL_Context ctx);
void os_get_window_dimensions(OS_Window win, s32 *width, s32 *height);
bool os_get_mouse_position(OS_Window win, s32 *x, s32 *y);
void os_init_platform();
char *os_get_executable_path();
void *os_load_gl_func(const char *name);
void os_set_vsync(bool flag);

struct File_Notification {
    int type;
    char name[256];
};

typedef void file_notif_func(File_Notification *notif, void *data);

void os_watch_dir(const char *path);
void os_pump_file_notifications(file_notif_func *callback, void *userdata);

void setcwd(const char *path);

enum Event_Type {
	NO_EVENT,
	KEYBOARD,
	MOUSE_BUTTON,
	QUIT
};
enum Button_Type {
	MOUSE_LEFT,
	MOUSE_RIGHT,
	MOUSE_MIDDLE, // press scroll-wheel
	MOUSE_SCROLL, // this is assumed as a tick since X11 is weird and maps scroll up/down as buttons
};

enum Key_Type {
	NONE,
	LCONTROL,
	KEY_S,
	KEY_T,
};

struct Input_Event {
	Event_Type type;
	OS_Window window;

	Button_Type button;
	int x, y;
	Key_Type key;
	Key_Type mod;
	bool down;
};

const u16 JOYSTICK_BUTTON_A        = (1 << 0);
const u16 JOYSTICK_BUTTON_B        = (1 << 1);
const u16 JOYSTICK_BUTTON_X        = (1 << 2);
const u16 JOYSTICK_BUTTON_Y        = (1 << 3);
const u16 JOYSTICK_BUTTON_DUP      = (1 << 4);
const u16 JOYSTICK_BUTTON_DDOWN    = (1 << 5);
const u16 JOYSTICK_BUTTON_DLEFT    = (1 << 6);
const u16 JOYSTICK_BUTTON_DRIGHT   = (1 << 7);
const u16 JOYSTICK_BUTTON_LBUMPER  = (1 << 8);
const u16 JOYSTICK_BUTTON_RBUMPER  = (1 << 9);
const u16 JOYSTICK_BUTTON_LSTICK   = (1 << 10);
const u16 JOYSTICK_BUTTON_RSTICK   = (1 << 11);
const u16 JOYSTICK_BUTTON_START    = (1 << 12);
const u16 JOYSTICK_BUTTON_BACK     = (1 << 13);


struct Joystick {
    u16 buttons;

    struct {
        union {
            float x;
            float left;
        };

        union {
            float y;
            float right;
        };
    } triggers, left_thumb, right_thumb;
};

extern Array<Input_Event> input_events;
extern Array<Joystick> joysticks;
extern Array<File_Notification> file_changes;

#endif
