
Xml :: struct {
    line_number: u32;
    character_number: u32;
    filename: string;
}

Xml_Property :: struct {
    using xml: Xml;
    name: string;
    content: string;
}

Xml_Node :: struct {
    using xml: Xml;
    node_type: string;
    content: [..] ML_Token; // bare content that isn't a node!
    properties: [..] *Xml_Property;
    children: [..] *Xml_Node;
}

 Xml_Parser :: struct {
    filename: string;
    current_token: s64 = -1;
    tokens: [..] ML_Token;
}

xml_parse_property :: (p: *Xml_Parser) -> *Xml_Property {
    prop := XML_NEW(p, Xml_Property);
    
    expect(p, ML_TOKEN_IDENTIFIER);
    tok := next_token(p);
    
    prop.name = tok._string;

    expect_and_eat(p, #char "=");
    tok = peek_token(p);
    prop.content = tok._string;

    expect_and_eat(p, ML_TOKEN_STRING);
    return prop;
}

xml_parse_node :: (p: *Xml_Parser) -> *Xml_Node {
    node := XML_NEW(p, Xml_Node);
    expect_and_eat(p, #char "<");

    expect(p, ML_TOKEN_IDENTIFIER);
    tok := next_token(p);

    print("TOK: %\n", tok._string);
    node.node_type = copy_string(tok._string);

    tok = peek_token(p);
    while tok.type != cast(ML_Token_Type) #char ">" && tok.type != ML_TOKEN_HTML_SLASH_GT && tok.type != ML_TOKEN_END {
        prop := xml_parse_property(p);
        array_add(*node.properties, prop);
        tok = peek_token(p);
    }

    if tok.type == ML_TOKEN_HTML_SLASH_GT return node;
    expect_and_eat(p, #char ">");

    tok = peek_token(p);
    while tok.type != ML_TOKEN_HTML_LT_SLASH && tok.type != ML_TOKEN_END {
        if tok.type == cast(ML_Token_Type) #char "<" {
            child := xml_parse_node(p);
            array_add(*node.children, child);
        } else {
            // bare token ?
            array_add(*node.content, <<tok);
			tok = next_token(p);
        }

        tok = peek_token(p);
    }

    expect_and_eat(p, ML_TOKEN_HTML_LT_SLASH);
    expect(p, ML_TOKEN_IDENTIFIER);
    tok = peek_token(p);
    type := tok._string;

    if type != node.node_type {
        logprint("Xml_Parser", "Expected end-tag to node of type '%' but got '%'\n", node.node_type, type);
    }
    tok = next_token(p);

    expect_and_eat(p, #char ">");

    return node;
}

xml_parse_header_node :: (p: *Xml_Parser) -> *Xml_Node {
    expect_and_eat(p, ML_TOKEN_HTML_LT_QM);

    tok := next_token(p);
    while tok.type != ML_TOKEN_HTML_QM_GT && tok.type != ML_TOKEN_END {
        tok = next_token(p);
    }

    return null;
}

xml_parse :: (src: string, filename: string) -> *Xml_Node {
    st: ML_State;
    st.flags = ML_DOTS_IN_IDENTIFIERS | ML_ENABLE_HTML;
    init(*st, src);
    tok: ML_Token;

    parser: Xml_Parser;
    parser.filename = filename;

    ml_get_token(*st, *tok);
    while tok.type != ML_TOKEN_END {
        array_add(*parser.tokens, tok);
        ml_get_token(*st, *tok);
    }
    array_add(*parser.tokens, tok);

    root := XML_NEW(*parser, Xml_Node);
    while peek_token(*parser).type != ML_TOKEN_END {
        if peek_token(*parser).type == ML_TOKEN_HTML_LT_QM {
            child := xml_parse_header_node(*parser);
            // do nothing
        } else {
            child := xml_parse_node(*parser);
            array_add(*root.children, child);
        }
    }
    return root;
}


#scope_file

using ML_Token_Type;

XML_NEW :: (p: *Xml_Parser, $type: Type) -> *type {
    tok := peek_token(p);

    this := New(type);
    this.line_number = tok.line_number;
    this.character_number = tok.character_number;
    this.filename = p.filename;
    return this;
}

expect_and_eat :: (p: *Xml_Parser, ty: ML_Token_Type) {
    tok := next_token(p);
    if tok.type != ty {
        logprint("Xml_Parser", "expected token '%' but got '%'\n", ty, tok.type);
        assert(false);
    }
}

expect_and_eat :: (p: *Xml_Parser, ty: ML_Token_Type.loose) {
    tok := next_token(p);
    if tok.type != xx ty {
        logprint("Xml_Parser", "expected token '%' but got '%'\n", ty, tok.type);
        assert(false);
    }
}

expect :: (p: *Xml_Parser, ty: ML_Token_Type) {
    tok := peek_token(p);
    if tok.type != ty {
        logprint("Xml_Parser", "expected token '%' but got '%'\n", ty, tok.type);
        assert(false);
    }
}

expect :: (p: *Xml_Parser, ty: ML_Token_Type.loose) {
    tok := peek_token(p);
    if tok.type != xx ty {
        logprint("Xml_Parser", "expected token '%' but got '%'\n", ty, tok.type);
        assert(false);
    }
}

next_token :: (p: *Xml_Parser) -> *ML_Token {
    if p.current_token < p.tokens.count-1 p.current_token += 1;
    tok := *p.tokens[p.current_token];
    return tok;
}

peek_token :: (p: *Xml_Parser) -> *ML_Token {
    target := p.current_token+1;
    if target >= p.tokens.count
        target = p.tokens.count-1;
    return *p.tokens[target];
}