

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