
SUPPORTS_OCULUS :: OS_WINDOWS;

#if SUPPORTS_OCULUS {
    #load "OVR.jai";
}
#load "editor.jai";

WATER_HEIGHT :: 0.05;

Game :: struct {
    renderer: *GL_Renderer;
    asset_man: *Asset_Manager;
    window: *Game_Window;
    joy: *Joystick;
    current_scene: *Scene;
    text_strings: [..] string;

    nuklear: nk_context;

    fov: float = 60;

    water_dudv_texture: *Texture;

    enable_vr := false;

    font: *Font;

    #if SUPPORTS_OCULUS {
        vr: struct {
            session: ovrSession;
            luid: ovrGraphicsLuid;
            hmd_desc: ovrHmdDesc;

            eyeRenderDesc: [2] ovrEyeRenderDesc;
            hmdToEyeViewPose: [2] ovrPosef;
            layer: ovrLayerEyeFovDepth;
            color_texture: *Texture;
            depth_texture: *Texture;
            vr_frame_buffer: Frame_Buffer;
            temp_fb: Frame_Buffer;

            buffer_size: ovrSizei;
            color_swap_chain: ovrTextureSwapChain;
            depth_swap_chain: ovrTextureSwapChain;

            mirror_texture_id: u32;
            mirror_texture: ovrMirrorTexture;
        };
    }

    frame_index := 0;
}

Scene :: struct {
    models: [..] *Model;
    actors: [..] *Actor;
    cameras: [..] *Camera;
    lights: [..] *Light;
    all_objects: [..] *Scene_Object;

    next_available_id: s32 = 1;

    active_camera: *Camera;
}

add_to_scene :: (sc: *Scene, thing: *$T) #body_text {
    builder: String_Builder;
ACTOR_STRING :: #string DONE
    assert(thing.object_id == -1);
    thing.object_id = sc.next_available_id;
    sc.next_available_id += 1;
    #if DEBUG {
         if find_object_by_id(sc, thing.object_id) != null {
            logprint("Scene", "Error: object id % is already registered in scene!\n", thing.object_id);
         }
    }
DONE
    append(*builder, ACTOR_STRING);

    // @Warning idk if this is safe in the long run
    array_name := sprint("%", <<cast(*Type) *T);
    print_to_builder(*builder, "thing.object_type = %;\n", array_name);

    to_lower(array_name);
    defer free(array_name);
    print_to_builder(*builder, "array_add(*sc.%s, thing);\n", array_name);
    append(*builder, "array_add(*sc.all_objects, thing);\n");
    return builder_to_string(*builder);
}

find_object_by_id :: (sc: *Scene, id: s32) -> *Scene_Object {
    for sc.all_objects {
        if it.object_id == id then return it;
    }

    return null;
}

draw_scene :: (rdr: *GL_Renderer, sc: Scene) {
    for sc.actors {
        if it.model {
            orient := matrix_rotate(it.orientation);
            it.model.model_matrix = matrix_translate(it.position) * orient;
        }

        if it.model draw_model(rdr, <<it.model);
    }
    for sc.models draw_model(rdr, <<it);
}

update_scene :: (game: *Game, sc: *Scene, dt: float) {
    for sc.actors {
        if it.body {
            it.position = it.body.position;
            // @TODO Rigid_Body.orientation should probably be a Quaternion
            // it.orientation = it.body.orientation;
        }

        if it.update_callback it.update_callback(game, it, dt);
    }
}

Scene_Object :: struct {
    object_id: s32 = -1;
    object_type: Type;

    position: Vector3;
}

Actor :: struct {
    using object: Scene_Object;

    model: *Model;
    body: *Rigid_Body;

    // position: Vector3;
    orientation: Quaternion; // orientiation around Y axis

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

game_logger :: (message: string, ident: string, mode: Log_Mode, data: *void) -> void {
    print("[%] %", ident, message);
}

init_game :: (window_title: string, options: ..string) -> *Game {
    os_init_platform();
    context.logger = game_logger;

    orig_wd: string;
    if running_at_compile_time() {
        #import "Compiler";
        orig_wd = get_working_directory(); // @Leak ?
        opts := get_build_options();
        set_working_directory(opts.output_path);
    } else {
        path := get_path_of_running_executable();
        final_path := path_strip_filename(path);
        set_working_directory(final_path);
    }
    os_watch_dir("assets");
    os_watch_dir("assets/shaders");

    WINDOW_WIDTH :: 1280;
    WINDOW_HEIGHT :: 720;
    win := os_create_window(WINDOW_WIDTH, WINDOW_HEIGHT, window_title);
    ctx := os_create_gl_context(win);
    os_make_current(win, ctx);

    game := New(Game);
    window := New(Game_Window);

    _width, _height := os_get_window_dimensions(win);
    window.width = xx _width;
    window.height = xx _height;
    window.handle = win;
    window.glc = ctx;

    game.window = window;
    game.renderer = New(GL_Renderer);
    game.renderer.game = game;
    asset_man := New(Asset_Manager);
    asset_man.game = game;
    game.asset_man = asset_man;

    // @TODO update framebuffer sizes when window gets resized
    // init(game.renderer, game.window.width, game.window.height);
    init(game.renderer, game.window.width, game.window.height);

    game.water_dudv_texture = load_image(game.asset_man, "assets/water_dudv.png");

    game.renderer.render_to_gbuffer = load_shader_pair(asset_man, "assets/shaders/render_to_gbuffer.vert", "assets/shaders/render_to_gbuffer.frag");
    game.renderer.render_light_using_gbuffer = load_shader_pair(asset_man, "assets/shaders/render_light_using_gbuffer.vert", "assets/shaders/render_light_using_gbuffer.frag");
    game.renderer.render_plain_texture = load_shader_pair(asset_man, "assets/shaders/render_plain_texture.vert", "assets/shaders/render_plain_texture.frag");
    game.renderer.picking_shader = load_shader_pair(asset_man, "assets/shaders/picking.vert", "assets/shaders/picking.frag");
    game.renderer.render_text = load_shader_pair(asset_man, "assets/shaders/render_text.vert", "assets/shaders/render_text.frag");
    game.renderer.render_rect = load_shader_pair(asset_man, "assets/shaders/render_rect.vert", "assets/shaders/render_rect.frag");
    game.renderer.render_water = load_shader_pair(asset_man, "assets/shaders/render_water.vert", "assets/shaders/render_water.frag");
    game.renderer.render_gamma_correction = load_shader_pair(asset_man, "assets/shaders/render_plain_texture.vert", "assets/shaders/gamma_correction.frag");
    game.renderer.null_shader = load_shader_pair(asset_man, "assets/shaders/null_shader.vert", "assets/shaders/null_shader.frag");
    game.renderer.light_entity_texture = load_image(asset_man, "assets/lightbulb.png");

    // @Temporary
    game.text_strings = load_text_strings(asset_man);

    fnt := New(Font);
    my_stbtt_initfont(fnt);
    create_font(fnt, 512, 512, temp_bitmap.data);
    game.font = fnt;

    

    game.renderer.camera.position.z = 0;
    game.renderer.camera.position.y = 1.8;
    game.renderer.camera.rotation = set_angle_vector(0, 0, 1, 0);
    
    for options {
        if it == "-vr" {
            initialize_vr(game);
        }
    }

    // os_set_vsync(game.vr.session == null);
    os_set_vsync(false);


    nuklear_text_width_calc :: (handle: nk_handle, height: float, text: *u8, len: s32) -> float #c_callback {
        ft := cast(*Font) handle.ptr;
        str := to_string(text, len);

        ctx: Context;
        push_context ctx {
            return font_get_length(<<ft, str);
        }
    }

    nuklear_font := New(nk_user_font);
    nuklear_font.userdata.ptr = game.font;
    // nuklear_font.userdata.id = 0;
    nuklear_font.height = game.font.char_height;
    nuklear_font.width = nuklear_text_width_calc;

    MAX_MEMORY :: 0x1000000;
    nk_init_fixed(*game.nuklear, alloc(MAX_MEMORY), MAX_MEMORY, nuklear_font);
    return game;
}

ttf_buffer: [1<<20] u8;
temp_bitmap: [512*512] u8;

my_stbtt_initfont :: (font: *Font) {
    f, success := file_open("assets/fonts/Skytree/Skytree.ttf");
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

update_game :: (game: *Game, dt: float) {

    was_resized, record := is_a_window_resized();
    while was_resized {
        if record.window == game.window.handle {
            game.window.width = cast(u32) record.width;
            game.window.height = cast(u32) record.height;
        }

        was_resized, record = is_a_window_resized();
    }

    if (joysticks.count) {
        game.joy = *joysticks[0];
    } else {
        game.joy = null;
    }

    using game;
    DISTORT_OFFSET_STEP :: 0.01;
    renderer.water_distort_offset += DISTORT_OFFSET_STEP * dt;
    if renderer.water_distort_offset > 1.0 then renderer.water_distort_offset = 0.0;
}

render_scene :: (using game: *Game, target_frame_buffer: *Frame_Buffer) {
    game.renderer.lights = game.current_scene.lights;

    // game.renderer.projection_matrix = matrix_perspective(game.fov, cast(float) game.window.width/cast(float) game.window.height, 1.0, 100000.0);
    // gl.glViewport(0, 0, xx game.window.width, xx game.window.height);
    use_frame_buffer(game.renderer, target_frame_buffer);

    
    // @FixMe the water reflection rotates dramatically when the camera is rolled (tilted) about the Z axis, breaking VR immersion
    // maybe it's just that the roll should be inverted ?
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
}

#if SUPPORTS_OCULUS {
    render_game_ovr :: (using game: *Game, target_frame_buffer: *Frame_Buffer) {
        using game.vr;

        _proj := renderer.projection_matrix;
        defer renderer.projection_matrix = _proj;

        resize_rendering_buffers(game.renderer, xx (vr.buffer_size.w / 2), xx vr.buffer_size.h);
        eyeRenderDesc[0] = ovr_GetRenderDesc(vr.session, ovrEye_Left, hmd_desc.DefaultEyeFov[0]);
        eyeRenderDesc[1] = ovr_GetRenderDesc(vr.session, ovrEye_Right, hmd_desc.DefaultEyeFov[1]);
        hmdToEyeViewPose[0] = eyeRenderDesc[0].HmdToEyePose;
        hmdToEyeViewPose[1] = eyeRenderDesc[1].HmdToEyePose;

        displayMidpointSeconds := ovr_GetPredictedDisplayTime(vr.session, game.frame_index);
        hmdState := ovr_GetTrackingState(vr.session, displayMidpointSeconds, ovrTrue);
        ovr_CalcEyePoses(hmdState.HeadPose.ThePose, hmdToEyeViewPose.data, layer.RenderPose.data);

        color_tex_id: u32;
        depth_tex_id: u32;
        {
            currentIndex: s32;
            ovr_GetTextureSwapChainCurrentIndex(vr.session, vr.color_swap_chain, *currentIndex);
            ovr_GetTextureSwapChainBufferGL(vr.session, vr.color_swap_chain, currentIndex, *color_tex_id);
        }
        {
            currentIndex: s32;
            ovr_GetTextureSwapChainCurrentIndex(vr.session, vr.depth_swap_chain, *currentIndex);
            ovr_GetTextureSwapChainBufferGL(vr.session, vr.depth_swap_chain, currentIndex, *depth_tex_id);
        }
        color_texture.id = color_tex_id;
        depth_texture.id = depth_tex_id;

        set_frame_buffer_textures(*vr_frame_buffer, color_texture, depth_texture);

        result := ovr_WaitToBeginFrame(vr.session, game.frame_index);

        ovr_BeginFrame(vr.session, game.frame_index);

        for eye: 0..1 {
            vp := layer.Viewport[eye];
            set_viewport(*temp_fb, make_Viewport(vp.Pos.x, vp.Pos.y, xx vp.Size.w, xx vp.Size.h));

            ts := ovr_GetTrackingState(vr.session, ovr_GetTimeInSeconds(), ovrTrue);
            pos_offset := to_vector3(layer.RenderPose[eye].Position);

            q := to_quaternion(layer.RenderPose[eye].Orientation);

            camera_orig := game.renderer.camera;
            defer game.renderer.camera = camera_orig;

            game.renderer.camera.position += pos_offset;
            game.renderer.camera.rotation = q;
            fov := layer.Fov[eye];

            m0 := ovrMatrix4f_Projection(fov, 0.001, 100000.0, 0);
            m1: Matrix4;

            for x: 0..3 {
                for y: 0..3 {
                    m1.m[x][y] = m0.M[x][y];
                }
            }
            game.renderer.projection_matrix = m1;
            render_scene(game, *temp_fb);
        }

        glDisable(GL_CULL_FACE);
        defer glEnable(GL_CULL_FACE);
        
        game.renderer.projection_matrix = matrix_ortho(0, 1, 1, 0, -1, 1);
        // set_viewport(0, 0, xx vr.buffer_size.w, xx vr.buffer_size.h);
        use_frame_buffer(game.renderer, *vr_frame_buffer);

        // apply gamma correction
        draw_textured_rect(<<game.renderer, temp_fb.color_texture, 0, 0, 1, 1, renderer.render_gamma_correction);

        ovr_CommitTextureSwapChain(vr.session, vr.color_swap_chain);
        ovr_CommitTextureSwapChain(vr.session, vr.depth_swap_chain);

        layers := *layer.Header;
        result = ovr_EndFrame(vr.session, game.frame_index, null, *layers, 1);
        // is_visible = (result == xx ovrSuccess);

        ovr_GetMirrorTextureBufferGL(vr.session, vr.mirror_texture, *vr.mirror_texture_id);
    }

    initialize_vr :: (using game: *Game) {
        if game_vr_mode_active(game) return;

        params: ovrInitParams;
        params.Flags = xx (ovrInit_RequestVersion);
        params.RequestedMinorVersion = OVR_MINOR_VERSION;
        res := ovr_Initialize(*params);
        if OVR_FAILURE(res) {
            logprint("VR", "ovr_Initialize failed with %\n", res);
            return;
        }

        res = ovr_Create(*vr.session, *vr.luid);

        if OVR_FAILURE(res) {
            ovr_Shutdown();
            logprint("VR", "ovr_Create failed with %\n", res);
            return;
        }

        using game.vr;
        hmd_desc = ovr_GetHmdDesc(vr.session);
        tex0size := ovr_GetFovTextureSize(vr.session, ovrEye_Left, hmd_desc.DefaultEyeFov[0], 1.0);
        tex1size := ovr_GetFovTextureSize(vr.session, ovrEye_Right, hmd_desc.DefaultEyeFov[1], 1.0);

        vr.buffer_size.w = tex0size.w + tex1size.w;
        vr.buffer_size.h = max(tex0size.h, tex1size.h);

        logprint("VR", "buffer size: %\n", vr.buffer_size);

        {
            desc: ovrTextureSwapChainDesc;
            desc.Type = ovrTexture_2D;
            desc.ArraySize = 1;
            desc.Format = OVR_FORMAT_R8G8B8A8_UNORM_SRGB;
            desc.Width = vr.buffer_size.w;
            desc.Height = vr.buffer_size.h;
            desc.MipLevels = 1;
            desc.SampleCount = 1;
            desc.StaticImage = ovrFalse;


            if ovr_CreateTextureSwapChainGL(vr.session, *desc, *vr.color_swap_chain) == 0 {
            }

            desc.Format = OVR_FORMAT_D32_FLOAT;

            if ovr_CreateTextureSwapChainGL(vr.session, *desc, *vr.depth_swap_chain) == 0 {
            }
        }

        mirror_desc: ovrMirrorTextureDesc;

        mirror_desc.Format = OVR_FORMAT_R8G8B8A8_UNORM_SRGB;
        mirror_desc.Width = xx game.window.width;
        mirror_desc.Height = xx game.window.height;
        mirror_desc.MiscFlags = 0;
        mirror_desc.MirrorOptions = xx ovrMirrorOption_PostDistortion;

        ovr_CreateMirrorTextureWithOptionsGL(vr.session, *mirror_desc, *vr.mirror_texture);
        ovr_GetMirrorTextureBufferGL(vr.session, vr.mirror_texture, *vr.mirror_texture_id);

        eyeRenderDesc[0] = ovr_GetRenderDesc(vr.session, ovrEye_Left, hmd_desc.DefaultEyeFov[0]);
        eyeRenderDesc[1] = ovr_GetRenderDesc(vr.session, ovrEye_Right, hmd_desc.DefaultEyeFov[1]);
        hmdToEyeViewPose[0] = eyeRenderDesc[0].HmdToEyePose;
        hmdToEyeViewPose[1] = eyeRenderDesc[1].HmdToEyePose;

        
        layer.Header.Type = ovrLayerType_EyeFovDepth;
        layer.Header.Flags = 0;
        layer.ColorTexture[0] = vr.color_swap_chain;
        layer.ColorTexture[1] = vr.color_swap_chain;
        layer.DepthTexture[0] = vr.depth_swap_chain;
        layer.DepthTexture[1] = vr.depth_swap_chain;
        layer.Fov[0] = eyeRenderDesc[0].Fov;
        layer.Fov[1] = eyeRenderDesc[1].Fov;
        layer.Viewport[0] = make_Recti(0, 0, vr.buffer_size.w / 2, vr.buffer_size.h);
        layer.Viewport[1] = make_Recti(vr.buffer_size.w / 2, 0, vr.buffer_size.w / 2, vr.buffer_size.h);

        color_texture = New(Texture);
        depth_texture = New(Texture);

        set_texture(color_texture, xx vr.buffer_size.w, xx vr.buffer_size.h, 0, Texture.RGBA);
        set_texture(depth_texture, xx vr.buffer_size.w, xx vr.buffer_size.h, 0, Texture.DEPTH);

        vr_frame_buffer = create_frame_buffer_from_textures(renderer, null, null);
        temp_fb = create_frame_buffer(game.renderer, xx vr.buffer_size.w, xx vr.buffer_size.h);

        enable_vr = true;
    }

    shutdown_vr :: (using game: *Game) {
        ovr_Destroy(vr.session);
        ovr_Shutdown();
    }

    game_vr_mode_active :: inline (using game: *Game) -> bool {
        return vr.session != null;
    }

    to_quaternion :: (ovrq: ovrQuatf) -> Quaternion {
        q: Quaternion = ---;
        q.x = ovrq.x;
        q.y = ovrq.y;
        q.z = ovrq.z;
        q.w = ovrq.w;
        return q;
    }

    to_vector3 :: (ovrv3: ovrVector3f) -> Vector3 {
        v: Vector3 = ---;
        v.x = ovrv3.x;
        v.y = ovrv3.y;
        v.z = ovrv3.z;
        return v;
    }
} else {
    render_game_ovr :: (using game: *Game, target_frame_buffer: *Frame_Buffer) {
        assert(false);
    }

    initialize_vr :: (using game: *Game) { }

    shutdown_vr :: (using game: *Game) { }

    game_vr_mode_active :: inline (using game: *Game) -> bool {
        return false;
    }
}

render_game :: (using game: *Game, target_frame_buffer: *Frame_Buffer = null) {

    if game.enable_vr && game_vr_mode_active(game) {
        render_game_ovr(game, target_frame_buffer);
    } else {
        width := game.window.width;
        height := game.window.height;

        if target_frame_buffer {
            vp := target_frame_buffer.viewport;
            width = vp.w;
            height = vp.h;
        }

        game.renderer.projection_matrix = matrix_perspective(game.fov, cast(float) width/cast(float) height, 1.0, 100000.0);
        resize_rendering_buffers(game.renderer, width, height);
        glViewport(0, 0, width, height);

        use_frame_buffer(game.renderer, *renderer.scratch_frame_buffer);
        render_scene(game, *renderer.scratch_frame_buffer);

        game.renderer.projection_matrix = matrix_ortho(0, 1, 0, 1, -1, 1);

        // apply gamma correction
        use_frame_buffer(game.renderer, target_frame_buffer);
        use_frame_buffer(game.renderer, renderer.current_frame_buffer);
        if renderer.current_frame_buffer enable_scissor(renderer.current_frame_buffer.viewport);
        clear_screen(0, 0, 0, 1);

        game.renderer.view_matrix = matrix_identity();
        draw_textured_rect(<<game.renderer, renderer.scratch_frame_buffer.color_texture, 0, 0, 1, 1, renderer.render_gamma_correction);
    }
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

// @TODO @FixMe remove the dollar signs here once bug261 is fixed.

contains_key :: (using map: *$Hash_Map, str: string) -> bool {
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

get_slot :: (using map: *$Hash_Map, str: string) -> map.Value_Type {
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

set_slot :: (using map: *$Hash_Map, str: string, val: map.Value_Type) {
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
