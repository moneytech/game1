#load "xml_parser.jai";

Collada :: struct {
    using xml: Xml_Node;
    library_effects: [..] *Effect;
}

#scope_file

Effect :: struct {
    using xml: Xml_Node;
    id: string;
    emission: [4] float;
    ambient: [4] float;
    diffuse: [4] float;
    specular: [4] float;
    shininess: float;
    index_of_refraction: float;
}

Color :: struct {
    using xml: Xml_Node;
    sid: string;
    color: [4] float;
}

Float :: struct {
    using xml: Xml_Node;
    sid: string;
    value: float;
}

Float_Array :: struct {
    using xml_: Xml_Node;
    id: string;
    array: [] float;
}

using ML_Token_Type;

#scope_export

collada_parse_float :: (p: *Xml_Parser, parent: *Xml_Node, properties: [..] *Xml_Property) -> *Xml_Node {
    fl := XML_NEW(p, Float);
    fl.sid = xml_get_property(properties, "sid").content;
    fl.value = cast(float32) xml_parse_float(p);
    return fl;
}

collada_parse_float_array :: (p: *Xml_Parser, parent: *Xml_Node, properties: [..] *Xml_Property) -> *Xml_Node {
    fl := XML_NEW(p, Float_Array);
    fl.id = xml_get_property(properties, "id").content;
    array_data: [..] float;
    while xml_peek_token(p).type != ML_TOKEN_HTML_LT_SLASH {
        val := xml_parse_float(p);
        array_add(*array_data, cast(float32) val);
    }
    fl.array = array_data;
    return fl;
} 

collada_parse_color :: (p: *Xml_Parser, parent: *Xml_Node, properties: [..] *Xml_Property) -> *Xml_Node {
    color := XML_NEW(p, Color);
    color.sid = xml_get_property(properties, "sid").content;
    color.color[0] = cast(float32) xml_parse_float(p);
    color.color[1] = cast(float32) xml_parse_float(p);
    color.color[2] = cast(float32) xml_parse_float(p);

    if xml_peek_token(p).type != ML_TOKEN_HTML_LT_SLASH color.color[3] = cast(float32) xml_parse_float(p);
    return color;
}

collada_parse_effect :: (p: *Xml_Parser, parent: *Xml_Node, properties: [..] *Xml_Property) -> *Xml_Node {
    effect := XML_NEW(p, Effect);
    effect.id = xml_get_property(properties, "id").content;

    children := xml_parse_child_loop(p, effect);
    // @Hack
    phong := children[0].children[0].children[0];

    for phong.children {
        value := it.children[0];
        if value.type == Color {
            col := cast(*Color) value;
            color := col.color;
            if it.node_type == {
                case "emission"; effect.emission = color;
                case "ambient"; effect.ambient = color;
                case "diffuse"; effect.diffuse = color;
                case "specular"; effect.specular = color;
            }
        } else if value.type == Float {
            fl := cast(*Float) value;
            val := fl.value;
            if it.node_type == {
                case "shininess"; effect.shininess = val;
                case "index_of_refraction"; effect.index_of_refraction = val;
            }
        }
    }

    return effect;
}

collada_parse_library_effects :: (p: *Xml_Parser, parent: *Xml_Node, properties: [..] *Xml_Property) -> *Xml_Node {
    collada := cast(*Collada) p.user_data;
    children := xml_parse_child_loop(p);
    for children {
        assert(it.type == Effect);
        array_add(*collada.library_effects, cast(*Effect) it);
    }
    return null;
}

collada_parse_COLLADA :: (p: *Xml_Parser, parent: *Xml_Node, properties: [..] *Xml_Property) -> *Xml_Node {
    collada := XML_NEW(p, Collada);
    collada.properties = properties;
    p.user_data = collada;
    collada.children = xml_parse_child_loop(p);
    return collada;
}

collada_parse :: (src: string, filename: string) -> *Collada {
    parser: Xml_Parser;
    xml_init_parser(*parser, src, filename);
    xml_register_hook(*parser, "COLLADA", collada_parse_COLLADA);
    xml_register_hook(*parser, "library_effects", collada_parse_library_effects);
    xml_register_hook(*parser, "effect", collada_parse_effect);
    xml_register_hook(*parser, "color", collada_parse_color);
    xml_register_hook(*parser, "float", collada_parse_float);
    root := xml_parse(*parser);
    ret := root.children[0];
    Delete(root);

    assert(ret.type == Collada);
    return cast(*Collada) ret;
}
