
#include "general.h"
#include "os_api.h"
#include "renderer.h"
#include "game.h"

#include "stb_image.h"

#define MACH_LEXER_IMPLEMENTATION
#define MACH_LEXER_ENABLE_HTML

#include "lexer.h"
#include "html_parser.h"

const int WINDOW_WIDTH = 1280;
const int WINDOW_HEIGHT = 720;

float x = 0, y = 0;

Texture *tex = nullptr;
GL_Renderer *renderer = nullptr;
Font *font = nullptr;
Model *__model = nullptr;

struct Html_Phase {
    float text_x = 0;
    float text_y = 0;
    bool centered = false;
    Font *font = nullptr;
};

void render_html_node(Html_Phase *phs, Html *node);

void render_html_center(Html_Phase *phs, Html_Node *n) {
    // if a parent node in the tree is a center tag, we
    // need to avoid turning off centered until we get back up
    // to the parent-most center node
    bool update = !phs->centered;
    phs->centered = true;
    for (u32 i = 0; i < n->children.count; ++i) {
        auto c = n->children[i];
        render_html_node(phs, c);
    }
    if (update) phs->centered = false;
}

void render_html_node(Html_Phase *phs, Html *node) {
    if (node->type == HTML_TYPE_BARE_WORD) {
        Html_Bare_Word *word = static_cast<Html_Bare_Word *>(node);
        renderer->draw_text(font, word->word, 20, 20);
    } else if (node->type == HTML_TYPE_NODE || node->type == HTML_TYPE_TAG) {
        Html_Node *n = static_cast<Html_Node *>(node);
        // @FixMe Atom table
        if (node->type == HTML_TYPE_TAG && strcmp(static_cast<Html_Tag *>(n)->identifier->name->name, "center") == 0) {
            render_html_center(phs, n);
            return;
        }
        for (u32 i = 0; i < n->children.count; ++i) {
            auto c = n->children[i];
            render_html_node(phs, c);
        }
    }
}

void render_html_dom(Html_Dom *dom) {
    Html_Phase phs;
    for (u32 i = 0; i < dom->children.count; ++i) {
        auto c = dom->children[i];
        render_html_node(&phs, c);
    }
}

void render() {
    renderer->set_projection_fov(90.0f, (float)WINDOW_WIDTH/(float)WINDOW_HEIGHT, 0.1f, 100.0f);
    renderer->start_scene();
    renderer->clear_screen(0.0, 0.0, 0.0, 1.0);
    // renderer->draw_cube(0, 0, -2, 1);
    renderer->draw_model(__model);
    renderer->finish_scene();


    renderer->set_projection_ortho(0, (float)WINDOW_WIDTH, (float)WINDOW_HEIGHT, 0, -1, 1);
    /*
    Bitmap_Frame frame = {0};
    frame.tex_coords.width = 14.0f / (float)tex->width;
    frame.tex_coords.height = 14.0f / (float)tex->height;
    frame.tex_coords.x = (16.0f * 3) / (float)tex->width;
    frame.tex_coords.y = (16.0f * 4) / (float)tex->height;
    Sprite sp = {0};
    sp.current_frame = &frame;
    sp.dimensions.x = x;
    sp.dimensions.y = y;
    sp.dimensions.width = 100.0;
    sp.dimensions.height = 100.0;
    sp.texture = tex;
    */
    // renderer->draw_sprite(&sp);
    // renderer->draw_text(font, "Hello World!", 32, 32);
    // render_html_dom(dom);
}

#pragma warning(disable:4996)

char *slurp_file(const char *path) {
    FILE *file = fopen(path, "rb");
    if (!file) return nullptr;

    fseek(file, 0, SEEK_END);
    size_t len = ftell(file);
    fseek(file, 0, SEEK_SET);

    char *out = GET_MEMORY_SIZED(len+1);
    size_t count = 0;
    while ((count = fread(out+count, 1, len-count, file)) != 0) {}

    fclose(file);
    out[len] = 0;
    return out;
}

unsigned char ttf_buffer[1<<20];
unsigned char temp_bitmap[512*512];

void my_stbtt_initfont(Font *font)
{
    FILE *f = fopen("c:/windows/fonts/times.ttf", "rb");
    fread(ttf_buffer, 1, 1<<20, f);
    stbtt_BakeFontBitmap(ttf_buffer,0, 32.0, temp_bitmap,512,512, 32,96, font->cdata); // no guarantee this fits!
    fclose(f);
}


struct Shader_Info {
    Array<Shader *> dependencies; // shaders linked using this one
};


typedef Hash_Map<Material *> Material_Lib;

Model *model_loader_parse_obj(Game *game, const char *src, const char *obj_filepath);
void model_loader_parse_mtl(Game *game, const char *src, Material_Lib &lib, const char *mtl_filepath);

void maybe_calc_tangent_normals(Mesh *m) {
    if (!m->material->textures[TEXTURE_NORMAL_INDEX]) return;

    auto &tex = m->tex_coords;
    auto &verts = m->vertices;
    auto &tangents = m->tangent_normals;
    tangents.reserve(verts.count);
    for (u32 i = 0; i < verts.count; i += 3) {
        Vector3 e1 = verts[i+1] - verts[i];
        Vector3 e2 = verts[i+2] - verts[i];

        Vector2 dUV1 = tex[i+1] - tex[i];
        Vector2 dUV2 = tex[i+2] - tex[i];

        float f = 1.0f / (dUV1.x * dUV2.y - dUV2.x * dUV1.y);

        Vector3 tangent;
        tangent.x = f * (dUV2.y * e1.x - dUV1.y * e2.x);
        tangent.y = f * (dUV2.y * e1.y - dUV1.y * e2.y);
        tangent.z = f * (dUV2.y * e1.z - dUV1.y * e2.z);
        tangent = normalize(tangent);

        // we add it three times, one for each vertex
        tangents.add(tangent);
        tangents.add(tangent);
        tangents.add(tangent);
    }    
}

struct Asset_Manager {
    Hash_Map<Texture *> textures;
    Hash_Map<Model *> models;
    Hash_Map<Material_Lib *> materials;
    Hash_Map<Font *> fonts;
    Hash_Map<Shader_Info> shader_catalog;

    Game *game;

    Asset_Manager(Game *g) : game(g) {}

    Texture *load_image(const char *filepath) {
        int width, height, comp;
        unsigned char *data = stbi_load(filepath, &width, &height, &comp, 4); // 4 forces RGBA components / 4 bytes-per-pixel

        if (data) {
            Texture *tex = textures[filepath];
            if (!tex) {
                tex = GET_MEMORY(Texture);
                textures[filepath] = tex;
            } else {
                game->renderer->delete_texture(tex);
            }

            game->renderer->create_texture(tex, width, height, data);
            stbi_image_free(data);
            return tex;
        }

        printf("ERROR:%s\n", stbi_failure_reason());
        return nullptr;
    }

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
};


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
    ml_init(&st, strlen(src), (char *)src);
    ML_Token tok;

    Material *mat = nullptr;
    ml_get_token(&st, &tok);
    while(tok.type != ML_TOKEN_END) {
        if (tok.type == '#') {
            int current_line = tok.line_number;
            while (tok.line_number == current_line && tok.type != ML_TOKEN_END)
                ml_get_token(&st, &tok); // eat comment line
            continue;
        }

        if (tok.type == ML_TOKEN_IDENTIFIER) {
            char *ml_string_to_c_string(ML_String *str);
            char *name = ml_string_to_c_string(&tok.string);
            if (compare_c_strings(name, "newmtl")) {
                ml_get_token(&st, &tok);
                assert(tok.type == ML_TOKEN_IDENTIFIER);
                lib[ml_string_to_c_string(&tok.string)] = mat = GET_MEMORY_ZERO_INIT(Material);

                ml_get_token(&st, &tok);
            } else if (!mat) {
                assert(0 && "setting property before declaring material");
            } else if (compare_c_strings(name, "Ns")) {
                ml_get_token(&st, &tok);
                assert(tok.type == ML_TOKEN_FLOAT || tok.type == ML_TOKEN_INTEGER);
                if (tok.type == ML_TOKEN_FLOAT)
                    mat->specular_exp = (float)tok.float64;
                else if (tok.type == ML_TOKEN_INTEGER)
                    mat->specular_exp = (float)tok.integer;
                ml_get_token(&st, &tok);
            } else if (compare_c_strings(name, "Ka")) {
                ml_get_token(&st, &tok);
                assert(tok.type == ML_TOKEN_FLOAT);
                float r = (float)tok.float64;
                
                ml_get_token(&st, &tok);
                assert(tok.type == ML_TOKEN_FLOAT);
                float g = (float)tok.float64;

                ml_get_token(&st, &tok);
                assert(tok.type == ML_TOKEN_FLOAT);
                float b = (float)tok.float64;

                Color c;
                c.r = r;
                c.g = g;
                c.b = b;
                mat->ambient = c;

                ml_get_token(&st, &tok);
            } else if (compare_c_strings(name, "Kd")) {
                ml_get_token(&st, &tok);
                assert(tok.type == ML_TOKEN_FLOAT);
                float r = (float)tok.float64;
                
                ml_get_token(&st, &tok);
                assert(tok.type == ML_TOKEN_FLOAT);
                float g = (float)tok.float64;

                ml_get_token(&st, &tok);
                assert(tok.type == ML_TOKEN_FLOAT);
                float b = (float)tok.float64;

                Color c;
                c.r = r;
                c.g = g;
                c.b = b;
                mat->diffuse = c;

                ml_get_token(&st, &tok);
            } else if (compare_c_strings(name, "Ks")) {
                ml_get_token(&st, &tok);
                assert(tok.type == ML_TOKEN_FLOAT);
                float r = (float)tok.float64;
                
                ml_get_token(&st, &tok);
                assert(tok.type == ML_TOKEN_FLOAT);
                float g = (float)tok.float64;

                ml_get_token(&st, &tok);
                assert(tok.type == ML_TOKEN_FLOAT);
                float b = (float)tok.float64;

                Color c;
                c.r = r;
                c.g = g;
                c.b = b;
                mat->specular = c;

                ml_get_token(&st, &tok);
            } else if (compare_c_strings(name, "Ke")) {
                ml_get_token(&st, &tok);
                assert(tok.type == ML_TOKEN_FLOAT);
                float r = (float)tok.float64;
                
                ml_get_token(&st, &tok);
                assert(tok.type == ML_TOKEN_FLOAT);
                float g = (float)tok.float64;

                ml_get_token(&st, &tok);
                assert(tok.type == ML_TOKEN_FLOAT);
                float b = (float)tok.float64;

                Color c;
                c.r = r;
                c.g = g;
                c.b = b;
                mat->emissive = c;

                ml_get_token(&st, &tok);
            } else if (compare_c_strings(name, "Ni")) {
                ml_get_token(&st, &tok);
                assert(tok.type == ML_TOKEN_FLOAT);
                ml_get_token(&st, &tok);
            } else if (compare_c_strings(name, "d")) {
                ml_get_token(&st, &tok);
                assert(tok.type == ML_TOKEN_FLOAT || tok.type == ML_TOKEN_INTEGER);
                if (tok.type == ML_TOKEN_FLOAT)
                    mat->transparency = (float)tok.float64;
                else if (tok.type == ML_TOKEN_INTEGER)
                    mat->transparency = (float)tok.integer;
                ml_get_token(&st, &tok);
            } else if (compare_c_strings(name, "illum")) {
                ml_get_token(&st, &tok);
                assert(tok.type == ML_TOKEN_INTEGER);
                ml_get_token(&st, &tok);
            } else if (compare_c_strings(name, "map_Kd")) {
                ml_get_token(&st, &tok);
                assert(tok.type == ML_TOKEN_IDENTIFIER);
                char *filepath = ml_string_to_c_string(&tok.string);
                char *p = path_of(mtl_filepath);
                filepath = concatenate(p, filepath);

                Texture *tex = game->asset_man->load_image(filepath);
                mat->textures[TEXTURE_DIFFUSE_INDEX] = tex;

                ml_get_token(&st, &tok);
            } else if (compare_c_strings(name, "map_Bump")) {
                ml_get_token(&st, &tok);
                if (tok.type == '-') {
                    ml_get_token(&st, &tok);
                    assert(tok.type == ML_TOKEN_IDENTIFIER);

                    name = ml_string_to_c_string(&tok.string);
                    if (compare_c_strings(name, "bm")) {
                        ml_get_token(&st, &tok);
                        float bump_mult = ml_get_signed_float(&st, &tok);

                        // @TODO not really sure how to use the bump multiplier..
                    } else {
                        assert(0);
                    }
                }
                assert(tok.type == ML_TOKEN_IDENTIFIER);
                char *filepath = ml_string_to_c_string(&tok.string);
                char *p = path_of(mtl_filepath);
                filepath = concatenate(p, filepath);

                Texture *tex = game->asset_man->load_image(filepath);
                mat->textures[TEXTURE_NORMAL_INDEX] = tex;

                ml_get_token(&st, &tok);
            } else if (compare_c_strings(name, "map_Ks")) {
                ml_get_token(&st, &tok);
                assert(tok.type == ML_TOKEN_IDENTIFIER);
                char *filepath = ml_string_to_c_string(&tok.string);
                char *p = path_of(mtl_filepath);
                filepath = concatenate(p, filepath);

                Texture *tex = game->asset_man->load_image(filepath);
                mat->textures[TEXTURE_SPECULAR_INDEX] = tex;

                ml_get_token(&st, &tok);
            } else {
                assert(0);
            }
        } else {
            assert(0);
        }
    }
}

Model *model_loader_parse_obj(Game *game, const char *src, const char *obj_filepath) {
    Material_Lib lib;
    ML_State st;
    st.flags = ML_DOTS_IN_IDENTIFIERS;
    ml_init(&st, strlen(src), (char *)src);
    ML_Token tok;

    Model *mod = GET_MEMORY_ZERO_INIT(Model);
    Mesh *mesh = nullptr;
    Array<Vector3> vertices;
    Array<Vector3> normals;
    Array<Vector2> tex_coords;
    ml_get_token(&st, &tok);
    while(tok.type != ML_TOKEN_END) {
        if (tok.type == '#') {
            int current_line = tok.line_number;
            while (tok.line_number == current_line && tok.type != ML_TOKEN_END)
                ml_get_token(&st, &tok); // eat comment line
            continue;
        }

        if (tok.type == ML_TOKEN_IDENTIFIER) {
            char *ml_string_to_c_string(ML_String *str);
            char *name = ml_string_to_c_string(&tok.string);
            if (compare_c_strings(name, "mtllib")) {
                ml_get_token(&st, &tok);
                assert(tok.type == ML_TOKEN_IDENTIFIER);
                char *filepath = ml_string_to_c_string(&tok.string);
                char *p = path_of(obj_filepath);
                filepath = concatenate(p, filepath);
                char *lib_src = slurp_file(filepath);

                // @TODO this should hook into asset_man
                model_loader_parse_mtl(game, lib_src, lib, filepath);

                ml_get_token(&st, &tok);
            } else if (compare_c_strings(name, "o")) {
                ml_get_token(&st, &tok);
                assert(tok.type == ML_TOKEN_IDENTIFIER);
                mesh = GET_MEMORY_ZERO_INIT(Mesh);
                mod->meshes.add(mesh);
                vertices.clear();

                ml_get_token(&st, &tok);
            } else if (!mesh) {
                assert(0 && "setting property before declaring object");
            } else if (compare_c_strings(name, "v")) {
                ml_get_token(&st, &tok);
                Vector3 v;
                v.x = ml_get_signed_float(&st, &tok);
                v.y = ml_get_signed_float(&st, &tok);
                v.z = ml_get_signed_float(&st, &tok);
                vertices.add(v);
            } else if (compare_c_strings(name, "vn")) {
                ml_get_token(&st, &tok);
                Vector3 v;
                v.x = ml_get_signed_float(&st, &tok);
                v.y = ml_get_signed_float(&st, &tok);
                v.z = ml_get_signed_float(&st, &tok);
                normals.add(v);
            } else if (compare_c_strings(name, "vt")) {
                ml_get_token(&st, &tok);
                Vector2 v;
                v.x = ml_get_signed_float(&st, &tok);
                v.y = 1.0f - ml_get_signed_float(&st, &tok);
                tex_coords.add(v);
            } else if (compare_c_strings(name, "usemtl")) {
                ml_get_token(&st, &tok);
                assert(tok.type == ML_TOKEN_IDENTIFIER);
                char *mtl_name = ml_string_to_c_string(&tok.string);
                mesh->material = lib[mtl_name];
                assert(mesh->material);
                ml_get_token(&st, &tok);
            } else if (compare_c_strings(name, "s")) {
                ml_get_token(&st, &tok);
                assert(tok.type == ML_TOKEN_IDENTIFIER || tok.type == ML_TOKEN_INTEGER);
                // smooth shading
                ml_get_token(&st, &tok);
            } else if (compare_c_strings(name, "f")) {
                ml_get_token(&st, &tok);
                assert(tok.type == ML_TOKEN_INTEGER);
                mesh->vertices.add(vertices[tok.integer-1]);
                ml_get_token(&st, &tok); assert(tok.type == '/');
                ml_get_token(&st, &tok);
                if (tok.type == ML_TOKEN_INTEGER) {
                    mesh->tex_coords.add(tex_coords[tok.integer-1]);
                    ml_get_token(&st, &tok);
                }
                assert(tok.type == '/');
                ml_get_token(&st, &tok); assert(tok.type == ML_TOKEN_INTEGER);
                mesh->normals.add(normals[tok.integer-1]);

                ml_get_token(&st, &tok);
                assert(tok.type == ML_TOKEN_INTEGER);
                mesh->vertices.add(vertices[tok.integer-1]);
                ml_get_token(&st, &tok); assert(tok.type == '/');
                ml_get_token(&st, &tok);
                if (tok.type == ML_TOKEN_INTEGER) {
                    mesh->tex_coords.add(tex_coords[tok.integer-1]);
                    ml_get_token(&st, &tok);
                }
                assert(tok.type == '/');
                ml_get_token(&st, &tok); assert(tok.type == ML_TOKEN_INTEGER);
                mesh->normals.add(normals[tok.integer-1]);

                ml_get_token(&st, &tok);
                assert(tok.type == ML_TOKEN_INTEGER);
                mesh->vertices.add(vertices[tok.integer-1]);
                ml_get_token(&st, &tok); assert(tok.type == '/');
                ml_get_token(&st, &tok);
                if (tok.type == ML_TOKEN_INTEGER) {
                    mesh->tex_coords.add(tex_coords[tok.integer-1]);
                    ml_get_token(&st, &tok);
                }
                assert(tok.type == '/');
                ml_get_token(&st, &tok); assert(tok.type == ML_TOKEN_INTEGER);
                mesh->normals.add(normals[tok.integer-1]);

                ml_get_token(&st, &tok);
            } else {
                assert(0);
            }
        } else {
            assert(0);
        }
    }
    return mod;
}

void file_update_callback(File_Notification *notif, void *userdata) {
    Game *g = (Game *)userdata;
    printf("CALLBACK %s\n", &notif->name[0]);
    if (g->asset_man->textures.contains_key(&notif->name[0])) {
        printf("Updating file: %s\n", &notif->name[0]);
        g->asset_man->load_image(notif->name);
    } else if (g->asset_man->shader_catalog.contains_key(&notif->name[0])) {
        printf("Reloading shader: %s\n", notif->name);
        g->asset_man->reload_shader(notif->name);
    } else {
        printf("No key for %s\n", &notif->name[0]);
    }
}


#include <string.h>
#include <stdio.h>
void report_error(int err, const char *err_str, int line, int char_num) {
    printf("Error:%d:%d: %s\n", line, char_num, err_str);
}

void Game::report_error(char *format, ...) {
    assert(0);
}

void print_token(ML_Token *tok) {
    printf("%d:%d: ", tok->line_number, tok->character_number);
    switch(tok->type) {
        case ML_TOKEN_UNINITIALIZED:
            printf("Uninitialized token\n");
            break;
        case ML_TOKEN_STRING:
            printf("string: \"%.*s\"\n", (int)tok->string.length, tok->string.data);
            break;
        case ML_TOKEN_HTML_COMMENT:
            printf("<!\n");
            break;
        case ML_TOKEN_IDENTIFIER:
            printf("ident: \"%.*s\"\n", (int)tok->string.length, tok->string.data);
            break;
        case ML_TOKEN_INTEGER:
            printf("int: %llu\n", tok->integer);
            break;
        case ML_TOKEN_FLOAT:
            printf("float: %f\n", tok->float64);
            break;
        default:
            printf("tok: '%c'\n", tok->type);
    }
}

int main(int argc, char **argv) {
    os_init_platform();
    setcwd(os_get_executable_path());
    os_watch_dir("assets");
    // os_watch_dir("assets/shaders");

    OS_Window win = os_create_window(WINDOW_WIDTH, WINDOW_HEIGHT, "test");
    OS_GL_Context ctx = os_create_gl_context(win);
    os_make_current(win, ctx);
    os_set_vsync(true);

    GL_Renderer rdr;
    Game game;
    game.renderer = &rdr;
    Asset_Manager asset_man (&game);
    game.asset_man = &asset_man;

    rdr.game = &game;
    rdr.init(WINDOW_WIDTH, WINDOW_HEIGHT);
    renderer = &rdr;

    rdr.render_to_gbuffer = asset_man.load_shader_pair("assets/shaders/render_to_gbuffer.vert", "assets/shaders/render_to_gbuffer.frag");
    rdr.render_light_using_gbuffer = asset_man.load_shader_pair("assets/shaders/render_light_using_gbuffer.vert", "assets/shaders/render_light_using_gbuffer.frag");
    rdr.render_plain_texture = asset_man.load_shader_pair("assets/shaders/render_light_using_gbuffer.vert", "assets/shaders/render_plain_texture.frag");
    

    // Font fnt;
    // my_stbtt_initfont(&fnt);
    // rdr.create_font(&fnt, 512, 512, &temp_bitmap[0]);
    // font = &fnt;

    // __model = asset_man.load_model("assets/keyOGA.obj");
    __model = asset_man.load_model("assets/well.coveredopen.obj");

    while (true) {
        bool exit = false;

        for (u32 i = 0; i < input_events.count; ++i) {
            Input_Event &ev = input_events[i];
            if (ev.type == Event_Type::QUIT) {
                exit = true;
            } else if (ev.type == Event_Type::MOUSE_BUTTON) {
               
            } else if (ev.type == Event_Type::KEYBOARD) {
                
            }
        }

        if (joysticks.count) {
            auto &joy = joysticks[0];
            x += joy.left_thumb.x;
            y -= joy.left_thumb.y;

            if (joy.buttons & JOYSTICK_BUTTON_BACK) exit = true;
        }

        if (exit) break;

        if (file_changes.count) Sleep(10);
        for (u32 i = 0; i < file_changes.count; ++i) {
            auto &it = file_changes[i];
            file_update_callback(&it, &game);
        }

        render();

        os_swap_buffers(win);
        os_pump_input();

        // @Note we have to wait long enough for whatever program is
        // changing our file to release its handle in order for us
        // to reload it
        os_pump_file_notifications(file_update_callback, &game);
    }

    os_close_window(win);
    return 0;
}
