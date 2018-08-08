
Nk_Command_Iterator :: struct {
    ctx: *nk_context;
    cmd: *nk_command;
}

iterator_make :: (ctx: *nk_context) -> Nk_Command_Iterator {
    i: Nk_Command_Iterator;
    i.ctx = ctx;
    i.cmd = nk__begin(ctx);
    return i;
}

iterator_next :: (i: *Nk_Command_Iterator) {
    i.cmd = nk__next(i.ctx, i.cmd);
}

iterator_get_value :: (i: *Nk_Command_Iterator) -> *nk_command, bool {
    cmd := i.cmd;
    return cmd, cmd != null;
}


render_imgui :: (renderer: *GL_Renderer, ctx: *nk_context) {
    make_Color :: (col: nk_colorf) -> Color {
        r := col.r;
        g := col.g;
        b := col.b;
        a := col.a;
        return make_Color(r, g, b);
    }

    for ctx {
        if it.type == {
            case NK_COMMAND_RECT_FILLED;
                rect := cast(*nk_command_rect_filled) it;
                c := nk_color_cf(rect.color);
                color := make_Color(c);
                draw_rect(<<renderer, cast(float) rect.x, cast(float) rect.y, cast(float) rect.w, cast(float) rect.h, color, c.a);
            case NK_COMMAND_TEXT;
                tex := cast(*nk_command_text) it;
                color := make_Color(nk_color_cf(tex.foreground));
                font := cast(*Font) tex.font.userdata.ptr;
                text: string;
                text.count = tex.length;
                text.data = tex.string.data;
                draw_text(<<renderer, <<font, cast(float) tex.x, cast(float) tex.y + (font.char_height * 3) / 4, text, color=color);
            case;
                print("cmd: %\n", it.type);
        }
    }
}


