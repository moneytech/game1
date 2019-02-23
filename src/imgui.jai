
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

make_Color :: (col: nk_colorf) -> Color {
    r := col.r;
    g := col.g;
    b := col.b;
    a := col.a;
    return make_Color(r, g, b, a);
}

make_Vector2 :: (vec: nk_vec2i) -> Vector2 {
    v: Vector2 = ---;
    v.x = cast(float) vec.x;
    v.y = cast(float) vec.y;
    return v;
}

render_imgui :: (renderer: *GL_Renderer, ctx: *nk_context) {
    for ctx {
        if it.type == {
            case NK_COMMAND_TRIANGLE_FILLED;
                tri := cast(*nk_command_triangle_filled) it;
                c := nk_color_cf(tri.color);
                color := make_Color(c);
                // draw_rect(<<renderer, cast(float) rect.x, cast(float) rect.y, cast(float) rect.w, cast(float) rect.h, color);
                V2 :: make_Vector2;
                draw_triangle(<<renderer, V2(tri.a), V2(tri.b), V2(tri.c), color);
            case NK_COMMAND_RECT_FILLED;
                rect := cast(*nk_command_rect_filled) it;
                c := nk_color_cf(rect.color);
                color := make_Color(c);
                draw_rect(<<renderer, cast(float) rect.x, cast(float) rect.y, cast(float) rect.w, cast(float) rect.h, color);
            case NK_COMMAND_RECT_MULTI_COLOR;
                rect := cast(*nk_command_rect_multi_color) it;
                left := make_Color(nk_color_cf(rect.left));
                right := make_Color(nk_color_cf(rect.right));
                bottom := make_Color(nk_color_cf(rect.bottom));
                top := make_Color(nk_color_cf(rect.top));

                // print("left: %\n", left);
                // print("right: %\n", right);
                // print("top: %\n", top);
                // print("bottom: %\n", bottom);
                // if bottom.r == 0 && bottom.g == 0 && bottom.b == 0 then assert(false);

                draw_rect_multi_color(<<renderer, cast(float) rect.x, cast(float) rect.y, cast(float) rect.w, cast(float) rect.h, left, right, top, bottom);
            case NK_COMMAND_RECT;
                rect := cast(*nk_command_rect) it;
                c := nk_color_cf(rect.color);
                color := make_Color(c);
                draw_rect_outline(<<renderer, cast(float) rect.x, cast(float) rect.y, cast(float) rect.w, cast(float) rect.h, color);
            case NK_COMMAND_TEXT;
                tex := cast(*nk_command_text) it;
                color := make_Color(nk_color_cf(tex.foreground));
                font := cast(*Font) tex.font.userdata.ptr;
                text: string;
                text.count = tex.length;
                text.data = tex.string.data;
                draw_text(<<renderer, <<font, cast(float) tex.x, cast(float) tex.y + (font.char_height * 3) / 4, text, color=color);
            case NK_COMMAND_CIRCLE_FILLED;
                circ := cast(*nk_command_circle_filled) it;
                assert(circ.w == circ.h);
                c := nk_color_cf(circ.color);
                draw_circle(<<renderer, cast(float) circ.x, cast(float) circ.y, cast(float) circ.w / 2, make_Color(c));
            case NK_COMMAND_LINE;
                line := cast(*nk_command_line) it;
                make_Vector2 :: (v: nk_vec2i) -> Vector2 {
                    return make_Vector2(cast(float) v.x, cast(float) v.y);
                }
                v1 := make_Vector2(line.begin);
                v2 := make_Vector2(line.end);
                c := nk_color_cf(line.color);
                draw_line(<<renderer, v1, v2, make_Color(c), cast(float) line.line_thickness);
            case NK_COMMAND_SCISSOR;
                sci := cast(*nk_command_scissor) it;
                v := make_Viewport(sci.x, sci.y, sci.w, sci.h);
                if sci.x == -8192 then
                    disable_scissor();
                else {
                    off := v.y + cast(s32) v.h;
                    if renderer.current_frame_buffer then v.y = cast(s32) renderer.current_frame_buffer.viewport.h - off;
                    else v.y = cast(s32) renderer.game.window.height - off;

                    enable_scissor(v);
                }
            case;
                print("cmd: %\n", it.type);
        }
    }
}


