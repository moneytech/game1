
WATER_HEIGHT :: 0.05;

Game :: struct {
    renderer: *GL_Renderer;
    asset_man: *Asset_Manager;
    window: *Game_Window;
    joy: *Joystick;
    current_scene: *Scene;
    text_strings: [..] string;

    fov: float = 60;

    water_dudv_texture: *Texture;
}

Scene :: struct {
    models: [..] *Model;
    actors: [..] *Actor;
    cameras: [..] Camera;
    lights: [..] Light;

    active_camera: Camera;
}

draw_scene :: (rdr: *GL_Renderer, sc: Scene) {
    for sc.actors {
        if it.body && it.model {
            orient := matrix_rotate(it.orientiation);
            it.model.model_matrix = matrix_translate(it.body.position) * orient;
        }
    }
    for sc.models draw_model(rdr, <<it);
}

update_scene :: (game: *Game, sc: *Scene, dt: float) {
    for sc.actors {
        if it.update_callback it.update_callback(game, it, dt);
    }
}

Actor :: struct {
    model: *Model;
    body: *Rigid_Body;
    orientiation: Quaternion; // orientiation around Y axis

    update_callback: (game: *Game, actor: *Actor, dt: float);
    picked_by_player: (game: *Game, actor: *Actor, player: *Actor, dt: float);
}

Game_Window :: struct {
    width: u32;
    height: u32;

    handle: OS_Window;
    glc: OS_GL_Context;
}

update_camera :: (game: *Game, dt: float) {
    using Key_Current_State;

    if input_button_states[Key_Code.MOUSE_BUTTON_RIGHT] & DOWN {
        delta := make_Vector3(xx mouse_delta_x, xx mouse_delta_y, 0);
        delta = mul(delta, make_Vector3(1.0/cast(float)game.window.width, 1.0/cast(float)game.window.height, 0)); // nomalize pixels to viewport
        sx, sy := viewport_scale(game.fov, cast(float)game.window.width / cast(float)game.window.height, 1.0);
        delta = mul(delta, make_Vector3(sx, sy, 1));

        rotation_current := game.renderer.camera.rotation;
        quat := set_angle_vector(delta.x * 1.5, 0, 1, 0) * rotation_current * set_angle_vector(delta.y * 1.5, 1, 0, 0);
        game.renderer.camera.rotation = quat;
    } else if input_button_states[Key_Code.MOUSE_BUTTON_MIDDLE] & DOWN {
        delta := make_Vector3(xx -mouse_delta_x, xx mouse_delta_y, 0);
        delta = mul(delta, make_Vector3(1.0/cast(float)game.window.width, 1.0/cast(float)game.window.height, 0)); // nomalize pixels to viewport
        sx, sy := viewport_scale(game.fov, cast(float)game.window.width / cast(float)game.window.height, 1.0);
        delta = mul(delta, make_Vector3(sx, sy, 1));
        q := game.renderer.camera.rotation;

        move := delta * 5;

        game.renderer.camera.position += q * (move * 20);
    }

    if mouse_delta_z != 0 {
        q := game.renderer.camera.rotation;
        game.renderer.camera.position += q * make_Vector3(0.0, 0.0, -mouse_delta_z * 0.01);
    }

}

init_game :: (window_title: string, vr: bool = false) -> *Game {
    os_init_platform();

    orig_wd: string;
    if running_at_compile_time() {
        orig_wd = get_current_directory(); // @Leak ?
        opts := get_build_options();
        setcwd(opts.output_path);
    } else {
        path := get_path_of_running_executable();
        final_path := strip_path_filename(path);
        setcwd(final_path);
    }
    os_watch_dir("assets");
    os_watch_dir("assets/shaders");

    WINDOW_WIDTH :: 1280;
    WINDOW_HEIGHT :: 720;
    win := os_create_window(WINDOW_WIDTH, WINDOW_HEIGHT, window_title);
    ctx := os_create_gl_context(win);
    os_make_current(win, ctx);
    os_set_vsync(!vr);

    game := New(Game);
    window := New(Game_Window);

    _width, _height := os_get_window_dimensions(win);
    window.width = xx _width;
    window.height = xx _height;
    window.handle = win;
    window.glc = ctx;

    game.window = window;
    game.renderer = New(GL_Renderer);
    asset_man := New(Asset_Manager);
    asset_man.game = game;
    game.asset_man = asset_man;

    // @TODO update framebuffer sizes when window gets resized
    // init(game.renderer, game.window.width, game.window.height);
    init(game.renderer, 1080, 1200);

    game.water_dudv_texture = load_image(game.asset_man, "assets/water_dudv.png");

    game.renderer.render_to_gbuffer = load_shader_pair(asset_man, "assets/shaders/render_to_gbuffer.vert", "assets/shaders/render_to_gbuffer.frag");
    game.renderer.render_light_using_gbuffer = load_shader_pair(asset_man, "assets/shaders/render_light_using_gbuffer.vert", "assets/shaders/render_light_using_gbuffer.frag");
    game.renderer.render_plain_texture = load_shader_pair(asset_man, "assets/shaders/render_light_using_gbuffer.vert", "assets/shaders/render_plain_texture.frag");
    game.renderer.picking_shader = load_shader_pair(asset_man, "assets/shaders/picking.vert", "assets/shaders/picking.frag");
    game.renderer.render_text = load_shader_pair(asset_man, "assets/shaders/render_text.vert", "assets/shaders/render_text.frag");
    game.renderer.render_rect = load_shader_pair(asset_man, "assets/shaders/render_rect.vert", "assets/shaders/render_rect.frag");
    game.renderer.render_water = load_shader_pair(asset_man, "assets/shaders/render_water.vert", "assets/shaders/render_water.frag");

    // @Temporary
    game.text_strings = load_text_strings(asset_man);

    fnt := New(Font);
    my_stbtt_initfont(fnt);
    create_font(fnt, 512, 512, temp_bitmap.data);
    font = fnt;

    

    game.renderer.camera.position.z = 0;
    game.renderer.camera.position.y = 1.8;
    game.renderer.camera.rotation = set_angle_vector(0, 0, 1, 0);

    return game;
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

font: *Font;

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

draw_geometry :: (using game: *Game, water := false) {
    start_scene(game.renderer);
    draw_scene(game.renderer, <<game.current_scene);

    #if DEVELOPER {
        draw_debug_bodies(game);
    }

    if water {
        draw_water(<<renderer, water_dudv_texture, WATER_HEIGHT);
    }
    finish_scene(game.renderer);
    set_clip_plane(renderer, false);
}

update_game :: (game: *Game) {
    if (joysticks.count) {
        game.joy = *joysticks[0];
    } else {
        game.joy = null;
    }
}

render_game :: (using game: *Game, target_frame_buffer: *Frame_Buffer = null) {
    // game.renderer.projection_matrix = matrix_perspective(game.fov, cast(float) game.window.width/cast(float) game.window.height, 1.0, 100000.0);
    // gl.glViewport(0, 0, xx game.window.width, xx game.window.height);
    use_frame_buffer(game.renderer, target_frame_buffer);

    old_camera := game.renderer.camera;
    new_camera := old_camera;
    new_camera.position.y -= 2 * (new_camera.position.y - WATER_HEIGHT);
    phi := get_euler_angles(new_camera.rotation);
    new_camera.rotation = new_camera.rotation * set_angle_vector(xx (-phi * 2), 1, 0, 0);
    game.renderer.camera = new_camera;

    use_frame_buffer(renderer, *renderer.water_reflect_frame_buffer);
    set_clip_plane(renderer, true, make_Vector4(0, 1, 0, -WATER_HEIGHT));
    draw_geometry(game);
    use_frame_buffer(renderer, target_frame_buffer);


    game.renderer.camera = old_camera;
    use_frame_buffer(renderer, *renderer.water_refract_frame_buffer);
    set_clip_plane(renderer, true, make_Vector4(0, -1, 0, WATER_HEIGHT));
    draw_geometry(game);
    use_frame_buffer(renderer, target_frame_buffer);

    set_clip_plane(renderer, false);
    draw_geometry(game, true);

    game.renderer.projection_matrix = matrix_ortho(0, xx game.window.width, xx game.window.height, 0, -1, 1);
}


Hash_Map :: struct (Value_Type: Type, table_size := 1024) {
    Hash_Entry :: struct {
        key: string;
        next: *Hash_Entry;
        value: Value_Type;
    }

    table: [table_size] Hash_Entry;
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

contains_key :: (using map: *Hash_Map, str: string) -> bool {
    slot := hash_key(str) & (table_size-1);
    e := *table[slot];

    while e != null {
        if (!e.key.count) break;

        if (str == e.key) break;

        e = e.next;
    }

    if !e return false;
    return e.key.count != 0;
}

get_slot :: (using map: *Hash_Map, str: string) -> map.Value_Type {
    slot := hash_key(str) & (table_size-1);
    e := *table[slot];

    while e != null {
        if (!e.key.count) {
            e.key = copy_string(str);
            break;
        }

        if (str == e.key) break;

        if (!e.next) {
            e.next = New(map.Hash_Entry);
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

set_slot :: (using map: *Hash_Map, str: string, val: map.Value_Type) {
    slot := hash_key(str) & (table_size-1);
    e := *table[slot];

    while e != null {
        if (!e.key.count) {
            e.key = copy_string(str);
            break;
        }

        if (str == e.key) break;

        if (!e.next) {
            e.next = New(map.Hash_Entry);
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