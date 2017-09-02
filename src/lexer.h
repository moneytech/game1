
#ifndef MACH_LEXER_H
#define MACH_LEXER_H

#ifdef MACH_LEXER_ENABLE_HTML

#endif

#define s64 ml__s64
#define s32 ml__s32
#define s16 ml__s16
#define s8  ml__s8
#define u64 ml__u64
#define u32 ml__u32
#define u16 ml__u16
#define u8  ml__u8

#include <stdint.h>
typedef int64_t s64;
typedef int32_t s32;
typedef int16_t s16;
typedef int8_t  s8;

typedef uint64_t u64;
typedef uint32_t u32;
typedef uint16_t u16;
typedef uint8_t  u8;

#include <string.h> // memcpy

#ifndef MACH_LEXER_ALLOC
#include <stdlib.h>
#define MACH_LEXER_ALLOC(x) malloc(x)
#endif

#ifndef MACH_LEXER_FREE
#define MACH_LEXER_FREE(x) free(x)
#endif

#ifndef MACH_LEXER_REPORT_ERROR
#define MACH_LEXER_REPORT_ERROR(type, str, line, char_num) (0)
#endif

#ifdef __cplusplus
extern "C" {
#endif

const u32 ML_DOTS_IN_IDENTIFIERS = (1 << 0);

typedef struct {
	char *current;
	u32 line_number;
	u32 character_number;

	char *start;
	char *end;
    u32 flags;
} ML_State;

typedef struct {
	u64 length;
	char *data;
} ML_String;

typedef enum {
	ML_TOKEN_UNINITIALIZED = 0,

	ML_TOKEN_END = 256,
	ML_TOKEN_INTEGER,
	ML_TOKEN_FLOAT,
	ML_TOKEN_STRING,
	ML_TOKEN_IDENTIFIER,

#ifdef MACH_LEXER_ENABLE_HTML
	ML_TOKEN_HTML_COMMENT, // <!
    ML_TOKEN_HTML_LT_SLASH, // </
    ML_TOKEN_HTML_SLASH_GT, // />
#endif
} ML_Token_Type;

typedef struct {
	ML_Token_Type type;

	union {
		u64 integer;
		double float64;
		float float32;
		ML_String string;
	};

	u32 line_number;
	u32 character_number;

} ML_Token;

typedef enum {
	ML_ERROR_INCOMPLETE_STRING,
	ML_ERROR_INVALID_ESCAPE_SEQUENCE,
	ML_ERROR_NEWLINE_IN_STRING,
} ML_Error_Type;

extern void ml_init(ML_State *st, u32 source_len, char *source);
extern void ml_get_token(ML_State *st, ML_Token *tok);
extern void ml_peek_token(ML_State *st, ML_Token *tok);

#ifdef MACH_LEXER_IMPLEMENTATION

void ml_init(ML_State *st, u32 source_len, char *source) {
	st->current = source;
	st->line_number = 1;
	st->character_number = 0;

	st->start = source;
	st->end = source + source_len;
}

int ml__isnumber(char c) {
	return c >= '0' && c <= '9';
}

int ml__isalpha(char c) {
	return (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z');
}

int ml__isAFaf(char c) {
	return (c >= 'A' && c <= 'F') || (c >= 'a' && c <= 'f');
}

int ml__isalphanumeric(char c) {
	return  ml__isalpha(c) || ml__isnumber(c);
}

int ml__is_whitespace(char c) {
	return (c == ' ') || (c == '\t') || (c == '\r') || (c == '\n') || (c == '\f');
}

void ml__eat_whitespace(ML_State *st) {
	char *current = st->current;
	char *end = st->end;
	while (current < end && ml__is_whitespace(*current)) {
		if (*current == '\n') {
			st->line_number++;
			st->character_number = 0;
		} else {
			st->character_number++;
		}
		current++;
	}
	st->current = current;
}

void ml__token(ML_State *st, ML_Token *tok, int type) {
	tok->type = (ML_Token_Type) type;
	tok->line_number = st->line_number;
	tok->character_number = st->character_number;
}

void ml_peek_token(ML_State *st, ML_Token *tok) {
	ML_State local;
	memcpy(&local, st, sizeof(ML_State));
	ml_get_token(&local, tok);
}

int ml__ident_dots(ML_State *st, int c) {
    if (st->flags & ML_DOTS_IN_IDENTIFIERS) {
        return c == '.';
    }

    return 0;
}

void ml_get_token(ML_State *st, ML_Token *tok) {
	ml__eat_whitespace(st);
	tok->type = ML_TOKEN_UNINITIALIZED;

	char *current = st->current;
	char *end = st->end;
	u32 char_num = st->character_number;

	if (current >= end) {
		ml__token(st, tok, ML_TOKEN_END);
		return;
	}

#ifdef MACH_LEXER_ENABLE_HTML
	if (*current == '<' && (current+1) < end) {
		if (current[1] == '!') {
			ml__token(st, tok, ML_TOKEN_HTML_COMMENT);
			current += 2;
			st->character_number += 2;
			st->current = current;
			return;
		}
        if (current[1] == '/') {
            ml__token(st, tok, ML_TOKEN_HTML_LT_SLASH);
            current += 2;
            st->character_number += 2;
            st->current = current;
            return;
        }
	}
    if (*current == '/' && (current+1) < end) {
        if (current[1] == '>') {
            ml__token(st, tok, ML_TOKEN_HTML_SLASH_GT);
            current += 2;
            st->character_number += 2;
            st->current = current;
            return;
        }
    }
#endif

	if (*current == '\"') {
		ml__token(st, tok, ML_TOKEN_STRING);
		current++;
		st->character_number++;
		char *beg = current;

		while (current < end && *current != '\"') {
			current++;
		}

		u32 length = (current - beg) - 1;

		tok->string.length = 0;

		if (length) {
			tok->string.data = (char *)MACH_LEXER_ALLOC(length);

			for (u64 index = 0; index <= length; ++index) {
				char *p = beg + index;

				if (*p == '\\') {
					if (index + 1 < length) {
						char out = 0;
						index++;
						switch(*(p+1)) {
							case 't':
								out = '\t';
								break;
							case 'r':
								out = '\r';
								break;
							case 'n':
								out = '\n';
								break;
							case 'f':
								out = '\f';
								break;
							case '\\':
								out = '\\';
								break;
							case '\'':
								out = '\'';
								break;
							case '\"':
								out = '\"';
								break;
							default:
								MACH_LEXER_REPORT_ERROR(ML_ERROR_INVALID_ESCAPE_SEQUENCE, "Invalid escape sequence in string", st->line_number, st->character_number);
								out = '\\'; // output what the user typed
								index--;
								break;
						}
						tok->string.data[tok->string.length] = out;
						tok->string.length++;
					}
				} else {
					tok->string.data[tok->string.length] = *p;
					tok->string.length++;
				}

				if (*p == '\n') {
					MACH_LEXER_REPORT_ERROR(ML_ERROR_NEWLINE_IN_STRING, "Newline in string", st->line_number, st->character_number);
					st->line_number++;
					st->character_number = 0;
				} else {
					st->character_number++;
				}
			}
		} else {
			tok->string.data = 0;
		}


		if (current >= end) {
			MACH_LEXER_REPORT_ERROR(ML_ERROR_INCOMPLETE_STRING, "No string terminator found before end-of-file", tok->line_number, tok->character_number);
		} else {
			current++;
			st->character_number++;
		}

		st->current = current;
		return;
	}

	if (ml__isalpha(*current) || *current == '_' || ml__ident_dots(st, *current)) {
		ml__token(st, tok, ML_TOKEN_IDENTIFIER);
		char *beg = current;
		current++;
		while (current < end && (ml__isalphanumeric(*current) || *current == '_' || ml__ident_dots(st, *current))) {
			current++;
		}
		u32 len = current - beg;

		tok->string.data = (char *)MACH_LEXER_ALLOC(len);
		tok->string.length = len;
		memcpy(tok->string.data, beg, len);

		st->character_number += len;
		st->current = current;
		return;
	}

	if (ml__isnumber(*current)) {
		ml__token(st, tok, ML_TOKEN_INTEGER);

		char *beg = current;
		current++;
		int base = 10;
		if (*beg == '0') {
			
			base = 8;
			if (current < end && (*current == 'x' || *current == 'X')) {
				current++;
				beg = current;
				st->character_number += 2;
				base = 16;
			} else if (current < end && *current == '.') {
				// float
                base = 10;
			}
		}

		if (base == 10) {
			while (current < end && (ml__isnumber(*current) || *current == '.')) {
				if (*current == '.') {
					if (base != -1) {
						base = -1;
						tok->type = ML_TOKEN_FLOAT;
					}
					else break; // extra dot in float
				}
				current++;
			}
		} else if (base == 16) {
			while (current < end && (ml__isnumber(*current) || ml__isAFaf(*current)))
				current++;
		} else {
			// base 8
			while (current < end && ml__isnumber(*current))
				current++;
		}
		u32 len = current - beg;

		char *temp = (char *)MACH_LEXER_ALLOC(len+1);
		memcpy(temp, beg, len);
		temp[len] = 0;

		if (base >= 0) {
			tok->integer = strtoull(temp, 0, base);
		} else {
			tok->float64 = strtod(temp, 0);
		}
		
		MACH_LEXER_FREE(temp);
		st->character_number += len;
		st->current = current;
		return;
	}

	if (current < end) {
		char c = *current;
		current++;
		ml__token(st, tok, c);
		st->character_number++;
		st->current = current;
	}
}

#endif

#ifdef __cplusplus
}
#endif


#undef s64
#undef s32
#undef s16
#undef s8
#undef u64
#undef u32
#undef u16
#undef u8

#endif
