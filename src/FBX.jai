// FBX.jai by Josh Huelsman

// @Note @Requires zlib-type decompression in order to decompress data array streams from the input FBX.
// @Requires uncompress :: (*u8, *u64, *u8, u64) -> int 

FBX_Node_Property :: struct {

    FBX_Primitive_Type :: enum u8 {
        TYPE_INT16 :: #char "Y";
        TYPE_BOOL  :: #char "C";
        TYPE_INT32 :: #char "I";
        TYPE_FLOAT :: #char "F";
        TYPE_DOUBLE:: #char "D";
        TYPE_INT64 :: #char "L";

        TYPE_FLOAT_ARRAY :: #char "f";
        TYPE_DOUBLE_ARRAY:: #char "d";
        TYPE_INT64_ARRAY :: #char "l";
        TYPE_INT32_ARRAY :: #char "i";
        TYPE_BOOL_ARRAY  :: #char "b";

        TYPE_STRING      :: #char "S";
        TYPE_RAW_DATA    :: #char "R";
    };

    type: FBX_Primitive_Type;

    _Primitive :: struct {
        int64: s64;
        #place int64;
        int16: s16;
        #place int64;
        int32: s32;
        #place int64;
        f32: float32;
        #place int64;
        f64: float64;
        #place int64;
        bool8: u8;
    }

    primitive: _Primitive;
    string_data: string;
    data: [..] _Primitive;
    raw_data: [..] u8;
}

FBX_Node :: struct {
    node_type: string;
    properties: [..] FBX_Node_Property;
    nodes: [..] *FBX_Node;
};

operator[] :: (using node: FBX_Node, name: string) -> *FBX_Node {
    for node.nodes {
        if it.node_type == name return it;
    }

    return null;
}

FBX :: struct  {
    Header :: struct {
        magic: string;
        reserved: [2] u8;
        version: u32;
    }

    header: Header;
    root_node: FBX_Node;
};

FBX_get_data_array :: (type: FBX_Node_Property.FBX_Primitive_Type, file: File) -> [..] FBX_Node_Property._Primitive {
    array_length: u32;
    encoding: u32;
    compressed_length: u32;
    data : [..] FBX_Node_Property._Primitive;

    file_read(file, *array_length, 4);
    file_read(file, *encoding, 4);
    file_read(file, *compressed_length, 4);

    buffer_size := array_length * FBX_get_property_type_size(type);
    buffer := alloc(buffer_size);
    defer free(buffer);

    if encoding file_read(file, buffer, compressed_length);
    else file_read(file, buffer, buffer_size);
    buffer = FBX_get_decompressed_buffer(buffer, FBX_get_property_type_size(type), array_length, encoding, compressed_length);

    array_reserve(*data, array_length);

    using FBX_Node_Property.FBX_Primitive_Type;
    primitive: FBX_Node_Property._Primitive;
    if type == TYPE_FLOAT_ARRAY {
        float_buffer := cast(*float) buffer;
        for 0..array_length-1 {
            primitive.f32 = float_buffer[it];
            array_add(*data, primitive);
        }
    } else if type == TYPE_DOUBLE_ARRAY {
        float_buffer := cast(*float64) buffer;
        for 0..array_length-1 {
            primitive.f64 = float_buffer[it];
            array_add(*data, primitive);
        }
    } else if type == TYPE_BOOL_ARRAY {
        bool_buffer := cast(*u8) buffer;
        for 0..array_length-1 {
            primitive.bool8 = bool_buffer[it];
            array_add(*data, primitive);
        }
    } else if type == TYPE_INT32_ARRAY {
        int_buffer := cast(*s32) buffer;
        for 0..array_length-1 {
            primitive.int32 = int_buffer[it];
            array_add(*data, primitive);
        }
    } else if type == TYPE_INT64_ARRAY {
        int_buffer := cast(*s64) buffer;
        for 0..array_length-1 {
            primitive.int64 = int_buffer[it];
            array_add(*data, primitive);
        }
    }  

    return data;
}

FBX_get_decompressed_buffer :: (input : *u8, type_size: u8, array_length: u32, encoding: u32, compressed_length: u32) -> *u8 {
    if encoding {
        uncompressed_size: u64 = array_length * type_size;
        buffer := alloc(compressed_length);
        memcpy(buffer, input, compressed_length);
        ret := uncompress(input, *uncompressed_size, buffer, compressed_length);
        free(buffer);
    }

    return input;
}

FBX_get_property_type_size :: (type: FBX_Node_Property.FBX_Primitive_Type) -> u8 {
    using FBX_Node_Property.FBX_Primitive_Type;
    if type == TYPE_BOOL ||
        type == TYPE_BOOL_ARRAY ||
        type == TYPE_STRING ||
        type == TYPE_RAW_DATA return 1;

    if type == TYPE_INT16 return 2;

    if type == TYPE_INT32 ||
        type == TYPE_INT32_ARRAY ||
        type == TYPE_FLOAT ||
        type == TYPE_FLOAT_ARRAY return 4;

    if type == TYPE_INT64 ||
        type == TYPE_INT64_ARRAY ||
        type == TYPE_DOUBLE ||
        type == TYPE_DOUBLE_ARRAY return 8;

    // shouldn't reach here
    assert(false);
    return 0;
}

FBX_read_property :: (file: File) -> FBX_Node_Property {
    property: FBX_Node_Property;
    file_read(file, *property.type, 1);

    // sigh JAI doesnt support switch statements yet
    // @TODO we do support switches now !
    using FBX_Node_Property.FBX_Primitive_Type;
    type := property.type;
    primitive: *FBX_Node_Property._Primitive = *property.primitive;
    if type == TYPE_INT16 file_read(file, primitive, 2);
    if type == TYPE_BOOL file_read(file, primitive, 1);
    if type == TYPE_INT32 file_read(file, primitive, 4);
    if type == TYPE_FLOAT file_read(file, primitive, 4);
    if type == TYPE_DOUBLE file_read(file, primitive, 8);
    if type == TYPE_INT64 file_read(file, primitive, 8);

    if type == TYPE_FLOAT_ARRAY ||
    type == TYPE_BOOL_ARRAY ||
    type == TYPE_INT32_ARRAY ||
    type == TYPE_INT64_ARRAY ||
    type == TYPE_DOUBLE_ARRAY property.data = FBX_get_data_array(type, file);

    if type == TYPE_STRING {
        length: u32;
        file_read(file, *length, 4);
        buffer := alloc(length);
        file_read(file, buffer, length);
        property.string_data.data = buffer;
        property.string_data.count = length;
    }

    if type == TYPE_RAW_DATA {
        length: u32;
        file_read(file, *length, 4);
        buffer := alloc(length);
        file_read(file, buffer, length);
        property.raw_data.data = buffer;
        property.raw_data.count = length;
    }

    return property;
}

FBX_read_node :: (file: File) -> *FBX_Node {
    node := New(FBX_Node);
    end_offset: s64;
    num_properties: u32;
    property_list_len: u32;
    name_len: u8;

    file_read(file, *end_offset, 4);
    file_read(file, *num_properties, 4);
    file_read(file, *property_list_len, 4);
    file_read(file, *name_len, 1);

    temp_name: string;
    temp_name.data = alloc(name_len);
    temp_name.count = name_len;
    file_read(file, temp_name.data, name_len);
    node.node_type = temp_name;

    if num_properties for 0..num_properties-1 {
        prop := FBX_read_property(file);
        array_add(*node.properties, prop);
    }

    pos := file_current_position(file);
    if pos < end_offset {
        end_record_buf: [14] u8;
        while pos < end_offset {
            pos = file_current_position(file);
            file_read(file, end_record_buf.data, 13);

            at_end := true;
            for end_record_buf {
                if (it != 0) {
                    at_end = false;
                    break;
                }
            }

            if !at_end {
                file_set_position(file, pos);
                n := FBX_read_node(file);

                array_add(*node.nodes, n);
            } else {
                break;
            }

            pos = file_current_position(file);
        }
    }

    return node;
}

KAYDARA_MAGIC_STRING :: "Kaydara FBX Binary  ";

FBX_check_header :: (fbx: *FBX) -> bool {
    return (fbx.header.magic == KAYDARA_MAGIC_STRING) &&
            (fbx.header.reserved[0] == 0x1A && fbx.header.reserved[1] == 0x00);
}


FBX_load_file :: (path: string) -> *FBX {
    file, success := file_open(path);
    if (!success) {
        return null;
    }

    total_file_size := file_length(file);

    fbx := New(FBX);
    magic: string;
    magic.data = alloc(21);
    magic.count = 20;
    file_read(file, magic.data, magic.count+1);
    fbx.header.magic = magic;

    file_read(file, fbx.header.reserved.data, 2);
    file_read(file, *fbx.header.version, 4);

    if (!FBX_check_header(fbx)) {
        print("invalid header\n");
        Delete(fbx);
        file_close(*file);
        return null;
    }

    while true {
        if ((total_file_size - file_current_position(file)) <= 200) break; // skip footer
        node := FBX_read_node(file);
        if !node break;

        array_add(*fbx.root_node.nodes, node);
    }

    file_close(*file);
    return fbx;
}