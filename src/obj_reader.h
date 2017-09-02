
#pragma once

struct Model;
struct Game;


Model *model_loader_parse_obj(Game *g, const char *src);
