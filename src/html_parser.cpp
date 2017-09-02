#include "html_parser.h"
#include <new>

inline Html *init(Html *h, ML_Token *tok) {
    h->line_number = tok->line_number;
    h->character_number = tok->character_number;
    return h;
}

#define MAKE_HTML(type) ((type *)init(new (GET_MEMORY(type)) type(), tok))

void Html_Parser::eat_token() {
    if (token_index < tokens.count) token_index++;
    tok = &tokens[token_index];
}

Html_Dom *Html_Parser::parse_dom() {
    token_index = 0;
    ML_Token token;
    do {
        ml_get_token(lex, &token);
        tokens.add(token);
    } while (token.type != ML_TOKEN_END);

    tok = &tokens[0];

    Html_Dom *dom = MAKE_HTML(Html_Dom);

	while (tok->type != ML_TOKEN_END) {
		dom->children.add(parse_stmt());
	}

    return dom;
}

char *ml_string_to_c_string(ML_String *str) {
    char *out = GET_MEMORY_SIZED(str->length + 1);
    memcpy(out, str->data, str->length);
    out[str->length] = 0;
    return out;
}

Atom *Html_Parser::make_atom(const char *name) {
    Atom *a = &atoms[name];
    if (!a->name) a->name = copy_c_string(name);
    return a;
}


Html_Ident *Html_Parser::parse_ident() {
    Html_Ident *ident = nullptr;
    if (tok->type == ML_TOKEN_IDENTIFIER) {
        ident = MAKE_HTML(Html_Ident);
        ident->name = make_atom(ml_string_to_c_string(&tok->string));
        eat_token();
    } else {
        expect(ML_TOKEN_IDENTIFIER);
    }
    return ident;
}

Html *Html_Parser::parse_stmt() {
    if (tok->type == ML_TOKEN_HTML_COMMENT) {
        // eat through the comment since it isn't useful
        while (tok->type != '>' && tok->type != ML_TOKEN_END) {
            eat_token();
        }
        expect('>');
    } else if (tok->type == ML_TOKEN_IDENTIFIER) {
        // we should only get here when a bare word is allowed
        Html_Bare_Word *word = MAKE_HTML(Html_Bare_Word);
        word->word = ml_string_to_c_string(&tok->string);
        eat_token();
        return word;
    } else if (expect('<')) {
        Html_Tag *node = MAKE_HTML(Html_Tag);
        node->identifier = parse_ident();

        while (tok->type != '>' && tok->type != ML_TOKEN_HTML_SLASH_GT && tok->type != ML_TOKEN_END) {
            // @TODO parse attributes
            eat_token();
        }

        if (tok->type == ML_TOKEN_HTML_SLASH_GT) {
            eat_token();
            return node;
        }

        expect('>');

        while (tok->type != ML_TOKEN_HTML_LT_SLASH && tok->type != ML_TOKEN_END) {
            Html *child = parse_stmt();
            assert(child);
            node->children.add(child);
        }

        expect(ML_TOKEN_HTML_LT_SLASH);
        Html_Ident *ident = parse_ident();
        if (ident->name != node->identifier->name)
            game->report_error("expected end tag for '%s' but got '%s'\n", node->identifier->name->name, ident->name->name);
        expect('>');
        return node;
    }

    return nullptr;
}

char *token_to_string(ML_Token *tok) {
    return "";
}

bool Html_Parser::expect(int tok_type) {
    if (tok_type != tok->type) {
        game->report_error("expected token '%ld' before token %s\n", tok_type, token_to_string(tok));
        return false;
    }

    eat_token();
    return true;
}

