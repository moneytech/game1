
#import "Compiler";

#load "renderer.jai";
#load "lexer.jai";
#load "asset_manager.jai";
#load "editor.jai";
#load "FBX.jai";

miniz :: #foreign_library "miniz";
uncompress :: (dst: *u8, dst_size: *u64, src: *u8, src_size: u64) -> int #foreign miniz "mz_uncompress";

// solidify Rigid_Body type
// Rigid_Body :: #type Rigid_Body_Poly(Actor);
#load "physics.jai";

Game :: struct {
    renderer: *GL_Renderer;
    asset_man: *Asset_Manager;
    window: *Game_Window;
    joy: *Joystick;
    current_scene: *Scene;
    text_strings: [..] string;

    fov: float = 60;
    water_distort_offset: float;

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

update_player_controller :: (game: *Game, player: *Actor, dt: float) {
    joy := game.joy;
    vel_xz := make_Vector3(player.body.velocity.x, 0, player.body.velocity.z);
    if length(vel_xz) {
        target_dir := normalize(vel_xz);

        axis := make_Vector3(0, 1, 0);
        angle := atan2(target_dir.x, target_dir.z);
        player.orientiation = set_angle_vector(xx angle, axis.x, axis.y, axis.z);
    }

    dir := player.orientiation * make_Vector3(0, 0, 1);

    bods: [] *Rigid_Body = bodies;
    obj := do_raycast(make_Ray(player.body.position, dir), bods);
    if obj && obj.user_data {
        if obj.user_data.picked_by_player
            obj.user_data.picked_by_player(game, obj.user_data, player, dt);
    }
}

Signpost :: struct {
    using actor: Actor;
    text: Text;

    #constructor con_signpost;
}

con_signpost :: (s: *Signpost) {
    s.picked_by_player = signpost_picked_by_player;
}

signpost_picked_by_player :: (game: *Game, actor: *Actor, player: *Actor, dt: float) {
    me := cast(*Signpost) actor;
    issue_text(game, game.text_strings[me.text]);
}

make_signpost :: (text: Text) -> *Signpost {
    ret := New(Signpost);
    ret.text = text;
    return ret;
}

make_crate :: (game: *Game) -> *Actor {
    actor := New(Actor);
    actor.model = load_model(game.asset_man, "assets/crate.fbx");;
    actor.body = New(Rigid_Body);

    collider := make_AABB(make_Vector3(0, 0, 0), make_Vector3(2, 2, 2));
    Rigid_Body_con(actor.body, 2.0, collider, actor);
    return actor;
}

Holdable_Actor :: struct {
    using actor: Actor;
}

make_barrel :: (game: *Game) -> *Holdable_Actor {
    actor := New(Holdable_Actor);
    actor.model = load_model(game.asset_man, "assets/barrel.fbx");;
    actor.body = New(Rigid_Body);

    collider := make_Capsule(make_Vector3(0, 0, 0), 0.5, 0.2);
    Rigid_Body_con(actor.body, 2.0, collider, actor);
    return actor;
}

Text :: enum u16 {
    NO_MESSAGE,

    LAST_MESSAGE
}

issue_text :: (game: *Game, message: string) {
    sc := game.current_scene;


}

Game_Window :: struct {
    width: u32;
    height: u32;

    handle: OS_Window;
    glc: OS_GL_Context;
}

create_checker_board_mesh :: (rotation: Quaternion, width: s16, height: s16) -> *Mesh {
    pn := make_Vector3(0, 1, 0);
    hw := width/2;
    hh := height/2;
    x_start := -hw;
    y_start := -hh;

    m := New(Mesh);

    off_white := make_Color(0.1, 0.3, 0.1);
    // white := make_Color(1, 1, 1);
    white := make_Color(0.5, 0.5, 0.5);

    subh := 1;
    subw := 1;
    ext_h := 0.0;
    ext_w := 0.0;

    if width & 1 == 1 {
        subw = 0;
        ext_w = 0.5;
    }

    if height & 1 == 1 {
        subh = 0;
        ext_h = 0.5;
    }

    for y: y_start..hh-subh {
        is_white := false;
        if y % 2 != 0 is_white = true;

        for x: x_start..hw-subw {
            v0 := rotation * make_Vector3(xx x - ext_w, 0, xx y - ext_h);
            v1 := rotation * make_Vector3(xx x+1 - ext_w, 0, xx y - ext_h);
            v2 := rotation * make_Vector3(xx x+1 - ext_w, 0, xx y+1 - ext_h);
            v3 := rotation * make_Vector3(xx x - ext_w, 0, xx y+1 - ext_h);

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
    store_mesh_in_buffer(m);
    return m;
}

create_checker_board_box :: (width: s16, height: s16, depth: s16) -> *Model {
    up := create_checker_board_mesh(set_angle_vector(0, 1, 0, 0), width, depth);
    up.model_matrix = matrix_translate(0, cast(float) height / 2, 0);
    down := create_checker_board_mesh(set_angle_vector(PI, 1, 0, 0), width, depth);
    down.model_matrix = matrix_translate(0, cast(float) -height / 2, 0);
    left := create_checker_board_mesh(set_angle_vector(PI / 2, 0, 0, 1), height, depth);
    left.model_matrix = matrix_translate(cast(float) -width / 2, 0, 0);
    right := create_checker_board_mesh(set_angle_vector(-PI / 2, 0, 0, 1), height, depth);
    right.model_matrix = matrix_translate(cast(float) width / 2, 0, 0);
    front := create_checker_board_mesh(set_angle_vector(-PI / 2, 1, 0, 0), width, height);
    front.model_matrix = matrix_translate(0, 0, cast(float) -depth / 2);
    back := create_checker_board_mesh(set_angle_vector(PI / 2, 1, 0, 0), width, height);
    back.model_matrix = matrix_translate(0, 0, cast(float) depth / 2);

    mod := New(Model);
    array_add(*mod.meshes, up);
    array_add(*mod.meshes, down);
    array_add(*mod.meshes, left);
    array_add(*mod.meshes, right);
    array_add(*mod.meshes, front);
    array_add(*mod.meshes, back);
    return mod;
}

make_sphere_mesh :: (sp: Sphere) -> *Model {
    out := create_sphere(sp.radius, 8, 8);
    out.meshes[0].material = New(Material);
    out.meshes[0].material.diffuse = make_Color(1, 1, 1);
    out.meshes[0].model_matrix = matrix_translate(sp.center);
    out.meshes[0].normals.count = 0;
    store_mesh_in_buffer(out.meshes[0]);
    return out;
}

make_capsule_mesh :: (cap: Capsule) -> *Model {
    out := create_capsule(cap.radius, 8, 8, 1.0);
    out.meshes[0].material = New(Material);
    out.meshes[0].material.diffuse = make_Color(1, 1, 1);
    out.meshes[0].model_matrix = matrix_translate(cap.center);
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

unit_sphere_model: *Model;
unit_capsule_model: *Model;
aabb_model: *Model;
checker_board: *Model;

bodies: [..] *Rigid_Body;

do_collision_detection :: () {

    /*
    // intersects, simplex := do_gjk(<<b0, <<b1);
    // if intersects {
    //     separate := do_epa(simplex, <<b0, <<b1);

    //     impulse_response(b0, b1, separate);
    // }
    */
    
    for b0_index: 0..bodies.count-2 {
        for b1_index: b0_index+1..bodies.count-1 {
            b0 := bodies[b0_index];
            b1 := bodies[b1_index];

            intersects: bool;
            cp: Contact_Point;
            if b0.shape_type == Sphere && b1.shape_type == AABB {
                intersects, cp = do_collide_sphere_aabb(b0.sphere, b1.aabb);
            } else if b0.shape_type == Capsule && b1.shape_type == AABB {
                intersects, cp = do_collide_capsule_aabb(b0.capsule, b1.aabb);
            } else if b0.shape_type == AABB && b1.shape_type == AABB {
                intersects, cp = do_collide_aabb_aabb(b0.aabb, b1.aabb);
            }

            if intersects {
                impulse_response(b0, b1, cp);
            }
        }
    }
    
}

MAX_WALK_SPEED :: 1.36; // magnitude of fastest walk velocity allowed (length(xy veloctiy))
MAX_RUN_SPEED :: 3.12928;

update_physics :: (game: *Game, dt: float) {
    for bodies {
        // if it.is_static continue;

        if it.inverse_mass != 0 {
            gravity := make_Vector3(0, -9.81, 0);
            gravity *= (1.0 / it.inverse_mass);
            it.force += gravity;
        }

        if it.shape_type == AABB {
            // @Hack exp decay
            it.velocity.x *= 0.7;
            it.velocity.z *= 0.7;
        }
        
        integrate(it, dt);

        it.force = make_Vector3(0, 0, 0);
    }

    do_collision_detection();
}

draw_debug_bodies :: (game: *Game) {
    for bodies {
        pos := it.position;
        model_matrix := matrix_translate(pos.x, pos.y, pos.z);
        if it.shape_type == Sphere {
            model_matrix = model_matrix * matrix_scale(it.sphere.radius, it.sphere.radius, it.sphere.radius);
            unit_sphere_model.meshes[0].model_matrix = model_matrix;
            draw_model(game.renderer, <<unit_sphere_model);

            // print("body %: %\n", it.shape_type, <<it);
        } else if it.shape_type == Capsule {
            // @Incomplete this scale is technically not correct
            model_matrix = model_matrix * matrix_scale(1, 1, 1);
            unit_capsule_model.meshes[0].model_matrix = model_matrix;
            draw_model(game.renderer, <<unit_capsule_model);
        } else if it.shape_type == AABB {
            model_matrix = model_matrix * matrix_scale(it.aabb.halfs.x*2, it.aabb.halfs.y*2, it.aabb.halfs.z*2);
            aabb_model.meshes[0].model_matrix = model_matrix;
            draw_model(game.renderer, <<aabb_model);
        } else {
            assert(false);
        }

        // print("body %: %\n", it.shape_type, <<it);
    }
}

create_test_scene :: (game: *Game) -> Scene {
    sc: Scene;
    {
        up := load_image(game.asset_man, "assets/clouds1/clouds1_up.bmp");
        down := load_image(game.asset_man, "assets/clouds1/clouds1_down.bmp");
        left := load_image(game.asset_man, "assets/clouds1/clouds1_east.bmp");
        right := load_image(game.asset_man, "assets/clouds1/clouds1_west.bmp");
        back := load_image(game.asset_man, "assets/clouds1/clouds1_south.bmp");
        front := load_image(game.asset_man, "assets/clouds1/clouds1_north.bmp");
        array_add(*sc.models, create_skybox_model(up, down, left, right, front, back));
    }

    {
        test_model := New(Model);
        test_mesh := create_checker_board_mesh(set_angle_vector(0, 1, 0, 0), 50, 50);
        array_add(*test_model.meshes, test_mesh);
        array_add(*sc.models, test_model);
    }

    {
        aabb := make_AABB(make_Vector3(0, 0, 0), make_Vector3(1, 1, 1));
        aabb_model = make_aabb_mesh(aabb);
        aabb_model.draw_mode = DRAW_MODE_WIREFRAME;
        // array_add(*sc.models, aabb_model);
    }

    aabb := make_AABB(make_Vector3(0, -5, 0), make_Vector3(50, 10, 50));

    sphere_a: Sphere;
    sphere_a.radius = 1;

    unit_sphere_model = make_sphere_mesh(sphere_a);
    unit_sphere_model.draw_mode = DRAW_MODE_WIREFRAME;
    // array_add(*sc.models, unit_sphere_model);

    unit_capsule_model = make_capsule_mesh(make_Capsule(make_Vector3(0, 3, 0), 0.75/2.0, 1.2 - 0.75));
    unit_capsule_model.draw_mode = DRAW_MODE_WIREFRAME;
    // {
    //     sphere_a.center = make_Vector3(0, 2.0, 0);
    //     sphere_a.radius = 1.0;
    //     rb := New(Rigid_Body);
    //     Rigid_Body_con(rb, 1.0, sphere_a);

    //     print("rb: %\n", rb);

    //     array_add(*bodies, rb);
    // }


    {
        player_actor := New(Actor);
        player_actor.model = load_model(game.asset_man, "assets/player.fbx");
        assert(player_actor.model != null);
        array_add(*sc.actors, player_actor);
        array_add(*sc.models, player_actor.model);
        player_actor.update_callback = update_player_controller;

        cap := make_Capsule(make_Vector3(0, 3, 0), 0.75/2.0, 1.2 - 0.75);
        rb := New(Rigid_Body);
        Rigid_Body_con(rb, 1.0, cap, player_actor);

        print("rb2: %\n", rb);
        array_add(*bodies, rb);
    }

    {
        sign := make_signpost(Text.NO_MESSAGE);
        sign.model = load_model(game.asset_man, "assets/signpost.fbx");
        array_add(*sc.actors, sign);
        array_add(*sc.models, sign.model);

        aabb2 := make_AABB(make_Vector3(2, 3, 0), make_Vector3(2, 2, 2));
        rb := New(Rigid_Body);
        Rigid_Body_con(rb, 1.0, aabb2, sign);

        array_add(*bodies, rb);
    }

    {
        barrel := make_barrel(game);
        barrel.body.position = make_Vector3(4, 3, 0);

        array_add(*sc.actors, barrel);
        array_add(*sc.models, barrel.model);
        array_add(*bodies, barrel.body);
    }

    {
        crate := make_crate(game);
        crate.body.position = make_Vector3(6, 3, 0);

        array_add(*sc.actors, crate);
        array_add(*sc.models, crate.model);
        array_add(*bodies, crate.body);
    }

    {
        box := New(Actor);
        box.model = create_checker_board_box(50, 4, 5);
        array_add(*sc.actors, box);
        array_add(*sc.models, box.model);

        aabb2 := make_AABB(make_Vector3(0, 2, -10), make_Vector3(50, 4, 5));
        rb := New(Rigid_Body);
        rb.is_static = true;
        Rigid_Body_con(rb, 0, aabb2, box);

        array_add(*bodies, rb);
    }

    {
        rb := New(Rigid_Body);
        Rigid_Body_con(rb, 0, aabb);
        rb.is_static = true;

        print("rb1: %\n", rb);
        array_add(*bodies, rb);
    }

    set_point_size(<<game.renderer, 5);
    return sc;
}

create_textured_rect_mesh :: (v0: Vector3, v1: Vector3, v2: Vector3, v3: Vector3, tex: *Texture) -> *Mesh {
    m := New(Mesh);
    
    V2 :: make_Vector2;
    t0 := V2(0, 0);
    t1 := V2(1, 0);
    t2 := V2(1, 1);
    t3 := V2(0, 1);

    add_quad(*m.vertices, v0, v1, v2, v3);
    add_quad(*m.tex_coords, t0, t1, t2, t3);

    mat := New(Material);
    mat.diffuse = make_Color(1, 1, 1);
    m.material = mat;
    mat.textures[TEXTURE_DIFFUSE_INDEX] = tex;
    store_mesh_in_buffer(m);
    return m;
}

create_skybox_model :: (up: *Texture, down: *Texture, left: *Texture, right: *Texture, front: *Texture, back: *Texture) -> *Model {
    set_texture_wrap(up, true);
    set_texture_wrap(down, true);
    set_texture_wrap(left, true);
    set_texture_wrap(right, true);
    set_texture_wrap(front, true);
    set_texture_wrap(back, true);

    mod := New(Model);

    V3 :: make_Vector3;
    v0 := V3(-1, -1, -1);
    v1 := V3(-1,  1, -1);
    v2 := V3(-1,  1,  1);
    v3 := V3(-1, -1,  1);
    v4 := V3( 1, -1, -1);
    v5 := V3( 1,  1, -1);
    v6 := V3( 1,  1,  1);
    v7 := V3( 1, -1,  1);

    array_add(*mod.meshes, create_textured_rect_mesh(v5, v1, v2, v6, up));
    array_add(*mod.meshes, create_textured_rect_mesh(v7, v3, v0, v4, down));
    array_add(*mod.meshes, create_textured_rect_mesh(v2, v1, v0, v3, left));
    array_add(*mod.meshes, create_textured_rect_mesh(v5, v6, v7, v4, right));
    array_add(*mod.meshes, create_textured_rect_mesh(v6, v2, v3, v7, front));
    array_add(*mod.meshes, create_textured_rect_mesh(v1, v5, v4, v0, back));

    mod.model_matrix = matrix_scale(10000, 10000, 10000);
    return mod;
}

_logger :: (message: string, ident: string, mode: Log_Mode, data: *void) {
    print("%: %\n", ident, message);
}

draw_geometry :: (using game: *Game, water := false) {
    start_scene(game.renderer);
    draw_scene(game.renderer, <<game.current_scene);

    #if DEVELOPER {
        // render_editor(game);
        draw_debug_bodies(game);
    }

    if water {
        draw_water(<<renderer, water_reflect_frame_buffer.color_texture, water_refract_frame_buffer.color_texture, water_dudv_texture, WATER_HEIGHT);
    }
    finish_scene(game.renderer);
    set_clip_plane(renderer, false);
}

main :: () {
    context.logger = _logger;
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
    os_watch_dir("assets");
    os_watch_dir("assets/shaders");

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

    game.water_reflect_frame_buffer = create_frame_buffer(game.renderer, xx game.window.width, xx game.window.height);
    game.water_refract_frame_buffer = create_frame_buffer(game.renderer, xx game.window.width, xx game.window.height);

    game.water_dudv_texture = load_image(game.asset_man, "assets/water_dudv.png");

    rdr.render_to_gbuffer = load_shader_pair(asset_man, "assets/shaders/render_to_gbuffer.vert", "assets/shaders/render_to_gbuffer.frag");
    rdr.render_light_using_gbuffer = load_shader_pair(asset_man, "assets/shaders/render_light_using_gbuffer.vert", "assets/shaders/render_light_using_gbuffer.frag");
    rdr.render_plain_texture = load_shader_pair(asset_man, "assets/shaders/render_light_using_gbuffer.vert", "assets/shaders/render_plain_texture.frag");
    rdr.picking_shader = load_shader_pair(asset_man, "assets/shaders/picking.vert", "assets/shaders/picking.frag");
    rdr.render_text = load_shader_pair(asset_man, "assets/shaders/render_text.vert", "assets/shaders/render_text.frag");
    rdr.render_rect = load_shader_pair(asset_man, "assets/shaders/render_rect.vert", "assets/shaders/render_rect.frag");
    rdr.render_water = load_shader_pair(asset_man, "assets/shaders/render_water.vert", "assets/shaders/render_water.frag");
    load_model(asset_man, "../../untitled.dae");
    game.text_strings = load_text_strings(asset_man);

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

    _scene := create_test_scene(*game);
    game.current_scene = *_scene;

    pressed := false;

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
            game.joy = *joysticks[0];

            // game.renderer.camera.position.x += joy.left_thumb.x;
            // game.renderer.camera.position.z -= joy.left_thumb.y;

            // bodies[0].force.x = (joy.left_thumb.x * (1.0 / bodies[0].inverse_mass) * 100);
            // bodies[0].force.z = -(joy.left_thumb.y * (1.0 / bodies[0].inverse_mass) * 100);

            char_body := bodies[0];
            x_speed := joy.left_thumb.x;
            z_speed := -joy.left_thumb.y;
            vel := make_Vector2(x_speed, z_speed);
            vel = max(MAX_RUN_SPEED, length(vel)) * normalize(vel);

            char_body.velocity.x = vel.x;
            char_body.velocity.z = vel.y;
            if joy.buttons & JOYSTICK_BUTTON_A && !pressed {
                pressed = true;
                // game.player_is_jumping = true;
                assert(char_body.inverse_mass > 0);
                char_body.force += make_Vector3(0, 500 * (1.0 / char_body.inverse_mass), 0);
            }

            if !(joy.buttons & JOYSTICK_BUTTON_A) && pressed {
                pressed = false;
            }
            if joy.buttons & JOYSTICK_BUTTON_RBUMPER {
                // game.renderer.camera.position.y += 1;
            }
            if joy.buttons & JOYSTICK_BUTTON_LBUMPER {
                // game.renderer.camera.position.y -= 1;
            }

            if (joy.buttons & JOYSTICK_BUTTON_BACK) exit = true;
        } else {
            game.joy = null;
        }

        if (exit) break;

        // if (file_changes.count) Sleep(10);
        // for (u32 i = 0; i < file_changes.count; ++i) {
        //     auto &it = file_changes[i];
        //     file_update_callback(&it, &game);
        // }

        update_camera(*game, 1.0/60.0);
        update_physics(*game, 1.0/60.0);
        update_scene(*game, game.current_scene, 1.0/60.0);
        renderer.projection_matrix = matrix_perspective(game.fov, cast(float) game.window.width/cast(float) game.window.height, 1.0, 100000.0);
        // update_editor(*game, 1.0);
        glViewport(0, 0, xx game.window.width, xx game.window.height);

        old_camera := game.renderer.camera;
        new_camera := old_camera;
        new_camera.position.y -= 2 * (new_camera.position.y - WATER_HEIGHT);
        phi := get_euler_angles(new_camera.rotation);
        new_camera.rotation = new_camera.rotation * set_angle_vector(xx (-phi * 2), 1, 0, 0);
        game.renderer.camera = new_camera;

        use_frame_buffer(renderer, *game.water_reflect_frame_buffer);
        set_clip_plane(renderer, true, make_Vector4(0, 1, 0, -WATER_HEIGHT));
        draw_geometry(*game);
        use_frame_buffer(renderer, null);


        game.renderer.camera = old_camera;
        use_frame_buffer(renderer, *game.water_refract_frame_buffer);
        set_clip_plane(renderer, true, make_Vector4(0, -1, 0, WATER_HEIGHT));
        draw_geometry(*game);
        use_frame_buffer(renderer, null);

        set_clip_plane(renderer, false);
        draw_geometry(*game, true);

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