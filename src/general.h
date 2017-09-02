
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
	int reserved = 0;
	int count = 0;

	void reserve(int amount) {
		if (amount <= count) assert(0);

		T *new_data = (T *)malloc(sizeof(T) * amount);
		memcpy(new_data, data, sizeof(T) * count);
		free(data);
		data = new_data;
		reserved = amount;
	}

	T &operator[] (int index) {
		assert(index >= 0 && index < count);
		return data[index];
	}

	void add(T item) {
		if ((count+1) >= reserved) reserve((count+1) * 2);
		data[count] = item;
		count++;
	}

	void remove(int index) {
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

        return e != nullptr;
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

// vector math

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

struct Matrix {
    float m[16];

    float &operator[](int index) {
        assert(index >= 0 && index < 16);
        return m[index];
    }
};
