

Game :: struct {
    renderer: *GL_Renderer;
    asset_man: *Asset_Manager;
    window: *Game_Window;
    joy: *Joystick;
    current_scene: *Scene;
    text_strings: [..] string;

    fov: float = 60;

    water_reflect_frame_buffer: Frame_Buffer;
    water_refract_frame_buffer: Frame_Buffer;
    water_dudv_texture: *Texture;
}

Scene :: struct {
    models: [..] *Model;
    actors: [..] *Actor;
    cameras: [..] Camera;
    lights: [..] Light;

    active_camera: Camera;
}

draw_scene :: (rdr: *GL_Renderer, sc: Scene) {
    for sc.actors {
        if it.body && it.model {
            orient := matrix_rotate(it.orientiation);
            it.model.model_matrix = matrix_translate(it.body.position) * orient;
        }
    }
    for sc.models draw_model(rdr, <<it);
}

update_scene :: (game: *Game, sc: *Scene, dt: float) {
    for sc.actors {
        if it.update_callback it.update_callback(game, it, dt);
    }
}

Actor :: struct {
    model: *Model;
    body: *Rigid_Body;
    orientiation: Quaternion; // orientiation around Y axis

    update_callback: (game: *Game, actor: *Actor, dt: float);
    picked_by_player: (game: *Game, actor: *Actor, player: *Actor, dt: float);
}

Game_Window :: struct {
    width: u32;
    height: u32;

    handle: OS_Window;
    glc: OS_GL_Context;
}
