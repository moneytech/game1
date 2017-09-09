
WINDOW_WIDTH :: 1280;
WINDOW_HEIGHT :: 720;

file_update_callback :: (notif: *File_Notification, data: *void) {

}

Game :: struct {

}

main :: () {
    os_init_platform();
    path := os_get_executable_path();
    setcwd(path);
    os_watch_dir("assets");
    // os_watch_dir("assets/shaders");

    win := os_create_window(WINDOW_WIDTH, WINDOW_HEIGHT, "test");
    ctx := os_create_gl_context(win);
    os_make_current(win, ctx);
    os_set_vsync(true);

    // GL_Renderer rdr;
    game: Game;
    // game.renderer = &rdr;
    // Asset_Manager asset_man (&game);
    // game.asset_man = &asset_man;

    // rdr.game = &game;
    // rdr.init(WINDOW_WIDTH, WINDOW_HEIGHT);
    // renderer = &rdr;

    // rdr.render_to_gbuffer = asset_man.load_shader_pair("assets/shaders/render_to_gbuffer.vert", "assets/shaders/render_to_gbuffer.frag");
    // rdr.render_light_using_gbuffer = asset_man.load_shader_pair("assets/shaders/render_light_using_gbuffer.vert", "assets/shaders/render_light_using_gbuffer.frag");
    // rdr.render_plain_texture = asset_man.load_shader_pair("assets/shaders/render_light_using_gbuffer.vert", "assets/shaders/render_plain_texture.frag");
    

    // Font fnt;
    // my_stbtt_initfont(&fnt);
    // rdr.create_font(&fnt, 512, 512, &temp_bitmap[0]);
    // font = &fnt;

    // __model = asset_man.load_model("assets/keyOGA.obj");
    // __model = asset_man.load_model("assets/well.coveredopen.obj");

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

        // render();

        os_swap_buffers(win);
        os_pump_input();

        // @Note we have to wait long enough for whatever program is
        // changing our file to release its handle in order for us
        // to reload it
        os_pump_file_notifications(file_update_callback, *game);
    }

    os_close_window(win);
}
