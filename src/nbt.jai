
// Hash_Table :: #import "Hash_Table";

Tag :: struct {
    using Tag_Type :: enum u8 {
        End        :: 0;
        Byte       :: 1;
        Short      :: 2;
        Int        :: 3;
        Long       :: 4;
        Float      :: 5;
        Double     :: 6;
        Byte_Array :: 7;
        String     :: 8;
        List       :: 9;
        Compound   :: 10;
        Int_Array  :: 11;
        Long_Array :: 12;
    }

    type: Tag_Type;
    name: string;
    union {
        _byte:  s8;
        _short: s16;
        _int:   s32;
        _long:  s64;
        _float: float32;
        _double: float64;
        byte_array: [] s8;
        _string: string;
        list: [] *Tag;
        map: [] Tuple;
        int_array: [] s32;
        long_array: [] s64;
    }
}

nbt_float :: (val: float, name: string = "") -> Tag {
    t: Tag;
    t.name = name;
    t.type = Tag.Float;
    t._float = val;
    return t;
}

nbt_string :: (val: string, name: string = "") -> Tag {
    t: Tag;
    t.name = name;
    t.type = Tag.String;
    t._string = val;
    return t;
}

nbt_int :: (val: s32, name: string = "") -> Tag {
    t: Tag;
    t.name = name;
    t.type = Tag.Int;
    t._int = val;
    return t;
}

write_tag_header :: (stream: *$Stream_Type, tag_type: Tag.Tag_Type, name: string) {
    write_value(stream, tag_type);
    if tag_type != Tag.End {
        assert(name.count < 65536);
        name_length := cast(s16) name.count;
        write_value(stream, name_length);
        write_string(stream, name);
    }
}

write_list_start :: (stream: *$Stream_Type, payload_type: Tag.Tag_Type, name: string, count: s32) {
    write_tag_header(stream, Tag.List, name);
    write_value(stream, payload_type);
    write_value(stream, count);
}

write_tag :: (stream: *$Stream_Type, tag: Tag, is_in_list := false) {
    if tag.type == Tag.End {
        write_value(stream, tag.type);
    } else {
        if !is_in_list {
            write_value(stream, tag.type);

            assert(tag.name.count < 65536);
            name_length := cast(s16) tag.name.count;
            write_value(stream, name_length);
            write_string(stream, tag.name);
        }

        if tag.type == {
            case Tag.Byte;   write_value(stream, tag._byte);
            case Tag.Short;  write_value(stream, tag._short);
            case Tag.Int;    write_value(stream, tag._int);
            case Tag.Long;   write_value(stream, tag._long);
            case Tag.Float;  write_value(stream, tag._float);
            case Tag.Double; write_value(stream, tag._double);
            case Tag.Byte_Array;
                assert(tag.byte_array.count < INT_MAX);
                length: s32 = cast(s32) tag.byte_array.count;
                write_value(stream, length);
                write_array(stream, tag.byte_array);
            case Tag.String;
                assert(tag._string.count < SHORT_MAX);
                name_length := cast(s16) tag._string.count;
                write_value(stream, name_length);
                write_string(stream,tag. _string);
            case Tag.List;
                if tag.list.count {
                    assert(tag.list.count < INT_MAX);
                    length: s32 = cast(s32) tag.list.count;

                    write_value(stream, tag.list[0].type);
                    write_value(stream, length);

                    for tag.list {
                        write_tag(stream, <<it);
                    }
                } else {
                    length: s32 = 0;
                    write_value(stream, Tag.Byte);
                    write_value(stream, length);
                }
            case Tag.Compound;
                for tag.map {
                    write_tag(stream, <<it.tag);
                }

                write_value(stream, Tag.End);
            case Tag.Int_Array;
                assert(tag.int_array.count < INT_MAX);
                length: s32 = cast(s32) tag.int_array.count;
                write_value(stream, length);
                write_array(stream, tag.int_array);
            case Tag.Long_Array;
                assert(tag.long_array.count < INT_MAX);
                length: s32 = cast(s32) tag.long_array.count;
                write_value(stream, length);
                write_array(stream, tag.long_array);
        }
    }
}


read_tag :: (stream: *$Stream_Type, is_in_list := false, list_tag_type: Tag.Tag_Type = Tag.End) -> Tag {
    tag: Tag;
    if !is_in_list {
        tag.type = read_value(stream, Tag.Tag_Type);
        name_length := read_value(stream, s16);
        tag.name = read_string(stream, name_length);
    } else {
        tag.type = list_tag_type;
        assert(list_tag_type != Tag.End);
    }

    if tag.type == {
        case Tag.Byte;   tag._byte = read_value(stream, s8);
        case Tag.Short;  tag._short = read_value(stream, s16);
        case Tag.Int;    tag._int = read_value(stream, s32);
        case Tag.Long;   tag._long = read_value(stream, s64);
        case Tag.Float;  tag._float = read_value(stream, float32);
        case Tag.Double; tag._double = read_value(stream, float64);
        case Tag.Byte_Array;
            // length := read_value(stream, s32);
            // write_array(stream, tag.byte_array);

            assert(false);
        case Tag.String;
            name_length := read_value(stream, s16);
            tag._string = read_string(stream, name_length);
        case Tag.List;
            // if tag.list.count {
            //     assert(tag.list.count < INT_MAX);
            //     length: s32 = cast(s32) tag.list.count;

            //     write_value(stream, tag.list[0].type);
            //     write_value(stream, length);

            //     for tag.list {
            //         write_tag(stream, <<it);
            //     }
            // } else {
            //     length: s32 = 0;
            //     write_value(stream, Tag.Byte);
            //     write_value(stream, length);
            // }

            assert(false);
        case Tag.Compound;
            // for tag.map {
            //     write_tag(stream, <<it.tag);
            // }

            // write_value(stream, Tag.End);

            assert(false);
        case Tag.Int_Array;
            // assert(tag.int_array.count < INT_MAX);
            // length: s32 = cast(s32) tag.int_array.count;
            // write_value(stream, length);
            // write_array(stream, tag.int_array);

            assert(false);
        case Tag.Long_Array;
            // assert(tag.long_array.count < INT_MAX);
            // length: s32 = cast(s32) tag.long_array.count;
            // write_value(stream, length);
            // write_array(stream, tag.long_array);

            assert(false);
    }

    return tag;
}

read_list_start :: (stream: *$Stream_Type) -> (payload_type: Tag.Tag_Type, name: string, count: s32) {
    type, name := read_tag_header(stream);
    assert(type == Tag.List);

    payload_type := read_value(stream, Tag.Tag_Type);
    count := read_int(stream);
    return payload_type, name, count;
}

read_tag_header :: (stream: *$Stream_Type) -> (type: Tag.Tag_Type, name: string) {
    type := read_value(stream, Tag.Tag_Type);
    name: string;
    if type != Tag.End {
        len := read_value(stream, s16);
        name = read_string(stream, len);
    }

    return type, name;
}

read_float :: (stream: *$Stream_Type) -> float {
    return read_value(stream, float);
}

read_int :: (stream: *$Stream_Type) -> s32 {
    return read_value(stream, s32);
}

peek_next_tag :: (stream: *$Stream_Type) -> Tag.Tag_Type {
    current := stream_current_position(stream);
    defer stream_set_position(stream, current);

    value := read_value(stream, Tag.Tag_Type);
    return value;
}

#scope_file

Tuple :: struct {
    key: string;
    tag: *Tag;
}

INT_MAX :: 4294967296;
SHORT_MAX :: 65536;

LITTLE_ENDIAN :: 0;
BIG_ENDIAN    :: 1;

SYSTEM_ENDIANESS :: LITTLE_ENDIAN;
OUTPUT_ENDIANESS :: BIG_ENDIAN;

maybe_reverse_bytes :: (value: $T) -> T {
    #if (size_of(T) == 1) || (SYSTEM_ENDIANESS == OUTPUT_ENDIANESS) {
        return value;
    } else {
        data := cast(*u8) *value;

        new_data: [size_of(T)] u8;

        for 0..new_data.count-1 {
            new_data[it] = data[(new_data.count-1) - it];
        }

        return <<cast(*T) new_data.data;
    }
}

write_value :: (stream: *$Stream_Type, value: $T) {
    value = maybe_reverse_bytes(value);
    stream_write(stream, cast(*void) *value, size_of(T));
}

read_value :: (stream: *$Stream_Type, $T: Type) -> T {
    value: T;
    stream_read(stream, cast(*void) *value, size_of(T));
    return maybe_reverse_bytes(value);
}

write_array :: (stream: $Stream_Type, array: [] $T) {
    for array {
        write_value(stream, it);
    }
}

write_string :: (stream: *$Stream_Type, str: string) {
    stream_write(stream, str.data, str.count);
}

read_string :: (stream: *$Stream_Type, count: s16) -> string {
    data := cast(*u8) alloc(count);
    stream_read(stream, cast(*void) data, count);
    out: string;
    out.data = data;
    out.count = count;

    assert(out.data != null);
    return out;
}


stream_write :: file_write;
stream_read  :: (file: *File, data: *void, count: s64) {
    file_read(<<file, data, count);
}
stream_current_position :: (file: *File) -> s64 {
    return file_current_position(<<file);
}
stream_set_position :: (file: *File, pos: s64) {
    file_set_position(<<file, pos);
}