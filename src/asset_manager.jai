#import "Basic";
#import "File";

Asset_Manager :: struct {
    textures: Hash_Map(#type *Texture);
    models: Hash_Map(#type *Model);
    materials: Hash_Map(#type *Material_Lib);
    fonts: Hash_Map(#type *Font);
    shader_catalog: Hash_Map(#type Shader_Info);

    game: *Game;
}

Shader_Info :: struct {
    dependencies: [..] *Shader; // shaders linked using this one
};

Material_Lib :: struct {
    using map: Hash_Map(#type *Material);
}
// Material_Lib :: Hash_Map(#type (*Material));

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

    print("ERROR:%s\n", point_at_c_string(stbi_failure_reason()));
    return null;
}

load_model :: (using asset_man: *Asset_Manager, filepath: string) -> *Model {
    obj_source := read_entire_file(filepath);
    mod := model_loader_parse_obj(game, obj_source, filepath);
    for mod.meshes {
        maybe_calc_tangent_normals(it);
        store_mesh_in_buffer(it);
    }
    if (get_slot(*models, filepath)) {
        // @TODO free old model
    }
    set_slot(*models, filepath, mod);
    return mod;
}

reload_shader :: (using asset_man: *Asset_Manager, path: string) {
    deps := get_slot(*shader_catalog, path).dependencies;
    for deps {
        // kind of wastefull, we can speed this up by detecting which shader it is early (extension check)
        vsrc := read_entire_file(it.vert_path);
        fsrc := read_entire_file(it.frag_path);
        compile_shader_source(it, vsrc, fsrc);
        free(vsrc);
        free(fsrc);
    }
}

// Load vert/frag pair as a new shader
load_shader_pair :: (using asset_man: *Asset_Manager, vpath: string, fpath: string) -> *Shader {
    vert := read_entire_file(vpath);
    frag := read_entire_file(fpath);
    sh := compile_shader_source(vert, frag);
    array_add(*get_slot(*shader_catalog, vpath).dependencies, sh);
    array_add(*get_slot(*shader_catalog, fpath).dependencies, sh);
    sh.vert_path = copy_string(vpath);
    sh.frag_path = copy_string(fpath);
    free(vert);
    free(frag);
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
    p := find_and_truncate_character_from_right(filepath, #char "/");
    return p;
}

#scope_file
using ML_Token_Type;
#scope_export

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

    print("");

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
                mat = New(Material);
                set_slot(lib, tok._string, mat);

                ml_get_token(*st, *tok);
            } else if (!mat) {
                assert(false && "setting property before declaring material");
            } else if (name == "Ns") {
                ml_get_token(*st, *tok);
                assert(tok.type == ML_TOKEN_FLOAT || tok.type == ML_TOKEN_INTEGER);
                if (tok.type == ML_TOKEN_FLOAT)
                    mat.specular_exp = cast(float) tok._float;
                else if (tok.type == ML_TOKEN_INTEGER)
                    mat.specular_exp = cast(float) tok.integer;
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

                c: Color;
                c.r = r;
                c.g = g;
                c.b = b;
                mat.ambient = c;

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

                c: Color;
                c.r = r;
                c.g = g;
                c.b = b;
                mat.specular = c;

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

                c: Color;
                c.r = r;
                c.g = g;
                c.b = b;
                mat.emissive = c;

                ml_get_token(*st, *tok);
            } else if (name == "Ni") {
                ml_get_token(*st, *tok);
                assert(tok.type == ML_TOKEN_FLOAT);
                ml_get_token(*st, *tok);
            } else if (name == "d") {
                ml_get_token(*st, *tok);
                assert(tok.type == ML_TOKEN_FLOAT || tok.type == ML_TOKEN_INTEGER);
                if (tok.type == ML_TOKEN_FLOAT)
                    mat.transparency = cast(float) tok._float;
                else if (tok.type == ML_TOKEN_INTEGER)
                    mat.transparency = cast(float) tok.integer;
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
                filepath := tok._string;
                p := path_of(mtl_filepath);
                filepath = concatenate(p, "/", filepath);

                tex := load_image(game.asset_man, filepath);
                mat.textures[TEXTURE_SPECULAR_INDEX] = tex;

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

    mod := New(Model);
    mesh: *Mesh = null;
    vertices: [..] Vector3;
    normals: [..] Vector3;
    tex_coords: [..] Vector2;
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
            if (name == "mtllib") {
                ml_get_token(*st, *tok);
                assert(tok.type == ML_TOKEN_IDENTIFIER);
                filepath := tok._string;
                print("%\n", filepath);
                p := path_of(obj_filepath);
                filepath = concatenate(p, "/", filepath);
                print("path: %\n", filepath);
                lib_src := read_entire_file(filepath);

                // @TODO this should hook into asset_man
                model_loader_parse_mtl(game, lib_src, lib, filepath);

                ml_get_token(*st, *tok);
            } else if (name == "o") {
                ml_get_token(*st, *tok);
                assert(tok.type == ML_TOKEN_IDENTIFIER);
                mesh = New(Mesh);
                array_add(*mod.meshes, mesh);
                array_reset(*vertices);

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
