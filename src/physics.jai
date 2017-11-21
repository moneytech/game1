

Rigid_Body :: struct {
    inverse_mass: float;

    position: Vector3;
    velocity: Vector3;
    force: Vector3;

    inverse_inertia_tensor: Matrix3; // body-space
    world_inertia_tensor: Matrix3;
    orientation: Matrix3;
    angular_momentum: Vector3;
    angular_velocity: Vector3;
    torque: Vector3;

    shape_type: Type;
    shape: void;

    #place shape;
    sphere: Sphere;

    #place shape;
    aabb: AABB;
}

Rigid_Body_con :: (using rb: *Rigid_Body, sh: $Shape_Type) {
    shape_type = Shape_Type;
    inverse_inertia_tensor = transpose(moment_of_inertia(sh, <<rb));
    orientation = make_orientation(0, 0, 1, 0);
    <<(cast(*Shape_Type) *shape) = sh;

    world_inertia_tensor = orientation * inverse_inertia_tensor * transpose(orientation);
    angular_velocity = world_inertia_tensor * angular_momentum;
}

integrate :: (using rb: *Rigid_Body, dt: float) {

    {
        acceleration := force * inverse_mass * dt;
        position += (0.5 * acceleration * dt) + velocity * dt;
        velocity += acceleration;
    }

    {
        // @Speed it's probably faster to multiply dt to angular_velocity
        // before we make it a skew symmetric matrix
        orientation += dt * (~angular_velocity) * orientation;
        angular_momentum += dt * torque;

        orthonormalize(*orientation);
        
        world_inertia_tensor += orientation * inverse_inertia_tensor * transpose(orientation);
        angular_velocity += world_inertia_tensor * angular_momentum;
    }

}


impulse_response :: (rb0: *Rigid_Body, rb1: *Rigid_Body) {
    
}


AABB :: struct {
    center: Vector3;
    halfs: Vector3;
}

make_AABB :: (center: Vector3, widths: Vector3) -> AABB {
    o: AABB = ---;
    o.center = center;
    o.halfs = widths * 0.5;
    return o;
}

Sphere :: struct {
    center: Vector3;
    radius: float;
}

moment_of_inertia :: (s: Sphere, body: Rigid_Body) -> Matrix3 {
    m: Matrix3;
    t := 2.0 * ((1.0 / body.inverse_mass) * s.radius * s.radius) / 5.0;
    m.m[0][0] = t;
    m.m[1][1] = t;
    m.m[2][2] = t;
    return m;
}

moment_of_inertia :: (b: AABB, body: Rigid_Body) -> Matrix3 {
    w2 := b.halfs.x*2;
    w2 = w2*w2;

    h2 := b.halfs.y*2;
    h2 = h2*h2;

    d2 := b.halfs.z*2;
    d2 = d2*d2;

    mass := (1.0 / 12.0) * (1.0 / body.inverse_mass);

    m: Matrix3;
    m.m[0][0] = mass * (h2 + d2);
    m.m[1][1] = mass * (w2 + d2);
    m.m[2][2] = mass * (w2 + h2);
    return m;
}

gjk_support :: (a: AABB, dir: Vector3) -> Vector3 {
    n := normalize(dir);

    min := a.center - a.halfs;
    max := a.center + a.halfs;

    out: Vector3 = ---;
    if n.x < 0 out.x = min.x;
    else out.x = max.x;
    if n.y < 0 out.y = min.y;
    else out.y = max.y;
    if n.z < 0 out.z = min.z;
    else out.z = max.z;
    return out;
}

gjk_support :: (a: Sphere, dir: Vector3) -> Vector3 {
    return a.center + (normalize(dir) * a.radius);
}

gjk_support :: (a: $T, b: $R, dir: Vector3) -> Support_Point {
    p: Support_Point = ---;
    p.val_a = gjk_support(a, dir);
    p.val_b = gjk_support(b, -dir);
    p.val = p.val_a - p.val_b;
    return p;
}

same_direction :: (a: Vector3, b: Vector3) -> bool {
    return dot(a, b) > 0;
}

Support_Point :: struct {
    val: Vector3;
    val_a: Vector3;
    val_b: Vector3;
}

operator== :: (a: Support_Point, b: Support_Point) -> bool {
    return a.val == b.val; // ignore val_a and val_b for now
}

Simplex :: struct {
    a: Support_Point;
    b: Support_Point;
    c: Support_Point;
    d: Support_Point;
    count: u8;
}

add :: (using s: *Simplex, new_a: Support_Point) {
    if count == {
    case 0;
        a = new_a;
        count += 1;
		return;
    case 1;
        b = a;
        a = new_a;
        count += 1;
		return;
    case 2;
        c = b;
        b = a;
        a = new_a;
        count += 1;
		return;
    case 3;
        d = c;
        c = b;
        b = a;
        a = new_a;
        count += 1;
        return;
    }

    assert(false);
}

set :: (using s: *Simplex, args: .. Support_Point) {
    assert(args.count < 5);
    s.count = xx args.count;

    if args.count s.a = args[0];
    if args.count > 1 s.b = args[1];
    if args.count > 2 s.c = args[2];
    if args.count > 3 s.d = args[3];
}

do_triange_simplex :: (sim: *Simplex, a: Support_Point, b: Support_Point, c: Support_Point, ao: Vector3) -> Vector3 {
    ab := b.val - a.val;
    ac := c.val - a.val;
    abc := cross(ab, ac);
    v := __closest_point_triangle_to_point(a.val, b.val, c.val, ORIGIN);
    if length(v) < (EPSILON * EPSILON) {
        set(sim, sim.b, sim.c);
        return ao;
    }
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


do_simplex :: (sim: *Simplex, a: Support_Point) -> bool, Vector3 {
    ao := -a.val;

    if sim.count < 2 { // we should never actually hit these cases
        assert(false);
        return false, ao;
    }

    if sim.count == 2 {
        ab := sim.b.val - a.val;
        if same_direction(ab, ao) {
            return false, cross(ab, cross(ao, ab));
        } else {
            set(sim, a);
            return false, ao;
        }
    } else if sim.count == 3 {
        return false, do_triange_simplex(sim, a, sim.b, sim.c, ao);
    } else if sim.count == 4 {
        // bcd is our old triangle and we already know that the origin is in the direction of the normal of bcd
        // add_normal(m, c, b, d, green);
        // add_normal(m, a, b, c, green);
        // add_normal(m, a, c, d, green);
        // add_normal(m, a, d, b, green);

        bv := sim.b.val;
        cv := sim.c.val;
        dv := sim.d.val;
        av := a.val;

        abc := cross(bv - av, cv - av);
        acd := cross(cv - av, dv - av);
        adb := cross(dv - av, bv - av);
        if same_direction(abc, ao) {
            return false, do_triange_simplex(sim, a, sim.b, sim.c, ao);
        } else if same_direction(acd, ao) {
            return false, do_triange_simplex(sim, a, sim.c, sim.d, ao);
        } else if same_direction(adb, ao) {
            return false, do_triange_simplex(sim, a, sim.d, sim.b, ao);
        } else {
            return true, ao;
        }
    }

    assert(false);
    return false, ao;
}

do_gjk :: (obja: $T, objb: $R) -> bool, Simplex {
    sim: Simplex;
    d := normalize(make_Vector3(1, 1, 0));
    s := gjk_support(obja, objb, d);
    add(*sim, s);
    d = normalize(make_Vector3(1, -1, 0));

    while true {
        a := gjk_support(obja, objb, d);
        if dot(a.val, d) < 0 return false, sim;
        add(*sim, a);

        intersects: bool;
        intersects, d = do_simplex(*sim, a);
        if intersects return true, sim;
    }

    return false, sim;
}

ORIGIN: Vector3;

Contact_Point :: struct {
    normal: Vector3;
    dist: float;
    point: Vector3;
}

Entry :: struct {
    p: [3] Support_Point;
    
    v: Vector3;
    vlen: float;
    y: [3] float;
    
    adj: [3] *Entry;
    j: [3] s32;
    internal: bool;
    obsolete: bool;
}

make_Entry :: (a: Support_Point, b: Support_Point, c: Support_Point) -> *Entry {
    e := New(Entry);
    e.p[0] = a;
    e.p[1] = b;
    e.p[2] = c;

    av := a.val;
    bv := b.val;
    cv := c.val;

    e.v, e.y[0], e.y[1], e.y[2] = __closest_point_triangle_to_point(av, bv, cv, ORIGIN);
    e.vlen = dot(e.v, e.v);
    assert(e.vlen > 0);
    internal := (e.y[0] >= 0 && e.y[0] <= 1) && (e.y[1] >= 0 && e.y[1] <= 1) && (e.y[2] >= 0 && e.y[2] <= 1);
    e.internal = internal;
    return e;
}

Set :: struct {
    e: *Entry;
    i: s32;
}

silhouette :: (e: *Entry, i: s32, w: Vector3, E: *[..] Set) {
    if !e.obsolete {
        if dot(e.v, w) < dot(e.v, e.v) {
            s: Set = ---;
            s.e = e;
            s.i = i;
            array_add(E, s);
        } else {
            e.obsolete = true;
            i0 := (i + 1) % 3;
            i1 := (i + 2) % 3;
            silhouette(e.adj[i0], e.j[i0], w, E);
            silhouette(e.adj[i1], e.j[i1], w, E);
        }
    }
}

do_epa :: (sim: Simplex, obja: $T, objb: $R) -> Contact_Point {
    Q: [..] *Entry;
    mu := 1000000.0;

    {
        a := sim.a;
        b := sim.b;
        c := sim.c;
        d := sim.d;

        cbd := make_Entry(c, b, d);
        abc := make_Entry(a, b, c);
        acd := make_Entry(a, c, d);
        adb := make_Entry(a, d, b);

        abc.adj[0] = adb;
        abc.adj[1] = cbd;
        abc.adj[2] = acd;
        abc.j[0] = 0;
        abc.j[1] = 0;
        abc.j[2] = 2;

        cbd.adj[0] = abc;
        cbd.adj[1] = adb;
        cbd.adj[2] = acd;
        cbd.j[0] = 1;
        cbd.j[1] = 1;
        cbd.j[2] = 1;
        
        acd.adj[0] = abc;
        acd.adj[1] = cbd;
        acd.adj[2] = adb;
        acd.j[0] = 2;
        acd.j[1] = 2;
        acd.j[2] = 0;

        adb.adj[0] = acd;
        adb.adj[1] = cbd;
        adb.adj[2] = abc;
        adb.j[0] = 0;
        adb.j[1] = 1;
        adb.j[2] = 2;

        array_add(*Q, cbd);
        array_add(*Q, abc);
        array_add(*Q, acd);
        array_add(*Q, adb);
    }

    cp: Contact_Point;
    while Q.count {
        entry := pop(*Q);

        if !entry.obsolete {
            v := entry.v;
            w := gjk_support(obja, objb, -v);
            mu = min(mu, dot(w.val, v));

            {
                cp.normal = normalize(v);
                cp.dist = length(v);

                a := entry.p[0].val_a;
                b := entry.p[1].val_a;
                c := entry.p[2].val_a;
                cp.point = a*entry.y[0] + b*entry.y[1] + c*entry.y[2];
            }

            if entry.vlen < mu {
                entry.obsolete = true;
                E: [..] Set;

                for 0..2 {
                    silhouette(entry.adj[it], entry.j[it], w.val, *E);
                }

                new_ents: [..] *Entry;
                for E {
                    ex := it.e;
                    i := it.i;
                    y := make_Entry(ex.p[(i+1)%3], entry.p[i], w);
                    y.adj[0] = ex;
                    y.j[0] = i;
                    ex.adj[i] = y;
                    ex.j[i] = 0;

                    array_add(*new_ents, y);
                }

                for new_ents {
                    ex1 := new_ents[(it_index+1) % new_ents.count];

                    it.adj[1] = ex1;
                    it.j[1] = 2;
                    ex1.adj[2] = it;
                    ex1.j[2] = 1;

                    if it.internal {
                        array_add(*Q, it);
                    }
                }
            } else {
                break;
            }
        }
    }
    return cp;
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


// based on Erin Catto's http://box2d.org/2014/02/computing-a-basis/
compute_basis :: (a: Vector3) -> Vector3, Vector3 {
    b: Vector3 = ---;
    if fabs(a.x) > 0.57735 {
        b.x =  a.y;
        b.y = -a.x;
        b.z =  0;
    } else {
        b.x =  0;
        b.y =  a.z;
        b.z = -a.y;
    }

    b = normalize(b);
    c := cross(a, b);
    return b, c;
}

// @Return point on triangle; barycentric coordinates
closest_point_triangle_to_point :: (v0: Vector3, v1: Vector3, v2: Vector3, p: Vector3) -> Vector3, float, float, float {
    u := v1-v0;
    v := v2-v0;

    n := cross(u, v);
    w := p - v0;

    nl := dot(n, n);
    y := dot(cross(u, w), n) / nl;
    b := dot(cross(w, v), n) / nl;
    a := 1 - y - b;
    return v0*a + v1*b + v2*y, a, b, y;
}

// from Eberly's geometric tools https://www.geometrictools.com/Documentation/DistancePoint3Triangle3.pdf
// this can probably be simplified by just returing base, v1, v2 when the point q on the triangle plane is
// in regions 2, 4, or 6; this should work fine for the time being. -josh 7 November 2017
__closest_point_triangle_to_point :: (base: Vector3, v1: Vector3, v2: Vector3, target_point: Vector3) -> Vector3, float, float, float {
    base_to_point := base - target_point;
    e0 := v1 - base;
    e1 := v2 - base;

    a := dot(e0, e0);
    b := dot(e0, e1);
    c := dot(e1, e1);
    d := dot(e0, base_to_point);
    e := dot(e1, base_to_point);
    f := dot(base_to_point, base_to_point);

    s := b*e - c*d;
    t := b*d - a*e;
    det := a*c - b*b;

    if (s+t) <= det {
        if s < 0 {
            if t < 0 {
                t = 0;
                
                if -d >= a
                    s = 1;
                else
                    s = -d/a;
            } else {
                s = 0;

                if e >= 0
                    t = 0;
                else if -e >= c
                    t = 1;
                else
                    t = -e/c;
            }
        } else if t < 0 {
            t = 0;
            if d >= 0
                s = 0;
            else if -d >= a
                s = 1;
            else
                s = -d/a;
        } else {
            invdet := 1.0 / det;
            s *= invdet;
            t *= invdet;
        }
    } else {
        if s < 0 {
            t0 := b + d;
            t1 := c + e;

            if t1 > t0 {
                n := t1 - t0;
                den := a - 2*b + c;

                if n >= den
                    s = 1;
                else
                    s = n / den;

                t = 1 - s;
            } else {
                s = 0;

                if t1 <= 0
                    t = 1;
                if e >= 0
                    t = 0;
                else
                    t = -e/c;
            }
        } else if t < 0 {
            t0 := b + e;
            t1 := a + d;

            if t1 > t0 {
                n := t1 - t0;
                den := a - 2*b + c;

                if n >= den
                    t = 1;
                else
                    t = n / den;

                s = 1 - t;
            } else {
                t = 0;

                if t1 <= 0
                    s = 1;
                if d >= 0
                    s = 0;
                else
                    s = -d/a;
            }
        } else {
            n := (c + e) - (b + d);
            if n <= 0
                s = 0;
            else {
                den := a - 2*b + c;

                if n >= den
                    s = 1;
                else
                    s = n / den;
            }

            t = 1 - s;
        }
    }

    return base + e0*s + e1*t, s, t, 1.0 - (s+t);
}


// old stuff
/*

Segment :: struct {
    origin:    Vector3;
    direction: Vector3;
}

make_Segment :: (a: Vector3, b: Vector3) -> Segment {
    s: Segment = ---;
    s.origin = a;
    s.direction = b - a;
    return s;
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
*/