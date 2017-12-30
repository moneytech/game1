#load "xml_parser.jai";

Collada :: struct {
    using xml: Xml_Node;
    library_effects: [..] *Effect;
    library_geometries: [..] *Geometry;
    library_images: [..] *Image;
    library_materials: [..] *Material;
    library_visual_scenes: [..] *Xml_Node;
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

    textures: [..] *Texture;
    surfaces: [..] *Xml_Node; // Read: newparam
    sampler2Ds: [..] *Xml_Node; // Read: sampler2D 
}

Material :: struct {
    using xml: Xml_Node;
    id: string;
    name: string;

    instance: *Effect;

    // these are resolved for user convinience
    bump_index :: 0;
    textures: [1] *Image;
}

Texture :: struct {
    using xml: Xml_Node;
    texture: string;
    texcoord: string;
    texture_type: Collada_Texture_Type;
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
    using xml: Xml_Node;
    id: string;
    array: [] float;
}

Int_Array :: struct {
    using xml: Xml_Node;
    array: [] int;
}

Geometry :: struct {
    using xml: Xml_Node;
    meshes: [..] *Collada_Mesh;
}

Collada_Mesh :: struct {
    using xml: Xml_Node;
    position_index: int = -1;
    normal_index: int = -1;
    texcoords_index: int = -1;
    // @Incomplete other vertex properties
    vertex_data: [3] [..] float;
}

Image :: struct {
    using xml: Xml_Node;
    id: string;
    name: string;
    filepath: string;
}

using ML_Token_Type;

#scope_export

Collada_Texture_Type :: enum u16 {
    NONE : 0,
    BUMP,
}

collada_parse_source :: (p: *Xml_Parser, node_type: string, parent: *Xml_Node, properties: [..] *Xml_Property) -> *Xml_Node {
    xml := XML_NEW(p, Xml_Node, node_type);
    if starts_with(parent.node_type, "sampler") {
        xml.content_string = xml_parse_string(p, ML_TOKEN_HTML_LT_SLASH);
        print("PARSE sampler %\n", xml.content_string);
    } else {
        xml.children = xml_parse_child_loop(p, xml);
        print("Parent: %\n", parent.node_type);
    }
    return xml;
}

collada_parse_float :: (p: *Xml_Parser, node_type: string, parent: *Xml_Node, properties: [..] *Xml_Property) -> *Xml_Node {
    fl := XML_NEW(p, Float, node_type);
    fl.sid = xml_get_property(properties, "sid").content;
    fl.value = cast(float32) xml_parse_float(p);
    return fl;
}

collada_parse_float_array :: (p: *Xml_Parser, node_type: string, parent: *Xml_Node, properties: [..] *Xml_Property) -> *Xml_Node {
    fl := XML_NEW(p, Float_Array, node_type);
    fl.id = xml_get_property(properties, "id").content;
    array_data: [..] float;
    while xml_peek_token(p).type != ML_TOKEN_HTML_LT_SLASH {
        val := xml_parse_float(p);
        array_add(*array_data, cast(float32) val);
    }
    fl.array = array_data;
    return fl;
} 

collada_parse_color :: (p: *Xml_Parser, node_type: string, parent: *Xml_Node, properties: [..] *Xml_Property) -> *Xml_Node {
    color := XML_NEW(p, Color, node_type);
    color.sid = xml_get_property(properties, "sid").content;
    color.color[0] = cast(float32) xml_parse_float(p);
    color.color[1] = cast(float32) xml_parse_float(p);
    color.color[2] = cast(float32) xml_parse_float(p);

    if xml_peek_token(p).type != ML_TOKEN_HTML_LT_SLASH color.color[3] = cast(float32) xml_parse_float(p);
    return color;
}

collada_parse_init_from :: (p: *Xml_Parser, node_type: string, parent: *Xml_Node, properties: [..] *Xml_Property) -> *Xml_Node {
    xml := XML_NEW(p, Xml_Node, node_type);
    xml.content_string = xml_parse_string(p, ML_TOKEN_HTML_LT_SLASH);
    return xml;
}

collada_parse_image :: (p: *Xml_Parser, node_type: string, parent: *Xml_Node, properties: [..] *Xml_Property) -> *Xml_Node {
    image := XML_NEW(p, Image, node_type);
    children := xml_parse_child_loop(p, image);
    image.id = xml_get_property(properties, "id").content;
    image.name = xml_get_property(properties, "name").content;
    for children {
        if it.node_type == "init_from" {
            image.filepath = it.content_string;
        }
    }
    return image;
}

collada_parse_effect :: (p: *Xml_Parser, node_type: string, parent: *Xml_Node, properties: [..] *Xml_Property) -> *Xml_Node {
    effect := XML_NEW(p, Effect, node_type);
    effect.id = xml_get_property(properties, "id").content;

    children := xml_parse_child_loop(p, effect);

    for children[0].children {
        if it.node_type == "technique" {
            for ch: it.children {
                if ch.node_type == "phong" {
                    phong := ch;
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
                } else if ch.node_type == "extra" {
                    for extra_ch: ch.children[0].children {
                        if extra_ch.node_type == "bump" {
                            assert(extra_ch.children[0].node_type == "texture");
                            tch := extra_ch.children[0];
                            tex := XML_NEW(p, Texture, "texture");
                            << cast(*Xml_Node) tex = <<tch;
                            tex.texture_type = Collada_Texture_Type.BUMP;
                            tex.texcoord = xml_get_property(tex, "texcoord").content;
                            tex.texture = xml_get_property(tex, "texture").content;
                            array_add(*effect.textures, tex);
                        }
                    }
                }
            }
        } else if it.node_type == "newparam" {
            if it.children[0].node_type == {
                case "sampler2D"; array_add(*effect.sampler2Ds, it);
                case "surface"; array_add(*effect.surfaces, it);
                case; assert(false);
            }
        }
    }

    return effect;
}

collada_parse_material :: (p: *Xml_Parser, node_type: string, parent: *Xml_Node, properties: [..] *Xml_Property) -> *Xml_Node {
    collada := cast(*Collada) p.user_data;
    material := XML_NEW(p, Material, node_type);
    children := xml_parse_child_loop(p, material);

    material.id = xml_get_property(properties, "id").content;
    material.name = xml_get_property(properties, "name").content;

    for children {
        if it.node_type == "instance_effect" {
            target := xml_get_property(it, "url").content;
            target.data += 1;
            target.count -= 1;

            for effect: collada.library_effects {
                if effect.id == target {
                    material.instance = effect;
                    break;
                }
            }
        }
    }

    instance := material.instance;
    if instance {
        for texture: instance.textures {
            sampler := texture.texture;
            image_target: string;
            for samp: instance.sampler2Ds {
                if xml_get_property(samp, "sid").content == sampler {
                    surface_target := samp.children[0].children[0].content_string;
                    print("SURFACE: %\n", surface_target);
                    for surf: instance.surfaces {
                        if xml_get_property(surf, "sid").content == surface_target {
                            image_target = surf.children[0].children[0].content_string;
                            print("TARGET FOUND: %\n", image_target);
                            break;
                        }
                    }

                    break;
                }
            }

            if image_target != "" {
                for image: collada.library_images {
                    print("Image: %\n", image.id);
                    if image.id == image_target {
                        if texture.texture_type == {
                            case Collada_Texture_Type.BUMP;
                                material.textures[material.bump_index] = image;
                            case; assert(false);
                        }

                        break;
                    }
                }
            }
        }
    }

    return material;
}

collada_parse_int_array :: (p: *Xml_Parser, node_type: string, parent: *Xml_Node, properties: [..] *Xml_Property) -> *Xml_Node {
    node := XML_NEW(p, Int_Array, node_type);
    array_data: [..] int;
    while xml_peek_token(p).type != ML_TOKEN_HTML_LT_SLASH {
        val := xml_parse_int(p);
        array_add(*array_data, val);
    }
    node.array = array_data;
    return node;
}

collada_parse_mesh :: (p: *Xml_Parser, node_type: string, parent: *Xml_Node, properties: [..] *Xml_Property) -> *Xml_Node {
    mesh := XML_NEW(p, Collada_Mesh, node_type);
    children := xml_parse_child_loop(p, mesh);

    polylist: *Xml_Node;
    for children {
        if it.node_type == "polylist" {
            polylist = it;
            break;
        }
    }

    sources: [..] *Float_Array;
    offsets: [..] int;
    components: [..] int;

    // input pass
    for pch: polylist.children {
        if pch.node_type == "input" {
            source: *Float_Array;
            target := xml_get_property(pch, "source").content;
            target.data += 1; // skip #
            target.count -= 1;
            source_name: string;
            semantic := xml_get_property(pch, "semantic").content;
            if semantic == "VERTEX" {
                for children {
                     if it.node_type == "vertices" && xml_get_property(it, "id").content == target {
                        source_name = xml_get_property(it.children[0], "source").content; // @Hack
                        source_name.data += 1;
                        source_name.count -= 1;
                        break;
                     }
                }
            } else {
                source_name = target;
            }

            for child: children {
                if child.node_type == "source" && xml_get_property(child, "id").content == source_name {
                    for ch: child.children {
                        if ch.type == Float_Array {
                            source = cast(*Float_Array) ch;
                            break;
                        }
                    }
                }
            }

            offset, success := string_to_int(xml_get_property(pch, "offset").content);
            assert(success);
            assert(source != null);

            array_add(*sources, source);
            array_add(*offsets, offset);

            if semantic == {
                case "VERTEX"; mesh.position_index = offset; array_add(*components, 3);
                case "NORMAL"; mesh.normal_index = offset; array_add(*components, 3);
                case "TEXCOORD"; mesh.texcoords_index = offset; array_add(*components, 2);
            }
        }
    }

    _sources: [..] *Float_Array;
    _components: [..] int;
    array_resize(*_sources, sources.count);
    array_resize(*_components, components.count);
    for offsets {
        _sources[it] = sources[it_index];
        _components[it] = components[it_index];
    }

    assert(_sources.count == sources.count);
    assert(sources.count == offsets.count);

    for pch: polylist.children {
        if pch.node_type == "p" {
            ia := cast(*Int_Array) pch;
            for ia.array {
                sel := it_index % offsets.count;
                index := it * _components[sel];
                array_add(*mesh.vertex_data[sel], _sources[sel].array[index]);
                array_add(*mesh.vertex_data[sel], _sources[sel].array[index+1]);
                if _components[sel] > 2 array_add(*mesh.vertex_data[sel], _sources[sel].array[index+2]);
            }
            break;
        }
    }

    return mesh;
}

collada_parse_geometry :: (p: *Xml_Parser, node_type: string, parent: *Xml_Node, properties: [..] *Xml_Property) -> *Xml_Node {
    geom := XML_NEW(p, Geometry, node_type);
    children := xml_parse_child_loop(p, geom);
    for children {
        assert(it.type == Collada_Mesh);
        mesh := cast(*Collada_Mesh) it;
        array_add(*geom.meshes, mesh);
    }
    if children.data free(children.data);
    return geom;
}

collada_parse_library_effects :: (p: *Xml_Parser, node_type: string, parent: *Xml_Node, properties: [..] *Xml_Property) -> *Xml_Node {
    collada := cast(*Collada) p.user_data;
    children := xml_parse_child_loop(p);
    for children {
        assert(it.type == Effect);
        array_add(*collada.library_effects, cast(*Effect) it);
    }
    return null;
}

collada_parse_library_geometries :: (p: *Xml_Parser, node_type: string, parent: *Xml_Node, properties: [..] *Xml_Property) -> *Xml_Node {
    collada := cast(*Collada) p.user_data;
    children := xml_parse_child_loop(p);
    for children {
        assert(it.type == Geometry);
        array_add(*collada.library_geometries, cast(*Geometry) it);
    }
    return null;
}

collada_parse_library_images :: (p: *Xml_Parser, node_type: string, parent: *Xml_Node, properties: [..] *Xml_Property) -> *Xml_Node {
    collada := cast(*Collada) p.user_data;
    children := xml_parse_child_loop(p);
    for children {
        assert(it.type == Image);
        array_add(*collada.library_images, cast(*Image) it);
    }
    return null;
}

collada_parse_library_materials :: (p: *Xml_Parser, node_type: string, parent: *Xml_Node, properties: [..] *Xml_Property) -> *Xml_Node {
    collada := cast(*Collada) p.user_data;
    children := xml_parse_child_loop(p);
    for children {
        assert(it.type == Material);
        array_add(*collada.library_materials, cast(*Material) it);
    }
    return null;
}

collada_parse_library_visual_scenes :: (p: *Xml_Parser, node_type: string, parent: *Xml_Node, properties: [..] *Xml_Property) -> *Xml_Node {
    collada := cast(*Collada) p.user_data;
    children := xml_parse_child_loop(p);
    for children {
        assert(it.node_type == "visual_scene");
        array_add(*collada.library_visual_scenes, it);
    }
    return null;
}

collada_parse_COLLADA :: (p: *Xml_Parser, node_type: string, parent: *Xml_Node, properties: [..] *Xml_Property) -> *Xml_Node {
    collada := XML_NEW(p, Collada, node_type);
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
    xml_register_hook(*parser, "library_geometries", collada_parse_library_geometries);
    xml_register_hook(*parser, "library_images", collada_parse_library_images);
    xml_register_hook(*parser, "library_materials", collada_parse_library_materials);
    xml_register_hook(*parser, "library_visual_scenes", collada_parse_library_visual_scenes);
    xml_register_hook(*parser, "effect", collada_parse_effect);
    xml_register_hook(*parser, "color", collada_parse_color);
    xml_register_hook(*parser, "float", collada_parse_float);
    xml_register_hook(*parser, "float_array", collada_parse_float_array);
    xml_register_hook(*parser, "mesh", collada_parse_mesh);
    xml_register_hook(*parser, "geometry", collada_parse_geometry);
    xml_register_hook(*parser, "p", collada_parse_int_array);
    xml_register_hook(*parser, "vcount", collada_parse_int_array);
    xml_register_hook(*parser, "init_from", collada_parse_init_from);
    xml_register_hook(*parser, "image", collada_parse_image);
    xml_register_hook(*parser, "source", collada_parse_source);
    xml_register_hook(*parser, "material", collada_parse_material);
    root := xml_parse(*parser);
    ret := root.children[0];
    Delete(root);

    assert(ret.type == Collada);
    return cast(*Collada) ret;
}
