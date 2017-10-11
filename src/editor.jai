

#scope_file

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

    if input_button_states[#char "."] & DOWN {
        q := game.renderer.camera.rotation;
        game.renderer.camera.position += q * make_Vector3(0.0, 0.0, -0.5);
    }

    if input_button_states[#char "E"] & DOWN {
        q := game.renderer.camera.rotation;
        game.renderer.camera.position -= (q * set_angle_vector(3.14, 0, 1, 0)) * make_Vector3(0.0, 0.0, 0.5);
    }
}

selected_points_mesh: *Mesh;
selected_points_indices: [..] u32;

#scope_export

__terrain_line_mesh: *Mesh;
__terrain_picking_mesh: *Mesh;

add_point :: (m: *Mesh, p: Vector3) {
    array_add(*m.vertices, p);
    array_add(*m.normals, make_Vector3(0, 0, 0));
    store_mesh_in_buffer(m);
}

update_point_mesh :: (m: *Mesh, map: Height_Map, indices: [] u32) {
	array_reset(*m.vertices);
	array_reset(*m.normals);

	for indices {
		array_add(*m.vertices, map.vertices[it]);
		array_add(*m.normals, make_Vector3(0, 0, 0));
	}

	store_mesh_in_buffer(m);
}

init_editor :: (game: *Game) {
    m := New(Mesh);
    m.material = New(Material);
    m.material.diffuse = make_Color(1.0, 0.5, 0.0);
    m.primitive_type = Primitive_Type.POINTS;

    selected_points_mesh = m;
}

update_editor :: (game: *Game, dt: float) {
    update_camera(game, dt);

    start_picking(renderer);
    draw_picking_mesh(<<renderer, <<__terrain_picking_mesh, renderer.picking_shader);
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

            // print("i: %, ix: %, iy: %\n", index, index % xx terrain_map.width, index / xx terrain_map.width);

            // @TODO check if point is already in array
            add_point(selected_points_mesh, terrain_map.vertices[index]);
            array_add(*selected_points_indices, index);
        }
    }

    if input_button_states[#char "Z"] & DOWN {
    	delta := make_Vector3(xx mouse_delta_x, xx -mouse_delta_y, 0);
        q := game.renderer.camera.rotation;

        delta = mul(delta, make_Vector3(1.0/cast(float)game.window.width, 1.0/cast(float)game.window.height, 0)); // nomalize pixels to viewport
        sx, sy := viewport_scale(game.fov, cast(float)game.window.width / cast(float)game.window.height, 1.0);
        delta = mul(delta, make_Vector3(sx, sy, 1)) * 20;

    	for selected_points_indices {
    		vert_current := terrain_map.vertices[it];
    		out := vert_current + delta;
    		terrain_map.vertices[it] = out;
    	}

    	update_point_mesh(selected_points_mesh, terrain_map, selected_points_indices);
    	generate_terrain_mesh(terrain_map, __terrain);
        generate_terrain_picking_mesh(terrain_map, __terrain_picking_mesh);
        generate_terrain_line_mesh(terrain_map, __terrain_line_mesh);
    }
}

render_editor :: (game: *Game) {
    start_scene(renderer);
    clear_screen(0.5, 0.5, 0.5, 1.0);
    // renderer->draw_cube(0, 0, -2, 1);
    // draw_model(<<renderer, <<__model);
    __terrain.material.diffuse = make_Color(0.8, 0.8, 0.8);
    __terrain_line_mesh.material.diffuse = make_Color(0.0, 0.0, 0.0);
    draw_mesh(<<renderer, <<__terrain);
    draw_mesh(<<renderer, <<__terrain_line_mesh);
    set_point_size(<<renderer, 5.0);
    draw_mesh(<<renderer, <<selected_points_mesh);
    finish_scene(<<renderer);
}