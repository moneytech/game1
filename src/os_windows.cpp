
#include "os_api.h"
#include <Windowsx.h>
#include <XInput.h>

#include <GL/gl.h>
#include "wglext.h"

static bool initialized = false;
static WNDCLASS wndclass {0};
static s32 num_open_windows = 0;
static s32 accum_wheel_delta = 0;

Array<Input_Event> input_events;
Array<Joystick> joysticks;
Array<File_Notification> file_changes;

DWORD WINAPI XInputGetStateStub(DWORD dwUserIndex, XINPUT_STATE *pState) {
    return ERROR_DEVICE_NOT_CONNECTED;
}

DWORD WINAPI XInputSetStateStub(DWORD dwUserIndex, XINPUT_VIBRATION *pState) {
    return ERROR_DEVICE_NOT_CONNECTED;
}

typedef DWORD WINAPI xinput_get_state (DWORD dwUserIndex, XINPUT_STATE *pState);
typedef DWORD WINAPI xinput_set_state (DWORD dwUserIndex, XINPUT_VIBRATION *pState);

xinput_get_state *__XInputGetState = XInputGetStateStub;
xinput_set_state *__XInputSetState = XInputSetStateStub;

PFNWGLCHOOSEPIXELFORMATARBPROC wglChoosePixelFormatARB = nullptr;
PFNWGLCREATECONTEXTATTRIBSARBPROC wglCreateContextAttribsARB = nullptr;

#include <cstdio>
LRESULT CALLBACK wnd_proc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam) {
	switch (message) {
		// case WM_CREATE:
		// 	break;
		case WM_CLOSE:
			Input_Event ev;
            ev.type = Event_Type::QUIT;
            ev.window = hWnd;
            input_events.add(ev);
			break;
		case WM_SYSKEYUP:
		case WM_KEYUP:
		case WM_SYSKEYDOWN:
		case WM_KEYDOWN: {
			if (lParam & (1 << 30) && ((lParam & (1 << 31)) == 0)) break; // skip repeats
			u32 vkcode = wParam;
        	Input_Event ev;
            ev.type = Event_Type::KEYBOARD;
            ev.down = (lParam & (1 << 31)) == 0;
            if (vkcode == VK_CONTROL) {
                ev.key = Key_Type::LCONTROL;
            } else if (vkcode == 'S') {
                ev.key = Key_Type::KEY_S;
            } else if (vkcode == 'T') {
                ev.key = Key_Type::KEY_T;
            } else {
                break;
            }
            ev.mod = (GetKeyState(VK_CONTROL) & (1 << 15)) ? Key_Type::LCONTROL : (Key_Type)-1;
            ev.window = hWnd;
            input_events.add(ev);
			break;
		}

		case WM_LBUTTONDOWN:
		case WM_LBUTTONUP: {
			Input_Event ev;
            ev.type = Event_Type::MOUSE_BUTTON;
            ev.window = hWnd;
            ev.down = (wParam & MK_LBUTTON) != 0;
            ev.button = Button_Type::MOUSE_LEFT;
            ev.x = GET_X_LPARAM(lParam);
            ev.y = GET_Y_LPARAM(lParam);

           	input_events.add(ev);
			break;
		}
		case WM_MBUTTONDOWN:
		case WM_MBUTTONUP: {
			Input_Event ev;
            ev.type = Event_Type::MOUSE_BUTTON;
            ev.window = hWnd;
            ev.down = (wParam & MK_MBUTTON) != 0;
            ev.button = Button_Type::MOUSE_MIDDLE;
            ev.x = GET_X_LPARAM(lParam);
            ev.y = GET_Y_LPARAM(lParam);

           	input_events.add(ev);
			break;
		}
		case WM_RBUTTONDOWN:
		case WM_RBUTTONUP: {
			Input_Event ev;
            ev.type = Event_Type::MOUSE_BUTTON;
            ev.window = hWnd;
            ev.down = (wParam & MK_RBUTTON) != 0;
            ev.button = Button_Type::MOUSE_RIGHT;
            ev.x = GET_X_LPARAM(lParam);
            ev.y = GET_Y_LPARAM(lParam);

           	input_events.add(ev);
			break;

		}

		case WM_MOUSEWHEEL: {
			Input_Event ev;
            ev.type = Event_Type::MOUSE_BUTTON;
            ev.window = hWnd;
            ev.button = Button_Type::MOUSE_SCROLL;
            ev.x = GET_X_LPARAM(lParam);
            ev.y = GET_Y_LPARAM(lParam);

            auto zDelta = GET_WHEEL_DELTA_WPARAM(wParam);
            if (zDelta < 0) {
            	ev.down = true;
            } else {
            	ev.down = false;
            }

            accum_wheel_delta += zDelta;

            while (accum_wheel_delta < -WHEEL_DELTA || accum_wheel_delta > WHEEL_DELTA) {
            	accum_wheel_delta /= WHEEL_DELTA;
            	input_events.add(ev);
            }

			break;
		}

		default:
			return DefWindowProc(hWnd, message, wParam, lParam);
	}

	return 0;
}

OS_Window os_create_window(s32 width, s32 height, const char *title) {
	if (!initialized) {
		initialized = true;
		wndclass.lpfnWndProc = wnd_proc;
		wndclass.hInstance = GetModuleHandle(nullptr);
		wndclass.hCursor = LoadCursor(NULL, IDC_ARROW);
		wndclass.hbrBackground = (HBRUSH) COLOR_BACKGROUND;
		wndclass.lpszClassName = "SimpWndClass";
		wndclass.style = CS_OWNDC;
		if (!RegisterClass(&wndclass)) {
			// printf("ERROR: count not register WNDCLASS\n"); // @TODO proper error system
			assert(0);
			return 0;
		}
	}

	HINSTANCE hInstance = GetModuleHandle(nullptr);
	num_open_windows++;
	return CreateWindowA(wndclass.lpszClassName, title, WS_OVERLAPPEDWINDOW | WS_VISIBLE, 0, 0, width, height, 0, 0, hInstance, 0);
}


OS_GL_Context os_create_gl_context(OS_Window win) {
    HDC hdc = GetDC(win);

    if (wglChoosePixelFormatARB) {
        const int int_attribs[] = {
            WGL_DRAW_TO_WINDOW_ARB, GL_TRUE,
            WGL_SUPPORT_OPENGL_ARB, GL_TRUE,
            WGL_DOUBLE_BUFFER_ARB, GL_TRUE,
            WGL_PIXEL_TYPE_ARB, WGL_TYPE_RGBA_ARB,
            WGL_COLOR_BITS_ARB, 32,
            WGL_DEPTH_BITS_ARB, 24,
            WGL_STENCIL_BITS_ARB, 8,
            0,
        };

        const float float_attribs[] = {0};
        UINT num_formats;
        INT format;
        if (wglChoosePixelFormatARB(hdc, &int_attribs[0], &float_attribs[0], 1, &format, &num_formats)) {
            PIXELFORMATDESCRIPTOR pfd = {0};
            DescribePixelFormat(hdc, format, sizeof(PIXELFORMATDESCRIPTOR), &pfd);
            SetPixelFormat(hdc, format, &pfd);
        } else {
            assert(0);
        }
    } else {
        PIXELFORMATDESCRIPTOR pfd = {0};
        pfd.nSize = sizeof(PIXELFORMATDESCRIPTOR);
        pfd.nVersion = 1;
        pfd.dwFlags = PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL | PFD_DOUBLEBUFFER;
        pfd.iPixelType = PFD_TYPE_RGBA;
        pfd.cColorBits = 32;
        pfd.cDepthBits = 24;
        pfd.cStencilBits = 8;
        pfd.iLayerType = PFD_MAIN_PLANE;

        int cpf = ChoosePixelFormat(hdc, &pfd);
        DescribePixelFormat(hdc, cpf, sizeof(PIXELFORMATDESCRIPTOR), &pfd);
        SetPixelFormat(hdc, cpf, &pfd);
    }

    if (wglCreateContextAttribsARB) {
        const int attribs[] = {
            WGL_CONTEXT_MAJOR_VERSION_ARB, 3,
            WGL_CONTEXT_MINOR_VERSION_ARB, 0,
            WGL_CONTEXT_FLAGS_ARB, WGL_CONTEXT_FORWARD_COMPATIBLE_BIT_ARB
            #if DEBUG
            | WGL_CONTEXT_DEBUG_BIT_ARB
            #endif
            ,
            // WGL_CONTEXT_PROFILE_MASK_ARB, WGL_CONTEXT_COMPATIBILITY_PROFILE_BIT_ARB,
            WGL_CONTEXT_PROFILE_MASK_ARB, WGL_CONTEXT_CORE_PROFILE_BIT_ARB,
            0,
        };
        return wglCreateContextAttribsARB(hdc, 0, &attribs[0]);
    } else {
	   return wglCreateContext(hdc);
    }
}

void os_close_window(OS_Window win) {
	num_open_windows--;
	DestroyWindow(win);
}

void os_swap_buffers(OS_Window win) {
	SwapBuffers(GetDC(win));
}

static BOOL WINAPI wglSwapIntervalStub (int interval) {
    assert(0);
    return FALSE;
}

void os_set_vsync(bool on) {
    PFNWGLSWAPINTERVALEXTPROC wglSwapIntervalEXT = wglSwapIntervalStub;
    PFNWGLGETEXTENSIONSSTRINGEXTPROC wglGetExtensionsStringEXT = (PFNWGLGETEXTENSIONSSTRINGEXTPROC) os_load_gl_func("wglGetExtensionsStringEXT");

    if (strstr(wglGetExtensionsStringEXT(), "EXT_swap_control")) {
        wglSwapIntervalEXT = (PFNWGLSWAPINTERVALEXTPROC) os_load_gl_func("wglSwapIntervalEXT");
        assert(wglSwapIntervalEXT);
    }

    if (on) wglSwapIntervalEXT(1);
    else wglSwapIntervalEXT(0);
}

s32  os_number_open_windows() {
	return num_open_windows;
}

void os_pump_input() {
	input_events.clear();

	MSG msg = {0};
	while (PeekMessage(&msg, 0, 0, 0, PM_REMOVE)) {
		TranslateMessage(&msg);
		DispatchMessage(&msg);
	}

    joysticks.clear();
    for (int i = 0; i < XUSER_MAX_COUNT; ++i) {
        XINPUT_STATE st;
        if (__XInputGetState(i, &st) == ERROR_SUCCESS) {
            Joystick joy;
            memset(&joy, 0, sizeof(Joystick));
            XINPUT_GAMEPAD *pad = &st.Gamepad;

            u16 buttons = 0;
            if (pad->wButtons & XINPUT_GAMEPAD_DPAD_UP) buttons |= JOYSTICK_BUTTON_DUP;
            if (pad->wButtons & XINPUT_GAMEPAD_DPAD_DOWN) buttons |= JOYSTICK_BUTTON_DDOWN;
            if (pad->wButtons & XINPUT_GAMEPAD_DPAD_LEFT) buttons |= JOYSTICK_BUTTON_DLEFT;
            if (pad->wButtons & XINPUT_GAMEPAD_DPAD_RIGHT) buttons |= JOYSTICK_BUTTON_DRIGHT;

            if (pad->wButtons & XINPUT_GAMEPAD_START) buttons |= JOYSTICK_BUTTON_START;
            if (pad->wButtons & XINPUT_GAMEPAD_BACK) buttons |= JOYSTICK_BUTTON_BACK;

            if (pad->wButtons & XINPUT_GAMEPAD_LEFT_THUMB) buttons |= JOYSTICK_BUTTON_LSTICK;
            if (pad->wButtons & XINPUT_GAMEPAD_RIGHT_THUMB) buttons |= JOYSTICK_BUTTON_RSTICK;

            if (pad->wButtons & XINPUT_GAMEPAD_LEFT_SHOULDER) buttons |= JOYSTICK_BUTTON_LBUMPER;
            if (pad->wButtons & XINPUT_GAMEPAD_RIGHT_SHOULDER) buttons |= JOYSTICK_BUTTON_RBUMPER;

            if (pad->wButtons & XINPUT_GAMEPAD_A) buttons |= JOYSTICK_BUTTON_A;
            if (pad->wButtons & XINPUT_GAMEPAD_B) buttons |= JOYSTICK_BUTTON_B;
            if (pad->wButtons & XINPUT_GAMEPAD_X) buttons |= JOYSTICK_BUTTON_X;
            if (pad->wButtons & XINPUT_GAMEPAD_Y) buttons |= JOYSTICK_BUTTON_Y;

            joy.buttons = buttons;
            joy.triggers.left = ((float)pad->bLeftTrigger) / 255.0f;
            joy.triggers.right = ((float)pad->bRightTrigger) / 255.0f;

            if (pad->sThumbLX < -XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE || pad->sThumbLX > XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE)
                joy.left_thumb.x = ((float)pad->sThumbLX) / 32767.0f;
            if (pad->sThumbLY < -XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE || pad->sThumbLY > XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE)
                joy.left_thumb.y = ((float)pad->sThumbLY) / 32767.0f;

            if (pad->sThumbRX < -XINPUT_GAMEPAD_RIGHT_THUMB_DEADZONE || pad->sThumbRX > XINPUT_GAMEPAD_RIGHT_THUMB_DEADZONE)
                joy.right_thumb.x = ((float)pad->sThumbRX) / 32767.0f;
            if (pad->sThumbRY < -XINPUT_GAMEPAD_RIGHT_THUMB_DEADZONE || pad->sThumbRY > XINPUT_GAMEPAD_RIGHT_THUMB_DEADZONE)
                joy.right_thumb.y = ((float)pad->sThumbRY) / 32767.0f;
            
            joysticks.add(joy);
        }
    }
}

void os_make_current(OS_Window win, OS_GL_Context ctx) {
	wglMakeCurrent(GetDC(win), ctx);
}

void os_get_window_dimensions(OS_Window win, s32 *width, s32 *height) {
	RECT rect;
	GetWindowRect(win, &rect);
	*width = (rect.right - rect.left);
	*height = (rect.bottom - rect.top);
}

bool os_get_mouse_position(OS_Window win, s32 *x, s32 *y) {
	RECT rect;
	GetWindowRect(win, &rect);
	POINT pt;
	GetCursorPos(&pt);
	*x = (pt.x - rect.left);
	*y = (pt.y - rect.top);
	return true;
}

static HMODULE gl_lib;

void os_init_platform() {
    HMODULE xinput = LoadLibrary("xinput1_3.dll");
    if (xinput) {
        __XInputGetState = (xinput_get_state *) GetProcAddress(xinput, "XInputGetState");
        __XInputSetState = (xinput_set_state *) GetProcAddress(xinput, "XInputSetState");
    }

    gl_lib = LoadLibrary("opengl32.dll");
    assert(gl_lib);

    OS_Window dummy = os_create_window(50, 50, "");
    ShowWindow(dummy, SW_HIDE);
    OS_GL_Context glc = os_create_gl_context(dummy);
    os_make_current(dummy, glc);

    wglChoosePixelFormatARB = (PFNWGLCHOOSEPIXELFORMATARBPROC)os_load_gl_func("wglChoosePixelFormatARB");
    wglCreateContextAttribsARB = (PFNWGLCREATECONTEXTATTRIBSARBPROC)os_load_gl_func("wglCreateContextAttribsARB");

    wglMakeCurrent(0, 0);
    wglDeleteContext(glc);
    os_close_window(dummy);
}

char *os_get_executable_path() {
    HMODULE module = GetModuleHandle(nullptr);
    const int FSIZE = 512;
    char filename[FSIZE];
    DWORD size = GetModuleFileName(module, &filename[0], FSIZE);
    assert(GetLastError() != ERROR_INSUFFICIENT_BUFFER);

    char *data = (char *)malloc(size);
    memcpy(data, filename, size);
    data[strrchr(data, '\\')-data] = 0;
    return data;
}

void *os_load_gl_func(const char *name) {
    void *p = wglGetProcAddress(name);
    if(p == 0 || (p == (void*)0x1) || (p == (void*)0x2) || (p == (void*)0x3) || (p == (void*)-1) ) {
        p = GetProcAddress(gl_lib, name);
        if (!p) printf("Couldnt load func %s\n", name);
    }
    return p;
}

struct Watch_Direct {
    HANDLE handle;
    OVERLAPPED overlapped;
    char *notif_data;
    DWORD notif_bytes;
    char *name;
};

static Array<Watch_Direct> directs;

static void read_dir_changes(Watch_Direct *dir) {
    dir->notif_bytes = 0;

    int status = ReadDirectoryChangesW(dir->handle, dir->notif_data, 0x8000, TRUE,
                    FILE_NOTIFY_CHANGE_FILE_NAME | FILE_NOTIFY_CHANGE_ATTRIBUTES |
                    FILE_NOTIFY_CHANGE_SIZE | FILE_NOTIFY_CHANGE_LAST_WRITE | FILE_NOTIFY_CHANGE_SECURITY,
                    &dir->notif_bytes, &dir->overlapped, nullptr);
}

void os_watch_dir(const char *path) {
    Watch_Direct dir;
    dir.handle = CreateFileA(path, FILE_LIST_DIRECTORY, FILE_SHARE_READ | FILE_SHARE_DELETE | FILE_SHARE_WRITE,
                            nullptr, OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS | FILE_FLAG_OVERLAPPED, nullptr);
    if (dir.handle == INVALID_HANDLE_VALUE) {
        printf("ERROR: Couldnt open '%s' for watching\n", path);
        return;
    }

    dir.overlapped.hEvent = CreateEventA(nullptr, FALSE, FALSE, nullptr);
    dir.overlapped.Offset = 0;

    if (dir.overlapped.hEvent == INVALID_HANDLE_VALUE) {
        CloseHandle(dir.handle);
        printf("Couldn't create event for watching '%s'\n", path);
        return;
    }

    dir.name = copy_c_string(path);
    if (dir.name[strlen(path)-1] != '/') {
        char *n = dir.name;
        dir.name = concatenate(n, "/");
        FREE_MEMORY(n);
    }
    dir.notif_data = GET_MEMORY_SIZED(0x8000);
    directs.add(dir);
    read_dir_changes(&directs[directs.count-1]);
}

void os_pump_file_notifications(file_notif_func *callback, void *userdata) {
    file_changes.clear();
    for (int i = 0; i < directs.count; ++i) {
        auto &it = directs[i];

        if (!HasOverlappedIoCompleted(&it.overlapped)) continue;

        DWORD count;
        GetOverlappedResult(it.handle, &it.overlapped, &count, FALSE);
        read_dir_changes(&it);
        if (!count) continue;

        printf("%d\n", count);

        FILE_NOTIFY_INFORMATION *info = (FILE_NOTIFY_INFORMATION *)it.notif_data;
        while (true) {
            char buf[1000];
            int len = WideCharToMultiByte(CP_ACP, WC_NO_BEST_FIT_CHARS, &info->FileName[0], info->FileNameLength/2, &buf[0], 1000, nullptr, nullptr);
            buf[len] = 0;

            char *path = concatenate(it.name, buf);
            printf("%s\n", path);
            File_Notification f;
            copy_c_string(&f.name[0], path);
            FREE_MEMORY(path);
            if (info->Action == FILE_ACTION_MODIFIED) file_changes.add(f);

            if (info->NextEntryOffset) {
                char *data = (char *)info;
                data += info->NextEntryOffset;
                info = (FILE_NOTIFY_INFORMATION *)data;
            } else {
                break;
            }
        }
    }
}

#include <direct.h>

void setcwd(const char *path) {
    _chdir(path);
}