// Simple desecnt parser without Schemas!

#load "lexer.jai";

Xml :: struct {
    line_number: u32;
    character_number: u32;
    filename: string;
    type: Type;
}

Xml_Property :: struct {
    using __xml: Xml;
    name: string;
    content: string;
}

Xml_Node :: struct {
    using __xml: Xml;
    node_type: string;

    content: [..] ML_Token; // content that should be parsed by spec of a schema
    content_string: string;

    properties: [..] *Xml_Property;
    children: [..] *Xml_Node;
}

 Xml_Parser :: struct {
    filename: string;
    current_token: s64 = -1;
    tokens: [..] ML_Token;
    node_hooks: Hash_Map(XML_NODE_HOOK);
    user_data: *void;
}

XML_NODE_HOOK :: #type (p: *Xml_Parser, node_type: string, parent: *Xml_Node, properties: [..] *Xml_Property) -> *Xml_Node;

// ------------------------------------------------------------------
// expected data type API

xml_parse_float :: (p: *Xml_Parser) -> float64 {
    tok := next_token(p);
    neg := false;
    if tok.type == cast(ML_Token_Type) #char "-" {
        neg = true;
        tok = next_token(p);
    }

    val: float64;
    if tok.type == {
        case ML_TOKEN_FLOAT; val = tok._float;
        case ML_TOKEN_INTEGER; val = cast(float64) tok.integer;
        case; assert(false);
    }
    if neg val = -val;
    return val;
}

xml_parse_int :: (p: *Xml_Parser) -> int {
    tok := next_token(p);
    neg := false;
    if tok.type == cast(ML_Token_Type) #char "-" {
        neg = true;
        tok = next_token(p);
    }

    val: int;
    if tok.type == {
        case ML_TOKEN_INTEGER; val = cast(int) tok.integer;
        case; assert(false);
    }
    if neg val = -val;
    return val;
}

// can be used to transform content between <></> to be a string rather than tokens!
xml_parse_string :: (p: *Xml_Parser, delim: ML_Token_Type) -> string {
    tok_start := next_token(p);

    tok_end := peek_token(p);
    while peek_token(p).type != delim {
        tok_end = next_token(p);
    }
    tok_end = peek_token(p);

    str := ml_get_string_from(tok_start, tok_end);
    // print("string: %\n", str);
    return str;
}

// ------------------------------------------------------------------


xml_parse_property :: (p: *Xml_Parser) -> *Xml_Property {
    prop := XML_NEW(p, Xml_Property, "___property");
    
    expect(p, ML_TOKEN_IDENTIFIER);
    tok := next_token(p);
    
    prop.name = tok._string;

    expect_and_eat(p, #char "=");
    tok = peek_token(p);
    prop.content = tok._string;

    expect_and_eat(p, ML_TOKEN_STRING);
    return prop;
}

xml_get_property :: (props: [] *Xml_Property, target: string) -> *Xml_Property {
    for props {
        if it.name == target return it;
    }

    return null;
}

xml_get_property :: (node: *Xml_Node, target: string) -> *Xml_Property {
    return xml_get_property(node.properties, target);
}

xml_parse_child_loop :: (p: *Xml_Parser, node: *Xml_Node = null) -> [..] *Xml_Node {
    children: [..] *Xml_Node;
    tok := peek_token(p);
    while tok.type != ML_TOKEN_HTML_LT_SLASH && tok.type != ML_TOKEN_END {
        if tok.type == cast(ML_Token_Type) #char "<" {
            child := xml_parse_node(p, node);
            if child array_add(*children, child);
        } else {
            if node {
                array_add(*node.content, <<tok);
                tok = next_token(p);
            }
        }

        tok = peek_token(p);
    }
    return children;
}

xml_parse_node :: (p: *Xml_Parser, parent: *Xml_Node) -> *Xml_Node {
    expect_and_eat(p, #char "<");

    expect(p, ML_TOKEN_IDENTIFIER);
    tok := next_token(p);

    node_type := copy_string(tok._string);

    properties: [..] *Xml_Property;

    tok = peek_token(p);
    while tok.type != cast(ML_Token_Type) #char ">" && tok.type != ML_TOKEN_HTML_SLASH_GT && tok.type != ML_TOKEN_END {
        prop := xml_parse_property(p);
        array_add(*properties, prop);
        tok = peek_token(p);
    }

    if tok.type == ML_TOKEN_HTML_SLASH_GT {
        node := XML_NEW(p, Xml_Node, node_type);
        node.node_type = node_type;
        node.properties = properties;
        expect_and_eat(p, ML_TOKEN_HTML_SLASH_GT);
        return node;
    }
    expect_and_eat(p, #char ">");

    node: *Xml_Node;
    if contains_key(*p.node_hooks, node_type) {
        hook := get_slot(*p.node_hooks, node_type);
        node = hook(p, node_type, parent, properties);
        if node node.properties = properties;
    } else {
        node = XML_NEW(p, Xml_Node, node_type);
        node.properties = properties;
        node.node_type = node_type;
        node.children = xml_parse_child_loop(p, node);
    }

    expect_and_eat(p, ML_TOKEN_HTML_LT_SLASH);
    expect(p, ML_TOKEN_IDENTIFIER);
    tok = peek_token(p);
    type := tok._string;

    if type != node_type {
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

xml_parse :: (p: *Xml_Parser) -> *Xml_Node {

    root := XML_NEW(p, Xml_Node, "___root");
    while peek_token(p).type != ML_TOKEN_END {
        if peek_token(p).type == ML_TOKEN_HTML_LT_QM {
            child := xml_parse_header_node(p);
            // do nothing
        } else {
            child := xml_parse_node(p, root);
            if child array_add(*root.children, child);
        }
    }
    return root;
}

xml_init_parser :: (parser: *Xml_Parser, src: string, filename: string) {
    st: ML_State;
    st.flags = ML_DOTS_IN_IDENTIFIERS | ML_ENABLE_HTML;
    init(*st, src);
    tok: ML_Token;

    parser.filename = filename;

    ml_get_token(*st, *tok);
    while tok.type != ML_TOKEN_END {
        array_add(*parser.tokens, tok);
        ml_get_token(*st, *tok);
    }
    array_add(*parser.tokens, tok);
}

xml_register_hook ::(p: *Xml_Parser, node_type: string, hook: XML_NODE_HOOK) {
    set_slot(*p.node_hooks, node_type, hook);
}

xml_peek_token :: peek_token;

XML_NEW :: (p: *Xml_Parser, $type: Type, node_type: string) -> *type {
    tok := peek_token(p);

    this := New(type);
    this.line_number = tok.line_number;
    this.character_number = tok.character_number;
    this.filename = p.filename;
    this.type = type;
    #if type != Xml_Property {
        this.node_type = node_type;
    }
    return this;
}

#scope_file

using ML_Token_Type;

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