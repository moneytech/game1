
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
    b: VectorT;
    c: VectorT;
    d: VectorT;

    count: u8;

    penetration: VectorT;
}

add :: (using s: *Simplex($T), a: T) {
    if count == {
     case 0;
        b = a;
        count += 1;
     case 1;
        c = b;
        b = a;
        count += 1;
    case 2;
        d = c;
        c = b;
        b = a;
        count += 1;
     case;
        assert(false);
    }
}

do_simplex :: (sim: *Simplex($VectorType), a: VectorType) -> bool, VectorType {
    if sim.count < 2 { // we should never actually hit these cases
        assert(false);
        return false;
    }

    ao := -a;

    if sim.count == 2 {
        ab := sim.b - a;
        if same_direction(ab, ao) {
            return false, cross(cross(ab, ao), ab);
        } else {
            return false, ao;
        }
    }
}

do_gjk :: (obja: Sphere, objb: Sphere) -> bool {
    sim: Simplex(Vector3);
    d := make_Vector3(0, 1, 0);
    s := gjk_support(obja, d) - gjk_support(objb, -d);
    add(*sim, s);
    d = -s;

    while true {
        a := gjk_support(obja, d) - gjk_support(objb, -d);
        if dot(a, d) < 0 return false;
        add(*sim, a);

        intersects: bool;
        intersects, d = do_simplex(*sim, d);
        if intersects break;
    }

    return true;
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
