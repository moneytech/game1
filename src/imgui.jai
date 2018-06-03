
Imgui :: struct {
    renderer: *GL_Renderer;
    hot: ID_TYPE;
    active: ID_TYPE;

    mouse_went_up: bool;
    mouse_went_down: bool;

    mouse_x: s32;
    mouse_y: s32;
}

ID_TYPE :: s32;


do_label :: (using ui: *Imgui, my_id: ID_TYPE, font: Font, x: float, y: float, text: string) -> bool {
    result := false;
    if is_active(ui, my_id) {
        if mouse_went_up {
            if is_hot(ui, my_id) result = true;
            active = 0;
        }
    } else if is_hot(ui, my_id) {
        if mouse_went_down active = my_id;
    }

    if is_mouse_inside(ui, cast(s32) x, cast(s32) y, cast(s32) font_get_length(font, text), cast(s32) font.char_height) {
        hot = my_id;
    } else if is_hot(ui, my_id) hot = 0;

    color: Color = make_Color(1, 1, 1);
    if is_hot(ui, my_id) color = make_Color(1, 0, 0);
    if is_active(ui, my_id) color=  make_Color(0, 1, 0);
    test := draw_text(<<renderer, font, x, y + font.char_height*0.75, text, color=color);
    return result;
}

#scope_file

is_hot :: (using ui: *Imgui, id: ID_TYPE) -> bool {
    return hot == id;
}

is_active :: (using ui: *Imgui, id: ID_TYPE) -> bool {
    return active == id;
}

is_mouse_inside :: (using ui: *Imgui, x: s32, y: s32, w: s32, h: s32) -> bool {
    return mouse_x >= x  && mouse_x <= x+w && mouse_y >= y && mouse_y <= y+h;
}