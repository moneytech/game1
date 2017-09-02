
#pragma once
#include "renderer.h"

struct Asset_Manager;

struct Game {
    GL_Renderer *renderer;
    Asset_Manager *asset_man;

    void report_error(char *fmt, ...);
};
