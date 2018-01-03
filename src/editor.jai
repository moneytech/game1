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

#scope_file

selected_points_mesh: *Mesh;
selected_points_indices: [..] u32;
picking_position_buf: [] Vector2;

__terrain: *Mesh;
terrain_map: Height_Map;

Tool_Mode :: enum u16 {
    VERTEX_PICK;
    BRUSH_ADD;
    BRUSH_SUBTRACT;
    BRUSH_SPHERE_ADD;
    BRUSH_SPHERE_SUBTRACT;
    BRUSH_TEXTURE_PAINT;
}

terrain_texture: Texture;
terrain_texture_buffer: [512 * 512] u32;
tool_brush_add_sub_vector: Vector3;
tool_brush_radius := 10.0;
current_tool_mode := Tool_Mode.BRUSH_TEXTURE_PAINT;
draw_line_overlay := false;
texture_paint_color: u32 = 0xFF1A8B53;

collect_indices_around_circle :: (map: Height_Map, p: Vector2, radius: float) {
    array_reset(*selected_points_indices);
    reset_mesh_arrays(selected_points_mesh);
    // @Speed better circle picking
    for y: 0..terrain_map.height-1 {
        for x: 0..terrain_map.width-1 {
            in: u32 = xx (x + y * terrain_map.width); 
            cur := make_Vector2(xx x, xx y);
            if length(cur - p) < radius {
                add_point(selected_points_mesh, map.vertices[in]);
                array_add(*selected_points_indices, in);
            }
        }
    }

    store_mesh_in_buffer(selected_points_mesh, true);
}

#scope_export

__terrain_line_mesh: *Mesh;

add_point :: (m: *Mesh, p: Vector3) {
    array_add(*m.vertices, p);
    array_add(*m.normals, make_Vector3(0, 0, 0));
}

update_point_mesh :: (m: *Mesh, map: Height_Map, indices: [] u32) {
	reset_mesh_arrays(m);

	for indices {
		array_add(*m.vertices, map.vertices[it]);
	}

	store_mesh_in_buffer(m);
}

init_editor :: (game: *Game) {
    m := New(Mesh);
    m.material = New(Material);
    m.material.diffuse = make_Color(1.0, 0.5, 0.0);
    m.primitive_type = Primitive_Type.POINTS;

    selected_points_mesh = m;

    picking_position_buf.count = game.window.width * game.window.height;
    picking_position_buf.data = alloc(picking_position_buf.count*size_of(Vector2));

    tool_brush_add_sub_vector = make_Vector3(0.0, 0.2, 0.0);

    // terrain_map, __terrain = new_terrain_map(128, 128);
    terrain_map, __terrain = load_heightmap(game.asset_man, "assets/heightmap.png");
    __terrain_line_mesh = New(Mesh);
    <<__terrain_line_mesh = generate_terrain_line_mesh(terrain_map);

    for * terrain_texture_buffer {
        <<it = 0xFFFFFFFF;
    }
    create_texture(*terrain_texture, 512, 512, terrain_texture_buffer.data, Texture.RGBA);
    __terrain.material.textures[TEXTURE_DIFFUSE_INDEX] = *terrain_texture;
}

update_editor :: (game: *Game, dt: float) {
    x, y, success := get_mouse_pointer_position(true);
    if !success return;

    update_camera(game, dt);

    start_picking(renderer);
    draw_picking_mesh(<<renderer, <<__terrain, renderer.picking_shader);
    finish_picking(renderer);
    get_picking_position_data(<<renderer, picking_position_buf.data);

    in := (y * game.window.width) + x;

    using Key_Current_State;

    if current_tool_mode == Tool_Mode.VERTEX_PICK {
        if input_button_states[Key_Code.MOUSE_BUTTON_LEFT] & START {
            if success {
                assert(x >= 0 && x < game.window.width);
                assert(y >= 0 && y < game.window.height);

                assert(false); // @FixMe to use position data
                index: u32;
                if index > (terrain_map.width * terrain_map.height) {
                    return;
                }

                // print("i: %, ix: %, iy: %\n", index, index % xx terrain_map.width, index / xx terrain_map.width);

                // @TODO check if point is already in array
                add_point(selected_points_mesh, terrain_map.vertices[index]);
                store_mesh_in_buffer(selected_points_mesh);
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
            generate_terrain_line_mesh(terrain_map, __terrain_line_mesh);
        }
    } else if current_tool_mode == Tool_Mode.BRUSH_ADD || current_tool_mode == Tool_Mode.BRUSH_SUBTRACT {
        if !(x >= 0 && x < game.window.width) return;
        if !(y >= 0 && y < game.window.height) return;
        collect_indices_around_circle(terrain_map, picking_position_buf[in], tool_brush_radius);

        if input_button_states[Key_Code.MOUSE_BUTTON_LEFT] & DOWN {
            delta := tool_brush_add_sub_vector;
            if current_tool_mode == Tool_Mode.BRUSH_SUBTRACT delta = -delta;
            for selected_points_indices {
                vert_current := terrain_map.vertices[it];
                out := vert_current + delta;
                terrain_map.vertices[it] = out;
            }

            update_point_mesh(selected_points_mesh, terrain_map, selected_points_indices);
            generate_terrain_mesh(terrain_map, __terrain);
            generate_terrain_line_mesh(terrain_map, __terrain_line_mesh);
        }
    } else if current_tool_mode == Tool_Mode.BRUSH_SPHERE_ADD || current_tool_mode == Tool_Mode.BRUSH_SPHERE_SUBTRACT {
        if !(x >= 0 && x < game.window.width) return;
        if !(y >= 0 && y < game.window.height) return;
        p := picking_position_buf[in];
        collect_indices_around_circle(terrain_map, p, tool_brush_radius);

        if input_button_states[Key_Code.MOUSE_BUTTON_LEFT] & DOWN {
            for selected_points_indices {
                x := it % terrain_map.width;
                y := it / terrain_map.width;
                cur := make_Vector2(xx x, xx y);

                // not technically spherical, but achieves a good enough effect
                d := length(cur - p) / tool_brush_radius;
                delta := mul(make_Vector3(0, (1.0 - d), 0), tool_brush_add_sub_vector);
                if current_tool_mode == Tool_Mode.BRUSH_SPHERE_SUBTRACT delta = -delta;

                vert_current := terrain_map.vertices[it];
                out := vert_current + delta;
                terrain_map.vertices[it] = out;
            }

            update_point_mesh(selected_points_mesh, terrain_map, selected_points_indices);
            generate_terrain_mesh(terrain_map, __terrain);
            generate_terrain_line_mesh(terrain_map, __terrain_line_mesh);
        }
    } else if current_tool_mode == Tool_Mode.BRUSH_TEXTURE_PAINT {
        if !(x >= 0 && x < game.window.width) return;
        if !(y >= 0 && y < game.window.height) return;
        p := picking_position_buf[in];
        collect_indices_around_circle(terrain_map, p, tool_brush_radius);

        // project p into texture space
        p.x = (p.x / cast(float) terrain_map.width) * terrain_texture.width;
        p.y = (p.y / cast(float) terrain_map.height) * terrain_texture.height;
        // I'm not sure how to transform this if we have differing width/height of the map
        brush_radius := (tool_brush_radius / cast(float) terrain_map.width) * terrain_texture.width;

        brush_x := cast(s32) (p.x - brush_radius);
        brush_xw := cast(s32) (p.x + brush_radius);
        brush_y := cast(s32) (p.y - brush_radius);
        brush_yh := cast(s32) (p.y + brush_radius);

        if brush_x < 0 brush_x = 0;
        if brush_y < 0 brush_y = 0;
        if brush_xw >= terrain_texture.width brush_xw = terrain_texture.width-1;
        if brush_yh >= terrain_texture.height brush_yh = terrain_texture.height-1;

        if input_button_states[Key_Code.MOUSE_BUTTON_LEFT] & DOWN {
            
            for y_p: brush_y..brush_yh {
                for x_p: brush_x..brush_xw {
                    o := make_Vector2(cast(float) x_p, cast(float) y_p);
                    if length(p - o) < brush_radius {
                        x_in: u32 = xx o.x;
                        y_in: u32 = xx o.y;

                        terrain_texture_buffer[x_in + y_in * terrain_texture.width] = texture_paint_color;
                    }
               }
            }

            update_texture(*terrain_texture, terrain_texture_buffer.data);
            update_point_mesh(selected_points_mesh, terrain_map, selected_points_indices);
            generate_terrain_mesh(terrain_map, __terrain);
            generate_terrain_line_mesh(terrain_map, __terrain_line_mesh);
        }
    }
}

WATER_HEIGHT :: 0.05;

render_editor_scene :: (using game: *Game, water := false) {
    start_scene(renderer);
    clear_screen(0.5, 0.5, 0.5, 1.0);
    // renderer->draw_cube(0, 0, -2, 1);
    // draw_model(<<renderer, <<__model);
    __terrain.material.diffuse = make_Color(0.8, 0.8, 0.8);
    __terrain_line_mesh.material.diffuse = make_Color(0.0, 0.0, 0.0);
    draw_mesh(<<renderer, <<__terrain);
    if draw_line_overlay draw_mesh(<<renderer, <<__terrain_line_mesh);
    set_point_size(<<renderer, 5.0);
    draw_mesh(<<renderer, <<selected_points_mesh);

    if water {
        draw_water(<<renderer, water_reflect_frame_buffer.color_texture, water_refract_frame_buffer.color_texture, water_dudv_texture, WATER_HEIGHT);
    }
    finish_scene(renderer);
    set_clip_plane(renderer, false);
}

render_editor :: (using game: *Game) {

    old_camera := game.renderer.camera;
    new_camera := old_camera;
    new_camera.position.y -= 2 * (new_camera.position.y - WATER_HEIGHT);
    phi := get_euler_angles(new_camera.rotation);
    new_camera.rotation = new_camera.rotation * set_angle_vector(xx (-phi * 2), 1, 0, 0);
    game.renderer.camera = new_camera;

    use_frame_buffer(renderer, *water_reflect_frame_buffer);
    set_clip_plane(renderer, true, make_Vector4(0, 1, 0, -WATER_HEIGHT));
    render_editor_scene(game);
    use_frame_buffer(renderer, null);


    game.renderer.camera = old_camera;
    use_frame_buffer(renderer, *water_refract_frame_buffer);
    set_clip_plane(renderer, true, make_Vector4(0, -1, 0, WATER_HEIGHT));
    render_editor_scene(game);
    use_frame_buffer(renderer, null);

    set_clip_plane(renderer, false);
    render_editor_scene(game, true);

    // renderer.projection_matrix = matrix_ortho(0, 1, 0, 1, -1, 1);
    // draw_textured_rect(<<renderer, water_reflect_frame_buffer.color_texture, 0, 0, 0.25, 0.25);
    // draw_textured_rect(<<renderer, water_refract_frame_buffer.color_texture, 0, 0.25, 0.25, 0.25);

    renderer.projection_matrix = matrix_ortho(0, xx game.window.width, xx game.window.height, 0, -1, 1);
    draw_rect(<<renderer, 0, 0, 500, font.char_height*5, make_Color(0.2, 0.2, 0.2), 0.5);
    
    h := font.char_height*0.75;
    draw_text(<<renderer, <<font, 0, h+font.char_height*0, "Current Tool: %", current_tool_mode);
    draw_text(<<renderer, <<font, 0, h+font.char_height*1, "Brush Radius: %", tool_brush_radius);
    draw_text(<<renderer, <<font, 0, h+font.char_height*2, "Add/Sub Vector: %", tool_brush_add_sub_vector);
    draw_text(<<renderer, <<font, 0, h+font.char_height*3, "Show line mesh: %", draw_line_overlay);

    r := texture_paint_color & 0xFF;
    g := (texture_paint_color >> 8) & 0xFF;
    b := (texture_paint_color >> 16) & 0xFF;
    a := (texture_paint_color >> 24) & 0xFF;
    draw_text(<<renderer, <<font, 0, h+font.char_height*4, "Texture Paint Color: %,%,%,%", r, g, b, a);
}
