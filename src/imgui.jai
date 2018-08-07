
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
    for ctx {
        print("cmd: %\n", it.type);
    }
}


