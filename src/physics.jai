
Segment :: struct {
    origin:    Vector3;
    direction: Vector3;
}

Capsule :: struct {
    segment: Segment;
    radius: float;
}

make_Capsule :: (origin: Vector3, end: Vector3, radius: float) -> Capsule {
    out: Capsule = ---;
    out.segment.origin = origin;
    out.segment.direction = end - origin;
    out.radius = radius;
    return out;
}

AABB :: struct {
    xmin: float;
    xmax: float;
    ymin: float;
    ymax: float;
    zmin: float;
    zmax: float;
}

Sphere :: struct {
    center: Vector3;
    radius: float;
}

same_direction :: (a: Vector3, b: Vector3) -> bool {
    return dot(a, b) > 0;
}

gjk_support :: (a: Sphere, dir: Vector3) -> Vector3 {
    return a.center + (normalize(dir) * a.radius);
}

Simplex :: struct(VectorT: Type) {
    a: VectorT;
    b: VectorT;
    c: VectorT;
    d: VectorT;

    count: u8;

    debug_dir: VectorT;

    penetration: VectorT;
}

add :: (using s: *Simplex($T), new_a: T) {
    if count == {
    case 0;
        a = new_a;
        count += 1;
    case 1;
        b = a;
        a = new_a;
        count += 1;
    case 2;
        c = b;
        b = a;
        a = new_a;
        count += 1;
    }

    #if T == Vector3 {
        if count == 3 {
            d = c;
            c = b;
            b = a;
            a = new_a;
            count += 1;
        }
    }

    assert(count <= (size_of(T) / size_of(float)) + 1);
}

set :: (using s: *Simplex($T), args: .. T) {
    assert(args.count < 5);
    s.count = xx args.count;

    if args.count s.a = args[0];
    if args.count > 1 s.b = args[1];
    if args.count > 2 s.c = args[2];

    #if T == Vector3 {
        if args.count > 3 s.d = args[3];
    }
}

operator[] :: (using s: Simplex($T), index: int) -> T {
    assert(index >= 0 && index < count);
    if index == {
     case 0;
        return a;
     case 1;
        return b;
     case 2;
        return c;
    }

    #if T == Vector3 {
        if index == 3 return d;
    }

    assert(index <= size_of(T) / size_of(float));
}

do_triange_simplex :: (sim: *Simplex($VectorType), a: VectorType, b: VectorType, c: VectorType, ao: VectorType) -> VectorType {
    ab := b - a;
    ac := c - a;
    abc := cross(ab, ac);
    if same_direction(cross(abc, ac), ao) {
        if same_direction(ac, ao) {
            set(sim, a, c);
            return cross(ac, cross(ao, ac));
        } else if same_direction(ab, ao) {
            set(sim, a, b);
            return cross(ab, cross(ao, ab));
        } else {
            set(sim, a);
            return ao;
        }
    } else if same_direction(cross(ab, abc), ao) {
        if same_direction(ab, ao) {
            set(sim, a, b);
            return cross(ab, cross(ao, ab));
        } else {
            set(sim, a);
            return ao;
        }
    } else if same_direction(abc, ao) {
        set(sim, a, sim.b, sim.c);
        return abc;
    } else {
        set(sim, a, sim.c, sim.b);
        return -abc;
    }
}

do_simplex :: (sim: *Simplex($VectorType), a: VectorType) -> bool, VectorType {
    ao := -a;

    if sim.count < 2 { // we should never actually hit these cases
        assert(false);
        return false, ao;
    }

    if sim.count == 2 {
        ab := sim.b - a;
        if same_direction(ab, ao) {
            // set(sim, a, sim.b);
            return false, cross(ab, cross(ao, ab));
        } else {
            set(sim, a);
            return false, ao;
        }
    } else if sim.count == 3 {
        return false, do_triange_simplex(sim, a, sim.b, sim.c, ao);
    } else #if VectorType == Vector3 {
        if sim.count == 4 {
            // bcd is our old triangle and we already know that the origin is in the direction of the normal of bcd
            // add_normal(m, c, b, d, green);
            // add_normal(m, a, b, c, green);
            // add_normal(m, a, c, d, green);
            // add_normal(m, a, d, b, green);

            b := sim.b;
            c := sim.c;
            d := sim.d;

            abc := cross(b - a, c - a);
            acd := cross(c - a, d - a);
            adb := cross(d - a, b - a);
            if same_direction(abc, ao) {
                return false, do_triange_simplex(sim, a, b, c, ao);
            } else if same_direction(acd, ao) {
                return false, do_triange_simplex(sim, a, c, d, ao);
            } else if same_direction(adb, ao) {
                return false, do_triange_simplex(sim, a, d, b, ao);
            } else {
                return true, ao;
            }
        } else {
            assert(false);
            return false, ao;
        }
    }

    assert(false);
    return false, ao;
}

do_gjk :: (obja: $T, objb: $R, $VectorType: Type) -> bool, Simplex($VectorType) {
    sim: Simplex(VectorType);
    d := normalize(make_Vector3(1, 0, 0));
    s := gjk_support(obja, d) - gjk_support(objb, -d);
    add(*sim, s);
    d = -s;

    while true {
        a := gjk_support(obja, d) - gjk_support(objb, -d);
        if dot(a, d) < 0 return false, sim;
        add(*sim, a);

        intersects: bool;
        intersects, d = do_simplex(*sim, a);
        if intersects return true, sim;
    }
}

do_epa :: (gjk_output: *Simplex($VectorType), obja: $T, objb: $T) -> VectorType {
    sim := <<gjk_output;

    while true {
        
    }
}

start_debug_gjk :: (obja: $ShapeA, objb: $ShapeB) -> Simplex(Vector3) {
    sim: Simplex(Vector3);
    d := normalize(make_Vector3(0, 1, 1));
    s := gjk_support(obja, d) - gjk_support(objb, -d);
    add(*sim, s);
    d = -s;
    sim.debug_dir = d;
    return sim;
}

step_debug_gjk :: (sim: *Simplex($T), obja: $ShapeA, objb: $ShapeB) -> bool /* stop */, bool /* intersects */ {
    d := sim.debug_dir;
    a := gjk_support(obja, d) - gjk_support(objb, -d);
    if dot(a, d) < 0 return true, false;
    add(sim, a);

    intersects: bool;
    intersects, d = do_simplex(sim, a);
    sim.debug_dir = d;
    update_simplex_mesh(*__simplex_mesh, <<sim);
    if intersects return true, true;
    return false, false;
}

add_normal :: (m: *Mesh, a: $VectorT, b: VectorT, c: VectorT, color: Color) {
    array_add(*m.vertices, (a + b + c) * (1.0 / 3.0));
    array_add(*m.vertices, ((a + b + c) * (1.0 / 3.0)) + normalize(cross(b - a, c - a)));

    array_add(*m.colors, color);
    array_add(*m.colors, color);
}

update_simplex_mesh :: (m: *Mesh, sim: Simplex($T)) {
    if !m.material {
        m.material = New(Material);
        m.material.diffuse = make_Color(1, 1, 1);
    }

    m.vertices.count = 0;
    m.colors.count = 0;
    red := make_Color(1, 0, 0);
    green := make_Color(0, 1, 0);

    if sim.count < 2 {
        m.primitive_type = Primitive_Type.POINTS;
        array_add(*m.vertices, sim.a);
        array_add(*m.colors, red);
    } else if sim.count <= 3 {
        m.primitive_type = Primitive_Type.LINES;

        a := sim.a;
        b := sim.b;
        c := sim.c;

        m.primitive_type = Primitive_Type.LINES;

        array_add(*m.vertices, a);
        array_add(*m.vertices, b);

        array_add(*m.colors, red);
        array_add(*m.colors, red);
        if sim.count > 2 {
            array_add(*m.vertices, c);
            array_add(*m.vertices, a);

            array_add(*m.colors, red);
            array_add(*m.colors, red);

            array_add(*m.vertices, b);
            array_add(*m.vertices, c);

            array_add(*m.colors, red);
            array_add(*m.colors, red);

            // we also draw the outward facing normal

            add_normal(m, a, b, c, green);
        }
    } else {
        a := sim.a;
        b := sim.b;
        c := sim.c;
        d := sim.d;

        m.primitive_type = Primitive_Type.LINES;

        array_add(*m.vertices, a);
        array_add(*m.vertices, b);
        array_add(*m.vertices, b);
        array_add(*m.vertices, c);
        array_add(*m.vertices, c);
        array_add(*m.vertices, a);

        array_add(*m.vertices, b);
        array_add(*m.vertices, c);
        array_add(*m.vertices, c);
        array_add(*m.vertices, d);
        array_add(*m.vertices, d);
        array_add(*m.vertices, b);

        array_add(*m.vertices, c);
        array_add(*m.vertices, d);
        array_add(*m.vertices, d);
        array_add(*m.vertices, a);
        array_add(*m.vertices, a);
        array_add(*m.vertices, c);

        array_add(*m.vertices, d);
        array_add(*m.vertices, a);
        array_add(*m.vertices, a);
        array_add(*m.vertices, b);
        array_add(*m.vertices, b);
        array_add(*m.vertices, d);

        array_add(*m.colors, red);
        array_add(*m.colors, red);
        array_add(*m.colors, red);
        array_add(*m.colors, red);
        array_add(*m.colors, red);
        array_add(*m.colors, red);


        array_add(*m.colors, red);
        array_add(*m.colors, red);
        array_add(*m.colors, red);
        array_add(*m.colors, red);
        array_add(*m.colors, red);
        array_add(*m.colors, red);

        array_add(*m.colors, red);
        array_add(*m.colors, red);
        array_add(*m.colors, red);
        array_add(*m.colors, red);
        array_add(*m.colors, red);
        array_add(*m.colors, red);

        array_add(*m.colors, red);
        array_add(*m.colors, red);
        array_add(*m.colors, red);
        array_add(*m.colors, red);
        array_add(*m.colors, red);
        array_add(*m.colors, red);

        add_normal(m, c, b, d, green);
        add_normal(m, a, b, c, green);
        add_normal(m, a, c, d, green);
        add_normal(m, a, d, b, green);
    }

    store_mesh_in_buffer(m);

    print("%\n", sim);
}


closest_point_line_to_point :: (a: Vector3, b: Vector3, q: Vector3) -> Vector3 {
    invlen := 1.0 / length(b - a);
    n := (b - a) * invlen;

    u := dot((q - a), n) * invlen;
    v := dot((b - q), n) * invlen;

    if u <= 0 return b;
    if v <= 0 return a;
    else return u*a + v*b;
}


// old stuff

do_intersect :: (s: Sphere, b: AABB) -> bool {
    sqr_dist: float64;
    d: float64;

    if s.center.x < b.xmin {
        d = s.center.x - b.xmin;
        sqr_dist += (d * d);
    } else if s.center.x > b.xmax {
        d = s.center.x - b.xmax;
        sqr_dist += (d * d);
    }

    if s.center.y < b.ymin {
        d = s.center.y - b.ymin;
        sqr_dist += (d * d);
    } else if s.center.y > b.ymax {
        d = s.center.y - b.ymax;
        sqr_dist += (d * d);
    }

    if s.center.z < b.zmin {
        d = s.center.z - b.zmin;
        sqr_dist += (d * d);
    } else if s.center.z > b.zmax {
        d = s.center.z - b.zmax;
        sqr_dist += (d * d);
    }

    return sqr_dist < (s.radius * s.radius);
}

do_overlap :: (a: Sphere, b: Sphere) -> bool {
    rad := a.radius + b.radius;
    return length(a.center - b.center) <= rad;
}

do_overlap :: (a: Capsule, b: Capsule) -> bool {
    rad := a.radius + b.radius;
    dist := distance(a.segment, b.segment);
    return dist <= rad;
}

will_overlap :: (tmin: float, tmax: float, s0: Sphere, v0: Vector3, s1: Sphere, v1: Vector3) -> bool {
    c0 := make_Capsule(s0.center + v0*tmin, s0.center + v0*tmax, s0.radius);
    c1 := make_Capsule(s1.center + v1*tmin, s1.center + v1*tmax, s1.radius);

    return do_overlap(c0, c1);
}

NEAR_ZERO :: 0.00000001;

distance :: (p: Segment, q: Segment) -> float, Segment {
    w0 := p.origin - q.origin;
    a := dot(p.direction, p.direction);
    b := dot(p.direction, q.direction);
    c := dot(q.direction, q.direction);
    d := dot(p.direction, w0);

    det := (a * c) - (b * b)
    sc: float;
    tc: float;

    if det < NEAR_ZERO {
        sc = 0;
        tc = d / b;
    } else {
        e := dot(q.direction, w0);
        sc := ((b * e) - (c * d)) / det;
        tc := ((a * e) - (b * d)) / det;
    }

    point0 := p.origin + (p.direction * sc);
    point1 := q.origin + (q.direction * tc);

    out_segment: Segment = ---;
    out_segment.origin = point0;
    out_segment.direction = point1 - point0;
    return length(out_segment.direction), out_segment;
}
