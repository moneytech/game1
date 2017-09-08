
#pragma once

#ifdef WIN32
#define Rectangle Windows_Rectangle
#include <Windows.h>
#undef Rectangle
#endif

#include <cstdlib>
#include <cassert>

#include <stdint.h>
typedef int64_t s64;
typedef int32_t s32;
typedef int16_t s16;
typedef int8_t  s8;

typedef uint64_t u64;
typedef uint32_t u32;
typedef uint16_t u16;
typedef uint8_t  u8;


// @Temporary
inline void *__get_cleared_mem(size_t size) {
    void *out = malloc(size);
    memset(out, 0, size);
    return out;
}
#define GET_MEMORY_ZERO_INIT(type) ((type *)__get_cleared_mem(sizeof(type)))
#define GET_MEMORY(type) ((type *)malloc(sizeof(type)))
#define GET_MEMORY_SIZED(num) ((char *)malloc(num))
#define FREE_MEMORY(ptr) (free(ptr))

template <typename T>
struct Array {
	T *data = nullptr;
    size_t reserved = 0;
	size_t count = 0;

	void reserve(size_t amount) {
        assert(amount >= 0);

		if (amount <= count) assert(0);

		T *new_data = (T *)malloc(sizeof(T) * amount);
		memcpy(new_data, data, sizeof(T) * count);
		free(data);
		data = new_data;
		reserved = amount;
	}

	T &operator[] (s64 index) {
		assert(index >= 0 && index < count);
		return data[index];
	}

	void add(T item) {
		if ((count+1) >= reserved) reserve((count+1) * 2);
		data[count] = item;
		count++;
	}

	void remove(s64 index) {
		assert(index >= 0 && index < count);
		if ((count-(index+1)) > 0)
			memmove(&data[index], &data[index+1], sizeof(T) * (count-(index+1)));
		count--;
	}

	void clear() {
		 count = 0;
	}
};

inline char *copy_c_string(const char *str) {
    u32 len = strlen(str);
    char *out = (char *)GET_MEMORY_SIZED(len + 1);
    memcpy(out, str, len);
    out[len] = 0;
    return out;
}

inline void copy_c_string(char *out, const char *str, u32 nbytes = 0) {
    if (!nbytes) nbytes = strlen(str);
    memcpy(out, str, nbytes);
    out[nbytes] = 0;
}

inline bool compare_c_strings(const char *a, const char *b) {
    u32 a_len = strlen(a), b_len = strlen(b);
    if (a_len != b_len) return false;

    while (*a) {
        if (*a != *b) return false;
        a++;
        b++;
    }

    return true;
}

inline char *concatenate(const char *a, const char *b) {
    u32 la = strlen(a);
    u32 lb = strlen(b);

    char *out = GET_MEMORY_SIZED(la+lb+1);
    memcpy(out, a, la);
    memcpy(out+la, b, lb);
    out[la+lb] = 0;
    return out;
}

// convert '\' to /
inline void convert_slashes(char *str) {
    while (*str++) {
        if (*str == '\\') *str = '/';
    }
}

template <typename T>
struct Hash_Map {
    struct Hash_Entry {
        const char *key;
        Hash_Entry *next;
        T value;
    };

    Hash_Entry table[4096];

    Hash_Map() {
        memset(&table[0], 0, sizeof(Hash_Entry)*4096);
    }

    u32 hash_key(const unsigned char *str) {
        u32 hash = 5381;
        s16 c;

        while (c = *str++)
            hash = ((hash << 5) + hash) + c;

        return hash;
    }

    bool contains_key(const char *str) {
        u32 slot = hash_key((const unsigned char *)str) & (4096-1);
        Hash_Entry *e = &table[slot];

        while (e) {
            if (!e->key)
                break;

            if (compare_c_strings(str, e->key))
                break;

            // if (!e->next) break;
            e = e->next;
        }

        return e->key != nullptr;
    }

    T &operator[](const char *str) {
        u32 slot = hash_key((const unsigned char *)str) & (4096-1);
        Hash_Entry *e = &table[slot];

        while (e) {
            if (!e->key) {
                e->key = copy_c_string(str);
                break;
            }

            if (compare_c_strings(str, e->key))
                break;

            if (!e->next) {
                e->next = GET_MEMORY(Hash_Entry);
                e = e->next;
                e->key = copy_c_string(str);
                e->next = nullptr;
                break;
            }

            e = e->next;
            assert(e);
        }

        return e->value;
    }
};

#include <math.h>

// vector math

inline float clamp(float val, float min, float max) {
    return (val > max) ? max : (val < min) ? min : val;
}

struct Vector4 {
    float x;
    float y;
    float z;
    float w;
};

struct Vector3 {
    float x;
    float y;
    float z;
};

inline Vector3 operator+(const Vector3 &a, const Vector3 &b) {
    Vector3 out;
    out.x = a.x + b.x;
    out.y = a.y + b.y;
    out.z = a.z + b.z;
    return out;
}

inline Vector3 operator-(const Vector3 &a, const Vector3 &b) {
    Vector3 out;
    out.x = a.x - b.x;
    out.y = a.y - b.y;
    out.z = a.z - b.z;
    return out;
}

inline Vector3 operator*(const Vector3 &a, float s) {
    Vector3 out;
    out.x = a.x * s;
    out.y = a.y * s;
    out.z = a.z * s;
    return out;
}

inline Vector3 operator*(float s, const Vector3 &a) {
    Vector3 out;
    out.x = a.x * s;
    out.y = a.y * s;
    out.z = a.z * s;
    return out;
}

inline float dot(const Vector3 &a, const Vector3 &b) {
    return a.x*b.x + a.y*b.y + a.z*b.z;
}

inline Vector3 cross(const Vector3 &a, const Vector3 &b) {
    Vector3 out;
    out.x = a.y*b.z - a.z*b.y;
    out.y = a.z*b.x - a.x*b.z;
    out.z = a.x*b.y - a.y*b.x;
    return out;
}

inline float length(const Vector3 &v) {
    return sqrt(v.x*v.x + v.y*v.y + v.z*v.z);
}

inline Vector3 normalize(const Vector3 &v) {
    Vector3 out;
    float len = length(v);
    if (len == 0) return v;
    out.x = v.x / len;
    out.y = v.y / len;
    out.z = v.z / len;
    return out;
}

struct Vector2 {
    float x;
    float y;
};

inline Vector2 operator+(const Vector2 &a, const Vector2 &b) {
    Vector2 out;
    out.x = a.x + b.x;
    out.y = a.y + b.y;
    return out;
}

inline Vector2 operator-(const Vector2 &a, const Vector2 &b) {
    Vector2 out;
    out.x = a.x - b.x;
    out.y = a.y - b.y;
    return out;
}

inline Vector2 operator*(const Vector2 &a, float s) {
    Vector2 out;
    out.x = a.x * s;
    out.y = a.y * s;
    return out;
}

inline Vector2 operator*(float s, const Vector2 &a) {
    Vector2 out;
    out.x = a.x * s;
    out.y = a.y * s;
    return out;
}

inline float dot(const Vector2 &a, const Vector2 &b) {
    return a.x*b.x + a.y*b.y;
}


struct Quaternion {
    float w;
    float x;
    float y;
    float z;

    // Radians
    void set_angle_vector(float angle, float vx, float vy, float vz) {
        float s = sin(angle / 2);
        w = cos(angle / 2);
        x = vx * s;
        y = vy * s;
        z = vz * s;
    }
};

inline Quaternion operator*(const Quaternion &q0, const Quaternion &q1) {
    Quaternion o;
    float dot = q0.x*q1.x + q0.y*q1.y + q0.z*q1.z;
    o.w = q0.w*q1.w - dot;
    o.x = q0.w*q1.x + q1.w*q0.x + (q0.y*q1.z - q0.z*q1.y);
    o.y = q0.w*q1.y + q1.w*q0.y + (q0.z*q1.x - q0.x*q1.z);
    o.z = q0.w*q1.z + q1.w*q0.z + (q0.x*q1.y - q0.y*q1.x);
    return o;
}

inline Quaternion operator*(const Quaternion &q, float s) {
    Quaternion o;
    o.w = q.w * s;
    o.x = q.x * s;
    o.y = q.y * s;
    o.z = q.z * s;
    return o;
}

inline Quaternion operator*(float s, const Quaternion &q) {
    Quaternion o;
    o.w = q.w * s;
    o.x = q.x * s;
    o.y = q.y * s;
    o.z = q.z * s;
    return o;
}

inline Quaternion operator+(const Quaternion &q0, const Quaternion &q1) {
    Quaternion o;
    o.w = q0.w + q1.w;
    o.x = q0.x + q1.x;
    o.y = q0.y + q1.y;
    o.z = q0.z + q1.z;
    return o;
}

inline Quaternion operator-(const Quaternion &q0, const Quaternion &q1) {
    Quaternion o;
    o.w = q0.w - q1.w;
    o.x = q0.x - q1.x;
    o.y = q0.y - q1.y;
    o.z = q0.z - q1.z;
    return o;
}

inline float length(const Quaternion &q) {
    return sqrt(q.w*q.w + q.x*q.x + q.y*q.y + q.z*q.z);
}

inline Quaternion inverse(const Quaternion &q) {
    Quaternion o;
    float len_squared = q.w*q.w + q.x*q.x + q.y*q.y + q.z*q.z;
    o.w = q.w / len_squared;
    o.x = -q.x / len_squared;
    o.y = -q.y / len_squared;
    o.z = -q.z / len_squared;
    return o;
}

inline Quaternion normalize(const Quaternion &q) {
    Quaternion o;
    float len = length(q);
    o.w = q.w / len;
    o.x = q.x / len;
    o.y = q.y / len;
    o.z = q.z / len;
    return o;
}

inline float dot(const Quaternion &a, const Quaternion &b) {
    return a.w*b.w + a.x*b.x + a.y*b.y + a.z*b.z;
}

// t 0..1
inline Quaternion slerp(float t, Quaternion &q0, Quaternion &q1) {
    float theta = acos(dot(q0, q1)) * t;
    return cos(theta)*q0 + sin(theta)*q1;
}

// t 0..1
inline Quaternion nlerp(float t, Quaternion &q0, Quaternion &q1) {
    return normalize((1 - t) * q0 + t * q1);
}

struct Matrix4 {

    union {
        float m[4][4];
        float flat[16];
    };

    Matrix4() {}

    Matrix4(const Matrix4& mat) {
        for(int i = 0; i < 4; i++) {
            for(int j = 0; j < 4; j++) {
                m[i][j] = mat.m[i][j];
            }
        }
    }

    float& operator[](unsigned int index) {
        assert(index >= 0 && index < 16);
        return flat[index];
    }

    float at(unsigned int index) const {
        return flat[index];
    }

    float determinate() const {
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
    Matrix4 inverse() const {
        Matrix4 result;
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

        float det = 1.0f/result.determinate();
        if (det != 0.0f) {
            for (int i = 0; i < 16; ++i) {
                result[i] *= det;
            }
        }
        return result;
    }

    Matrix4 transpose() const {
        Matrix4 result = *this;

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

    Vector4 operator*(const Vector4& v) {
        Vector4 result;
        result.x = m[0][0] * v.x + m[0][1] * v.y + m[0][2] * v.z + m[0][3] * v.w;
        result.y = m[1][0] * v.x + m[1][1] * v.y + m[1][2] * v.z + m[1][3] * v.w;
        result.z = m[2][0] * v.x + m[2][1] * v.y + m[2][2] * v.z + m[2][3] * v.w;

        result.w = m[3][0] * v.x + m[3][1] * v.y + m[3][2] * v.z + m[3][3] * v.w;

        return result;
    }

    Matrix4 operator*(const Matrix4& mat) {
        Matrix4 result;
        result[0] = m[0][0] * mat.m[0][0] + m[0][1] * mat.m[1][0] + m[0][2] * mat.m[2][0] + m[0][3] * mat.m[3][0];
        result[1] = m[0][0] * mat.m[0][1] + m[0][1] * mat.m[1][1] + m[0][2] * mat.m[2][1] + m[0][3] * mat.m[3][1];
        result[2] = m[0][0] * mat.m[0][2] + m[0][1] * mat.m[1][2] + m[0][2] * mat.m[2][2] + m[0][3] * mat.m[3][2];
        result[3] = m[0][0] * mat.m[0][3] + m[0][1] * mat.m[1][3] + m[0][2] * mat.m[2][3] + m[0][3] * mat.m[3][3];

        result[4] = m[1][0] * mat.m[0][0] + m[1][1] * mat.m[1][0] + m[1][2] * mat.m[2][0] + m[1][3] * mat.m[3][0];
        result[5] = m[1][0] * mat.m[0][1] + m[1][1] * mat.m[1][1] + m[1][2] * mat.m[2][1] + m[1][3] * mat.m[3][1];
        result[6] = m[1][0] * mat.m[0][2] + m[1][1] * mat.m[1][2] + m[1][2] * mat.m[2][2] + m[1][3] * mat.m[3][2];
        result[7] = m[1][0] * mat.m[0][3] + m[1][1] * mat.m[1][3] + m[1][2] * mat.m[2][3] + m[1][3] * mat.m[3][3];

        result[8] = m[2][0] * mat.m[0][0] + m[2][1] * mat.m[1][0] + m[2][2] * mat.m[2][0] + m[2][3] * mat.m[3][0];
        result[9] = m[2][0] * mat.m[0][1] + m[2][1] * mat.m[1][1] + m[2][2] * mat.m[2][1] + m[2][3] * mat.m[3][1];
        result[10] = m[2][0] * mat.m[0][2] + m[2][1] * mat.m[1][2] + m[2][2] * mat.m[2][2] + m[2][3] * mat.m[3][2];
        result[11] = m[2][0] * mat.m[0][3] + m[2][1] * mat.m[1][3] + m[2][2] * mat.m[2][3] + m[2][3] * mat.m[3][3];

        result[12] = m[3][0] * mat.m[0][0] + m[3][1] * mat.m[1][0] + m[3][2] * mat.m[2][0] + m[3][3] * mat.m[3][0];
        result[13] = m[3][0] * mat.m[0][1] + m[3][1] * mat.m[1][1] + m[3][2] * mat.m[2][1] + m[3][3] * mat.m[3][1];
        result[14] = m[3][0] * mat.m[0][2] + m[3][1] * mat.m[1][2] + m[3][2] * mat.m[2][2] + m[3][3] * mat.m[3][2];
        result[15] = m[3][0] * mat.m[0][3] + m[3][1] * mat.m[1][3] + m[3][2] * mat.m[2][3] + m[3][3] * mat.m[3][3];

        return result;
    }

    static Matrix4 screen_space(float halfWidth, float halfHeight) {
        Matrix4 mat;
        identity(&mat);

        mat.m[0][0] = halfWidth;
        mat.m[1][1] =-halfHeight;
        mat.m[0][3] = halfWidth;
        mat.m[1][3] = halfHeight;
        return mat;
    }

    static Matrix4 viewport(float x, float y, float width, float height) {
        Matrix4 scale = Matrix4::scale(width, height, 0.5f);
        Matrix4 trans = Matrix4::translate(x + x + width, y + y + height, 0.0f);
        Matrix4 correction = Matrix4::translate(-(1.0f / width), -(1.0f / height), 1.0f);
        return trans * scale * correction;
    }

    static Matrix4 rotate(double degrees, float tx, float ty, float tz) {
        Matrix4 result;
        identity(&result);

        float x = tx, y = ty, z = tz;
        float length = sqrt(x * x + y * y + z * z);
        if(length == 0.0f) return result;
        x /= length;
        y /= length;
        z /= length;

        double angle = degrees * (3.14159265359 / 180.0);
        float c = (float) cos(angle);
        float omc = 1.0f - c;
        float s = (float) sin(angle);

        result[0] = x * x * omc + c;
        result[1] = x * y * omc - z * s;
        result[2] = x * z * omc + y * s;

        result[4] = y * x * omc + z * s;
        result[5] = y * y * omc + c;
        result[6] = y * z * omc - x * s;

        result.m[2][0] = x * z * omc - y * s;
        result.m[2][1] = y * z * omc + x * s;
        result.m[2][2] = z * z * omc + c;
        return result;
    }

    static Matrix4 rotate(Quaternion &q) {
        float rta = sqrt(1 - q.w*q.w);
        if (rta == 0) {
            return Matrix4::identity();
        }
        float theta = acos(q.w) * 2;
        float x = q.x / rta;
        float y = q.y / rta;
        float z = q.z / rta;
        return rotate(theta * (180.0 /3.14159265359), x, y, z);
    }

    static Matrix4 translate(float x, float y, float z) {
        Matrix4 mat;
        identity(&mat);
        mat.m[0][3] = x;
        mat.m[1][3] = y;
        mat.m[2][3] = z;
        return mat;
    }

    static Matrix4 scale(float x, float y, float z) {
        Matrix4 mat;
        identity(&mat);
        mat.m[0][0] = x;
        mat.m[1][1] = y;
        mat.m[2][2] = z;
        return mat;
    }

    static Matrix4 perspective(float fov, float aspect, float _near, float _far) {
        float t = (float) tan(fov * 3.14159 / 360.0) * _near;
        float b = -t;
        float l = aspect * b;
        float r = aspect * t;
        return frustum(l, r, b, t, _near, _far);
    }

    static Matrix4 frustum(float left, float right, float bottom, float top, float _near, float _far) {
        Matrix4 mat;
        identity(&mat);

        float A = (right + left) / (right - left);
        float B = (top + bottom) / (top - bottom);
        float C = - (_far + _near) / (_far - _near);
        float D = - (2 * _far * _near) / (_far - _near);
        
        mat.m[0][0] = 2 * _near / (right - left);
        mat.m[0][2] = A;
        mat.m[1][1] = 2 * _near / (top - bottom);
        mat.m[1][2] = B;
        mat.m[2][2] = C;
        mat.m[2][3] = D;
        mat.m[3][2] = -1.0f;
        mat.m[3][3] = 0.0f;
        return mat;
    }
    
    static Matrix4 ortho(float left, float right, float bottom, float top, float _near, float _far) {
        Matrix4 mat;
        identity(&mat);
        mat.m[0][0] = 2.0f / (right - left);
        mat.m[0][3] = - (right + left) / (right - left);
        mat.m[1][1] = 2.0f / (top - bottom);
        mat.m[1][3] = - (top + bottom) / (top - bottom);
        mat.m[2][2] = - 2.0f / (_far - _near);
        mat.m[2][3] = - (_far + _near) / (_far - _near);
        return mat;
    }
    
    static Matrix4 identity() {
        Matrix4 mat;
        identity(&mat);
        return mat;
    }


    static void identity(Matrix4 *mat) {
        memset(mat, 0, sizeof(Matrix4));
        mat->m[0][0] = 1.0f;
        mat->m[1][1] = 1.0f;
        mat->m[2][2] = 1.0f;
        mat->m[3][3] = 1.0f;
    }
};
