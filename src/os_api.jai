

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
