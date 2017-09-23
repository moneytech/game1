

#scope_file

update_camera :: (game: *Game, dt: float) {
    using Key_Current_State;

    if input_button_states[Key_Code.MOUSE_BUTTON_MIDDLE] & DOWN {
        delta := make_Vector3(xx -mouse_delta_x, xx mouse_delta_y, 0);
        q := game.renderer.camera.rotation;

        delta = mul(delta, make_Vector3(1.0/cast(float)game.window.width, 1.0/cast(float)game.window.height, 0)); // nomalize pixels to viewport
        sx, sy := viewport_scale(game.fov, cast(float)game.window.width / cast(float)game.window.height, 1.0);
        delta = mul(delta, make_Vector3(sx, sy, 1));

        move := delta * 5;

        game.renderer.camera.position += move;
    }

    if input_button_states[#char "."] & DOWN {
        game.renderer.camera.position.z -= 0.5;
    }

    if input_button_states[#char "E"] & DOWN {
        game.renderer.camera.position.z += 0.5;
    }
}

selected_points_mesh: *Mesh;

#scope_export

add_point :: (m: *Mesh, p: Vector3) {
    array_add(*m.vertices, p);
    array_add(*m.normals, make_Vector3(0, 0, 0));
    store_mesh_in_buffer(m);
}

init_editor :: (game: *Game) {
    m := New(Mesh);
    m.material = New(Material);
    m.material.diffuse = make_Color(1, 0, 0);
    m.primitive_type = Primitive_Type.POINTS;

    add_point(m, make_Vector3(0, 0, 0));

    selected_points_mesh = m;
}

update_editor :: (game: *Game, dt: float) {
    update_camera(game, dt);

    start_picking(renderer);
    draw_picking_mesh(<<renderer, <<__terrain, renderer.picking_shader);
    finish_picking(<<renderer);
    get_picking_data(<<renderer, picking_buf.data, xx picking_buf.count * size_of(u32));

    using Key_Current_State;
    if input_button_states[Key_Code.MOUSE_BUTTON_LEFT] & START {
        x, y, success := get_mouse_pointer_position(true);
        if success {
            assert(x >= 0 && x < game.window.width);
            assert(y >= 0 && y < game.window.height);

            in := (y * game.window.width) + x;
            index := picking_buf[in];
            if index > (terrain_map.width * terrain_map.height) {
                return;
            }

            // print("x, y: %, %; index: %; %\n", x, game.window.height - y, index, terrain_map.vertices[index]);
            print("i: %, ix: %, iy: %\n", index, index % xx terrain_map.width, index / xx terrain_map.width);
            add_point(selected_points_mesh, terrain_map.vertices[index]);
        }
    }
}

render_editor :: (game: *Game) {
    start_scene(renderer);
    clear_screen(0.0, 0.0, 0.0, 1.0);
    // renderer->draw_cube(0, 0, -2, 1);
    // draw_model(<<renderer, <<__model);
    draw_mesh_wireframe(<<renderer, <<__terrain);
    set_point_size(<<renderer, 5.0);
    draw_mesh(<<renderer, <<selected_points_mesh);
    finish_scene(<<renderer);
}