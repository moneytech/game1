
#import "Compiler";

#load "editor.jai";
#load "mesh_utils.jai";

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
    actor.model = load_model(game.asset_man, "assets/crate.dae");
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
    NO_MESSAGE;

    LAST_MESSAGE;
}

issue_text :: (game: *Game, message: string) {
    sc := game.current_scene;


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



_logger :: (message: string, ident: string, mode: Log_Mode, data: *void) {
    print("%: %\n", ident, message);
}

main :: () {
    context.logger = _logger;
    orig_wd := getcwd();
    game := init_game("game1");

    init_editor(game);

    // key := load_model(asset_man, "assets/keyOGA.obj");
    // __model = load_model(asset_man, "assets/well.coveredopen.obj");
    // __model = load_model(asset_man, "assets/treasure_chest.fbx");
    // __model = key;
    // __model = create_sphere(1.0, 32, 32);
    // __model.meshes[0].material = key.meshes[0].material;
    // key.meshes[0].material.textures[0] = null;

    _scene := create_test_scene(game);
    game.current_scene = *_scene;

    renderer := game.renderer;

    pressed := false;
    imgui: Imgui;
    imgui.renderer = game.renderer;

    while true {
        exit := false;

        imgui.mouse_went_down = false;
        imgui.mouse_went_up = false;

        for events_this_frame {
            if (it.type == Event_Type.QUIT) {
                exit = true;
            } else if (it.type == Event_Type.KEYBOARD) {
                if it.key_code == Key_Code.MOUSE_BUTTON_LEFT {
                    if it.key_pressed imgui.mouse_went_down = true;
                    else imgui.mouse_went_up = true;
                }
            }
        }

        {
            x, y, success := get_mouse_pointer_position(false);
            if success {
                imgui.mouse_x = xx x;
                imgui.mouse_y = xx y;
            }
        }

        update_game(game);

        if game.joy {
            joy := game.joy;

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
        }

        if (exit) break;

        // if (file_changes.count) Sleep(10);
        // for (u32 i = 0; i < file_changes.count; ++i) {
        //     auto &it = file_changes[i];
        //     file_update_callback(&it, &game);
        // }

        update_camera(game, 1.0/60.0);
        update_physics(game, 1.0/60.0);
        update_scene(game, game.current_scene, 1.0/60.0);
        game.renderer.projection_matrix = matrix_perspective(game.fov, cast(float) game.window.width/cast(float) game.window.height, 1.0, 100000.0);
        render_game(game);
        do_label(*imgui, 1, <<font, 0.0, 0.0, "Hello World");

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

        swap_buffers(game.window.handle);
        os_pump_input();

        // @Note we have to wait long enough for whatever program is
        // changing our file to release its handle in order for us
        // to reload it
        os_pump_file_notifications(file_update_callback, *game);
    }

    os_close_window(game.window.handle);

    if running_at_compile_time() {
        setcwd(orig_wd);
    }
}

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
