

#scope_file

update_camera :: (game: *Game, dt: float) {
    using Key_Current_State;

    if input_button_states[Key_Code.MOUSE_BUTTON_LEFT] & DOWN {
        delta := make_Vector3(xx mouse_delta_x, xx mouse_delta_y, 0);
        q := game.renderer.camera.rotation;

        delta = mul(delta, make_Vector3(1.0/cast(float)WINDOW_WIDTH, 1.0/cast(float)WINDOW_HEIGHT, 0)); // nomalize pixels to viewport

        move := q * delta;

        // print("move: %\n", move);

        game.renderer.camera.position += move;
    }
}

#scope_export

update_editor :: (game: *Game, dt: float) {
    update_camera(game, dt);
}
