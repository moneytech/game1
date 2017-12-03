
#import "Basic";
#import "GL";
#import "Compiler";
#import "Window_Creation";

#load "os_api.jai";

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

HasOverlappedIoCompleted :: inline (overlapped: OVERLAPPED) -> bool {
    return (cast (s32) overlapped.Internal) != STATUS_PENDING;
}

#scope_export

OS_Window :: HWND;
OS_GL_Context :: HGLRC;

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

WINDOWED_STYLE : s32   : WS_VISIBLE | WS_CAPTION | WS_MINIMIZEBOX | WS_MAXIMIZEBOX | WS_SYSMENU | WS_SIZEBOX;
FULLSCREEN_STYLE : s32 : WS_VISIBLE | WS_POPUP;
os_create_window :: (width: s32, height: s32, title: string) -> OS_Window {
    // if (!window_class_initted) {
    //     init_window_class();
    // }

    // rect: RECT;
    // rect.right = width;
    // rect.bottom = height;
    // AdjustWindowRect(*rect, WINDOWED_STYLE, 0);

    // hInstance := GetModuleHandleA(null);
    // c_title := to_c_string(title);
    // ret := CreateWindowExA(0, WINDOW_CLASS_NAME.data, c_title, WS_OVERLAPPEDWINDOW | WS_VISIBLE, 0, 0, rect.right-rect.left, rect.bottom-rect.top, 0, 0, hInstance, null);
    // free(c_title);
    // return ret;

    return create_window(width, height, title);
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
