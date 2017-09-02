
#pragma once
#include "general.h"

#ifndef MACH_LEXER_ENABLE_HTML
#define MACH_LEXER_ENABLE_HTML
#endif

#include "lexer.h"
#include "game.h"

enum Html_Type {
    HTML_TYPE_NONE,
    HTML_TYPE_BARE_WORD,
    HTML_TYPE_NODE,
    HTML_TYPE_IDENT,
    HTML_TYPE_ATTRIBUTE,
    HTML_TYPE_TAG,
    HTML_TYPE_DOM,
};

struct Html {
    int type = HTML_TYPE_NONE;
    ML_String filename;
    int line_number;
    int character_number;
};

struct Atom {
    char *name;
};

struct Html_Bare_Word : Html {
    Html_Bare_Word() { type = HTML_TYPE_BARE_WORD; }
    char *word;
};

struct Html_Node : Html {
    Html_Node() { type = HTML_TYPE_NODE; }
	Array<Html *> children;
};

struct Html_Ident : Html {
    Html_Ident() { type = HTML_TYPE_IDENT; }
    Atom *name;
};

struct Html_Attribute : Html_Node {
    Html_Attribute() { type = HTML_TYPE_ATTRIBUTE; }
	Html_Ident *identifier;

	Html_Node *value;
};

struct Html_Tag : Html_Node {
    Html_Tag() { type = HTML_TYPE_TAG; }
	Html_Ident *identifier;

	Array<Html_Attribute *> attribs;
};

typedef Html_Node Html_Dom;

struct Game;

struct Html_Parser {
	ML_State *lex;
    Game *game;
    Hash_Map<Atom> atoms;
    ML_Token *tok;
    Array<ML_Token> tokens;
    u32 token_index;

    void eat_token();
    Atom *make_atom(const char *name);
    bool expect(int tok_type);
    Html_Ident *parse_ident();
	Html *parse_stmt();
	Html_Dom *parse_dom();
};

