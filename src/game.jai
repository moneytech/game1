

Game :: struct {
    renderer: *GL_Renderer;
    asset_man: *Asset_Manager;
    window: *Game_Window;
    joy: *Joystick;
    current_scene: *Scene;
    text_strings: [..] string;

    fov: float = 60;

    water_reflect_frame_buffer: Frame_Buffer;
    water_refract_frame_buffer: Frame_Buffer;
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
    os_set_vsync(true);

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
    init(game.renderer, game.window.width, game.window.height);

    game.water_reflect_frame_buffer = create_frame_buffer(game.renderer, xx game.window.width, xx game.window.height);
    game.water_refract_frame_buffer = create_frame_buffer(game.renderer, xx game.window.width, xx game.window.height);

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

    

    game.renderer.camera.position.z = 30;
    game.renderer.camera.position.y = 5;
    game.renderer.camera.rotation = set_angle_vector(0, 0, 1, 0);

    return game;
}