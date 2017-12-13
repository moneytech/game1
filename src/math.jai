

// vector math

clamp :: (val: float, min: float, max: float) -> float #c_callback {
    if (val > max) return max;
    if (val < min) return min;
    return val;
}

Vector4 :: struct {
    x: float;
    y: float;
    z: float;
    w: float;
}

make_Vector4 :: (v: Vector3, w: float) -> Vector4 {
    o: Vector4 = ---;
    o.x = v.x;
    o.y = v.y;
    o.z = v.z;
    o.w = w;
    return o;
}

make_Vector4 :: (x: float, y: float, z: float, w: float) -> Vector4 {
    o: Vector4 = ---;
    o.x = x;
    o.y = y;
    o.z = z;
    o.w = w;
    return o;
}

Vector3 :: struct {
    x: float;
    y: float;
    z: float;
}

make_Vector3 :: (x: float, y: float, z: float) -> Vector3 {
    v: Vector3 = ---;
    v.x = x;
    v.y = y;
    v.z = z;
    return v;
}

make_Vector3 :: (i: Vector4) -> Vector3 {
    v: Vector3 = ---;
    v.x = i.x;
    v.y = i.y;
    v.z = i.z;
    return v;
}

operator== :: (a: Vector3, b: Vector3) -> bool #c_callback {
    return a.x == b.x && a.y == b.y && a.z == b.z;
}

operator+ :: (a: Vector3, b: Vector3) -> Vector3 {
    out: Vector3 = ---;
    out.x = a.x + b.x;
    out.y = a.y + b.y;
    out.z = a.z + b.z;
    return out;
}

operator- :: (a: Vector3, b: Vector3) -> Vector3 {
    out: Vector3 = ---;
    out.x = a.x - b.x;
    out.y = a.y - b.y;
    out.z = a.z - b.z;
    return out;
}

operator- :: (a: Vector3) -> Vector3 {
    out: Vector3 = ---;
    out.x = -a.x;
    out.y = -a.y;
    out.z = -a.z;
    return out;
}

operator* :: (a: Vector3, s: float) -> Vector3 #symmetric {
    out: Vector3 = ---;
    out.x = a.x * s;
    out.y = a.y * s;
    out.z = a.z * s;
    return out;
}

operator* :: (a: Vector3, f64: float64) -> Vector3 #symmetric {
    s := cast(float) f64;
    out: Vector3 = ---;
    out.x = a.x * s;
    out.y = a.y * s;
    out.z = a.z * s;
    return out;
}

mul :: (a: Vector3, b: Vector3) -> Vector3 {
    out: Vector3 = ---;
    out.x = a.x * b.x;
    out.y = a.y * b.y;
    out.z = a.z * b.z;
    return out;
}

dot :: (a: Vector3, b: Vector3) -> float #c_callback {
    return a.x*b.x + a.y*b.y + a.z*b.z;
}

cross :: (a: Vector3, b: Vector3) -> Vector3 {
    out: Vector3 = ---;
    out.x = a.y*b.z - a.z*b.y;
    out.y = a.z*b.x - a.x*b.z;
    out.z = a.x*b.y - a.y*b.x;
    return out;
}

length :: (v: Vector3) -> float #c_callback {
    return sqrt(v.x*v.x + v.y*v.y + v.z*v.z);
}

normalize :: (v: Vector3) -> Vector3 {
    out: Vector3 = ---;
    len := length(v);
    if (len == 0) return v;
    out.x = v.x / len;
    out.y = v.y / len;
    out.z = v.z / len;
    return out;
}

Vector2 :: struct {
    x: float;
    y: float;
}

make_Vector2 :: (x: float, y: float) -> Vector2 {
    v: Vector2 = ---;
    v.x = x;
    v.y = y;
    return v;
}

operator+ :: (a: Vector2, b: Vector2) -> Vector2 {
    out: Vector2 = ---;
    out.x = a.x + b.x;
    out.y = a.y + b.y;
    return out;
}

operator- :: (a: Vector2, b: Vector2) -> Vector2 {
    out: Vector2 = ---;
    out.x = a.x - b.x;
    out.y = a.y - b.y;
    return out;
}

operator* :: (a: Vector2, s: float) -> Vector2 #symmetric {
    out: Vector2 = ---;
    out.x = a.x * s;
    out.y = a.y * s;
    return out;
}

operator* :: (a: Vector2, f64: float64) -> Vector2 #symmetric {
    s := cast(float) f64;
    out: Vector2 = ---;
    out.x = a.x * s;
    out.y = a.y * s;
    return out;
}

dot :: (a: Vector2, b: Vector2) -> float #c_callback {
    return a.x*b.x + a.y*b.y;
}

length :: (v: Vector2) -> float #c_callback {
    return sqrt(v.x*v.x + v.y*v.y);
}


normalize :: (v: Vector2) -> Vector2 {
    out: Vector2 = ---;
    len := length(v);
    if (len == 0) return v;
    out.x = v.x / len;
    out.y = v.y / len;
    return out;
}

Quaternion :: struct {
    w: float;
    x: float;
    y: float;
    z: float;
}

// Radians
set_angle_vector :: (angle: float, vx: float, vy: float, vz: float) -> Quaternion {
	q: Quaternion = ---;
    s: float = sin(angle / 2);
    q.w = cos(angle / 2);
    q.x = vx * s;
    q.y = vy * s;
    q.z = vz * s;
    return q;
}

get_euler_angles :: (using q: Quaternion) -> float64, float64, float64 {
    phi := atan2(y*z + w*x, 0.5 - (x*x + y*y));
    theta := asin(-2.0 * (x*z - w*y));
    gamma := atan2(x*y + w*z, 0.5 - (y*y + z*z));
    return phi, theta, gamma;
}

operator* :: (q0: Quaternion, q1: Quaternion) -> Quaternion {
    o: Quaternion = ---;
    dot := q0.x*q1.x + q0.y*q1.y + q0.z*q1.z;
    o.w = q0.w*q1.w - dot;
    o.x = q0.w*q1.x + q1.w*q0.x + (q0.y*q1.z - q0.z*q1.y);
    o.y = q0.w*q1.y + q1.w*q0.y + (q0.z*q1.x - q0.x*q1.z);
    o.z = q0.w*q1.z + q1.w*q0.z + (q0.x*q1.y - q0.y*q1.x);
    return o;
}

operator* :: (q: Quaternion, v: Vector3) -> Vector3 {
    qvec := make_Vector3(q.x, q.y, q.z);

    uv := cross(qvec, v);
    uuv := cross(qvec, uv);
    uv = uv * (2.0 * q.w);
    uuv = uuv * 2;

    return v + uv + uuv;
}

operator* :: (q: Quaternion, s: float) -> Quaternion #symmetric {
    o: Quaternion = ---;
    o.w = q.w * s;
    o.x = q.x * s;
    o.y = q.y * s;
    o.z = q.z * s;
    return o;
}

operator* :: (q: Quaternion, f64: float64) -> Quaternion #symmetric {
    s := cast(float) f64;
    o: Quaternion = ---;
    o.w = q.w * s;
    o.x = q.x * s;
    o.y = q.y * s;
    o.z = q.z * s;
    return o;
}

 operator+ :: (q0: Quaternion, q1: Quaternion) -> Quaternion {
    o: Quaternion = ---;
    o.w = q0.w + q1.w;
    o.x = q0.x + q1.x;
    o.y = q0.y + q1.y;
    o.z = q0.z + q1.z;
    return o;
}

operator- :: (q0: Quaternion, q1: Quaternion) -> Quaternion {
    o: Quaternion = ---;
    o.w = q0.w - q1.w;
    o.x = q0.x - q1.x;
    o.y = q0.y - q1.y;
    o.z = q0.z - q1.z;
    return o;
}

length :: (q: Quaternion) -> float #c_callback {
    return sqrt(q.w*q.w + q.x*q.x + q.y*q.y + q.z*q.z);
}

inverse :: (q: Quaternion) -> Quaternion {
    o: Quaternion = ---;
    len_squared := q.w*q.w + q.x*q.x + q.y*q.y + q.z*q.z;
    o.w = q.w / len_squared;
    o.x = -q.x / len_squared;
    o.y = -q.y / len_squared;
    o.z = -q.z / len_squared;
    return o;
}

normalize :: (q: Quaternion) -> Quaternion {
    o: Quaternion = ---;
    len := length(q);
    o.w = q.w / len;
    o.x = q.x / len;
    o.y = q.y / len;
    o.z = q.z / len;
    return o;
}

dot :: (a: Quaternion, b: Quaternion) -> float #c_callback {
    return a.w*b.w + a.x*b.x + a.y*b.y + a.z*b.z;
}

// t 0..1
slerp :: (t: float, q0: Quaternion, q1: Quaternion) -> Quaternion {
    theta := acos(dot(q0, q1)) * t;
    return cos(theta)*q0 + sin(theta)*q1;
}

// t 0..1
nlerp :: (t: float, q0: Quaternion, q1: Quaternion) -> Quaternion {
    return normalize((1 - t) * q0 + t * q1);
}

// 4x4 matrix

Matrix4 :: struct {
	m: [4][4] float;
	#place m;
	flat: [16] float;

    #constructor identity;
}

// float& operator[](unsigned int index) {
//     assert(index >= 0 && index < 16);
//     return flat[index];
// }

determinate :: (using mat: Matrix4) -> float #c_callback {
    return
    m[0][3] * m[1][2] * m[2][1] * m[3][0] - m[0][2] * m[1][3] * m[2][1] * m[3][0] -

    m[0][3] * m[1][1] * m[2][2] * m[3][0] + m[0][1] * m[1][3] * m[2][2] * m[3][0] +

    m[0][2] * m[1][1] * m[2][3] * m[3][0] - m[0][1] * m[1][2] * m[2][3] * m[3][0] -

    m[0][3] * m[1][2] * m[2][0] * m[3][1] + m[0][2] * m[1][3] * m[2][0] * m[3][1] +

    m[0][3] * m[1][0] * m[2][2] * m[3][1] - m[0][0] * m[1][3] * m[2][2] * m[3][1] -

    m[0][2] * m[1][0] * m[2][3] * m[3][1] + m[0][0] * m[1][2] * m[2][3] * m[3][1] +

    m[0][3] * m[1][1] * m[2][0] * m[3][2] - m[0][1] * m[1][3] * m[2][0] * m[3][2] -

    m[0][3] * m[1][0] * m[2][1] * m[3][2] + m[0][0] * m[1][3] * m[2][1] * m[3][2] +

    m[0][1] * m[1][0] * m[2][3] * m[3][2] - m[0][0] * m[1][1] * m[2][3] * m[3][2] -

    m[0][2] * m[1][1] * m[2][0] * m[3][3] + m[0][1] * m[1][2] * m[2][0] * m[3][3] +

    m[0][2] * m[1][0] * m[2][1] * m[3][3] - m[0][0] * m[1][2] * m[2][1] * m[3][3] -

    m[0][1] * m[1][0] * m[2][2] * m[3][3] + m[0][0] * m[1][1] * m[2][2] * m[3][3];
}

//TODO(josh) better calculations
inverse :: (using mat: Matrix4) -> Matrix4 {
    result: Matrix4 = ---;
    result.m[0][0] = m[1][1]*m[2][2]*m[3][3] + m[1][2]*m[2][3]*m[3][1] + m[1][3]*m[2][1]*m[3][2] -
                            m[1][1]*m[2][3]*m[3][2] - m[1][2]*m[2][1]*m[3][3] - m[1][3]*m[2][2]*m[3][1];
    result.m[0][1] = m[0][1]*m[2][3]*m[3][2] + m[0][2]*m[2][1]*m[3][3] + m[0][3]*m[2][2]*m[3][1] -
                            m[0][1]*m[2][2]*m[3][3] - m[0][2]*m[2][3]*m[3][1] - m[0][3]*m[2][1]*m[3][2];
    result.m[0][2] = m[0][1]*m[1][2]*m[3][3] + m[0][2]*m[1][3]*m[3][1] + m[0][3]*m[1][1]*m[3][2] -
                            m[0][1]*m[1][3]*m[3][2] - m[0][2]*m[1][1]*m[3][3] - m[0][3]*m[1][2]*m[3][1];
    result.m[0][3] = m[0][1]*m[1][3]*m[2][2] + m[0][2]*m[1][1]*m[2][3] + m[0][3]*m[1][2]*m[2][1] -
                            m[0][1]*m[1][2]*m[2][3] - m[0][2]*m[1][3]*m[2][1] - m[0][3]*m[1][1]*m[2][2];


    result.m[1][0] = m[1][0]*m[2][3]*m[3][2] + m[1][2]*m[2][0]*m[3][3] + m[1][3]*m[2][2]*m[3][0] -
                            m[1][0]*m[2][2]*m[3][3] - m[1][2]*m[2][3]*m[3][0] - m[1][3]*m[2][0]*m[3][2];
    result.m[1][1] = m[0][0]*m[2][2]*m[3][3] + m[0][2]*m[2][3]*m[3][0] + m[0][3]*m[2][0]*m[3][2] -
                            m[0][0]*m[2][3]*m[3][2] - m[0][2]*m[2][0]*m[3][3] - m[0][3]*m[2][2]*m[3][0];
    result.m[1][2] = m[0][0]*m[1][3]*m[3][2] + m[0][2]*m[1][0]*m[3][3] + m[0][3]*m[1][2]*m[3][0] -
                            m[0][0]*m[1][2]*m[3][3] - m[0][2]*m[1][3]*m[3][0] - m[0][3]*m[1][0]*m[3][2];
    result.m[1][3] = m[0][0]*m[1][2]*m[2][3] + m[0][2]*m[1][3]*m[2][0] + m[0][3]*m[1][0]*m[2][2] -
                            m[0][0]*m[1][3]*m[2][2] - m[0][2]*m[1][0]*m[2][3] - m[0][3]*m[1][2]*m[2][1];

    result.m[2][0] = m[1][0]*m[2][1]*m[3][3] + m[1][1]*m[2][3]*m[3][0] + m[1][3]*m[2][0]*m[3][1] -
                            m[1][0]*m[2][3]*m[3][1] - m[1][1]*m[2][0]*m[3][3] - m[1][3]*m[2][1]*m[3][0];
    result.m[2][1] = m[0][0]*m[2][3]*m[3][1] + m[0][1]*m[2][0]*m[3][3] + m[0][3]*m[2][1]*m[3][0] -
                            m[0][0]*m[2][1]*m[3][3] - m[0][1]*m[2][3]*m[3][0] - m[0][3]*m[2][0]*m[3][1];
    result.m[2][2] = m[0][0]*m[1][1]*m[3][3] + m[0][1]*m[1][3]*m[3][0] + m[0][3]*m[1][0]*m[3][1] -
                            m[0][0]*m[1][3]*m[3][1] - m[0][1]*m[1][0]*m[3][3] - m[0][3]*m[1][1]*m[3][0];
    result.m[2][3] = m[0][0]*m[1][3]*m[2][1] + m[0][1]*m[1][0]*m[2][3] + m[0][3]*m[1][1]*m[2][0] -
                            m[0][0]*m[1][1]*m[2][3] - m[0][1]*m[1][3]*m[2][0] - m[0][3]*m[1][0]*m[2][1];

    result.m[3][0] = m[1][0]*m[2][2]*m[3][1] + m[1][1]*m[2][0]*m[3][2] + m[1][2]*m[2][1]*m[3][0] -
                            m[1][0]*m[2][1]*m[3][2] - m[1][1]*m[2][2]*m[3][0] - m[1][2]*m[2][0]*m[3][1];
    result.m[3][1] = m[0][0]*m[2][1]*m[3][2] + m[0][1]*m[2][2]*m[3][0] + m[0][2]*m[2][0]*m[3][1] -
                            m[0][0]*m[2][2]*m[3][1] - m[0][1]*m[2][0]*m[3][2] - m[0][2]*m[2][1]*m[3][0];
    result.m[3][2] = m[0][0]*m[1][2]*m[3][1] + m[0][1]*m[1][0]*m[3][2] + m[0][2]*m[1][1]*m[3][0] -
                            m[0][0]*m[1][1]*m[3][2] - m[0][1]*m[1][2]*m[3][0] - m[0][2]*m[1][0]*m[3][1];
    result.m[3][3] = m[0][0]*m[1][1]*m[2][2] + m[0][1]*m[1][2]*m[2][0] + m[0][2]*m[1][0]*m[2][1] -
                            m[0][0]*m[1][2]*m[2][1] + m[0][1]*m[1][0]*m[2][2] + m[0][2]*m[1][1]*m[2][0];

    det := 1.0/determinate(result);
    if (det != 0.0) {
        for 0..15 {
            result.flat[it] *= det;
        }
    }
    return result;
}

transpose :: (using mat: Matrix4) -> Matrix4 {
    result := mat;

    result.m[1][0] = m[0][1];
    result.m[2][0] = m[0][2];
    result.m[3][0] = m[0][3];

    result.m[0][1] = m[1][0];
    result.m[2][1] = m[1][2];
    result.m[3][1] = m[1][3];

    result.m[1][2] = m[2][1];
    result.m[0][2] = m[2][0];
    result.m[3][2] = m[2][3];

    result.m[1][3] = m[3][1];
    result.m[2][3] = m[3][2];
    result.m[0][3] = m[3][0];
    return result;
}

operator* :: (using mat: Matrix4, v: Vector4) -> Vector4 {
    result: Vector4 = ---;
    result.x = m[0][0] * v.x + m[0][1] * v.y + m[0][2] * v.z + m[0][3] * v.w;
    result.y = m[1][0] * v.x + m[1][1] * v.y + m[1][2] * v.z + m[1][3] * v.w;
    result.z = m[2][0] * v.x + m[2][1] * v.y + m[2][2] * v.z + m[2][3] * v.w;
    result.w = m[3][0] * v.x + m[3][1] * v.y + m[3][2] * v.z + m[3][3] * v.w;

    return result;
}

operator* :: (using _mat: Matrix4, mat: Matrix4) -> Matrix4 {
    result: Matrix4 = ---;
    result.flat[0] = m[0][0] * mat.m[0][0] + m[0][1] * mat.m[1][0] + m[0][2] * mat.m[2][0] + m[0][3] * mat.m[3][0];
    result.flat[1] = m[0][0] * mat.m[0][1] + m[0][1] * mat.m[1][1] + m[0][2] * mat.m[2][1] + m[0][3] * mat.m[3][1];
    result.flat[2] = m[0][0] * mat.m[0][2] + m[0][1] * mat.m[1][2] + m[0][2] * mat.m[2][2] + m[0][3] * mat.m[3][2];
    result.flat[3] = m[0][0] * mat.m[0][3] + m[0][1] * mat.m[1][3] + m[0][2] * mat.m[2][3] + m[0][3] * mat.m[3][3];

    result.flat[4] = m[1][0] * mat.m[0][0] + m[1][1] * mat.m[1][0] + m[1][2] * mat.m[2][0] + m[1][3] * mat.m[3][0];
    result.flat[5] = m[1][0] * mat.m[0][1] + m[1][1] * mat.m[1][1] + m[1][2] * mat.m[2][1] + m[1][3] * mat.m[3][1];
    result.flat[6] = m[1][0] * mat.m[0][2] + m[1][1] * mat.m[1][2] + m[1][2] * mat.m[2][2] + m[1][3] * mat.m[3][2];
    result.flat[7] = m[1][0] * mat.m[0][3] + m[1][1] * mat.m[1][3] + m[1][2] * mat.m[2][3] + m[1][3] * mat.m[3][3];

    result.flat[8] = m[2][0] * mat.m[0][0] + m[2][1] * mat.m[1][0] + m[2][2] * mat.m[2][0] + m[2][3] * mat.m[3][0];
    result.flat[9] = m[2][0] * mat.m[0][1] + m[2][1] * mat.m[1][1] + m[2][2] * mat.m[2][1] + m[2][3] * mat.m[3][1];
    result.flat[10] = m[2][0] * mat.m[0][2] + m[2][1] * mat.m[1][2] + m[2][2] * mat.m[2][2] + m[2][3] * mat.m[3][2];
    result.flat[11] = m[2][0] * mat.m[0][3] + m[2][1] * mat.m[1][3] + m[2][2] * mat.m[2][3] + m[2][3] * mat.m[3][3];

    result.flat[12] = m[3][0] * mat.m[0][0] + m[3][1] * mat.m[1][0] + m[3][2] * mat.m[2][0] + m[3][3] * mat.m[3][0];
    result.flat[13] = m[3][0] * mat.m[0][1] + m[3][1] * mat.m[1][1] + m[3][2] * mat.m[2][1] + m[3][3] * mat.m[3][1];
    result.flat[14] = m[3][0] * mat.m[0][2] + m[3][1] * mat.m[1][2] + m[3][2] * mat.m[2][2] + m[3][3] * mat.m[3][2];
    result.flat[15] = m[3][0] * mat.m[0][3] + m[3][1] * mat.m[1][3] + m[3][2] * mat.m[2][3] + m[3][3] * mat.m[3][3];

    return result;
}

matrix_screen_space :: (halfWidth: float, halfHeight: float) -> Matrix4 {
	mat: Matrix4;
    mat.m[0][0] = halfWidth;
    mat.m[1][1] =-halfHeight;
    mat.m[0][3] = halfWidth;
    mat.m[1][3] = halfHeight;
    return mat;
}

matrix_viewport :: (x: float, y: float, width: float, height: float) -> Matrix4 {
	scale := matrix_scale(width, height, 0.5);
	trans := matrix_translate(x + x + width, y + y + height, 0.0);
	correction := matrix_translate(-(1.0 / width), -(1.0 / height), 1.0);
    return trans * scale * correction;
}

matrix_rotate :: (degrees: float64, tx: float, ty: float, tz: float) -> Matrix4 {
    result: Matrix4;

    x, y, z := tx, ty, tz;
    length := sqrt(x * x + y * y + z * z);
    if(length == 0.0) return result;
    x /= length;
    y /= length;
    z /= length;

    angle := degrees * (3.14159265359 / 180.0);
    c := cast(float) cos(angle);
    omc := 1.0 - c;
    s := cast(float) sin(angle);

    result.flat[0] = x * x * omc + c;
    result.flat[1] = x * y * omc - z * s;
    result.flat[2] = x * z * omc + y * s;

    result.flat[4] = y * x * omc + z * s;
    result.flat[5] = y * y * omc + c;
    result.flat[6] = y * z * omc - x * s;

    result.m[2][0] = x * z * omc - y * s;
    result.m[2][1] = y * z * omc + x * s;
    result.m[2][2] = z * z * omc + c;
    return result;
}

matrix_rotate :: (q: Quaternion) -> Matrix4 {
    rta := sqrt(1 - q.w*q.w);
    if (rta == 0) {
        return matrix_identity();
    }
    theta := acos(q.w) * 2;
    x := q.x / rta;
    y := q.y / rta;
    z := q.z / rta;
    return matrix_rotate(theta * (180.0 /3.14159265359), x, y, z);
}

matrix_translate :: (x: float, y: float, z: float) -> Matrix4 {
    mat: Matrix4;
    mat.m[0][3] = x;
    mat.m[1][3] = y;
    mat.m[2][3] = z;
    return mat;
}

matrix_translate :: (using v: Vector3) -> Matrix4 {
    mat: Matrix4;
    mat.m[0][3] = x;
    mat.m[1][3] = y;
    mat.m[2][3] = z;
    return mat;
}

matrix_scale :: (x: float, y: float, z: float) -> Matrix4 {
    mat: Matrix4;
    mat.m[0][0] = x;
    mat.m[1][1] = y;
    mat.m[2][2] = z;
    return mat;
}

matrix_perspective :: (fov: float, aspect: float, _near: float, _far: float) -> Matrix4 {
    t := cast(float) tan(fov * 3.14159 / 720.0) * _near;
    b := -t;
    l := aspect * b;
    r := aspect * t;
    return matrix_frustum(l, r, b, t, _near, _far);
}

viewport_scale :: (fov: float, aspect: float, _near: float) -> float, float {
    t := cast(float) tan(fov * 3.14159 / 720.0) * _near;
    r := aspect * t;
    return t*2, r*2; 
}

matrix_frustum :: (left: float, right: float, bottom: float, top: float, _near: float, _far: float) -> Matrix4 {
    mat: Matrix4;

    A := (right + left) / (right - left);
    B := (top + bottom) / (top - bottom);
    C := - (_far + _near) / (_far - _near);
    D := - (2 * _far * _near) / (_far - _near);
    
    mat.m[0][0] = 2 * _near / (right - left);
    mat.m[0][2] = A;
    mat.m[1][1] = 2 * _near / (top - bottom);
    mat.m[1][2] = B;
    mat.m[2][2] = C;
    mat.m[2][3] = D;
    mat.m[3][2] = -1.0;
    mat.m[3][3] = 0.0;
    return mat;
}

matrix_ortho :: (left: float, right: float, bottom: float, top: float, _near: float, _far: float) -> Matrix4 {
    mat: Matrix4;
    mat.m[0][0] = 2.0 / (right - left);
    mat.m[0][3] = - (right + left) / (right - left);
    mat.m[1][1] = 2.0 / (top - bottom);
    mat.m[1][3] = - (top + bottom) / (top - bottom);
    mat.m[2][2] = - 2.0 / (_far - _near);
    mat.m[2][3] = - (_far + _near) / (_far - _near);
    return mat;
}

matrix_identity :: () -> Matrix4 {
    mat: Matrix4;
    return mat;
}

// 3x3 matrix

Matrix3 :: struct {
    m: [3][3] float;
    #place m;
    flat: [9] float;

    #constructor identity;
}

orthonormalize :: (using _mat: *Matrix3) {
    // hmm.. this is column vectors but i'm pretty sure we use row vectors
    // so maybe we have to reverse these indices!
    x := make_Vector3(m[0][0], m[1][0], m[2][0]);
    y := make_Vector3(m[0][1], m[1][1], m[2][1]);

    x = normalize(x);
    z := normalize(cross(x, y));
    y = normalize(cross(z, x));

    m[0][0] = x.x;
    m[1][0] = x.y;
    m[2][0] = x.z;

    m[0][1] = y.x;
    m[2][1] = y.z;
    m[1][1] = y.y;

    m[0][2] = z.x;
    m[2][2] = z.z;
    m[1][2] = z.y;

}

matrix_orientation :: (degrees: float64, tx: float, ty: float, tz: float) -> Matrix3 {
    result: Matrix3;

    x, y, z := tx, ty, tz;
    length := sqrt(x * x + y * y + z * z);
    if length == 0.0 return result;
    x /= length;
    y /= length;
    z /= length;

    angle := degrees * (3.14159265359 / 180.0);
    c := cast(float) cos(angle);
    omc := 1.0 - c;
    s := cast(float) sin(angle);

    result.flat[0] = x * x * omc + c;
    result.flat[1] = x * y * omc - z * s;
    result.flat[2] = x * z * omc + y * s;

    result.flat[3] = y * x * omc + z * s;
    result.flat[4] = y * y * omc + c;
    result.flat[5] = y * z * omc - x * s;

    result.flat[6] = x * z * omc - y * s;
    result.flat[7] = y * z * omc + x * s;
    result.flat[8] = z * z * omc + c;
    return result;
}

operator* :: (using mat: Matrix3, v: Vector3) -> Vector3 {
    result: Vector3 = ---;
    result.x = m[0][0] * v.x + m[0][1] * v.y + m[0][2] * v.z;
    result.y = m[1][0] * v.x + m[1][1] * v.y + m[1][2] * v.z;
    result.z = m[2][0] * v.x + m[2][1] * v.y + m[2][2] * v.z;
    return result;
}

operator* :: (v: Vector3, using mat: Matrix3) -> Vector3 {
    result: Vector3 = ---;
    result.x = m[0][0] * v.x + m[1][0] * v.y + m[2][0] * v.z;
    result.y = m[0][1] * v.x + m[1][1] * v.y + m[2][1] * v.z;
    result.z = m[0][2] * v.x + m[1][2] * v.y + m[2][2] * v.z;
    return result;
}

operator* :: (using _mat: Matrix3, mat: Matrix3) -> Matrix3 {
    result: Matrix3 = ---;
    result.flat[0] = m[0][0] * mat.m[0][0] + m[0][1] * mat.m[1][0] + m[0][2] * mat.m[2][0];
    result.flat[1] = m[0][0] * mat.m[0][1] + m[0][1] * mat.m[1][1] + m[0][2] * mat.m[2][1];
    result.flat[2] = m[0][0] * mat.m[0][2] + m[0][1] * mat.m[1][2] + m[0][2] * mat.m[2][2];

    result.flat[0] = m[1][0] * mat.m[0][0] + m[1][1] * mat.m[1][0] + m[1][2] * mat.m[2][0];
    result.flat[1] = m[1][0] * mat.m[0][1] + m[1][1] * mat.m[1][1] + m[1][2] * mat.m[2][1];
    result.flat[2] = m[1][0] * mat.m[0][2] + m[1][1] * mat.m[1][2] + m[1][2] * mat.m[2][2];

    result.flat[0] = m[2][0] * mat.m[0][0] + m[2][1] * mat.m[1][0] + m[2][2] * mat.m[2][0];
    result.flat[1] = m[2][0] * mat.m[0][1] + m[2][1] * mat.m[1][1] + m[2][2] * mat.m[2][1];
    result.flat[2] = m[2][0] * mat.m[0][2] + m[2][1] * mat.m[1][2] + m[2][2] * mat.m[2][2];
    return result;
}

operator+ :: (m0: Matrix3, m1: Matrix3) -> Matrix3 {
    o: Matrix3 = ---;

    for m0.flat {
        o.flat[it_index] = it + m1.flat[it_index];
    }

    return o;
}

operator* :: (_mat: Matrix3, s: float) -> Matrix3 #symmetric {
    o: Matrix3 = ---;
    for _mat.flat {
        o.flat[it_index] = it * s;
    }
    return o;
}

transpose :: (using _mat: Matrix3) -> Matrix3 {
    o: Matrix3 = ---;
    o.m[0][0] = m[0][0];
    o.m[1][0] = m[0][1];
    o.m[2][0] = m[0][2];

    o.m[0][1] = m[1][0];
    o.m[1][1] = m[1][1];
    o.m[2][1] = m[1][2];

    o.m[0][2] = m[2][0];
    o.m[1][2] = m[2][1];
    o.m[2][2] = m[2][2];
    return o;
}

to_mat4 :: (m: Matrix3) -> Matrix4 {
    out: Matrix4;
    out.m[0][0] = m.m[0][0];
    out.m[0][1] = m.m[0][1];
    out.m[0][2] = m.m[0][2];

    out.m[1][0] = m.m[1][0];
    out.m[1][1] = m.m[1][1];
    out.m[1][2] = m.m[1][2];

    out.m[2][0] = m.m[2][0];
    out.m[2][1] = m.m[2][1];
    out.m[2][2] = m.m[2][2];
    return out;
}


// @Note I don't remember if this is actually needed since
// the ~ operator on a vector is equivalent to a cross product
// (unless we need to multiply this matrix against the orientation ?)
// -josh 18 November 2017
operator~ :: (v: Vector3) -> Matrix3 {
    out: Matrix3 = ---;
    out.m[0][0] = 0;
    out.m[0][1] = -v.z;
    out.m[0][2] = v.y;

    out.m[1][0] = v.z;
    out.m[1][1] = 0;
    out.m[1][2] = -v.x;

    out.m[2][0] = -v.y;
    out.m[2][1] = v.x;
    out.m[2][2] = 0;
    return out;
}


// floating point stuff


EPSILON :: 0.000001;

max :: (min: $T, a: T, b: T) -> T {
    val := max(a, b);
    if val < min
        val = min;
    return val;
}

floats_are_equal :: inline (a: $T, b: T) -> bool {
    return fabs(a - b) <= EPSILON * max(cast(float64) 1.0, fabs(a), fabs(b));
}

#scope_file

identity :: (mat: *Matrix4) {
    memset(mat, 0, size_of(Matrix4));
	mat.m[0][0] = 1.0;
    mat.m[1][1] = 1.0;
    mat.m[2][2] = 1.0;
    mat.m[3][3] = 1.0;
}

identity :: (mat: *Matrix3) {
    memset(mat, 0, size_of(Matrix3));
    mat.m[0][0] = 1.0;
    mat.m[1][1] = 1.0;
    mat.m[2][2] = 1.0;
}
