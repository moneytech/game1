#define NK_IMPLEMENTATION
#ifdef WINDOWS
#define NK_API __declspec(dllexport)
#define NK_LIB __declspec(dllexport)
#endif
#include "nuklear.h"