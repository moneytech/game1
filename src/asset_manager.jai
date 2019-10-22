#import "Basic";
#import "File";
#import "String";

Asset_Manager :: struct {
    textures: Hash_Map(#type *Texture);
    models: Hash_Map(#type *Model);
    materials: Hash_Map(#type *Material_Lib);
    fonts: Hash_Map(#type *Font);
    shader_catalog: Hash_Map(#type Shader_Info);
    heightmaps: Hash_Map(#type *Mesh);

    game: *Game;
}

Shader_Info :: struct {
    dependencies: [..] *Shader; // shaders linked using this one
};

Material_Lib :: struct {
    using _map: Hash_Map(#type *Material);
}
// Material_Lib :: Hash_Map(#type (*Material));

#load "nbt.jai";

serialize_vector3 :: (file: *File, v: Vector3, name: string) {
    write_list_start(file, Tag.Float, name, 3);
    write_tag(file, nbt_float(v.x), is_in_list=true);
    write_tag(file, nbt_float(v.y), is_in_list=true);
    write_tag(file, nbt_float(v.z), is_in_list=true);
}

serialize_quaternion :: (file: *File, q: Quaternion, name: string) {
    write_list_start(file, Tag.Float, name, 4);
    write_tag(file, nbt_float(q.x), is_in_list=true);
    write_tag(file, nbt_float(q.y), is_in_list=true);
    write_tag(file, nbt_float(q.z), is_in_list=true);
    write_tag(file, nbt_float(q.w), is_in_list=true);
}

serialize_actor :: (file: *File, actor: *Actor, scene: *Scene) {
    serialize_quaternion(file, actor.orientation, "orientation");
    if actor.model then {
        model := actor.model;
        if model.source_path == "" {
            name := sprint("Unnamed_Model.%.obj", scene.next_available_id);
            scene.next_available_id += 1;
            // name := get_unnamed_model_name(".obj");
            defer free(name);
            model.source_path = concatenate(scene.source_path, "/", name);
            export_model_as_obj(model);
        }
        write_tag(file, nbt_string(actor.model.source_path, "Model")); // @TODO this should probably be an object ID/index into a pool of models in the scene
    }
    else write_tag(file, nbt_string("", "Model"));
}

serialze_object :: (file: *File, obj: *Scene_Object, scene: Scene) {
    assert(obj.object_id >= 0);
    write_tag_header(file, Tag.Compound, tprint("ID%", obj.object_id));
    write_tag(file, nbt_string(tprint("%", obj.object_type), "object_type"));
    write_tag(file, nbt_int(obj.object_id, "object_id"));
    serialize_vector3(file, obj.position, "position");
    if obj.object_type == Actor {
        serialize_actor(file, cast(*Actor) obj, *scene);
    }
    write_tag_header(file, Tag.End, "");
}

serialze_scene :: (filename: string, scene: Scene) {
    file := file_open(filename, for_writing=true);
    defer file_close(*file);

    write_tag_header(*file, Tag.Compound, "");
    for scene.all_objects {
        serialze_object(*file, it, scene);
    }
    write_tag_header(*file, Tag.End, "");
}

deserialize_vector3 :: (file: *File) -> Vector3 {
    payload_type, name, count := read_list_start(file);
    v: Vector3;
    v.x = read_tag(file, is_in_list=true, payload_type)._float;
    v.y = read_tag(file, is_in_list=true, payload_type)._float;
    v.z = read_tag(file, is_in_list=true, payload_type)._float;
    return v;
}

deserialize_quaternion :: (file: *File) -> Quaternion {
    payload_type, name, count := read_list_start(file);
    v: Quaternion;
    v.x = read_tag(file, is_in_list=true, payload_type)._float;
    v.y = read_tag(file, is_in_list=true, payload_type)._float;
    v.z = read_tag(file, is_in_list=true, payload_type)._float;
    v.w = read_tag(file, is_in_list=true, payload_type)._float;
    return v;
}

deserialize_actor :: (asset_man: *Asset_Manager, file: *File, actor: *Actor) {
    actor.orientation = deserialize_quaternion(file);
    model_path := read_tag(file)._string;
    print("Model: %\n", model_path);
    if model_path != "" {
        actor.model = load_model(asset_man, model_path);
    }
}

deserialize_object :: (asset_man: *Asset_Manager, file: *File) -> *Scene_Object {
    type, name := read_tag_header(file);
    assert(type == Tag.Compound);

    print("Deserializing object name: %\n", name);
    type_name := read_tag(file)._string;
    print("Type: %\n", type_name);
    
    obj: *Scene_Object;
    if type_name == {
        case "Actor"; obj = Actor.new(); obj.object_type = Actor;
        case "Light"; obj = Light.new(); obj.object_type = Light;
        case "Model"; obj = Model.new(); obj.object_type = Model;
        case "Camera"; obj = New(Camera); obj.object_type = Camera;
    }

    obj.object_id = read_tag(file)._int;
    obj.position = deserialize_vector3(file);

    if obj.object_type == Actor {
        deserialize_actor(asset_man, file, cast(*Actor) obj);
    }

    read_tag_header(file); // Tag.End

    return obj;
}

deserialize_scene :: (asset_man: *Asset_Manager, file: *File, scene: *Scene) {
    type := read_tag_header(file); // Tag.Compound
    assert(type == Tag.Compound);

    while peek_next_tag(file) != Tag.End {
        obj := deserialize_object(asset_man, file);

        if obj.object_type == {
            case Actor; add_to_scene_with_id(scene, cast(*Actor) obj, obj.object_id);
            case Light; add_to_scene_with_id(scene, cast(*Light) obj, obj.object_id);
            case Model; add_to_scene_with_id(scene, cast(*Model) obj, obj.object_id);
            case Camera; add_to_scene_with_id(scene, cast(*Camera) obj, obj.object_id);
            
        }
    }

    read_tag_header(file); // Tag.End
}

export_model_as_obj :: (model: *Model) {
    assert(model.source_path != "");

    mtllib_fullpath := concatenate(path_strip_extension(model.source_path), ".mtllib");
    defer free(mtllib_fullpath);
    mtllib_path := concatenate(path_strip_extension(path_filename(model.source_path)), ".mtllib");
    defer free(mtllib_path);

    obj_builder: String_Builder;
    mtl_builder: String_Builder;

    mesh_index := 0;
    mtl_index := 0;

    print_to_builder(*obj_builder, "mtllib %\n", mtllib_path);

    vertex_offset := 1;
    texture_offset := 1;
    normal_offset := 1;

    for mesh: model.meshes {
        mat := mesh.material;
        assert(mat != null);

        material_name := sprint("Material.%", mtl_index);
        mtl_index += 1;
        defer free(material_name);

        /*
        Material :: struct {
            textures: [MAX_TEXTURES_PER_MESH] *Texture;
            diffuse: Color;
            roughness: float = 0.4;
            metallic: float = 0;

            // maybe these should be Mesh properties since they're rendering options as opposed to rendering attributes ?
            disable_lighting := false;
            disable_backface_culling := false;
            disable_vertex_colors := false;
            disable_depth_test := false;

            #constructor (using m: *Material) {
                diffuse = make_Color(1.0, 1.0, 1.0);
            }
        }
        */

        { // write the material info
            print_to_builder(*mtl_builder, "newmtl %\n", material_name);
            print_to_builder(*mtl_builder, "Kd % % %\n", mat.diffuse.r, mat.diffuse.g, mat.diffuse.b);
            print_to_builder(*mtl_builder, "Pr %\n", mat.roughness); // @TODO idk what Blender would actually accept for the parameter name
            print_to_builder(*mtl_builder, "Pm %\n", mat.metallic);

            // @TODO textures
        }

        mesh_name := sprint("Mesh.%\n", mesh_index);
        mesh_index += 1;
        defer free(mesh_name);

        print_to_builder(*obj_builder, "o %\n", mesh_name);

        for mesh.vertices {
            print_to_builder(*obj_builder, "v % % %\n", it.x, it.y, it.z);
        }

        for mesh.normals {
            print_to_builder(*obj_builder, "vn % % %\n", it.x, it.y, it.z);
        }

        for mesh.tex_coords {
            print_to_builder(*obj_builder, "vt % %\n", it.x, it.y);
        }

        print_to_builder(*obj_builder, "usemtl %\n", material_name);

        if mesh.normals.count    then assert(mesh.vertices.count == mesh.normals.count);
        if mesh.tex_coords.count then assert(mesh.tex_coords.count == mesh.vertices.count);

        for mesh.vertices {
            if it_index % 3 == 0 {
                append(*obj_builder, "\nf ");
            }
            print_to_builder(*obj_builder, "%/", it_index + vertex_offset);
            if mesh.tex_coords.count then print_to_builder(*obj_builder, "%", it_index + texture_offset);
            append(*obj_builder, "/");

            if mesh.normals.count then print_to_builder(*obj_builder, "%", it_index + normal_offset);
            append(*obj_builder, " ");
        }

        append(*obj_builder, "\n");

        vertex_offset += mesh.vertices.count;
        texture_offset += mesh.tex_coords.count;
        normal_offset += mesh.normals.count; 
    }

    obj_string := builder_to_string(*obj_builder);
    mtl_string := builder_to_string(*mtl_builder);
    write_entire_file(model.source_path, obj_string);
    write_entire_file(mtllib_fullpath, mtl_string);
}

export_scene :: (scene: Scene) {
    assert(scene.source_path != "");

    make_directory_if_it_does_not_exist(scene.source_path);
    data_dat_path := concatenate(scene.source_path, "/", "data.dat");
    serialze_scene(data_dat_path, scene);
    free(data_dat_path);
}

load_scene :: (using asset_man: *Asset_Manager, filepath: string) -> *Scene {
    data_dat_path := concatenate(filepath, "/", "data.dat");
    defer free(data_dat_path);

    file := file_open(data_dat_path);
    defer file_close(*file);

    scene := New(Scene);
    scene.source_path = filepath; // @ copy ?
    deserialize_scene(asset_man, *file, scene);
    return scene;
}

load_text_strings :: (using asset_man: *Asset_Manager, filepath: string = "") -> [..] string {
    // @Incomplete this is just a @Hack so we have something to get going
    strings: [..] string;
    array_resize(*strings, cast(u16) Text.LAST_MESSAGE);
    strings[Text.NO_MESSAGE] = "No message set!";
    return strings;
}

load_image :: (using asset_man: *Asset_Manager, filepath: string) -> *Texture {
    width, height, comp: s32;
    // @Leak
    data := stbi_load(to_c_string(filepath), *width, *height, *comp, 4); // 4 forces RGBA components / 4 bytes-per-pixel

    if (data) {
        tex: *Texture = get_slot(*textures, filepath);

        if (!tex) {
            tex = xx New(Texture);
            set_slot(*textures, filepath, tex);
        } else {
            delete_texture(tex);
        }

        create_texture(tex, xx width, xx height, data);
        stbi_image_free(data);
        return tex;
    }

    print("ERROR: can't open '%' because '%s'\n", filepath, to_string(stbi_failure_reason()));
    return null;
}

load_heightmap :: (using asset_man: *Asset_Manager, filepath: string) -> Height_Map, *Mesh {
    width, height, comp: s32;
    map: Height_Map;
    // @Leak
    data := stbi_load(to_c_string(filepath), *width, *height, *comp, 4); // 4 forces RGBA components / 4 bytes-per-pixel

    if (data) {
        m := get_slot(*heightmaps, filepath);
        if !m {
            m = Mesh.new();
        }
        map.width = width;
        map.height = height;
        array_reserve(*map.map, width*height);

        for y: 0..height-1 {
            for x: 0..width-1 {
                val: float = cast(float) data[(y * width + x) * 4];
                array_add(*map.map, val / 10.0);
            }
        }

        generate_heightmap_vertex_data(*map);
        <<m = generate_terrain_mesh(map);
        stbi_image_free(data);
        return map, m;
    }

    print("ERROR:%s\n", to_string(stbi_failure_reason()));
    return map, null;
}

load_image_from_memory :: (filepath: string, data: [] u8) -> *Texture {
    width, height, comp: s32;
    out := stbi_load_from_memory(data.data, xx data.count, *width, *height, *comp, 4);

    if out {
        tex: *Texture = New(Texture);
        create_texture(tex, xx width, xx height, out);
        stbi_image_free(out);
        return tex;
    }

    // @TODO asset_man
    return null;
}

load_model :: (using asset_man: *Asset_Manager, filepath: string) -> *Model {
    ext := find_character_from_right(filepath, #char ".");

    mod: *Model;
    if ext == ".obj" {
        obj_source := read_entire_file(filepath);
        mod = model_loader_parse_obj(game, obj_source, filepath);
    } else if ext == ".fbx" {
        mod = Model_load_fbx(filepath);
    } else if ext == ".dae" {
        obj_source := read_entire_file(filepath);
        mod = Model_load_dae(asset_man, obj_source, filepath);
    }

    if mod == null return null;

    for mod.meshes {
        maybe_calc_tangent_normals(it);
        store_mesh_in_buffer(it);
    }

    old_model := get_slot(*models, filepath);
    if old_model {
        <<old_model = <<mod;
        Delete(mod);
        return mod;
    }

    mod.source_path = filepath;
    set_slot(*models, filepath, mod);
    return mod;
}

reload_shader :: (using asset_man: *Asset_Manager, path: string) {
    deps := get_slot(*shader_catalog, path).dependencies;
    for deps {
        // kind of wasteful, we can speed this up by detecting which shader it is early (extension check)
        src := read_entire_file(it.source_path);
        compile_shader_source(it, src, src);
        free(src);
    }
}

load_shader :: (using asset_man: *Asset_Manager, path: string) -> *Shader {
    source, success := read_entire_file(path);
    if !success then return null; // print error ?

    sh := compile_shader_source(source);
    array_add(*get_slot(*shader_catalog, path).dependencies, sh);
    sh.source_path = copy_string(path);
    free(source);
    return sh;
}

maybe_calc_tangent_normals :: (using m: *Mesh) {
    if (!material.textures[TEXTURE_NORMAL_INDEX]) return;

    array_reserve(*tangent_normals, vertices.count);
    for 0..vertices.count-1 {
        e1 := vertices[it+1] - vertices[it];
        e2 := vertices[it+2] - vertices[it];

        dUV1 := tex_coords[it+1] - tex_coords[it];
        dUV2 := tex_coords[it+2] - tex_coords[it];

        f := 1.0 / (dUV1.x * dUV2.y - dUV2.x * dUV1.y);

        tangent: Vector3;
        tangent.x = f * (dUV2.y * e1.x - dUV1.y * e2.x);
        tangent.y = f * (dUV2.y * e1.y - dUV1.y * e2.y);
        tangent.z = f * (dUV2.y * e1.z - dUV1.y * e2.z);
        tangent = normalize(tangent);

        // we add it three times, one for each vertex
        array_add(*tangent_normals, tangent);
        array_add(*tangent_normals, tangent);
        array_add(*tangent_normals, tangent);

        it += 2;
    }    
}

path_of :: (filepath: string) -> string {
    return path_strip_filename(filepath);
}

ml_get_signed_float :: (st: *ML_State, tok: *ML_Token) -> float {
    neg := false;
    if (tok.type == xx #char "-") {
        neg = true;
        ml_get_token(st, tok);
    }

    assert(tok.type == ML_TOKEN_FLOAT);
    val := cast(float) tok._float;

    ml_get_token(st, tok);
    if (neg) val = -val;
    return val;
}

model_loader_parse_mtl :: (game: *Game, src: string, lib: *Material_Lib, mtl_filepath: string) {
    st: ML_State;
    st.flags = ML_DOTS_IN_IDENTIFIERS;
    init(*st, src);
    tok: ML_Token;

    mat: *Material;
    ml_get_token(*st, *tok);
    while(tok.type != ML_TOKEN_END) {
        if (tok.type == xx #char "#") {
            current_line := tok.line_number;
            while (tok.line_number == current_line && tok.type != ML_TOKEN_END)
                ml_get_token(*st, *tok); // eat comment line
            continue;
        }

        if (tok.type == ML_TOKEN_IDENTIFIER) {
            name := tok._string;
            if (name == "newmtl") {
                ml_get_token(*st, *tok);
                assert(tok.type == ML_TOKEN_IDENTIFIER);
                mat = Material.new();
                set_slot(lib, tok._string, mat);

                ml_get_token(*st, *tok);
            } else if (!mat) {
                assert(false && "setting property before declaring material");
            } else if (name == "Ns") {
                ml_get_token(*st, *tok);
                assert(tok.type == ML_TOKEN_FLOAT || tok.type == ML_TOKEN_INTEGER);
                // if (tok.type == ML_TOKEN_FLOAT)
                //     mat.specular_exp = cast(float) tok._float;
                // else if (tok.type == ML_TOKEN_INTEGER)
                //     mat.specular_exp = cast(float) tok.integer;
                ml_get_token(*st, *tok);
            } else if (name == "Ka") {
                ml_get_token(*st, *tok);
                assert(tok.type == ML_TOKEN_FLOAT);
                r := cast(float) tok._float;
                
                ml_get_token(*st, *tok);
                assert(tok.type == ML_TOKEN_FLOAT);
                g := cast(float) tok._float;

                ml_get_token(*st, *tok);
                assert(tok.type == ML_TOKEN_FLOAT);
                b := cast(float) tok._float;

                // c: Color;
                // c.r = r;
                // c.g = g;
                // c.b = b;
                // mat.ambient = c;

                ml_get_token(*st, *tok);
            } else if (name == "Kd") {
                ml_get_token(*st, *tok);
                assert(tok.type == ML_TOKEN_FLOAT);
                r := cast(float) tok._float;
                
                ml_get_token(*st, *tok);
                assert(tok.type == ML_TOKEN_FLOAT);
                g := cast(float) tok._float;

                ml_get_token(*st, *tok);
                assert(tok.type == ML_TOKEN_FLOAT);
                b := cast(float) tok._float;

                c: Color;
                c.r = r;
                c.g = g;
                c.b = b;
                mat.diffuse = c;

                ml_get_token(*st, *tok);
            } else if (name == "Ks") {
                ml_get_token(*st, *tok);
                assert(tok.type == ML_TOKEN_FLOAT);
                r := cast(float) tok._float;
                
                ml_get_token(*st, *tok);
                assert(tok.type == ML_TOKEN_FLOAT);
                g := cast(float) tok._float;

                ml_get_token(*st, *tok);
                assert(tok.type == ML_TOKEN_FLOAT);
                b := cast(float) tok._float;

                // c: Color;
                // c.r = r;
                // c.g = g;
                // c.b = b;
                // mat.specular = c;

                ml_get_token(*st, *tok);
            } else if (name == "Ke") {
                ml_get_token(*st, *tok);
                assert(tok.type == ML_TOKEN_FLOAT);
                r := cast(float) tok._float;
                
                ml_get_token(*st, *tok);
                assert(tok.type == ML_TOKEN_FLOAT);
                g := cast(float) tok._float;

                ml_get_token(*st, *tok);
                assert(tok.type == ML_TOKEN_FLOAT);
                b := cast(float) tok._float;

                // c: Color;
                // c.r = r;
                // c.g = g;
                // c.b = b;
                // mat.emissive = c;

                ml_get_token(*st, *tok);
            } else if (name == "Ni") {
                ml_get_token(*st, *tok);
                assert(tok.type == ML_TOKEN_FLOAT);
                ml_get_token(*st, *tok);
            } else if (name == "d") {
                ml_get_token(*st, *tok);
                assert(tok.type == ML_TOKEN_FLOAT || tok.type == ML_TOKEN_INTEGER);
                // if (tok.type == ML_TOKEN_FLOAT)
                //     mat.transparency = cast(float) tok._float;
                // else if (tok.type == ML_TOKEN_INTEGER)
                //     mat.transparency = cast(float) tok.integer;
                ml_get_token(*st, *tok);
            } else if (name == "Pr") {
                ml_get_token(*st, *tok);
                assert(tok.type == ML_TOKEN_FLOAT || tok.type == ML_TOKEN_INTEGER);
                if (tok.type == ML_TOKEN_FLOAT)
                    mat.roughness = cast(float) tok._float;
                else if (tok.type == ML_TOKEN_INTEGER)
                    mat.roughness = cast(float) tok.integer;
                ml_get_token(*st, *tok);
            } else if (name == "Pm") {
                ml_get_token(*st, *tok);
                assert(tok.type == ML_TOKEN_FLOAT || tok.type == ML_TOKEN_INTEGER);
                if (tok.type == ML_TOKEN_FLOAT)
                    mat.metallic = cast(float) tok._float;
                else if (tok.type == ML_TOKEN_INTEGER)
                    mat.metallic = cast(float) tok.integer;
                ml_get_token(*st, *tok);
            } else if (name == "illum") {
                ml_get_token(*st, *tok);
                assert(tok.type == ML_TOKEN_INTEGER);
                ml_get_token(*st, *tok);
            } else if (name == "map_Kd") {
                ml_get_token(*st, *tok);
                assert(tok.type == ML_TOKEN_IDENTIFIER);
                filepath := tok._string;
                p := path_of(mtl_filepath);
                filepath = concatenate(p, "/", filepath);

                tex := load_image(game.asset_man, filepath);
                mat.textures[TEXTURE_DIFFUSE_INDEX] = tex;

                ml_get_token(*st, *tok);
            } else if (name == "map_Bump") {
                ml_get_token(*st, *tok);
                if (tok.type == xx #char "-") {
                    ml_get_token(*st, *tok);
                    assert(tok.type == ML_TOKEN_IDENTIFIER);

                    name = tok._string;
                    if (name == "bm") {
                        ml_get_token(*st, *tok);
                        bump_mult := ml_get_signed_float(*st, *tok);

                        // @TODO not really sure how to use the bump multiplier..
                    } else {
                        assert(false);
                    }
                }
                assert(tok.type == ML_TOKEN_IDENTIFIER);
                filepath := tok._string;
                p := path_of(mtl_filepath);
                filepath = concatenate(p, "/", filepath);

                tex := load_image(game.asset_man, filepath);
                mat.textures[TEXTURE_NORMAL_INDEX] = tex;

                ml_get_token(*st, *tok);
            } else if (name == "map_Ks") {
                ml_get_token(*st, *tok);
                assert(tok.type == ML_TOKEN_IDENTIFIER);
                // filepath := tok._string;
                // p := path_of(mtl_filepath);
                // filepath = concatenate(p, "/", filepath);

                // tex := load_image(game.asset_man, filepath);
                // mat.textures[TEXTURE_SPECULAR_INDEX] = tex;

                ml_get_token(*st, *tok);
            } else {
                assert(false);
            }
        } else {
            assert(false);
        }
    }
}

model_loader_parse_obj :: (game: *Game, src: string, obj_filepath: string) -> *Model {
    lib := New(Material_Lib);
    st: ML_State;
    st.flags = ML_DOTS_IN_IDENTIFIERS;
    init(*st, src);
    tok: ML_Token;

    mod := Model.new();
    mesh: *Mesh = null;
    vertices: [..] Vector3;
    normals: [..] Vector3;
    tex_coords: [..] Vector2;
    ml_get_token(*st, *tok);
    while (tok.type != ML_TOKEN_END) {
        if (tok.type == xx #char "#") {
            current_line := tok.line_number;
            while (tok.line_number == current_line && tok.type != ML_TOKEN_END)
                ml_get_token(*st, *tok); // eat comment line
            continue;
        }

        if (tok.type == ML_TOKEN_IDENTIFIER) {
            name := tok._string;
            if (name == "mtllib") {
                ml_get_token(*st, *tok);
                assert(tok.type == ML_TOKEN_IDENTIFIER);
                filepath := tok._string;
                p := path_of(obj_filepath);
                filepath = concatenate(p, "/", filepath);
                lib_src := read_entire_file(filepath);

                // @TODO this should hook into asset_man
                model_loader_parse_mtl(game, lib_src, lib, filepath);

                ml_get_token(*st, *tok);
            } else if (name == "o") {
                ml_get_token(*st, *tok);
                assert(tok.type == ML_TOKEN_IDENTIFIER);
                mesh = Mesh.new();
                array_add(*mod.meshes, mesh);
                // array_reset(*vertices);

                ml_get_token(*st, *tok);
            } else if (!mesh) {
                assert(0 && "setting property before declaring object");
            } else if (name == "v") {
                ml_get_token(*st, *tok);
                v: Vector3;
                v.x = ml_get_signed_float(*st, *tok);
                v.y = ml_get_signed_float(*st, *tok);
                v.z = ml_get_signed_float(*st, *tok);
                array_add(*vertices, v);
            } else if (name == "vn") {
                ml_get_token(*st, *tok);
                v: Vector3;
                v.x = ml_get_signed_float(*st, *tok);
                v.y = ml_get_signed_float(*st, *tok);
                v.z = ml_get_signed_float(*st, *tok);
                array_add(*normals, v);
            } else if (name == "vt") {
                ml_get_token(*st, *tok);
                v: Vector2;
                v.x = ml_get_signed_float(*st, *tok);
                v.y = 1.0 - ml_get_signed_float(*st, *tok);
                array_add(*tex_coords, v);
            } else if (name == "usemtl") {
                ml_get_token(*st, *tok);
                assert(tok.type == ML_TOKEN_IDENTIFIER);
                mtl_name := tok._string;
                mesh.material = get_slot(lib, mtl_name);
                assert(mesh.material != null);
                ml_get_token(*st, *tok);
            } else if (name == "s") {
                ml_get_token(*st, *tok);
                assert(tok.type == ML_TOKEN_IDENTIFIER || tok.type == ML_TOKEN_INTEGER);
                // smooth shading
                ml_get_token(*st, *tok);
            } else if (name == "f") {
                ml_get_token(*st, *tok);
                assert(tok.type == ML_TOKEN_INTEGER);
                array_add(*mesh.vertices, vertices[tok.integer-1]);
                ml_get_token(*st, *tok); assert(tok.type == xx #char "/");
                ml_get_token(*st, *tok);
                if (tok.type == ML_TOKEN_INTEGER) {
                    array_add(*mesh.tex_coords, tex_coords[tok.integer-1]);
                    ml_get_token(*st, *tok);
                }
                assert(tok.type == xx #char "/");
                ml_get_token(*st, *tok); assert(tok.type == ML_TOKEN_INTEGER);
                array_add(*mesh.normals, normals[tok.integer-1]);

                ml_get_token(*st, *tok);
                assert(tok.type == ML_TOKEN_INTEGER);
                array_add(*mesh.vertices, vertices[tok.integer-1]);
                ml_get_token(*st, *tok); assert(tok.type == xx #char "/");
                ml_get_token(*st, *tok);
                if (tok.type == ML_TOKEN_INTEGER) {
                    array_add(*mesh.tex_coords, tex_coords[tok.integer-1]);
                    ml_get_token(*st, *tok);
                }
                assert(tok.type == xx #char "/");
                ml_get_token(*st, *tok); assert(tok.type == ML_TOKEN_INTEGER);
                array_add(*mesh.normals, normals[tok.integer-1]);

                ml_get_token(*st, *tok);
                assert(tok.type == ML_TOKEN_INTEGER);
                array_add(*mesh.vertices, vertices[tok.integer-1]);
                ml_get_token(*st, *tok); assert(tok.type == xx #char "/");
                ml_get_token(*st, *tok);
                if (tok.type == ML_TOKEN_INTEGER) {
                    array_add(*mesh.tex_coords, tex_coords[tok.integer-1]);
                    ml_get_token(*st, *tok);
                }
                assert(tok.type == xx #char "/");
                ml_get_token(*st, *tok); assert(tok.type == ML_TOKEN_INTEGER);
                array_add(*mesh.normals, normals[tok.integer-1]);

                ml_get_token(*st, *tok);
            } else {
                assert(false);
            }
        } else {
            print("token: %\n", tok.type);
            assert(false);
        }
    }
    return mod;
}

print_property :: (p: FBX_Node_Property) {
    using FBX_Node_Property.FBX_Primitive_Type;

    if p.type == {
        case TYPE_STRING;
            print("'%'", p.string_data);
        case TYPE_DOUBLE; 
            print("%", p.primitive.f64);
        case TYPE_FLOAT;
            print("%", p.primitive.f32);
        case TYPE_INT16;
            print("%", p.primitive.int16);
        case TYPE_BOOL;
            print("%", cast(bool) p.primitive.bool8);
        case TYPE_INT32;
            print("%", p.primitive.int32);
        case TYPE_INT64;
            print("%", p.primitive.int64);
        case TYPE_FLOAT_ARRAY;
            print("[%] float", p.data.count);
        case TYPE_DOUBLE_ARRAY;
            print("[%] float64", p.data.count);
        case TYPE_INT64_ARRAY;
            print("[%] int64", p.data.count);
        case TYPE_INT32_ARRAY;
            print("[%] int32", p.data.count);
        case TYPE_BOOL_ARRAY;
            print("[%] bool", p.data.count);
        case TYPE_RAW_DATA;
            print("[] <raw_data>", p.raw_data.count);
    } 
}

print_node :: (n: *FBX_Node, depth: int) {
    for 0..depth print("    ");
    print("%: ", n.node_type);
    for n.properties {
        print_property(it);
        print(", ");
    }
    print("{\n");
    for n.nodes {
        print_node(it, depth+1);
    }
    for 0..depth print("    ");
    print("}\n");
}

Model_load_fbx :: (path: string) -> *Model {
    model := Model.new();
    mesh := Mesh.new();
    array_add(*model.meshes, mesh);

    // @TODO this is one giant hack
    // really we want to build a scene graph and then
    // build the graph based on the UIDs and connections
    // of each node

    fbx := FBX_load_file(path);
    if !fbx {
        print("error: couldn't load FBX file: %\n", path);
        return null;
    }
    // print_node(*fbx.root_node, 0);

    objs := fbx.root_node["Objects"];
    if !objs {
        print("coulnt get objs\n");
        return null;
    }
    geom := (<<objs)["Geometry"];
    if (!geom) {
        print("Couldnt get geom\n");
        return null;
    }

    global_settings := fbx.root_node["GlobalSettings"];
    if !global_settings {
        print("Couldnt get GlobalSettings\n");
        return null;
    }
    properties70 := (<<global_settings)["Properties70"];
    assert(properties70 != null);

    scale_factor: float = 1.0;
    for properties70.nodes {
        if it.properties.count {
            if it.properties[0].string_data == "UnitScaleFactor" {
                scale_factor = xx it.properties[4].primitive.f64;
                logprint("AssetMan", "scale factor: %, %\n", path, scale_factor);
            }
        }
    }


    indices: [..] u32;
    normals: [..] Vector3;

    vdata := (<<geom)["Vertices"].properties[0].data;
    idata := (<<geom)["PolygonVertexIndex"].properties[0].data;
    layer_normal := (<<geom)["LayerElementNormal"];
    ndata := (<<layer_normal)["Normals"].properties[0].data;

    array_reserve(*mesh.vertices, vdata.count / 3);
    array_reserve(*mesh.normals, ndata.count / 3);
    array_reserve(*indices, idata.count);

    for idata {
        in := it.int32;
        if in < 0 in = (in * -1) -1;
        array_add(*indices, cast(u32) in);
    }

    assert(indices.count % 3 == 0);

    for indices {
        vec := make_Vector3(cast(float) vdata[it * 3].f64, cast(float) vdata[it * 3 + 1].f64, cast(float) vdata[it * 3 + 2].f64);
        array_add(*mesh.vertices, vec * scale_factor);
    }

    for 0..(ndata.count/3)-1 {
        norm := make_Vector3(cast(float) ndata[it * 3].f64, cast(float) ndata[it * 3 + 1].f64, cast(float) ndata[it * 3 + 2].f64);
        array_add(*mesh.normals, norm);
    }

    // for 0..(uvdata.count/2)-1 {
    //     uv := make_Vector2(cast(float) uvdata[it * 2].f64, cast(float) uvdata[it * 2 + 1].f64);
    //     array_add(*mesh.tex_coords, uv);
    // }

    layer_uv := (<<geom)["LayerElementUV"];
    if layer_uv {
        uvdata := (<<layer_uv)["UV"].properties[0].data;

        if (<<layer_uv)["UVIndex"] {
            uvindex := (<<layer_uv)["UVIndex"].properties[0].data;
            for uvindex {
                // @Note UVs are indexed as 3 dimensional vectors though we only support 2
                uv := make_Vector2(cast(float) uvdata[it.int32 * 2].f64, 1.0 - cast(float) uvdata[it.int32 * 2 + 1].f64);
                array_add(*mesh.tex_coords, uv);
            }
        } else {
            for 0..uvdata.count-2 {
                uv := make_Vector2(cast(float32) uvdata[it].f64, 1.0 - cast(float) uvdata[it+1].f64);
                array_add(*mesh.tex_coords, uv);
                it += 1;
            }
        }
    }

    // @Temporary material
    mat := Material.new();
    mesh.material = mat;
    mat.diffuse = make_Color(0.8, 0.8, 0.8);

    vid := (<<objs)["Video"];
    if vid {
        data := (<<vid)["Content"].properties[0].raw_data;
        mat.textures[TEXTURE_DIFFUSE_INDEX] = load_image_from_memory("", data);
    }

    return model;
}

Model_load_dae :: (asset_man: *Asset_Manager, src: string, path: string) -> *Model {
    // the goal here is to descend the XML tree for the things we care about and then
    // transform the XML branches into more useful Collada trees, maybe!

    collada := collada_parse(src, path);

    V3 :: make_Vector3;
    V2 :: make_Vector2;

    for scene: collada.library_visual_scenes {
        for node: scene.children {
            for node_child: node.children {
                if node_child.node_type == "instance_geometry" {
                    target := xml_get_property(node_child, "url").content;
                    target.data += 1;
                    target.count -= 1;

                    print("target: %\n", target);

                    geom: type_of(collada.library_geometries[0]);
                    for geo: collada.library_geometries {
                        if xml_get_property(geo, "id").content == target {
                            geom = geo;
                            break;
                        }
                    }

                    material_instance := node_child.children[0].children[0].children[0]; // hack
                    assert(material_instance.node_type == "instance_material");
                    target = xml_get_property(material_instance, "target").content;
                    target.data += 1;
                    target.count -= 1;

                    for m: collada.library_materials {
                        if xml_get_property(m, "id").content == target {
                            material_instance = m;
                            break;
                        }
                    }

                    material: type_of(collada.library_materials[0]) = xx material_instance;

                    // MAX_TEXTURES_PER_MESH  :: 4;
                    // TEXTURE_DIFFUSE_INDEX  :: 0;
                    // TEXTURE_NORMAL_INDEX   :: 1;
                    // TEXTURE_SPECULAR_INDEX :: 2;

                    // Material :: struct {
                    //     textures: [MAX_TEXTURES_PER_MESH] *Texture;
                    //     specular_exp: float;
                    //     ambient: Color;
                    //     diffuse: Color;
                    //     specular: Color;
                    //     emissive: Color;
                    //     transparency: float;
                    // };

                    // Effect :: struct {
                    //     using xml: Xml_Node;
                    //     id: string;
                    //     emission: [4] float;
                    //     ambient: [4] float;
                    //     diffuse: [4] float;
                    //     specular: [4] float;
                    //     shininess: float;
                    //     index_of_refraction: float;

                    //     textures: [..] *Texture;
                    //     surfaces: [..] *Xml_Node; // Read: newparam
                    //     sampler2Ds: [..] *Xml_Node; // Read: sampler2D 
                    // }

                    // Material :: struct {
                    //     using xml: Xml_Node;
                    //     id: string;
                    //     name: string;

                    //     instance: *Effect;

                    //     // these are resolved for user convinience
                    //     bump_index :: 0;
                    //     textures: [1] *Image;
                    // }

                    in := material.instance;

                    mat := Material.new();
                    mat.diffuse = make_Color(in.diffuse[0], in.diffuse[1], in.diffuse[2]);

                    if material.textures[material.bump_index] mat.textures[TEXTURE_NORMAL_INDEX] = load_image(asset_man, concatenate(path_of(path), "/", material.textures[material.bump_index].filepath));

                    assert(material.textures[material.bump_index] != null);
                    assert(mat.textures[TEXTURE_NORMAL_INDEX] != null);
                    {
                        model := Model.new();
                        for mesh: geom.meshes {
                            me := Mesh.new();

                            if mesh.position_index > -1 {
                                vdata := mesh.vertex_data[mesh.position_index];
                                for vdata {
                                    array_add(*me.vertices, V3(it, vdata[it_index+1], vdata[it_index+2]));
                                    it_index += 2;
                                }
                            }

                            if mesh.normal_index > -1 {
                                ndata := mesh.vertex_data[mesh.normal_index];
                                for ndata {
                                    array_add(*me.normals, V3(it, ndata[it_index+1], ndata[it_index+2]));
                                    it_index += 2;
                                }
                            }

                            if mesh.texcoords_index > -1 {
                                tdata := mesh.vertex_data[mesh.texcoords_index];
                                for tdata {
                                    array_add(*me.tex_coords, V2(it, tdata[it_index+1]));
                                    it_index += 1;
                                }
                            }

                            array_add(*model.meshes, me);
                            me.material = mat;
                        }

                        for model.meshes {
                            store_mesh_in_buffer(it);
                        }
                        return model;
                    }
                }
            }
        }
    }

    // for geom: collada.library_geometries {
    //     model := Model.new();
    //     for mesh: geom.meshes {
    //         me := Mesh.new();

    //         if mesh.position_index > -1 {
    //             vdata := mesh.vertex_data[mesh.position_index];
    //             for vdata {
    //                 array_add(*me.vertices, V3(it, vdata[it_index+1], vdata[it_index+2]));
    //              it_index += 2;
    //             }
    //         }

    //         if mesh.normal_index > -1 {
    //             ndata := mesh.vertex_data[mesh.normal_index];
    //             for ndata {
    //                 array_add(*me.normals, V3(it, ndata[it_index+1], ndata[it_index+2]));
    //                 it_index += 2;
    //             }
    //         }

    //         if mesh.texcoords_index > -1 {
    //             tdata := mesh.vertex_data[mesh.texcoords_index];
    //             for tdata {
    //                 array_add(*me.tex_coords, V2(it, tdata[it_index+1]));
    //                 it_index += 1;
    //             }
    //         }

    //         array_add(*model.meshes, me);
    //         mat := Material.new();
    //         me.material = mat;
    //         mat.diffuse = make_Color(0.8, 0.8, 0.8);
    //     }

    //     for model.meshes {
    //         store_mesh_in_buffer(it);
    //     }
    //     return model;
    // }

    // assert(false);

    return null;
}

#scope_file
#load "dae_parser.jai";

using ML_Token_Type;