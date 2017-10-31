
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

do_simplex :: (points: *[..] Vector3, a: Vector3) -> Vector3, bool {
    o: Vector3; // (0, 0, 0)
    ao := o - a;
    dir: Vector3 = ---;

    if points.count == 2 {
        b := points[0];
        ab := b - a;
        if same_direction(ab, ao) {
            points[0] = a;
            points[1] = b;
            dir = cross(cross(ab, ao), ab);
        } else {
            points[0] = a;
            points.count = 1;
            dir = ao;
        }
    } else if points.count == 3 {
        c := points[0];
        b := points[1];

        ab := b - a;
        ac := c - a;
        abc := cross(ab, ac);

        if same_direction(cross(abc, ac), ao) {
            if same_direction(ac, ao) {
                points[0] = a;
                points[1] = c;
                points.count = 2;
                dir = cross(cross(ac, ao), ac);
            } else if same_direction(ab, ao) {
                points[0] = a;
                points[1] = b;
                points.count = 2;
                dir = cross(cross(ab, ao), ab);
            } else {
                points[0] = a;
                points.count = 1;
                dir = ao;
            }
        } else if same_direction(cross(ab, abc), ao) {
            if same_direction(ab, ao) {
                points[0] = a;
                points[1] = b;
                points.count = 2;
                dir = cross(cross(ab, ao), ab);
            } else {
                points[0] = a;
                points.count = 1;
                dir = ao;
            }
        } else if same_direction(abc, ao) {
            points[0] = a;
            points[1] = b;
            points[2] = c;
            dir = abc;
        } else {
            points[0] = a;
            points[1] = c;
            points[2] = b;
            dir = -abc;
        }
    } else if points.count == 4 {

        return dir, true;
    }

    return dir, false;
}

do_gjk :: () -> bool {
    points: [..] Vector3;
    s := gjk_support(make_Vector3(0, 1, 0));
    array_add(*points, s);
    d := -s;

    while true {
        a := gjk_support(d);
        if dot(a, d) < 0 return false;
        array_add(*points, a);

        intersects: bool = ---;
        d, intersects = do_simplex(*points, d);
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
