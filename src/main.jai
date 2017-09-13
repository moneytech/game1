#load "renderer.jai";
#load "lexer.jai";
#load "asset_manager.jai";

WINDOW_WIDTH :: 1280;
WINDOW_HEIGHT :: 720;

Game :: struct {
    renderer: *GL_Renderer;
    asset_man: *Asset_Manager;
}

#import "Compiler";

main :: () {
    os_init_platform();
    #if running_at_compile_time() {
        orig_wd: string;
        orig_wd.data = alloc(512);
        orig_wd.count = get_current_directory(orig_wd.data, 512);
        opts := get_build_options();
        setcwd(opts.output_path);
    } else {
        path := os_get_executable_path();
        setcwd(path);
    }
    os_watch_dir("assets");
    // os_watch_dir("assets/shaders");

    win := os_create_window(WINDOW_WIDTH, WINDOW_HEIGHT, "test");
    ctx := os_create_gl_context(win);
    os_make_current(win, ctx);
    os_set_vsync(true);

    rdr: GL_Renderer;
    game: Game;
    game.renderer = *rdr;
    asset_man: Asset_Manager;
    asset_man.game = *game;
    game.asset_man = *asset_man;

    rdr.game = *game;
    init(*rdr, WINDOW_WIDTH, WINDOW_HEIGHT);
    renderer = *rdr;

    rdr.render_to_gbuffer = load_shader_pair(*asset_man, "assets/shaders/render_to_gbuffer.vert", "assets/shaders/render_to_gbuffer.frag");
    rdr.render_light_using_gbuffer = load_shader_pair(*asset_man, "assets/shaders/render_light_using_gbuffer.vert", "assets/shaders/render_light_using_gbuffer.frag");
    rdr.render_plain_texture = load_shader_pair(*asset_man, "assets/shaders/render_light_using_gbuffer.vert", "assets/shaders/render_plain_texture.frag");
    

    // Font fnt;
    // my_stbtt_initfont(&fnt);
    // rdr.create_font(&fnt, 512, 512, &temp_bitmap[0]);
    // font = &fnt;

    // __model = asset_man.load_model("assets/keyOGA.obj");
    __model = load_model(*asset_man, "assets/well.coveredopen.obj");

    while (true) {
        exit := false;

        for events_this_frame {
            if (it.type == Event_Type.QUIT) {
                exit = true;
            } else if (it.type == Event_Type.KEYBOARD) {
                
            }
        }

        if (joysticks.count) {
            joy := joysticks[0];
            // x += joy.left_thumb.x;
            // y -= joy.left_thumb.y;

            if (joy.buttons & JOYSTICK_BUTTON_BACK) exit = true;
        }

        if (exit) break;

        // if (file_changes.count) Sleep(10);
        // for (u32 i = 0; i < file_changes.count; ++i) {
        //     auto &it = file_changes[i];
        //     file_update_callback(&it, &game);
        // }

        render();

        os_swap_buffers(win);
        os_pump_input();

        // @Note we have to wait long enough for whatever program is
        // changing our file to release its handle in order for us
        // to reload it
        os_pump_file_notifications(file_update_callback, *game);
    }

    os_close_window(win);

    #if running_at_compile_time() {
        setcwd(orig_wd);
    }
}


x, y: float;

tex: *Texture;
renderer: *GL_Renderer;
font: *Font;
__model: *Model;

/*
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
*/

render :: () {
    renderer.projection_matrix = matrix_projection_fov(90.0, cast(float) WINDOW_WIDTH/cast(float) WINDOW_HEIGHT, 0.1, 100.0);
    start_scene(<<renderer);
    clear_screen(0.0, 0.0, 0.0, 1.0);
    // renderer->draw_cube(0, 0, -2, 1);
    draw_model(<<renderer, <<__model);
    finish_scene(<<renderer);


    renderer.projection_matrix = matrix_ortho(0, cast(float) WINDOW_WIDTH, cast(float) WINDOW_HEIGHT, 0, -1, 1);
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


/*
unsigned char ttf_buffer[1<<20];
unsigned char temp_bitmap[512*512];

void my_stbtt_initfont(Font *font)
{
    FILE *f = fopen("c:/windows/fonts/times.ttf", "rb");
    fread(ttf_buffer, 1, 1<<20, f);
    stbtt_BakeFontBitmap(ttf_buffer,0, 32.0, temp_bitmap,512,512, 32,96, font->cdata); // no guarantee this fits!
    fclose(f);
}
*/


file_update_callback :: (notif: *File_Notification, userdata: *void) {
    g := cast(*Game) userdata;
    print("CALLBACK %\n", notif.name);
    if (contains_key(*g.asset_man.textures, notif.name)) {
        print("Updating file: %\n", notif.name);
        load_image(g.asset_man, notif.name);
    } else if (contains_key(*g.asset_man.shader_catalog, notif.name)) {
        print("Reloading shader: %\n", notif.name);
        // reload_shader(*g.asset_man, notif.name);
    } else {
        print("No key for %\n", notif.name);
    }
}

/*

#include <string.h>
#include <stdio.h>
void report_error(int err, const char *err_str, int line, int char_num) {
    printf("Error:%d:%d: %s\n", line, char_num, err_str);
}

void Game::report_error(char *format, ...) {
    assert(false);
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
*/


Hash_Map :: struct (Value_Type: Type) {
    Hash_Entry :: struct {
        key: string;
        next: *Hash_Entry;
        value: Value_Type;
    }

    table: [4096] Hash_Entry;
}

hash_key :: (str: string) -> u32 {
    hash: u32 = 5381;
    c: s16;

    for 0..str.count-1 {
        // double cast to ensure sign extension
        c =  xx cast(s8) str[it];
        hash = ((hash << 5) + hash) + xx c;
    }

    return hash;
}

contains_key :: (using map: *Hash_Map($T), str: string) -> bool {
    slot := hash_key(str) & (4096-1);
    e := *table[slot];

    while e != null {
        if (!e.key.count) break;

        if (str == e.key) break;

        e = e.next;
    }

    return e.key.count != 0;
}

get_slot :: (using map: *Hash_Map($T), str: string) -> T {
    slot := hash_key(str) & (4096-1);
    e := *table[slot];

    while e != null {
        if (!e.key.count) {
            e.key = copy_string(str);
            break;
        }

        if (str == e.key) break;

        if (!e.next) {
            e.next = New(#type Hash_Map(T).Hash_Entry);
            e = e.next;
            e.key = copy_string(str);
            e.next = null;
            break;
        }

        e = e.next;
        assert(e != null);
    }

    return e.value;
}

set_slot :: (using map: *Hash_Map($T), str: string, val: T) {
    slot := hash_key(str) & (4096-1);
    e := *table[slot];

    while e != null {
        if (!e.key.count) {
            e.key = copy_string(str);
            break;
        }

        if (str == e.key) break;

        if (!e.next) {
            e.next = New(#type Hash_Map(T).Hash_Entry);
            e = e.next;
            e.key = copy_string(str);
            e.next = null;
            break;
        }

        e = e.next;
        assert(e != null);
    }

    e.value = val;
}