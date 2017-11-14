/*
Test_Struct :: struct {
    x: Vector3;
    y: Vector3;
}
test :: (t: *Test_Struct, new_x: Vector3, new_y: Vector3) {
    t.x = new_x;
    t.y = new_y;
}

test2 :: (t: *Test_Struct, args: .. Vector3) {
    assert(args.count == 2);
    t.x = args[0];
    t.y = args[1];
}

#run {
    ts: Test_Struct;
    ts.x = make_Vector3(1, 0, 0);
    ts.y = make_Vector3(0, 0, 1);
    print("ts: %\n", ts);
    test2(*ts, ts.y, ts.x);
    print("ts: %\n", ts);
    return;
};
*/
#import "Compiler";

#load "renderer.jai";
#load "lexer.jai";
#load "asset_manager.jai";
#load "editor.jai";
#load "FBX.jai";
#load "physics.jai";
miniz :: #foreign_library "miniz";
uncompress :: (dst: *u8, dst_size: *u64, src: *u8, src_size: u64) -> int #foreign miniz "mz_uncompress";

Game :: struct {
    renderer: *GL_Renderer;
    asset_man: *Asset_Manager;
    window: *Game_Window;

    fov: float = 60;
    water_distort_offset: float;
}

Game_Window :: struct {
    width: u32;
    height: u32;

    handle: OS_Window;
    glc: OS_GL_Context;
}

create_checker_board_mesh :: (plane_normal: Vector3, width: s16, height: s16) -> Mesh {
    UP := make_Vector3(0, 1, 0);
    pn := normalize(plane_normal);
    axis := cross(UP, pn);
    angle := dot(UP, pn);

    rotation := set_angle_vector(angle, axis.x, axis.y, axis.z);

    hw := width/2;
    hh := height/2;
    x_start := -hw;
    y_start := -hh;

    m: Mesh;

    off_white := make_Color(0.1, 0.3, 0.1);
    white := make_Color(1, 1, 1);

    for y: y_start..hh-1 {
        is_white := false;
        if y % 2 != 0 is_white = true;

        for x: x_start..hw-1 {
            v0 := rotation * make_Vector3(xx x, 0, xx y);
            v1 := rotation * make_Vector3(xx x+1, 0, xx y);
            v2 := rotation * make_Vector3(xx x+1, 0, xx y+1);
            v3 := rotation * make_Vector3(xx x, 0, xx y+1);

            add_quad(*m.vertices, v0, v1, v2, v3);
            add_quad(*m.normals, pn, pn, pn, pn);

            if is_white {
                add_quad(*m.colors, white, white, white, white);
            } else {
                add_quad(*m.colors, off_white, off_white, off_white, off_white);
            }
            is_white = !is_white;
        }
    }

    mat := New(Material);
    mat.diffuse = make_Color(1, 1, 1);
    m.material = mat;
    store_mesh_in_buffer(*m);
    return m;
}

sphere_a: Sphere;
// sphere_b: Sphere;
make_sphere_mesh :: (sp: Sphere) -> *Model {
    out := create_sphere(sp.radius, 8, 8);
    out.meshes[0].material = New(Material);
    out.meshes[0].material.diffuse = make_Color(1, 1, 1);
    out.meshes[0].model_matrix = matrix_translate(sp.center);
    out.meshes[0].normals.count = 0;
    store_mesh_in_buffer(out.meshes[0]);
    return out;
}

add_line :: (m: *Mesh, a: Vector3, b: Vector3, color: Color) {
    array_add(*m.vertices, a);
    array_add(*m.vertices, b);

    array_add(*m.colors, color);
    array_add(*m.colors, color);
}

make_aabb_mesh :: (a: AABB) -> *Model {
    out := New(Model);

    m := New(Mesh);
    m.material = New(Material);
    m.material.diffuse = make_Color(1, 1, 1);

    m.primitive_type = Primitive_Type.LINES;

    p0 := a.center - a.halfs;
    p1 := a.center + a.halfs;
    p2 := make_Vector3(p1.x, p0.y, p0.z);
    p3 := make_Vector3(p1.x, p1.y, p0.z);
    p4 := make_Vector3(p0.x, p1.y, p0.z);

    p5 := make_Vector3(p0.x, p0.y, p1.z);
    p6 := make_Vector3(p1.x, p0.y, p1.z);
    p7 := make_Vector3(p0.x, p1.y, p1.z);

    white := make_Color(1, 1, 1);
    red := make_Color(1, 0, 0);
    green := make_Color(0, 1, 0);
    blue := make_Color(0, 0, 1);

    add_line(m, p0, p2, white);
    add_line(m, p0, p4, white);
    add_line(m, p2, p3, white);
    add_line(m, p3, p4, white);

    add_line(m, p1, p7, white);
    add_line(m, p1, p6, white);
    add_line(m, p6, p5, white);
    add_line(m, p5, p7, white);

    add_line(m, p0, p5, white);
    add_line(m, p2, p6, white);
    add_line(m, p3, p1, white);
    add_line(m, p4, p7, white);

    add_line(m, a.center, a.center + make_Vector3(1, 0, 0) * a.halfs.x, red);
    add_line(m, a.center, a.center + make_Vector3(0, 1, 0) * a.halfs.y, green);
    add_line(m, a.center, a.center + make_Vector3(0, 0, 1) * a.halfs.z, blue);

    array_add(*out.meshes, m);
    store_mesh_in_buffer(m);
    return out;
}

create_test_scene :: (game: *Game) -> Scene {
    sc: Scene;
    test_model: Model;
    test_mesh: *Mesh = New(Mesh);
    <<test_mesh = create_checker_board_mesh(make_Vector3(0, 1, 0), 16, 16);
    array_add(*test_model.meshes, test_mesh);
    // array_add(*sc.models, test_model);


    aabb := make_AABB(make_Vector3(0, -5, -10), make_Vector3(10, 10, 10));
    // aabb2 := make_AABB(make_Vector3(-1, 0, -10), make_Vector3(1, 1, 1));

	// test_vector := normalize(aabb.center);

    sphere_a.radius = 1;
    sphere_a.center = make_Vector3(-1, 0.6, -10);
    // sphere_b.radius = 0.6;
    // sphere_b.center = make_Vector3(0, 0, -10);

    intersects, simplex := do_gjk(sphere_a, aabb);
    print("test:\n");
    if intersects {
        separate := do_epa(simplex, sphere_a, aabb);

        print("separate: %\n", separate);

        // @Incomplete since obja is a sphere we can just use separate.point as our separation vector but really we want to gradiate
        // between the normals of the three corners of our EPA triangle see http://www.dtecta.com/files/GDC2012_vandenBergen_Gino_Physics_Tut.pdf
        // separate.normal = normalize(separate.point);
        // print("separate: %\n", separate);
        sphere_a.center -= separate.normal * separate.dist;
        // sphere_a.center += separate.normal * (separate.dist * 0.5);
        // sphere_b.center += separate.normal * (separate.dist * 0.5);
    }

    sphere := make_sphere_mesh(sphere_a);
    array_add(*sc.models, <<sphere);

    // sphere2 := make_sphere_mesh(sphere_b);
    // array_add(*sc.models, <<sphere2);

    aabb_mesh := make_aabb_mesh(aabb);
    array_add(*sc.models, <<aabb_mesh);

    // aabb2_mesh := make_aabb_mesh(aabb2);
    // array_add(*sc.models, <<aabb2_mesh);


    set_point_size(<<game.renderer, 5);

    return sc;
}

main_scene: Scene;

main :: () {
    os_init_platform();

    orig_wd: string;
    if running_at_compile_time() {
        orig_wd.data = alloc(512);
        orig_wd.count = get_current_directory(orig_wd.data, 512);
        opts := get_build_options();
        setcwd(opts.output_path);
    } else {
        path := get_path_of_running_executable();
        final_path := find_and_truncate_character_from_right(path, #char "/");
        defer free(path);
        setcwd(final_path);
    }
    // os_watch_dir("assets");
    // os_watch_dir("assets/shaders");

    WINDOW_WIDTH :: 1280;
    WINDOW_HEIGHT :: 720;
    win := os_create_window(WINDOW_WIDTH, WINDOW_HEIGHT, "game1");
    ctx := os_create_gl_context(win);
    os_make_current(win, ctx);
    os_set_vsync(true);

    rdr: GL_Renderer;
    game: Game;
    window: Game_Window;
    window.width = WINDOW_WIDTH;
    window.height = WINDOW_HEIGHT;
    window.handle = win;
    window.glc = ctx;

    game.window = *window;
    game.renderer = *rdr;
    asset_man := New(Asset_Manager);
    asset_man.game = *game;
    game.asset_man = asset_man;

    rdr.game = *game;
    init(*rdr, game.window.width, game.window.height);
    renderer = *rdr;

    rdr.render_to_gbuffer = load_shader_pair(asset_man, "assets/shaders/render_to_gbuffer.vert", "assets/shaders/render_to_gbuffer.frag");
    rdr.render_light_using_gbuffer = load_shader_pair(asset_man, "assets/shaders/render_light_using_gbuffer.vert", "assets/shaders/render_light_using_gbuffer.frag");
    rdr.render_plain_texture = load_shader_pair(asset_man, "assets/shaders/render_light_using_gbuffer.vert", "assets/shaders/render_plain_texture.frag");
    rdr.picking_shader = load_shader_pair(asset_man, "assets/shaders/picking.vert", "assets/shaders/picking.frag");
    rdr.render_text = load_shader_pair(asset_man, "assets/shaders/render_text.vert", "assets/shaders/render_text.frag");
    rdr.render_rect = load_shader_pair(asset_man, "assets/shaders/render_rect.vert", "assets/shaders/render_rect.frag");
    rdr.render_water = load_shader_pair(asset_man, "assets/shaders/render_water.vert", "assets/shaders/render_water.frag");

    init_editor(*game);

    fnt: Font;
    my_stbtt_initfont(*fnt);
    create_font(*fnt, 512, 512, temp_bitmap.data);
    font = *fnt;

    // key := load_model(asset_man, "assets/keyOGA.obj");
    // __model = load_model(asset_man, "assets/well.coveredopen.obj");
    // __model = load_model(asset_man, "assets/treasure_chest.fbx");
    // __model = key;
    // __model = create_sphere(1.0, 32, 32);
    // __model.meshes[0].material = key.meshes[0].material;
    // key.meshes[0].material.textures[0] = null;

    renderer.camera.position.z = 30;
    renderer.camera.position.y = 5;
    renderer.camera.rotation = set_angle_vector(0, 0, 1, 0);

    main_scene = create_test_scene(*game);


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

            game.renderer.camera.position.x += joy.left_thumb.x;
            game.renderer.camera.position.z -= joy.left_thumb.y;
            if joy.buttons & JOYSTICK_BUTTON_RBUMPER {
                game.renderer.camera.position.y += 1;
            }
            if joy.buttons & JOYSTICK_BUTTON_LBUMPER {
                game.renderer.camera.position.y -= 1;
            }

            if (joy.buttons & JOYSTICK_BUTTON_BACK) exit = true;
        }

        if (exit) break;

        // if (file_changes.count) Sleep(10);
        // for (u32 i = 0; i < file_changes.count; ++i) {
        //     auto &it = file_changes[i];
        //     file_update_callback(&it, &game);
        // }

        update_camera(*game, 1.0/60.0);
        renderer.projection_matrix = matrix_perspective(game.fov, cast(float) game.window.width/cast(float) game.window.height, 1.0, 1000.0);
        // update_editor(*game, 1.0);
        render(*game);

        swap_buffers(win);
        os_pump_input();

        // @Note we have to wait long enough for whatever program is
        // changing our file to release its handle in order for us
        // to reload it
        os_pump_file_notifications(file_update_callback, *game);
    }

    os_close_window(win);

    if running_at_compile_time() {
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

render :: (game: *Game) {
    glViewport(0, 0, xx game.window.width, xx game.window.height);
    draw_scene(game.renderer, main_scene);

    #if DEVELOPER {
        // render_editor(game);  
    }

    // renderer.projection_matrix = matrix_ortho(0, cast(float) WINDOW_WIDTH, cast(float) WINDOW_HEIGHT, 0, -1, 1);
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



ttf_buffer: [1<<20] u8;
temp_bitmap: [512*512] u8;

my_stbtt_initfont :: (font: *Font) {
    f, success := file_open("c:/windows/fonts/times.ttf");
    if !success assert(false);
    file_read(f, ttf_buffer.data, ttf_buffer.count);
    font.char_height = 16.0;
    stbtt_BakeFontBitmap(ttf_buffer.data,0, 16.0, temp_bitmap.data,512,512, 32,96, font.cdata.data); // no guarantee this fits!
    file_close(*f);
}


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