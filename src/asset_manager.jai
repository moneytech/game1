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
    map: Hash_Map(#type (*Material));
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

/*



    Model *load_model(const char *filepath) {
        char *obj_source = slurp_file(filepath);
        Model *mod = model_loader_parse_obj(game, obj_source, filepath);
        for (u32 i = 0; i < mod->meshes.count; ++i) {
            auto it = mod->meshes[i];
            maybe_calc_tangent_normals(it);
            game->renderer->store_mesh_in_buffer(it);
        }
        if (models[filepath]) {
            // @TODO free old model
        }
        models[filepath] = mod;
        return mod;
    }

    void reload_shader(const char *path) {
        auto &deps = shader_catalog[path].dependencies;
        for (u32 i = 0; i < deps.count; ++i) {
            auto it = deps[i];
            // kind of wastefull, we can speed this up by detecting which shader it is early (extension check)
            char *vsrc = slurp_file(it->vert_path);
            char *fsrc = slurp_file(it->frag_path);
            game->renderer->compile_shader_source(it, vsrc, fsrc);
            FREE_MEMORY(vsrc);
            FREE_MEMORY(fsrc);
        }
    }

    // Load vert/frag pair as a new shader
    Shader *load_shader_pair(const char *vpath, const char *fpath) {
        char *vert = slurp_file(vpath);
        char *frag = slurp_file(fpath);
        Shader *sh = game->renderer->compile_shader_source(vert, frag);
        shader_catalog[vpath].dependencies.add(sh);
        shader_catalog[fpath].dependencies.add(sh);
        sh->vert_path = copy_c_string(vpath);
        sh->frag_path = copy_c_string(fpath);
        FREE_MEMORY(vert);
        FREE_MEMORY(frag);
        return sh;
    }



char *path_of(const char *filepath) {
    const char *p = strrchr(filepath, '/');
    char *out = GET_MEMORY_SIZED(p - filepath + 2);
    memcpy(out, filepath, p-filepath+1);
    out[p-filepath+1] = 0;
    return out;
}

float ml_get_signed_float(ML_State *st, ML_Token *tok) {
    bool neg = false;
    if (tok->type == '-') {
        neg = true;
        ml_get_token(st, tok);
    }

    assert(tok->type == ML_TOKEN_FLOAT);
    float val = (float) tok->float64;

    ml_get_token(st, tok);
    return neg ? -val : val;    
}

void model_loader_parse_mtl(Game *game, const char *src, Material_Lib &lib, const char *mtl_filepath) {
    ML_State st;
    st.flags = ML_DOTS_IN_IDENTIFIERS;
    ml_init(*st, strlen(src), (char *)src);
    ML_Token tok;

    Material *mat = nullptr;
    ml_get_token(*st, *tok);
    while(tok.type != ML_TOKEN_END) {
        if (tok.type == '#') {
            int current_line = tok.line_number;
            while (tok.line_number == current_line && tok.type != ML_TOKEN_END)
                ml_get_token(*st, *tok); // eat comment line
            continue;
        }

        if (tok.type == ML_TOKEN_IDENTIFIER) {
            char *ml_string_to_c_string(ML_String *str);
            char *name = ml_string_to_c_string(*tok.string);
            if (compare_c_strings(name, "newmtl")) {
                ml_get_token(*st, *tok);
                assert(tok.type == ML_TOKEN_IDENTIFIER);
                lib[ml_string_to_c_string(*tok.string)] = mat = GET_MEMORY_ZERO_INIT(Material);

                ml_get_token(*st, *tok);
            } else if (!mat) {
                assert(0 && "setting property before declaring material");
            } else if (compare_c_strings(name, "Ns")) {
                ml_get_token(*st, *tok);
                assert(tok.type == ML_TOKEN_FLOAT || tok.type == ML_TOKEN_INTEGER);
                if (tok.type == ML_TOKEN_FLOAT)
                    mat->specular_exp = (float)tok.float64;
                else if (tok.type == ML_TOKEN_INTEGER)
                    mat->specular_exp = (float)tok.integer;
                ml_get_token(*st, *tok);
            } else if (compare_c_strings(name, "Ka")) {
                ml_get_token(*st, *tok);
                assert(tok.type == ML_TOKEN_FLOAT);
                float r = (float)tok.float64;
                
                ml_get_token(*st, *tok);
                assert(tok.type == ML_TOKEN_FLOAT);
                float g = (float)tok.float64;

                ml_get_token(*st, *tok);
                assert(tok.type == ML_TOKEN_FLOAT);
                float b = (float)tok.float64;

                Color c;
                c.r = r;
                c.g = g;
                c.b = b;
                mat->ambient = c;

                ml_get_token(*st, *tok);
            } else if (compare_c_strings(name, "Kd")) {
                ml_get_token(*st, *tok);
                assert(tok.type == ML_TOKEN_FLOAT);
                float r = (float)tok.float64;
                
                ml_get_token(*st, *tok);
                assert(tok.type == ML_TOKEN_FLOAT);
                float g = (float)tok.float64;

                ml_get_token(*st, *tok);
                assert(tok.type == ML_TOKEN_FLOAT);
                float b = (float)tok.float64;

                Color c;
                c.r = r;
                c.g = g;
                c.b = b;
                mat->diffuse = c;

                ml_get_token(*st, *tok);
            } else if (compare_c_strings(name, "Ks")) {
                ml_get_token(*st, *tok);
                assert(tok.type == ML_TOKEN_FLOAT);
                float r = (float)tok.float64;
                
                ml_get_token(*st, *tok);
                assert(tok.type == ML_TOKEN_FLOAT);
                float g = (float)tok.float64;

                ml_get_token(*st, *tok);
                assert(tok.type == ML_TOKEN_FLOAT);
                float b = (float)tok.float64;

                Color c;
                c.r = r;
                c.g = g;
                c.b = b;
                mat->specular = c;

                ml_get_token(*st, *tok);
            } else if (compare_c_strings(name, "Ke")) {
                ml_get_token(*st, *tok);
                assert(tok.type == ML_TOKEN_FLOAT);
                float r = (float)tok.float64;
                
                ml_get_token(*st, *tok);
                assert(tok.type == ML_TOKEN_FLOAT);
                float g = (float)tok.float64;

                ml_get_token(*st, *tok);
                assert(tok.type == ML_TOKEN_FLOAT);
                float b = (float)tok.float64;

                Color c;
                c.r = r;
                c.g = g;
                c.b = b;
                mat->emissive = c;

                ml_get_token(*st, *tok);
            } else if (compare_c_strings(name, "Ni")) {
                ml_get_token(*st, *tok);
                assert(tok.type == ML_TOKEN_FLOAT);
                ml_get_token(*st, *tok);
            } else if (compare_c_strings(name, "d")) {
                ml_get_token(*st, *tok);
                assert(tok.type == ML_TOKEN_FLOAT || tok.type == ML_TOKEN_INTEGER);
                if (tok.type == ML_TOKEN_FLOAT)
                    mat->transparency = (float)tok.float64;
                else if (tok.type == ML_TOKEN_INTEGER)
                    mat->transparency = (float)tok.integer;
                ml_get_token(*st, *tok);
            } else if (compare_c_strings(name, "illum")) {
                ml_get_token(*st, *tok);
                assert(tok.type == ML_TOKEN_INTEGER);
                ml_get_token(*st, *tok);
            } else if (compare_c_strings(name, "map_Kd")) {
                ml_get_token(*st, *tok);
                assert(tok.type == ML_TOKEN_IDENTIFIER);
                char *filepath = ml_string_to_c_string(*tok.string);
                char *p = path_of(mtl_filepath);
                filepath = concatenate(p, filepath);

                Texture *tex = game->asset_man->load_image(filepath);
                mat->textures[TEXTURE_DIFFUSE_INDEX] = tex;

                ml_get_token(*st, *tok);
            } else if (compare_c_strings(name, "map_Bump")) {
                ml_get_token(*st, *tok);
                if (tok.type == '-') {
                    ml_get_token(*st, *tok);
                    assert(tok.type == ML_TOKEN_IDENTIFIER);

                    name = ml_string_to_c_string(*tok.string);
                    if (compare_c_strings(name, "bm")) {
                        ml_get_token(*st, *tok);
                        float bump_mult = ml_get_signed_float(*st, *tok);

                        // @TODO not really sure how to use the bump multiplier..
                    } else {
                        assert(false);
                    }
                }
                assert(tok.type == ML_TOKEN_IDENTIFIER);
                char *filepath = ml_string_to_c_string(*tok.string);
                char *p = path_of(mtl_filepath);
                filepath = concatenate(p, filepath);

                Texture *tex = game->asset_man->load_image(filepath);
                mat->textures[TEXTURE_NORMAL_INDEX] = tex;

                ml_get_token(*st, *tok);
            } else if (compare_c_strings(name, "map_Ks")) {
                ml_get_token(*st, *tok);
                assert(tok.type == ML_TOKEN_IDENTIFIER);
                char *filepath = ml_string_to_c_string(*tok.string);
                char *p = path_of(mtl_filepath);
                filepath = concatenate(p, filepath);

                Texture *tex = game->asset_man->load_image(filepath);
                mat->textures[TEXTURE_SPECULAR_INDEX] = tex;

                ml_get_token(*st, *tok);
            } else {
                assert(false);
            }
        } else {
            assert(false);
        }
    }
}

Model *model_loader_parse_obj(Game *game, const char *src, const char *obj_filepath) {
    Material_Lib lib;
    ML_State st;
    st.flags = ML_DOTS_IN_IDENTIFIERS;
    ml_init(*st, strlen(src), (char *)src);
    ML_Token tok;

    Model *mod = GET_MEMORY_ZERO_INIT(Model);
    Mesh *mesh = nullptr;
    Array<Vector3> vertices;
    Array<Vector3> normals;
    Array<Vector2> tex_coords;
    ml_get_token(*st, *tok);
    while(tok.type != ML_TOKEN_END) {
        if (tok.type == '#') {
            int current_line = tok.line_number;
            while (tok.line_number == current_line && tok.type != ML_TOKEN_END)
                ml_get_token(*st, *tok); // eat comment line
            continue;
        }

        if (tok.type == ML_TOKEN_IDENTIFIER) {
            char *ml_string_to_c_string(ML_String *str);
            char *name = ml_string_to_c_string(*tok.string);
            if (compare_c_strings(name, "mtllib")) {
                ml_get_token(*st, *tok);
                assert(tok.type == ML_TOKEN_IDENTIFIER);
                char *filepath = ml_string_to_c_string(*tok.string);
                char *p = path_of(obj_filepath);
                filepath = concatenate(p, filepath);
                char *lib_src = slurp_file(filepath);

                // @TODO this should hook into asset_man
                model_loader_parse_mtl(game, lib_src, lib, filepath);

                ml_get_token(*st, *tok);
            } else if (compare_c_strings(name, "o")) {
                ml_get_token(*st, *tok);
                assert(tok.type == ML_TOKEN_IDENTIFIER);
                mesh = GET_MEMORY_ZERO_INIT(Mesh);
                mod->meshes.add(mesh);
                vertices.clear();

                ml_get_token(*st, *tok);
            } else if (!mesh) {
                assert(0 && "setting property before declaring object");
            } else if (compare_c_strings(name, "v")) {
                ml_get_token(*st, *tok);
                Vector3 v;
                v.x = ml_get_signed_float(*st, *tok);
                v.y = ml_get_signed_float(*st, *tok);
                v.z = ml_get_signed_float(*st, *tok);
                vertices.add(v);
            } else if (compare_c_strings(name, "vn")) {
                ml_get_token(*st, *tok);
                Vector3 v;
                v.x = ml_get_signed_float(*st, *tok);
                v.y = ml_get_signed_float(*st, *tok);
                v.z = ml_get_signed_float(*st, *tok);
                normals.add(v);
            } else if (compare_c_strings(name, "vt")) {
                ml_get_token(*st, *tok);
                Vector2 v;
                v.x = ml_get_signed_float(*st, *tok);
                v.y = 1.0f - ml_get_signed_float(*st, *tok);
                tex_coords.add(v);
            } else if (compare_c_strings(name, "usemtl")) {
                ml_get_token(*st, *tok);
                assert(tok.type == ML_TOKEN_IDENTIFIER);
                char *mtl_name = ml_string_to_c_string(*tok.string);
                mesh->material = lib[mtl_name];
                assert(mesh->material);
                ml_get_token(*st, *tok);
            } else if (compare_c_strings(name, "s")) {
                ml_get_token(*st, *tok);
                assert(tok.type == ML_TOKEN_IDENTIFIER || tok.type == ML_TOKEN_INTEGER);
                // smooth shading
                ml_get_token(*st, *tok);
            } else if (compare_c_strings(name, "f")) {
                ml_get_token(*st, *tok);
                assert(tok.type == ML_TOKEN_INTEGER);
                mesh->vertices.add(vertices[tok.integer-1]);
                ml_get_token(*st, *tok); assert(tok.type == '/');
                ml_get_token(*st, *tok);
                if (tok.type == ML_TOKEN_INTEGER) {
                    mesh->tex_coords.add(tex_coords[tok.integer-1]);
                    ml_get_token(*st, *tok);
                }
                assert(tok.type == '/');
                ml_get_token(*st, *tok); assert(tok.type == ML_TOKEN_INTEGER);
                mesh->normals.add(normals[tok.integer-1]);

                ml_get_token(*st, *tok);
                assert(tok.type == ML_TOKEN_INTEGER);
                mesh->vertices.add(vertices[tok.integer-1]);
                ml_get_token(*st, *tok); assert(tok.type == '/');
                ml_get_token(*st, *tok);
                if (tok.type == ML_TOKEN_INTEGER) {
                    mesh->tex_coords.add(tex_coords[tok.integer-1]);
                    ml_get_token(*st, *tok);
                }
                assert(tok.type == '/');
                ml_get_token(*st, *tok); assert(tok.type == ML_TOKEN_INTEGER);
                mesh->normals.add(normals[tok.integer-1]);

                ml_get_token(*st, *tok);
                assert(tok.type == ML_TOKEN_INTEGER);
                mesh->vertices.add(vertices[tok.integer-1]);
                ml_get_token(*st, *tok); assert(tok.type == '/');
                ml_get_token(*st, *tok);
                if (tok.type == ML_TOKEN_INTEGER) {
                    mesh->tex_coords.add(tex_coords[tok.integer-1]);
                    ml_get_token(*st, *tok);
                }
                assert(tok.type == '/');
                ml_get_token(*st, *tok); assert(tok.type == ML_TOKEN_INTEGER);
                mesh->normals.add(normals[tok.integer-1]);

                ml_get_token(*st, *tok);
            } else {
                assert(false);
            }
        } else {
            assert(false);
        }
    }
    return mod;
}
*/