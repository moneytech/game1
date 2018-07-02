
ML_ENABLE_HTML         :: (1 << 0);
ML_DOTS_IN_IDENTIFIERS :: (1 << 1);

ML_State :: struct {
	current: *u8;
	line_number: u32;
	character_number: u32;

	start: *u8;
	end: *u8;
    flags: u32;
}

ML_Token_Type :: enum s32 {
	ML_TOKEN_UNINITIALIZED :: 0;

	ML_TOKEN_END :: 256;
	ML_TOKEN_INTEGER;
	ML_TOKEN_FLOAT;
	ML_TOKEN_STRING;
	ML_TOKEN_IDENTIFIER;

	// HTML tokens
	ML_TOKEN_HTML_COMMENT; 	// <!
    ML_TOKEN_HTML_LT_SLASH; // </
    ML_TOKEN_HTML_SLASH_GT; // />
    ML_TOKEN_HTML_LT_QM;    // <?
    ML_TOKEN_HTML_QM_GT;    // ?>
}

ML_Token :: struct {
	type: ML_Token_Type;

	// values
	integer: u64;
	#place integer;
	_float: float64;
	#place integer;
	_string: string;

	line_number: u32;
	character_number: u32;
	offset: *u8;
}

ML_Error_Type :: enum {
	ML_ERROR_INCOMPLETE_STRING;
	ML_ERROR_INVALID_ESCAPE_SEQUENCE;
	ML_ERROR_NEWLINE_IN_STRING;
}

init :: (st: *ML_State, source: string) {
	st.current = source.data;
	st.line_number = 1;
	st.character_number = 0;

	st.start = source.data;
	st.end = source.data + source.count;
}


#scope_file

using ML_Token_Type;

ml__isnumber :: (c: u8) -> bool {
	return c >= #char "0" && c <= #char "9";
}

ml__isalpha :: (c: u8) -> bool {
	return (c >= #char "A" && c <= #char "Z") || (c >= #char "a" && c <= #char "z");
}

ml__isAFaf :: (c: u8) -> bool {
	return (c >= #char "A" && c <= #char "F") || (c >= #char "a" && c <= #char "f");
}

ml__isalphanumeric :: (c: u8) -> bool {
	return  ml__isalpha(c) || ml__isnumber(c);
}

FORM_FEED :: 0x0C;

ml__is_whitespace :: (c: u8) -> bool {
	return (c == #char " ") || (c == #char "\t") || (c == #char "\r") || (c == #char "\n") || (c == FORM_FEED);
}

ml__eat_whitespace :: (st: *ML_State) {
	current := st.current;
	end := st.end;
	while (current < end && ml__is_whitespace(<< current)) {
		if (<<current == #char "\n") {
			st.line_number += 1;
			st.character_number = 0;
		} else {
			st.character_number += 1;
		}
		current += 1;
	}
	st.current = current;
}

ml__token :: (st: *ML_State, tok: *ML_Token, type: ML_Token_Type) {
	tok.type = type;
	tok.line_number = st.line_number;
	tok.character_number = st.character_number;
	tok.offset = st.current;
}

ml_peek_token :: (st: *ML_State, tok: *ML_Token) {
	local := <<st;
	ml_get_token(*local, tok);
}

ml__ident_dots :: (st: *ML_State, c: s32) -> bool {
    if (st.flags & ML_DOTS_IN_IDENTIFIERS) {
        return c == #char ".";
    }

    return false;
}

#scope_export

ml_get_string_from :: (start: *ML_Token, end: *ML_Token) -> string {
	out: string;
	out.data = start.offset;
	out.count = end.offset - start.offset;
	return out;
}

ml_get_string :: (st: *ML_State, tok: *ML_Token, delim: ML_Token_Type) {
	tok.type = ML_TOKEN_UNINITIALIZED;

	current := st.current;
	end := st.end;
	char_num := st.character_number;

	if (current >= end) {
		ml__token(st, tok, ML_TOKEN_END);
		return;
	}

	ml__token(st, tok, ML_TOKEN_STRING);
	current += 1;
	st.character_number += 1;
	beg := current;

	while (current < end && cast(ML_Token_Type) (<<current) != delim) {
		current += 1;
	}

	length: s64 = (current - beg);

	tok._string.count = 0;

	if (length) {
		tok._string.data = xx alloc(length);

		for 0..length-1 {
			p := beg + it;

			if (<<p == #char "\\") {
				if (it + 1 < length) {
					out: u8 = 0;
					it += 1;
					if <<(p+1) == {
						case #char "t";
							out = #char "\t";
						case #char "r";
							out = #char "\r";
						case #char "n";
							out = #char "\n";
						case #char "f";
							out = FORM_FEED;
						case #char "\\";
							out = #char "\\";
						case #char "'";
							out = #char "'";
						case #char "\"";
							out = #char "\"";
						case;
							// MACH_LEXER_REPORT_ERROR(ML_ERROR_INVALID_ESCAPE_SEQUENCE, "Invalid escape sequence in string", st->line_number, st->character_number);
							out = #char "\\"; // output what the user typed
							it -= 1;
					}
					tok._string.data[tok._string.count] = out;
					tok._string.count += 1;
				}
			} else {
				tok._string.data[tok._string.count] = <<p;
				tok._string.count += 1;
			}

			if (<<p == #char "\n") {
				// MACH_LEXER_REPORT_ERROR(ML_ERROR_NEWLINE_IN_STRING, "Newline in string", st->line_number, st->character_number);
				st.line_number += 1;
				st.character_number = 0;
			} else {
				st.character_number += 1;
			}
		}
	} else {
		tok._string.data = null;
	}


	if (current >= end) {
		// MACH_LEXER_REPORT_ERROR(ML_ERROR_INCOMPLETE_STRING, "No string terminator found before end-of-file", tok->line_number, tok->character_number);
	} else {
		current += 1;
		st.character_number += 1;
	}

	st.current = current;
}

ml_get_token :: (st: *ML_State, tok: *ML_Token) {
	ml__eat_whitespace(st);
	tok.type = ML_TOKEN_UNINITIALIZED;

	current := st.current;
	end := st.end;
	char_num := st.character_number;

	if (current >= end) {
		ml__token(st, tok, ML_TOKEN_END);
		return;
	}

	if (st.flags & ML_ENABLE_HTML) {
		if (<<current == #char "<" && (current+1) < end) {
			if (current[1] == #char "!") {
				ml__token(st, tok, ML_TOKEN_HTML_COMMENT);
				current += 2;
				st.character_number += 2;
				st.current = current;
				return;
			}
	        if (current[1] == #char "/") {
	            ml__token(st, tok, ML_TOKEN_HTML_LT_SLASH);
	            current += 2;
	            st.character_number += 2;
	            st.current = current;
	            return;
	        }
	        if (current[1] == #char "?") {
	            ml__token(st, tok, ML_TOKEN_HTML_LT_QM);
	            current += 2;
	            st.character_number += 2;
	            st.current = current;
	            return;
	        }
		}
	    if (<<current == #char "/" && (current+1) < end) {
	        if (current[1] == #char ">") {
	            ml__token(st, tok, ML_TOKEN_HTML_SLASH_GT);
	            current += 2;
	            st.character_number += 2;
	            st.current = current;
	            return;
	        }
	    }
        if (<<current == #char "?" && (current+1) < end) {
	        if (current[1] == #char ">") {
	            ml__token(st, tok, ML_TOKEN_HTML_QM_GT);
	            current += 2;
	            st.character_number += 2;
	            st.current = current;
	            return;
	        }
	    }
	}

	if (<<current == #char "\"") {
		ml_get_string(st, tok, xx #char "\"");
		return;
	}

	if (ml__isalpha(<<current) || <<current == #char "_" || ml__ident_dots(st, <<current)) {
		ml__token(st, tok, ML_TOKEN_IDENTIFIER);
		beg := current;
		current += 1;
		while (current < end && (ml__isalphanumeric(<<current) || <<current == #char "_" || ml__ident_dots(st, <<current))) {
			current += 1;
		}
		len: s64 = current - beg;

		tok._string.data = xx alloc(len);
		tok._string.count = len;
		memcpy(tok._string.data, beg, len);

		st.character_number += xx len;
		st.current = current;
		return;
	}

	if (ml__isnumber(<<current)) {
		ml__token(st, tok, ML_TOKEN_INTEGER);

		beg := current;
		current += 1;
		base: s32 = 10;
		if (<<beg == #char "0") {
			
			base = 8;
			if (current < end && (<<current == #char "x" || <<current == #char "X")) {
				current += 1;
				beg = current;
				st.character_number += 2;
				base = 16;
			} else if (current < end && <<current == #char ".") {
				// float
                base = 10;
			}
		}

		if (base == 10) {
			allow_e := false;
			while (current < end && (ml__isnumber(<<current) || <<current == #char "." || (allow_e && <<current == #char "e"))) {
				if (<<current == #char ".") {
					if (base != -1) {
						base = -1;
						tok.type = ML_TOKEN_FLOAT;
						allow_e = true;
					}
					else break; // extra dot in float
				} else if <<current == #char "e" {
					if current < end && (current+1) < end {
						if <<(current+1) == #char "-" {
							current += 1;
						}
					}
					allow_e = false;
				}
				current += 1;
			}
		} else if (base == 16) {
			while (current < end && (ml__isnumber(<<current) || ml__isAFaf(<<current)))
				current += 1;
		} else {
			// base 8
			while (current < end && ml__isnumber(<<current))
				current += 1;
		}
		len: s64 = current - beg;

		temp: *u8 = alloc(len+1);
		assert(len != 0);
		memcpy(temp, beg, len);
		temp[len] = 0;
		
		// print("TEMP: %\n", to_string(temp));

		if (base >= 0) {
			tok.integer = strtoull(temp, null, base);
		} else {
			tok._float = strtod(temp, null);
		}
		
		free(temp);
		st.character_number += xx len;
		st.current = current;
		return;
	}

	if (current < end) {
		c := <<current;
		current += 1;
		ml__token(st, tok, xx c);
		st.character_number += 1;
		st.current = current;
	}
}
