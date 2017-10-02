
#load "gl_api.jai";

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

File_Notification :: struct {
    type: s16;
    name: string;
};

FILE_NOTIF_FUNC :: #type (notif: *File_Notification, data: *void);

strtod :: (start: *u8, endptr: **u8) -> float64 #foreign crt;

#if OS_WINDOWS {
	strtoull :: (start: *u8, endptr: **u8, base: s32) -> u64 #foreign crt "_strtoui64";

	#scope_file
	crt :: #foreign_system_library "msvcrt";
} else {
	strtoull :: (start: *u8, endptr: **u8, base: s32) -> u64 #foreign crt;

	#scope_file
	crt :: #foreign_system_library "c";
}

find_and_truncate_character_from_right :: (s: string, c: int) -> string {
    cursor := s.count - 1;
    while cursor >= 0 {
        if s[cursor] == c  return substring(s, 0, cursor); // @TODO -1 ?
        cursor -= 1;
    }

    return "";
}


