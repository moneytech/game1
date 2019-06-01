libnuklear :: #foreign_library "../run_tree/nuklear";

nk_char :: u8;

nk_uchar :: u8;

nk_byte :: u8;

nk_short :: s16;

nk_ushort :: u16;

nk_int :: s32;

nk_uint :: u32;

nk_size :: u64;

nk_ptr :: u64;

nk_hash :: nk_uint;

nk_flags :: nk_uint;

nk_rune :: nk_uint;

_dummy_array0 :: [1] u8;

_dummy_array1 :: [1] u8;

_dummy_array2 :: [1] u8;

_dummy_array3 :: [1] u8;

_dummy_array4 :: [1] u8;

_dummy_array5 :: [1] u8;

_dummy_array6 :: [1] u8;

_dummy_array7 :: [1] u8;

_dummy_array8 :: [1] u8;

nk_draw_command :: struct {
}

nk_draw_list :: struct {
}

nk_draw_vertex_layout_element :: struct {
}

nk_style_slide :: struct {
}

nk_false :: 0;
nk_true :: 1;

nk_color :: struct {
    r: nk_byte;
    g: nk_byte;
    b: nk_byte;
    a: nk_byte;
}

nk_colorf :: struct {
    r: float32;
    g: float32;
    b: float32;
    a: float32;
}

nk_vec2 :: struct {
    x: float32;
    y: float32;
}

nk_vec2i :: struct {
    x: s16;
    y: s16;
}

nk_rect :: struct {
    x: float32;
    y: float32;
    w: float32;
    h: float32;
}

nk_recti :: struct {
    x: s16;
    y: s16;
    w: s16;
    h: s16;
}

nk_glyph :: [4] u8;

nk_handle :: union {
    ptr: *void;
    id: s32;
}

nk_image :: struct {
    handle: nk_handle;
    w: u16;
    h: u16;
    region: [4] u16;
}

nk_cursor :: struct {
    img: nk_image;
    size: nk_vec2;
    offset: nk_vec2;
}

nk_scroll :: struct {
    x: nk_uint;
    y: nk_uint;
}

using nk_heading :: enum s32 {
    NK_UP :: 0;
    NK_RIGHT :: 1;
    NK_DOWN :: 2;
    NK_LEFT :: 3;
}

using nk_button_behavior :: enum s32 {
    NK_BUTTON_DEFAULT :: 0;
    NK_BUTTON_REPEATER :: 1;
}

using nk_modify :: enum s32 {
    NK_FIXED :: 0;
    NK_MODIFIABLE :: 1;
}

using nk_orientation :: enum s32 {
    NK_VERTICAL :: 0;
    NK_HORIZONTAL :: 1;
}

using nk_collapse_states :: enum s32 {
    NK_MINIMIZED :: 0;
    NK_MAXIMIZED :: 1;
}

using nk_show_states :: enum s32 {
    NK_HIDDEN :: 0;
    NK_SHOWN :: 1;
}

using nk_chart_type :: enum s32 {
    NK_CHART_LINES :: 0;
    NK_CHART_COLUMN :: 1;
    NK_CHART_MAX :: 2;
}

using nk_chart_event :: enum s32 {
    NK_CHART_HOVERING :: 1;
    NK_CHART_CLICKED :: 2;
}

using nk_color_format :: enum s32 {
    NK_RGB :: 0;
    NK_RGBA :: 1;
}

using nk_popup_type :: enum s32 {
    NK_POPUP_STATIC :: 0;
    NK_POPUP_DYNAMIC :: 1;
}

using nk_layout_format :: enum s32 {
    NK_DYNAMIC :: 0;
    NK_STATIC :: 1;
}

using nk_tree_type :: enum s32 {
    NK_TREE_NODE :: 0;
    NK_TREE_TAB :: 1;
}

nk_plugin_alloc :: #type (a0: nk_handle, a1: *void, a2: nk_size) -> *void #c_callback;

nk_plugin_free :: #type (a0: nk_handle, a1: *void) -> void #c_callback;

nk_plugin_filter :: #type (a0: *nk_text_edit, a1: nk_rune) -> s32 #c_callback;

nk_plugin_paste :: #type (a0: nk_handle, a1: *nk_text_edit) -> void #c_callback;

nk_plugin_copy :: #type (a0: nk_handle, a1: *u8, a2: s32) -> void #c_callback;

nk_allocator :: struct {
    userdata: nk_handle;
    alloc: nk_plugin_alloc;
    free: nk_plugin_free;
}

using nk_symbol_type :: enum s32 {
    NK_SYMBOL_NONE :: 0;
    NK_SYMBOL_X :: 1;
    NK_SYMBOL_UNDERSCORE :: 2;
    NK_SYMBOL_CIRCLE_SOLID :: 3;
    NK_SYMBOL_CIRCLE_OUTLINE :: 4;
    NK_SYMBOL_RECT_SOLID :: 5;
    NK_SYMBOL_RECT_OUTLINE :: 6;
    NK_SYMBOL_TRIANGLE_UP :: 7;
    NK_SYMBOL_TRIANGLE_DOWN :: 8;
    NK_SYMBOL_TRIANGLE_LEFT :: 9;
    NK_SYMBOL_TRIANGLE_RIGHT :: 10;
    NK_SYMBOL_PLUS :: 11;
    NK_SYMBOL_MINUS :: 12;
    NK_SYMBOL_MAX :: 13;
}

nk_init_fixed :: (unk0: *nk_context, memory: *void, size: nk_size, unk1: *nk_user_font) -> s32 #foreign libnuklear;

nk_init :: (unk0: *nk_context, unk1: *nk_allocator, unk2: *nk_user_font) -> s32 #foreign libnuklear;

nk_init_custom :: (unk0: *nk_context, cmds: *nk_buffer, pool: *nk_buffer, unk1: *nk_user_font) -> s32 #foreign libnuklear;

nk_clear :: (unk0: *nk_context) -> void #foreign libnuklear;

nk_free :: (unk0: *nk_context) -> void #foreign libnuklear;

using nk_keys :: enum s32 {
    NK_KEY_NONE :: 0;
    NK_KEY_SHIFT :: 1;
    NK_KEY_CTRL :: 2;
    NK_KEY_DEL :: 3;
    NK_KEY_ENTER :: 4;
    NK_KEY_TAB :: 5;
    NK_KEY_BACKSPACE :: 6;
    NK_KEY_COPY :: 7;
    NK_KEY_CUT :: 8;
    NK_KEY_PASTE :: 9;
    NK_KEY_UP :: 10;
    NK_KEY_DOWN :: 11;
    NK_KEY_LEFT :: 12;
    NK_KEY_RIGHT :: 13;
    NK_KEY_TEXT_INSERT_MODE :: 14;
    NK_KEY_TEXT_REPLACE_MODE :: 15;
    NK_KEY_TEXT_RESET_MODE :: 16;
    NK_KEY_TEXT_LINE_START :: 17;
    NK_KEY_TEXT_LINE_END :: 18;
    NK_KEY_TEXT_START :: 19;
    NK_KEY_TEXT_END :: 20;
    NK_KEY_TEXT_UNDO :: 21;
    NK_KEY_TEXT_REDO :: 22;
    NK_KEY_TEXT_SELECT_ALL :: 23;
    NK_KEY_TEXT_WORD_LEFT :: 24;
    NK_KEY_TEXT_WORD_RIGHT :: 25;
    NK_KEY_SCROLL_START :: 26;
    NK_KEY_SCROLL_END :: 27;
    NK_KEY_SCROLL_DOWN :: 28;
    NK_KEY_SCROLL_UP :: 29;
    NK_KEY_MAX :: 30;
}

using nk_buttons :: enum s32 {
    NK_BUTTON_LEFT :: 0;
    NK_BUTTON_MIDDLE :: 1;
    NK_BUTTON_RIGHT :: 2;
    NK_BUTTON_DOUBLE :: 3;
    NK_BUTTON_MAX :: 4;
}

nk_input_begin :: (unk0: *nk_context) -> void #foreign libnuklear;

nk_input_motion :: (unk0: *nk_context, x: s32, y: s32) -> void #foreign libnuklear;

nk_input_key :: (unk0: *nk_context, unk1: nk_keys, down: s32) -> void #foreign libnuklear;

nk_input_button :: (unk0: *nk_context, unk1: nk_buttons, x: s32, y: s32, down: s32) -> void #foreign libnuklear;

nk_input_scroll :: (unk0: *nk_context, val: nk_vec2) -> void #foreign libnuklear;

nk_input_char :: (unk0: *nk_context, unk1: u8) -> void #foreign libnuklear;

nk_input_glyph :: (unk0: *nk_context, unk1: nk_glyph) -> void #foreign libnuklear;

nk_input_unicode :: (unk0: *nk_context, unk1: nk_rune) -> void #foreign libnuklear;

nk_input_end :: (unk0: *nk_context) -> void #foreign libnuklear;

using nk_anti_aliasing :: enum s32 {
    NK_ANTI_ALIASING_OFF :: 0;
    NK_ANTI_ALIASING_ON :: 1;
}

using nk_convert_result :: enum s32 {
    NK_CONVERT_SUCCESS :: 0;
    NK_CONVERT_INVALID_PARAM :: 1;
    NK_CONVERT_COMMAND_BUFFER_FULL :: 2;
    NK_CONVERT_VERTEX_BUFFER_FULL :: 4;
    NK_CONVERT_ELEMENT_BUFFER_FULL :: 8;
}

nk_draw_null_texture :: struct {
    texture: nk_handle;
    uv: nk_vec2;
}

nk_convert_config :: struct {
    global_alpha: float32;
    line_AA: nk_anti_aliasing;
    shape_AA: nk_anti_aliasing;
    circle_segment_count: u32;
    arc_segment_count: u32;
    curve_segment_count: u32;
    _null: nk_draw_null_texture;
    vertex_layout: *nk_draw_vertex_layout_element;
    vertex_size: nk_size;
    vertex_alignment: nk_size;
}

nk__begin :: (unk0: *nk_context) -> *nk_command #foreign libnuklear;

nk__next :: (unk0: *nk_context, unk1: *nk_command) -> *nk_command #foreign libnuklear;

using nk_panel_flags :: enum_flags nk_flags {
    NK_WINDOW_BORDER :: 1;
    NK_WINDOW_MOVABLE :: 2;
    NK_WINDOW_SCALABLE :: 4;
    NK_WINDOW_CLOSABLE :: 8;
    NK_WINDOW_MINIMIZABLE :: 16;
    NK_WINDOW_NO_SCROLLBAR :: 32;
    NK_WINDOW_TITLE :: 64;
    NK_WINDOW_SCROLL_AUTO_HIDE :: 128;
    NK_WINDOW_BACKGROUND :: 256;
    NK_WINDOW_SCALE_LEFT :: 512;
    NK_WINDOW_NO_INPUT :: 1024;
}

nk_begin :: (ctx: *nk_context, title: *u8, bounds: nk_rect, flags: nk_panel_flags) -> s32 #foreign libnuklear;

nk_begin_titled :: (ctx: *nk_context, name: *u8, title: *u8, bounds: nk_rect, flags: nk_panel_flags) -> s32 #foreign libnuklear;

nk_end :: (ctx: *nk_context) -> void #foreign libnuklear;

nk_window_find :: (ctx: *nk_context, name: *u8) -> *nk_window #foreign libnuklear;

nk_window_get_bounds :: (ctx: *nk_context) -> nk_rect #foreign libnuklear;

nk_window_get_position :: (ctx: *nk_context) -> nk_vec2 #foreign libnuklear;

nk_window_get_size :: (unk0: *nk_context) -> nk_vec2 #foreign libnuklear;

nk_window_get_width :: (unk0: *nk_context) -> float32 #foreign libnuklear;

nk_window_get_height :: (unk0: *nk_context) -> float32 #foreign libnuklear;

nk_window_get_panel :: (unk0: *nk_context) -> *nk_panel #foreign libnuklear;

nk_window_get_content_region :: (unk0: *nk_context) -> nk_rect #foreign libnuklear;

nk_window_get_content_region_min :: (unk0: *nk_context) -> nk_vec2 #foreign libnuklear;

nk_window_get_content_region_max :: (unk0: *nk_context) -> nk_vec2 #foreign libnuklear;

nk_window_get_content_region_size :: (unk0: *nk_context) -> nk_vec2 #foreign libnuklear;

nk_window_get_canvas :: (unk0: *nk_context) -> *nk_command_buffer #foreign libnuklear;

nk_window_has_focus :: (unk0: *nk_context) -> s32 #foreign libnuklear;

nk_window_is_hovered :: (unk0: *nk_context) -> s32 #foreign libnuklear;

nk_window_is_collapsed :: (ctx: *nk_context, name: *u8) -> s32 #foreign libnuklear;

nk_window_is_closed :: (unk0: *nk_context, unk1: *u8) -> s32 #foreign libnuklear;

nk_window_is_hidden :: (unk0: *nk_context, unk1: *u8) -> s32 #foreign libnuklear;

nk_window_is_active :: (unk0: *nk_context, unk1: *u8) -> s32 #foreign libnuklear;

nk_window_is_any_hovered :: (unk0: *nk_context) -> s32 #foreign libnuklear;

nk_item_is_any_active :: (unk0: *nk_context) -> s32 #foreign libnuklear;

nk_window_set_bounds :: (unk0: *nk_context, name: *u8, bounds: nk_rect) -> void #foreign libnuklear;

nk_window_set_position :: (unk0: *nk_context, name: *u8, pos: nk_vec2) -> void #foreign libnuklear;

nk_window_set_size :: (unk0: *nk_context, name: *u8, unk1: nk_vec2) -> void #foreign libnuklear;

nk_window_set_focus :: (unk0: *nk_context, name: *u8) -> void #foreign libnuklear;

nk_window_close :: (ctx: *nk_context, name: *u8) -> void #foreign libnuklear;

nk_window_collapse :: (unk0: *nk_context, name: *u8, state: nk_collapse_states) -> void #foreign libnuklear;

nk_window_collapse_if :: (unk0: *nk_context, name: *u8, unk1: nk_collapse_states, cond: s32) -> void #foreign libnuklear;

nk_window_show :: (unk0: *nk_context, name: *u8, unk1: nk_show_states) -> void #foreign libnuklear;

nk_window_show_if :: (unk0: *nk_context, name: *u8, unk1: nk_show_states, cond: s32) -> void #foreign libnuklear;

nk_layout_set_min_row_height :: (unk0: *nk_context, height: float32) -> void #foreign libnuklear;

nk_layout_reset_min_row_height :: (unk0: *nk_context) -> void #foreign libnuklear;

nk_layout_widget_bounds :: (unk0: *nk_context) -> nk_rect #foreign libnuklear;

nk_layout_ratio_from_pixel :: (unk0: *nk_context, pixel_width: float32) -> float32 #foreign libnuklear;

nk_layout_row_dynamic :: (ctx: *nk_context, height: float32, cols: s32) -> void #foreign libnuklear;

nk_layout_row_static :: (ctx: *nk_context, height: float32, item_width: s32, cols: s32) -> void #foreign libnuklear;

nk_layout_row_begin :: (ctx: *nk_context, fmt: nk_layout_format, row_height: float32, cols: s32) -> void #foreign libnuklear;

nk_layout_row_push :: (unk0: *nk_context, value: float32) -> void #foreign libnuklear;

nk_layout_row_end :: (unk0: *nk_context) -> void #foreign libnuklear;

nk_layout_row :: (unk0: *nk_context, unk1: nk_layout_format, height: float32, cols: s32, ratio: *float32) -> void #foreign libnuklear;

nk_layout_row_template_begin :: (unk0: *nk_context, row_height: float32) -> void #foreign libnuklear;

nk_layout_row_template_push_dynamic :: (unk0: *nk_context) -> void #foreign libnuklear;

nk_layout_row_template_push_variable :: (unk0: *nk_context, min_width: float32) -> void #foreign libnuklear;

nk_layout_row_template_push_static :: (unk0: *nk_context, width: float32) -> void #foreign libnuklear;

nk_layout_row_template_end :: (unk0: *nk_context) -> void #foreign libnuklear;

nk_layout_space_begin :: (unk0: *nk_context, unk1: nk_layout_format, height: float32, widget_count: s32) -> void #foreign libnuklear;

nk_layout_space_push :: (unk0: *nk_context, bounds: nk_rect) -> void #foreign libnuklear;

nk_layout_space_end :: (unk0: *nk_context) -> void #foreign libnuklear;

nk_layout_space_bounds :: (unk0: *nk_context) -> nk_rect #foreign libnuklear;

nk_layout_space_to_screen :: (unk0: *nk_context, unk1: nk_vec2) -> nk_vec2 #foreign libnuklear;

nk_layout_space_to_local :: (unk0: *nk_context, unk1: nk_vec2) -> nk_vec2 #foreign libnuklear;

nk_layout_space_rect_to_screen :: (unk0: *nk_context, unk1: nk_rect) -> nk_rect #foreign libnuklear;

nk_layout_space_rect_to_local :: (unk0: *nk_context, unk1: nk_rect) -> nk_rect #foreign libnuklear;

nk_group_begin :: (unk0: *nk_context, title: *u8, unk1: nk_flags) -> s32 #foreign libnuklear;

nk_group_begin_titled :: (unk0: *nk_context, name: *u8, title: *u8, unk1: nk_flags) -> s32 #foreign libnuklear;

nk_group_end :: (unk0: *nk_context) -> void #foreign libnuklear;

nk_group_scrolled_offset_begin :: (unk0: *nk_context, x_offset: *nk_uint, y_offset: *nk_uint, title: *u8, flags: nk_flags) -> s32 #foreign libnuklear;

nk_group_scrolled_begin :: (unk0: *nk_context, off: *nk_scroll, title: *u8, unk1: nk_flags) -> s32 #foreign libnuklear;

nk_group_scrolled_end :: (unk0: *nk_context) -> void #foreign libnuklear;

nk_tree_push_hashed :: (unk0: *nk_context, unk1: nk_tree_type, title: *u8, initial_state: nk_collapse_states, hash: *u8, len: s32, seed: s32) -> s32 #foreign libnuklear;

nk_tree_image_push_hashed :: (unk0: *nk_context, unk1: nk_tree_type, unk2: nk_image, title: *u8, initial_state: nk_collapse_states, hash: *u8, len: s32, seed: s32) -> s32 #foreign libnuklear;

nk_tree_pop :: (unk0: *nk_context) -> void #foreign libnuklear;

nk_tree_state_push :: (unk0: *nk_context, unk1: nk_tree_type, title: *u8, state: *nk_collapse_states) -> s32 #foreign libnuklear;

nk_tree_state_image_push :: (unk0: *nk_context, unk1: nk_tree_type, unk2: nk_image, title: *u8, state: *nk_collapse_states) -> s32 #foreign libnuklear;

nk_tree_state_pop :: (unk0: *nk_context) -> void #foreign libnuklear;

nk_tree_element_push_hashed :: (unk0: *nk_context, unk1: nk_tree_type, title: *u8, initial_state: nk_collapse_states, selected: *s32, hash: *u8, len: s32, seed: s32) -> s32 #foreign libnuklear;

nk_tree_element_image_push_hashed :: (unk0: *nk_context, unk1: nk_tree_type, unk2: nk_image, title: *u8, initial_state: nk_collapse_states, selected: *s32, hash: *u8, len: s32, seed: s32) -> s32 #foreign libnuklear;

nk_tree_element_pop :: (unk0: *nk_context) -> void #foreign libnuklear;

nk_list_view :: struct {
    begin: s32;
    end: s32;
    count: s32;
    total_height: s32;
    ctx: *nk_context;
    scroll_pointer: *nk_uint;
    scroll_value: nk_uint;
}

nk_list_view_begin :: (unk0: *nk_context, out: *nk_list_view, id: *u8, unk1: nk_flags, row_height: s32, row_count: s32) -> s32 #foreign libnuklear;

nk_list_view_end :: (unk0: *nk_list_view) -> void #foreign libnuklear;

using nk_widget_layout_states :: enum s32 {
    NK_WIDGET_INVALID :: 0;
    NK_WIDGET_VALID :: 1;
    NK_WIDGET_ROM :: 2;
}

using nk_widget_states :: enum s32 {
    NK_WIDGET_STATE_MODIFIED :: 2;
    NK_WIDGET_STATE_INACTIVE :: 4;
    NK_WIDGET_STATE_ENTERED :: 8;
    NK_WIDGET_STATE_HOVER :: 16;
    NK_WIDGET_STATE_ACTIVED :: 32;
    NK_WIDGET_STATE_LEFT :: 64;
    NK_WIDGET_STATE_HOVERED :: 18;
    NK_WIDGET_STATE_ACTIVE :: 34;
}

nk_widget :: (unk0: *nk_rect, unk1: *nk_context) -> nk_widget_layout_states #foreign libnuklear;

nk_widget_fitting :: (unk0: *nk_rect, unk1: *nk_context, unk2: nk_vec2) -> nk_widget_layout_states #foreign libnuklear;

nk_widget_bounds :: (unk0: *nk_context) -> nk_rect #foreign libnuklear;

nk_widget_position :: (unk0: *nk_context) -> nk_vec2 #foreign libnuklear;

nk_widget_size :: (unk0: *nk_context) -> nk_vec2 #foreign libnuklear;

nk_widget_width :: (unk0: *nk_context) -> float32 #foreign libnuklear;

nk_widget_height :: (unk0: *nk_context) -> float32 #foreign libnuklear;

nk_widget_is_hovered :: (unk0: *nk_context) -> s32 #foreign libnuklear;

nk_widget_is_mouse_clicked :: (unk0: *nk_context, unk1: nk_buttons) -> s32 #foreign libnuklear;

nk_widget_has_mouse_click_down :: (unk0: *nk_context, unk1: nk_buttons, down: s32) -> s32 #foreign libnuklear;

nk_spacing :: (unk0: *nk_context, cols: s32) -> void #foreign libnuklear;

using nk_text_align :: enum s32 {
    NK_TEXT_ALIGN_LEFT :: 1;
    NK_TEXT_ALIGN_CENTERED :: 2;
    NK_TEXT_ALIGN_RIGHT :: 4;
    NK_TEXT_ALIGN_TOP :: 8;
    NK_TEXT_ALIGN_MIDDLE :: 16;
    NK_TEXT_ALIGN_BOTTOM :: 32;
}

using nk_text_alignment :: enum nk_flags {
    NK_TEXT_LEFT :: 17;
    NK_TEXT_CENTERED :: 18;
    NK_TEXT_RIGHT :: 20;
}

nk_text :: (unk0: *nk_context, unk1: *u8, unk2: s32, unk3: nk_flags) -> void #foreign libnuklear;

nk_text_colored :: (unk0: *nk_context, unk1: *u8, unk2: s32, unk3: nk_flags, unk4: nk_color) -> void #foreign libnuklear;

nk_text_wrap :: (unk0: *nk_context, unk1: *u8, unk2: s32) -> void #foreign libnuklear;

nk_text_wrap_colored :: (unk0: *nk_context, unk1: *u8, unk2: s32, unk3: nk_color) -> void #foreign libnuklear;

nk_label :: (unk0: *nk_context, unk1: *u8, align: nk_text_alignment) -> void #foreign libnuklear;

nk_label_colored :: (unk0: *nk_context, unk1: *u8, align: nk_text_alignment, unk2: nk_color) -> void #foreign libnuklear;

nk_label_wrap :: (unk0: *nk_context, unk1: *u8) -> void #foreign libnuklear;

nk_label_colored_wrap :: (unk0: *nk_context, unk1: *u8, unk2: nk_color) -> void #foreign libnuklear;

_nk_image :: (unk0: *nk_context, unk1: nk_image) -> void #foreign libnuklear "nk_image";

nk_image_color :: (unk0: *nk_context, unk1: nk_image, unk2: nk_color) -> void #foreign libnuklear;

nk_button_text :: (unk0: *nk_context, title: *u8, len: s32) -> s32 #foreign libnuklear;

nk_button_label :: (unk0: *nk_context, title: *u8) -> s32 #foreign libnuklear;

nk_button_color :: (unk0: *nk_context, unk1: nk_color) -> s32 #foreign libnuklear;

nk_button_symbol :: (unk0: *nk_context, unk1: nk_symbol_type) -> s32 #foreign libnuklear;

nk_button_image :: (unk0: *nk_context, img: nk_image) -> s32 #foreign libnuklear;

nk_button_symbol_label :: (unk0: *nk_context, unk1: nk_symbol_type, unk2: *u8, text_alignment: nk_flags) -> s32 #foreign libnuklear;

nk_button_symbol_text :: (unk0: *nk_context, unk1: nk_symbol_type, unk2: *u8, unk3: s32, alignment: nk_flags) -> s32 #foreign libnuklear;

nk_button_image_label :: (unk0: *nk_context, img: nk_image, unk1: *u8, text_alignment: nk_flags) -> s32 #foreign libnuklear;

nk_button_image_text :: (unk0: *nk_context, img: nk_image, unk1: *u8, unk2: s32, alignment: nk_flags) -> s32 #foreign libnuklear;

nk_button_text_styled :: (unk0: *nk_context, unk1: *nk_style_button, title: *u8, len: s32) -> s32 #foreign libnuklear;

nk_button_label_styled :: (unk0: *nk_context, unk1: *nk_style_button, title: *u8) -> s32 #foreign libnuklear;

nk_button_symbol_styled :: (unk0: *nk_context, unk1: *nk_style_button, unk2: nk_symbol_type) -> s32 #foreign libnuklear;

nk_button_image_styled :: (unk0: *nk_context, unk1: *nk_style_button, img: nk_image) -> s32 #foreign libnuklear;

nk_button_symbol_text_styled :: (unk0: *nk_context, unk1: *nk_style_button, unk2: nk_symbol_type, unk3: *u8, unk4: s32, alignment: nk_flags) -> s32 #foreign libnuklear;

nk_button_symbol_label_styled :: (ctx: *nk_context, style: *nk_style_button, symbol: nk_symbol_type, title: *u8, align: nk_flags) -> s32 #foreign libnuklear;

nk_button_image_label_styled :: (unk0: *nk_context, unk1: *nk_style_button, img: nk_image, unk2: *u8, text_alignment: nk_flags) -> s32 #foreign libnuklear;

nk_button_image_text_styled :: (unk0: *nk_context, unk1: *nk_style_button, img: nk_image, unk2: *u8, unk3: s32, alignment: nk_flags) -> s32 #foreign libnuklear;

nk_button_set_behavior :: (unk0: *nk_context, unk1: nk_button_behavior) -> void #foreign libnuklear;

nk_button_push_behavior :: (unk0: *nk_context, unk1: nk_button_behavior) -> s32 #foreign libnuklear;

nk_button_pop_behavior :: (unk0: *nk_context) -> s32 #foreign libnuklear;

nk_check_label :: (unk0: *nk_context, unk1: *u8, active: s32) -> s32 #foreign libnuklear;

nk_check_text :: (unk0: *nk_context, unk1: *u8, unk2: s32, active: s32) -> s32 #foreign libnuklear;

nk_check_flags_label :: (unk0: *nk_context, unk1: *u8, flags: u32, value: u32) -> u32 #foreign libnuklear;

nk_check_flags_text :: (unk0: *nk_context, unk1: *u8, unk2: s32, flags: u32, value: u32) -> u32 #foreign libnuklear;

nk_checkbox_label :: (unk0: *nk_context, unk1: *u8, active: *s32) -> s32 #foreign libnuklear;

nk_checkbox_text :: (unk0: *nk_context, unk1: *u8, unk2: s32, active: *s32) -> s32 #foreign libnuklear;

nk_checkbox_flags_label :: (unk0: *nk_context, unk1: *u8, flags: *u32, value: u32) -> s32 #foreign libnuklear;

nk_checkbox_flags_text :: (unk0: *nk_context, unk1: *u8, unk2: s32, flags: *u32, value: u32) -> s32 #foreign libnuklear;

nk_radio_label :: (unk0: *nk_context, unk1: *u8, active: *s32) -> s32 #foreign libnuklear;

nk_radio_text :: (unk0: *nk_context, unk1: *u8, unk2: s32, active: *s32) -> s32 #foreign libnuklear;

nk_option_label :: (unk0: *nk_context, unk1: *u8, active: s32) -> s32 #foreign libnuklear;

nk_option_text :: (unk0: *nk_context, unk1: *u8, unk2: s32, active: s32) -> s32 #foreign libnuklear;

nk_selectable_label :: (unk0: *nk_context, unk1: *u8, align: nk_flags, value: *s32) -> s32 #foreign libnuklear;

nk_selectable_text :: (unk0: *nk_context, unk1: *u8, unk2: s32, align: nk_flags, value: *s32) -> s32 #foreign libnuklear;

nk_selectable_image_label :: (unk0: *nk_context, unk1: nk_image, unk2: *u8, align: nk_flags, value: *s32) -> s32 #foreign libnuklear;

nk_selectable_image_text :: (unk0: *nk_context, unk1: nk_image, unk2: *u8, unk3: s32, align: nk_flags, value: *s32) -> s32 #foreign libnuklear;

nk_selectable_symbol_label :: (unk0: *nk_context, unk1: nk_symbol_type, unk2: *u8, align: nk_flags, value: *s32) -> s32 #foreign libnuklear;

nk_selectable_symbol_text :: (unk0: *nk_context, unk1: nk_symbol_type, unk2: *u8, unk3: s32, align: nk_flags, value: *s32) -> s32 #foreign libnuklear;

nk_select_label :: (unk0: *nk_context, unk1: *u8, align: nk_flags, value: s32) -> s32 #foreign libnuklear;

nk_select_text :: (unk0: *nk_context, unk1: *u8, unk2: s32, align: nk_flags, value: s32) -> s32 #foreign libnuklear;

nk_select_image_label :: (unk0: *nk_context, unk1: nk_image, unk2: *u8, align: nk_flags, value: s32) -> s32 #foreign libnuklear;

nk_select_image_text :: (unk0: *nk_context, unk1: nk_image, unk2: *u8, unk3: s32, align: nk_flags, value: s32) -> s32 #foreign libnuklear;

nk_select_symbol_label :: (unk0: *nk_context, unk1: nk_symbol_type, unk2: *u8, align: nk_flags, value: s32) -> s32 #foreign libnuklear;

nk_select_symbol_text :: (unk0: *nk_context, unk1: nk_symbol_type, unk2: *u8, unk3: s32, align: nk_flags, value: s32) -> s32 #foreign libnuklear;

nk_slide_float :: (unk0: *nk_context, min: float32, val: float32, max: float32, step: float32) -> float32 #foreign libnuklear;

nk_slide_int :: (unk0: *nk_context, min: s32, val: s32, max: s32, step: s32) -> s32 #foreign libnuklear;

nk_slider_float :: (unk0: *nk_context, min: float32, val: *float32, max: float32, step: float32) -> s32 #foreign libnuklear;

nk_slider_int :: (unk0: *nk_context, min: s32, val: *s32, max: s32, step: s32) -> s32 #foreign libnuklear;

nk_progress :: (unk0: *nk_context, cur: *nk_size, max: nk_size, modifyable: s32) -> s32 #foreign libnuklear;

nk_prog :: (unk0: *nk_context, cur: nk_size, max: nk_size, modifyable: s32) -> nk_size #foreign libnuklear;

nk_color_picker :: (unk0: *nk_context, unk1: nk_colorf, unk2: nk_color_format) -> nk_colorf #foreign libnuklear;

nk_color_pick :: (unk0: *nk_context, unk1: *nk_colorf, unk2: nk_color_format) -> s32 #foreign libnuklear;

nk_property_int :: (unk0: *nk_context, name: *u8, min: s32, val: *s32, max: s32, step: s32, inc_per_pixel: float32) -> void #foreign libnuklear;

nk_property_float :: (unk0: *nk_context, name: *u8, min: float32, val: *float32, max: float32, step: float32, inc_per_pixel: float32) -> void #foreign libnuklear;

nk_property_double :: (unk0: *nk_context, name: *u8, min: float64, val: *float64, max: float64, step: float64, inc_per_pixel: float32) -> void #foreign libnuklear;

nk_propertyi :: (unk0: *nk_context, name: *u8, min: s32, val: s32, max: s32, step: s32, inc_per_pixel: float32) -> s32 #foreign libnuklear;

nk_propertyf :: (unk0: *nk_context, name: *u8, min: float32, val: float32, max: float32, step: float32, inc_per_pixel: float32) -> float32 #foreign libnuklear;

nk_propertyd :: (unk0: *nk_context, name: *u8, min: float64, val: float64, max: float64, step: float64, inc_per_pixel: float32) -> float64 #foreign libnuklear;

using nk_edit_flags :: enum s32 {
    NK_EDIT_DEFAULT :: 0;
    NK_EDIT_READ_ONLY :: 1;
    NK_EDIT_AUTO_SELECT :: 2;
    NK_EDIT_SIG_ENTER :: 4;
    NK_EDIT_ALLOW_TAB :: 8;
    NK_EDIT_NO_CURSOR :: 16;
    NK_EDIT_SELECTABLE :: 32;
    NK_EDIT_CLIPBOARD :: 64;
    NK_EDIT_CTRL_ENTER_NEWLINE :: 128;
    NK_EDIT_NO_HORIZONTAL_SCROLL :: 256;
    NK_EDIT_ALWAYS_INSERT_MODE :: 512;
    NK_EDIT_MULTILINE :: 1024;
    NK_EDIT_GOTO_END_ON_ACTIVATE :: 2048;
}

using nk_edit_types :: enum s32 {
    NK_EDIT_SIMPLE :: 512;
    NK_EDIT_FIELD :: 608;
    NK_EDIT_BOX :: 1640;
    NK_EDIT_EDITOR :: 1128;
}

using nk_edit_events :: enum s32 {
    NK_EDIT_ACTIVE :: 1;
    NK_EDIT_INACTIVE :: 2;
    NK_EDIT_ACTIVATED :: 4;
    NK_EDIT_DEACTIVATED :: 8;
    NK_EDIT_COMMITED :: 16;
}

nk_edit_string :: (unk0: *nk_context, unk1: nk_flags, buffer: *u8, len: *s32, max: s32, unk2: nk_plugin_filter) -> nk_flags #foreign libnuklear;

nk_edit_string_zero_terminated :: (unk0: *nk_context, unk1: nk_flags, buffer: *u8, max: s32, unk2: nk_plugin_filter) -> nk_flags #foreign libnuklear;

nk_edit_buffer :: (unk0: *nk_context, unk1: nk_flags, unk2: *nk_text_edit, unk3: nk_plugin_filter) -> nk_flags #foreign libnuklear;

nk_edit_focus :: (unk0: *nk_context, flags: nk_flags) -> void #foreign libnuklear;

nk_edit_unfocus :: (unk0: *nk_context) -> void #foreign libnuklear;

nk_chart_begin :: (unk0: *nk_context, unk1: nk_chart_type, num: s32, min: float32, max: float32) -> s32 #foreign libnuklear;

nk_chart_begin_colored :: (unk0: *nk_context, unk1: nk_chart_type, unk2: nk_color, active: nk_color, num: s32, min: float32, max: float32) -> s32 #foreign libnuklear;

nk_chart_add_slot :: (ctx: *nk_context, unk0: nk_chart_type, count: s32, min_value: float32, max_value: float32) -> void #foreign libnuklear;

nk_chart_add_slot_colored :: (ctx: *nk_context, unk0: nk_chart_type, unk1: nk_color, active: nk_color, count: s32, min_value: float32, max_value: float32) -> void #foreign libnuklear;

nk_chart_push :: (unk0: *nk_context, unk1: float32) -> nk_flags #foreign libnuklear;

nk_chart_push_slot :: (unk0: *nk_context, unk1: float32, unk2: s32) -> nk_flags #foreign libnuklear;

nk_chart_end :: (unk0: *nk_context) -> void #foreign libnuklear;

nk_plot :: (unk0: *nk_context, unk1: nk_chart_type, values: *float32, count: s32, offset: s32) -> void #foreign libnuklear;

nk_plot_function :: (unk0: *nk_context, unk1: nk_chart_type, userdata: *void, value_getter: #type (a0: *void, a1: s32) -> float32 #c_callback, count: s32, offset: s32) -> void #foreign libnuklear;

nk_popup_begin :: (unk0: *nk_context, unk1: nk_popup_type, unk2: *u8, unk3: nk_flags, bounds: nk_rect) -> s32 #foreign libnuklear;

nk_popup_close :: (unk0: *nk_context) -> void #foreign libnuklear;

nk_popup_end :: (unk0: *nk_context) -> void #foreign libnuklear;

nk_combo :: (unk0: *nk_context, items: **u8, count: s32, selected: s32, item_height: s32, size: nk_vec2) -> s32 #foreign libnuklear;

nk_combo_separator :: (unk0: *nk_context, items_separated_by_separator: *u8, separator: s32, selected: s32, count: s32, item_height: s32, size: nk_vec2) -> s32 #foreign libnuklear;

nk_combo_string :: (unk0: *nk_context, items_separated_by_zeros: *u8, selected: s32, count: s32, item_height: s32, size: nk_vec2) -> s32 #foreign libnuklear;

nk_combo_callback :: (unk0: *nk_context, item_getter: #type (a0: *void, a1: s32, a2: **u8) -> void #c_callback, userdata: *void, selected: s32, count: s32, item_height: s32, size: nk_vec2) -> s32 #foreign libnuklear;

nk_combobox :: (unk0: *nk_context, items: **u8, count: s32, selected: *s32, item_height: s32, size: nk_vec2) -> void #foreign libnuklear;

nk_combobox_string :: (unk0: *nk_context, items_separated_by_zeros: *u8, selected: *s32, count: s32, item_height: s32, size: nk_vec2) -> void #foreign libnuklear;

nk_combobox_separator :: (unk0: *nk_context, items_separated_by_separator: *u8, separator: s32, selected: *s32, count: s32, item_height: s32, size: nk_vec2) -> void #foreign libnuklear;

nk_combobox_callback :: (unk0: *nk_context, item_getter: #type (a0: *void, a1: s32, a2: **u8) -> void #c_callback, unk1: *void, selected: *s32, count: s32, item_height: s32, size: nk_vec2) -> void #foreign libnuklear;

nk_combo_begin_text :: (unk0: *nk_context, selected: *u8, unk1: s32, size: nk_vec2) -> s32 #foreign libnuklear;

nk_combo_begin_label :: (unk0: *nk_context, selected: *u8, size: nk_vec2) -> s32 #foreign libnuklear;

nk_combo_begin_color :: (unk0: *nk_context, color: nk_color, size: nk_vec2) -> s32 #foreign libnuklear;

nk_combo_begin_symbol :: (unk0: *nk_context, unk1: nk_symbol_type, size: nk_vec2) -> s32 #foreign libnuklear;

nk_combo_begin_symbol_label :: (unk0: *nk_context, selected: *u8, unk1: nk_symbol_type, size: nk_vec2) -> s32 #foreign libnuklear;

nk_combo_begin_symbol_text :: (unk0: *nk_context, selected: *u8, unk1: s32, unk2: nk_symbol_type, size: nk_vec2) -> s32 #foreign libnuklear;

nk_combo_begin_image :: (unk0: *nk_context, img: nk_image, size: nk_vec2) -> s32 #foreign libnuklear;

nk_combo_begin_image_label :: (unk0: *nk_context, selected: *u8, unk1: nk_image, size: nk_vec2) -> s32 #foreign libnuklear;

nk_combo_begin_image_text :: (unk0: *nk_context, selected: *u8, unk1: s32, unk2: nk_image, size: nk_vec2) -> s32 #foreign libnuklear;

nk_combo_item_label :: (unk0: *nk_context, unk1: *u8, alignment: nk_flags) -> s32 #foreign libnuklear;

nk_combo_item_text :: (unk0: *nk_context, unk1: *u8, unk2: s32, alignment: nk_flags) -> s32 #foreign libnuklear;

nk_combo_item_image_label :: (unk0: *nk_context, unk1: nk_image, unk2: *u8, alignment: nk_flags) -> s32 #foreign libnuklear;

nk_combo_item_image_text :: (unk0: *nk_context, unk1: nk_image, unk2: *u8, unk3: s32, alignment: nk_flags) -> s32 #foreign libnuklear;

nk_combo_item_symbol_label :: (unk0: *nk_context, unk1: nk_symbol_type, unk2: *u8, alignment: nk_flags) -> s32 #foreign libnuklear;

nk_combo_item_symbol_text :: (unk0: *nk_context, unk1: nk_symbol_type, unk2: *u8, unk3: s32, alignment: nk_flags) -> s32 #foreign libnuklear;

nk_combo_close :: (unk0: *nk_context) -> void #foreign libnuklear;

nk_combo_end :: (unk0: *nk_context) -> void #foreign libnuklear;

nk_contextual_begin :: (unk0: *nk_context, unk1: nk_flags, unk2: nk_vec2, trigger_bounds: nk_rect) -> s32 #foreign libnuklear;

nk_contextual_item_text :: (unk0: *nk_context, unk1: *u8, unk2: s32, align: nk_flags) -> s32 #foreign libnuklear;

nk_contextual_item_label :: (unk0: *nk_context, unk1: *u8, align: nk_flags) -> s32 #foreign libnuklear;

nk_contextual_item_image_label :: (unk0: *nk_context, unk1: nk_image, unk2: *u8, alignment: nk_flags) -> s32 #foreign libnuklear;

nk_contextual_item_image_text :: (unk0: *nk_context, unk1: nk_image, unk2: *u8, len: s32, alignment: nk_flags) -> s32 #foreign libnuklear;

nk_contextual_item_symbol_label :: (unk0: *nk_context, unk1: nk_symbol_type, unk2: *u8, alignment: nk_flags) -> s32 #foreign libnuklear;

nk_contextual_item_symbol_text :: (unk0: *nk_context, unk1: nk_symbol_type, unk2: *u8, unk3: s32, alignment: nk_flags) -> s32 #foreign libnuklear;

nk_contextual_close :: (unk0: *nk_context) -> void #foreign libnuklear;

nk_contextual_end :: (unk0: *nk_context) -> void #foreign libnuklear;

nk_tooltip :: (unk0: *nk_context, unk1: *u8) -> void #foreign libnuklear;

nk_tooltip_begin :: (unk0: *nk_context, width: float32) -> s32 #foreign libnuklear;

nk_tooltip_end :: (unk0: *nk_context) -> void #foreign libnuklear;

nk_menubar_begin :: (unk0: *nk_context) -> void #foreign libnuklear;

nk_menubar_end :: (unk0: *nk_context) -> void #foreign libnuklear;

nk_menu_begin_text :: (unk0: *nk_context, title: *u8, title_len: s32, align: nk_flags, size: nk_vec2) -> s32 #foreign libnuklear;

nk_menu_begin_label :: (unk0: *nk_context, unk1: *u8, align: nk_flags, size: nk_vec2) -> s32 #foreign libnuklear;

nk_menu_begin_image :: (unk0: *nk_context, unk1: *u8, unk2: nk_image, size: nk_vec2) -> s32 #foreign libnuklear;

nk_menu_begin_image_text :: (unk0: *nk_context, unk1: *u8, unk2: s32, align: nk_flags, unk3: nk_image, size: nk_vec2) -> s32 #foreign libnuklear;

nk_menu_begin_image_label :: (unk0: *nk_context, unk1: *u8, align: nk_flags, unk2: nk_image, size: nk_vec2) -> s32 #foreign libnuklear;

nk_menu_begin_symbol :: (unk0: *nk_context, unk1: *u8, unk2: nk_symbol_type, size: nk_vec2) -> s32 #foreign libnuklear;

nk_menu_begin_symbol_text :: (unk0: *nk_context, unk1: *u8, unk2: s32, align: nk_flags, unk3: nk_symbol_type, size: nk_vec2) -> s32 #foreign libnuklear;

nk_menu_begin_symbol_label :: (unk0: *nk_context, unk1: *u8, align: nk_flags, unk2: nk_symbol_type, size: nk_vec2) -> s32 #foreign libnuklear;

nk_menu_item_text :: (unk0: *nk_context, unk1: *u8, unk2: s32, align: nk_flags) -> s32 #foreign libnuklear;

nk_menu_item_label :: (unk0: *nk_context, unk1: *u8, alignment: nk_flags) -> s32 #foreign libnuklear;

nk_menu_item_image_label :: (unk0: *nk_context, unk1: nk_image, unk2: *u8, alignment: nk_flags) -> s32 #foreign libnuklear;

nk_menu_item_image_text :: (unk0: *nk_context, unk1: nk_image, unk2: *u8, len: s32, alignment: nk_flags) -> s32 #foreign libnuklear;

nk_menu_item_symbol_text :: (unk0: *nk_context, unk1: nk_symbol_type, unk2: *u8, unk3: s32, alignment: nk_flags) -> s32 #foreign libnuklear;

nk_menu_item_symbol_label :: (unk0: *nk_context, unk1: nk_symbol_type, unk2: *u8, alignment: nk_flags) -> s32 #foreign libnuklear;

nk_menu_close :: (unk0: *nk_context) -> void #foreign libnuklear;

nk_menu_end :: (unk0: *nk_context) -> void #foreign libnuklear;

using nk_style_colors :: enum s32 {
    NK_COLOR_TEXT :: 0;
    NK_COLOR_WINDOW :: 1;
    NK_COLOR_HEADER :: 2;
    NK_COLOR_BORDER :: 3;
    NK_COLOR_BUTTON :: 4;
    NK_COLOR_BUTTON_HOVER :: 5;
    NK_COLOR_BUTTON_ACTIVE :: 6;
    NK_COLOR_TOGGLE :: 7;
    NK_COLOR_TOGGLE_HOVER :: 8;
    NK_COLOR_TOGGLE_CURSOR :: 9;
    NK_COLOR_SELECT :: 10;
    NK_COLOR_SELECT_ACTIVE :: 11;
    NK_COLOR_SLIDER :: 12;
    NK_COLOR_SLIDER_CURSOR :: 13;
    NK_COLOR_SLIDER_CURSOR_HOVER :: 14;
    NK_COLOR_SLIDER_CURSOR_ACTIVE :: 15;
    NK_COLOR_PROPERTY :: 16;
    NK_COLOR_EDIT :: 17;
    NK_COLOR_EDIT_CURSOR :: 18;
    NK_COLOR_COMBO :: 19;
    NK_COLOR_CHART :: 20;
    NK_COLOR_CHART_COLOR :: 21;
    NK_COLOR_CHART_COLOR_HIGHLIGHT :: 22;
    NK_COLOR_SCROLLBAR :: 23;
    NK_COLOR_SCROLLBAR_CURSOR :: 24;
    NK_COLOR_SCROLLBAR_CURSOR_HOVER :: 25;
    NK_COLOR_SCROLLBAR_CURSOR_ACTIVE :: 26;
    NK_COLOR_TAB_HEADER :: 27;
    NK_COLOR_COUNT :: 28;
}

using nk_style_cursor :: enum s32 {
    NK_CURSOR_ARROW :: 0;
    NK_CURSOR_TEXT :: 1;
    NK_CURSOR_MOVE :: 2;
    NK_CURSOR_RESIZE_VERTICAL :: 3;
    NK_CURSOR_RESIZE_HORIZONTAL :: 4;
    NK_CURSOR_RESIZE_TOP_LEFT_DOWN_RIGHT :: 5;
    NK_CURSOR_RESIZE_TOP_RIGHT_DOWN_LEFT :: 6;
    NK_CURSOR_COUNT :: 7;
}

nk_style_default :: (unk0: *nk_context) -> void #foreign libnuklear;

nk_style_from_table :: (unk0: *nk_context, unk1: *nk_color) -> void #foreign libnuklear;

nk_style_load_cursor :: (unk0: *nk_context, unk1: nk_style_cursor, unk2: *nk_cursor) -> void #foreign libnuklear;

nk_style_load_all_cursors :: (unk0: *nk_context, unk1: *nk_cursor) -> void #foreign libnuklear;

nk_style_get_color_by_name :: (unk0: nk_style_colors) -> *u8 #foreign libnuklear;

nk_style_set_font :: (unk0: *nk_context, unk1: *nk_user_font) -> void #foreign libnuklear;

nk_style_set_cursor :: (unk0: *nk_context, unk1: nk_style_cursor) -> s32 #foreign libnuklear;

nk_style_show_cursor :: (unk0: *nk_context) -> void #foreign libnuklear;

nk_style_hide_cursor :: (unk0: *nk_context) -> void #foreign libnuklear;

nk_style_push_font :: (unk0: *nk_context, unk1: *nk_user_font) -> s32 #foreign libnuklear;

nk_style_push_float :: (unk0: *nk_context, unk1: *float32, unk2: float32) -> s32 #foreign libnuklear;

nk_style_push_vec2 :: (unk0: *nk_context, unk1: *nk_vec2, unk2: nk_vec2) -> s32 #foreign libnuklear;

nk_style_push_style_item :: (unk0: *nk_context, unk1: *nk_style_item, unk2: nk_style_item) -> s32 #foreign libnuklear;

nk_style_push_flags :: (unk0: *nk_context, unk1: *nk_flags, unk2: nk_flags) -> s32 #foreign libnuklear;

nk_style_push_color :: (unk0: *nk_context, unk1: *nk_color, unk2: nk_color) -> s32 #foreign libnuklear;

nk_style_pop_font :: (unk0: *nk_context) -> s32 #foreign libnuklear;

nk_style_pop_float :: (unk0: *nk_context) -> s32 #foreign libnuklear;

nk_style_pop_vec2 :: (unk0: *nk_context) -> s32 #foreign libnuklear;

nk_style_pop_style_item :: (unk0: *nk_context) -> s32 #foreign libnuklear;

nk_style_pop_flags :: (unk0: *nk_context) -> s32 #foreign libnuklear;

nk_style_pop_color :: (unk0: *nk_context) -> s32 #foreign libnuklear;

nk_rgb :: (r: s32, g: s32, b: s32) -> nk_color #foreign libnuklear;

nk_rgb_iv :: (rgb: *s32) -> nk_color #foreign libnuklear;

nk_rgb_bv :: (rgb: *nk_byte) -> nk_color #foreign libnuklear;

nk_rgb_f :: (r: float32, g: float32, b: float32) -> nk_color #foreign libnuklear;

nk_rgb_fv :: (rgb: *float32) -> nk_color #foreign libnuklear;

nk_rgb_cf :: (c: nk_colorf) -> nk_color #foreign libnuklear;

nk_rgb_hex :: (rgb: *u8) -> nk_color #foreign libnuklear;

nk_rgba :: (r: s32, g: s32, b: s32, a: s32) -> nk_color #foreign libnuklear;

nk_rgba_u32 :: (unk0: nk_uint) -> nk_color #foreign libnuklear;

nk_rgba_iv :: (rgba: *s32) -> nk_color #foreign libnuklear;

nk_rgba_bv :: (rgba: *nk_byte) -> nk_color #foreign libnuklear;

nk_rgba_f :: (r: float32, g: float32, b: float32, a: float32) -> nk_color #foreign libnuklear;

nk_rgba_fv :: (rgba: *float32) -> nk_color #foreign libnuklear;

nk_rgba_cf :: (c: nk_colorf) -> nk_color #foreign libnuklear;

nk_rgba_hex :: (rgb: *u8) -> nk_color #foreign libnuklear;

nk_hsva_colorf :: (h: float32, s: float32, v: float32, a: float32) -> nk_colorf #foreign libnuklear;

nk_hsva_colorfv :: (c: *float32) -> nk_colorf #foreign libnuklear;

nk_colorf_hsva_f :: (out_h: *float32, out_s: *float32, out_v: *float32, out_a: *float32, in: nk_colorf) -> void #foreign libnuklear;

nk_colorf_hsva_fv :: (hsva: *float32, in: nk_colorf) -> void #foreign libnuklear;

nk_hsv :: (h: s32, s: s32, v: s32) -> nk_color #foreign libnuklear;

nk_hsv_iv :: (hsv: *s32) -> nk_color #foreign libnuklear;

nk_hsv_bv :: (hsv: *nk_byte) -> nk_color #foreign libnuklear;

nk_hsv_f :: (h: float32, s: float32, v: float32) -> nk_color #foreign libnuklear;

nk_hsv_fv :: (hsv: *float32) -> nk_color #foreign libnuklear;

nk_hsva :: (h: s32, s: s32, v: s32, a: s32) -> nk_color #foreign libnuklear;

nk_hsva_iv :: (hsva: *s32) -> nk_color #foreign libnuklear;

nk_hsva_bv :: (hsva: *nk_byte) -> nk_color #foreign libnuklear;

nk_hsva_f :: (h: float32, s: float32, v: float32, a: float32) -> nk_color #foreign libnuklear;

nk_hsva_fv :: (hsva: *float32) -> nk_color #foreign libnuklear;

nk_color_f :: (r: *float32, g: *float32, b: *float32, a: *float32, unk0: nk_color) -> void #foreign libnuklear;

nk_color_fv :: (rgba_out: *float32, unk0: nk_color) -> void #foreign libnuklear;

nk_color_cf :: (unk0: nk_color) -> nk_colorf #foreign libnuklear;

nk_color_d :: (r: *float64, g: *float64, b: *float64, a: *float64, unk0: nk_color) -> void #foreign libnuklear;

nk_color_dv :: (rgba_out: *float64, unk0: nk_color) -> void #foreign libnuklear;

nk_color_u32 :: (unk0: nk_color) -> nk_uint #foreign libnuklear;

nk_color_hex_rgba :: (output: *u8, unk0: nk_color) -> void #foreign libnuklear;

nk_color_hex_rgb :: (output: *u8, unk0: nk_color) -> void #foreign libnuklear;

nk_color_hsv_i :: (out_h: *s32, out_s: *s32, out_v: *s32, unk0: nk_color) -> void #foreign libnuklear;

nk_color_hsv_b :: (out_h: *nk_byte, out_s: *nk_byte, out_v: *nk_byte, unk0: nk_color) -> void #foreign libnuklear;

nk_color_hsv_iv :: (hsv_out: *s32, unk0: nk_color) -> void #foreign libnuklear;

nk_color_hsv_bv :: (hsv_out: *nk_byte, unk0: nk_color) -> void #foreign libnuklear;

nk_color_hsv_f :: (out_h: *float32, out_s: *float32, out_v: *float32, unk0: nk_color) -> void #foreign libnuklear;

nk_color_hsv_fv :: (hsv_out: *float32, unk0: nk_color) -> void #foreign libnuklear;

nk_color_hsva_i :: (h: *s32, s: *s32, v: *s32, a: *s32, unk0: nk_color) -> void #foreign libnuklear;

nk_color_hsva_b :: (h: *nk_byte, s: *nk_byte, v: *nk_byte, a: *nk_byte, unk0: nk_color) -> void #foreign libnuklear;

nk_color_hsva_iv :: (hsva_out: *s32, unk0: nk_color) -> void #foreign libnuklear;

nk_color_hsva_bv :: (hsva_out: *nk_byte, unk0: nk_color) -> void #foreign libnuklear;

nk_color_hsva_f :: (out_h: *float32, out_s: *float32, out_v: *float32, out_a: *float32, unk0: nk_color) -> void #foreign libnuklear;

nk_color_hsva_fv :: (hsva_out: *float32, unk0: nk_color) -> void #foreign libnuklear;

nk_handle_ptr :: (unk0: *void) -> nk_handle #foreign libnuklear;

nk_handle_id :: (unk0: s32) -> nk_handle #foreign libnuklear;

nk_image_handle :: (unk0: nk_handle) -> nk_image #foreign libnuklear;

nk_image_ptr :: (unk0: *void) -> nk_image #foreign libnuklear;

nk_image_id :: (unk0: s32) -> nk_image #foreign libnuklear;

nk_image_is_subimage :: (img: *nk_image) -> s32 #foreign libnuklear;

nk_subimage_ptr :: (unk0: *void, w: u16, h: u16, sub_region: nk_rect) -> nk_image #foreign libnuklear;

nk_subimage_id :: (unk0: s32, w: u16, h: u16, sub_region: nk_rect) -> nk_image #foreign libnuklear;

nk_subimage_handle :: (unk0: nk_handle, w: u16, h: u16, sub_region: nk_rect) -> nk_image #foreign libnuklear;

nk_murmur_hash :: (key: *void, len: s32, seed: nk_hash) -> nk_hash #foreign libnuklear;

nk_triangle_from_direction :: (result: *nk_vec2, r: nk_rect, pad_x: float32, pad_y: float32, unk0: nk_heading) -> void #foreign libnuklear;

_nk_vec2 :: (x: float32, y: float32) -> nk_vec2 #foreign libnuklear "nk_vec2";

_nk_vec2i :: (x: s32, y: s32) -> nk_vec2 #foreign libnuklear "nk_vec2i";

nk_vec2v :: (xy: *float32) -> nk_vec2 #foreign libnuklear;

nk_vec2iv :: (xy: *s32) -> nk_vec2 #foreign libnuklear;

nk_get_null_rect :: () -> nk_rect #foreign libnuklear;

_nk_rect :: (x: float32, y: float32, w: float32, h: float32) -> nk_rect #foreign libnuklear "nk_rect";

_nk_recti :: (x: s32, y: s32, w: s32, h: s32) -> nk_rect #foreign libnuklear "nk_recti";

nk_recta :: (pos: nk_vec2, size: nk_vec2) -> nk_rect #foreign libnuklear;

nk_rectv :: (xywh: *float32) -> nk_rect #foreign libnuklear;

nk_rectiv :: (xywh: *s32) -> nk_rect #foreign libnuklear;

nk_rect_pos :: (unk0: nk_rect) -> nk_vec2 #foreign libnuklear;

nk_rect_size :: (unk0: nk_rect) -> nk_vec2 #foreign libnuklear;

nk_strlen :: (str: *u8) -> s32 #foreign libnuklear;

nk_stricmp :: (s1: *u8, s2: *u8) -> s32 #foreign libnuklear;

nk_stricmpn :: (s1: *u8, s2: *u8, n: s32) -> s32 #foreign libnuklear;

nk_strtoi :: (str: *u8, endptr: **u8) -> s32 #foreign libnuklear;

nk_strtof :: (str: *u8, endptr: **u8) -> float32 #foreign libnuklear;

nk_strtod :: (str: *u8, endptr: **u8) -> float64 #foreign libnuklear;

nk_strfilter :: (text: *u8, regexp: *u8) -> s32 #foreign libnuklear;

nk_strmatch_fuzzy_string :: (str: *u8, pattern: *u8, out_score: *s32) -> s32 #foreign libnuklear;

nk_strmatch_fuzzy_text :: (txt: *u8, txt_len: s32, pattern: *u8, out_score: *s32) -> s32 #foreign libnuklear;

nk_utf_decode :: (unk0: *u8, unk1: *nk_rune, unk2: s32) -> s32 #foreign libnuklear;

nk_utf_encode :: (unk0: nk_rune, unk1: *u8, unk2: s32) -> s32 #foreign libnuklear;

nk_utf_len :: (unk0: *u8, byte_len: s32) -> s32 #foreign libnuklear;

nk_utf_at :: (buffer: *u8, length: s32, index: s32, unicode: *nk_rune, len: *s32) -> *u8 #foreign libnuklear;

nk_user_font_glyph :: struct {
}

nk_text_width_f :: #type (a0: nk_handle, a1: float32, a2: *u8, a3: s32) -> float32 #c_callback;

nk_query_font_glyph_f :: #type (a0: nk_handle, a1: float32, a2: *nk_user_font_glyph, a3: nk_rune, a4: nk_rune) -> void #c_callback;

nk_user_font :: struct {
    userdata: nk_handle;
    height: float32;
    width: nk_text_width_f;
}

nk_memory_status :: struct {
    memory: *void;
    type: u32;
    size: nk_size;
    allocated: nk_size;
    needed: nk_size;
    calls: nk_size;
}

using nk_allocation_type :: enum s32 {
    NK_BUFFER_FIXED :: 0;
    NK_BUFFER_DYNAMIC :: 1;
}

using nk_buffer_allocation_type :: enum s32 {
    NK_BUFFER_FRONT :: 0;
    NK_BUFFER_BACK :: 1;
    NK_BUFFER_MAX :: 2;
}

nk_buffer_marker :: struct {
    active: s32;
    offset: nk_size;
}

nk_memory :: struct {
    ptr: *void;
    size: nk_size;
}

nk_buffer :: struct {
    marker: [2] nk_buffer_marker;
    pool: nk_allocator;
    type: nk_allocation_type;
    memory: nk_memory;
    grow_factor: float32;
    allocated: nk_size;
    needed: nk_size;
    calls: nk_size;
    size: nk_size;
}

nk_buffer_init :: (unk0: *nk_buffer, unk1: *nk_allocator, size: nk_size) -> void #foreign libnuklear;

nk_buffer_init_fixed :: (unk0: *nk_buffer, memory: *void, size: nk_size) -> void #foreign libnuklear;

nk_buffer_info :: (unk0: *nk_memory_status, unk1: *nk_buffer) -> void #foreign libnuklear;

nk_buffer_push :: (unk0: *nk_buffer, type: nk_buffer_allocation_type, memory: *void, size: nk_size, align: nk_size) -> void #foreign libnuklear;

nk_buffer_mark :: (unk0: *nk_buffer, type: nk_buffer_allocation_type) -> void #foreign libnuklear;

nk_buffer_reset :: (unk0: *nk_buffer, type: nk_buffer_allocation_type) -> void #foreign libnuklear;

nk_buffer_clear :: (unk0: *nk_buffer) -> void #foreign libnuklear;

nk_buffer_free :: (unk0: *nk_buffer) -> void #foreign libnuklear;

nk_buffer_memory :: (unk0: *nk_buffer) -> *void #foreign libnuklear;

nk_buffer_memory_const :: (unk0: *nk_buffer) -> *void #foreign libnuklear;

nk_buffer_total :: (unk0: *nk_buffer) -> nk_size #foreign libnuklear;

nk_str :: struct {
    buffer: nk_buffer;
    len: s32;
}

nk_str_init :: (unk0: *nk_str, unk1: *nk_allocator, size: nk_size) -> void #foreign libnuklear;

nk_str_init_fixed :: (unk0: *nk_str, memory: *void, size: nk_size) -> void #foreign libnuklear;

nk_str_clear :: (unk0: *nk_str) -> void #foreign libnuklear;

nk_str_free :: (unk0: *nk_str) -> void #foreign libnuklear;

nk_str_append_text_char :: (unk0: *nk_str, unk1: *u8, unk2: s32) -> s32 #foreign libnuklear;

nk_str_append_str_char :: (unk0: *nk_str, unk1: *u8) -> s32 #foreign libnuklear;

nk_str_append_text_utf8 :: (unk0: *nk_str, unk1: *u8, unk2: s32) -> s32 #foreign libnuklear;

nk_str_append_str_utf8 :: (unk0: *nk_str, unk1: *u8) -> s32 #foreign libnuklear;

nk_str_append_text_runes :: (unk0: *nk_str, unk1: *nk_rune, unk2: s32) -> s32 #foreign libnuklear;

nk_str_append_str_runes :: (unk0: *nk_str, unk1: *nk_rune) -> s32 #foreign libnuklear;

nk_str_insert_at_char :: (unk0: *nk_str, pos: s32, unk1: *u8, unk2: s32) -> s32 #foreign libnuklear;

nk_str_insert_at_rune :: (unk0: *nk_str, pos: s32, unk1: *u8, unk2: s32) -> s32 #foreign libnuklear;

nk_str_insert_text_char :: (unk0: *nk_str, pos: s32, unk1: *u8, unk2: s32) -> s32 #foreign libnuklear;

nk_str_insert_str_char :: (unk0: *nk_str, pos: s32, unk1: *u8) -> s32 #foreign libnuklear;

nk_str_insert_text_utf8 :: (unk0: *nk_str, pos: s32, unk1: *u8, unk2: s32) -> s32 #foreign libnuklear;

nk_str_insert_str_utf8 :: (unk0: *nk_str, pos: s32, unk1: *u8) -> s32 #foreign libnuklear;

nk_str_insert_text_runes :: (unk0: *nk_str, pos: s32, unk1: *nk_rune, unk2: s32) -> s32 #foreign libnuklear;

nk_str_insert_str_runes :: (unk0: *nk_str, pos: s32, unk1: *nk_rune) -> s32 #foreign libnuklear;

nk_str_remove_chars :: (unk0: *nk_str, len: s32) -> void #foreign libnuklear;

nk_str_remove_runes :: (str: *nk_str, len: s32) -> void #foreign libnuklear;

nk_str_delete_chars :: (unk0: *nk_str, pos: s32, len: s32) -> void #foreign libnuklear;

nk_str_delete_runes :: (unk0: *nk_str, pos: s32, len: s32) -> void #foreign libnuklear;

nk_str_at_char :: (unk0: *nk_str, pos: s32) -> *u8 #foreign libnuklear;

nk_str_at_rune :: (unk0: *nk_str, pos: s32, unicode: *nk_rune, len: *s32) -> *u8 #foreign libnuklear;

nk_str_rune_at :: (unk0: *nk_str, pos: s32) -> nk_rune #foreign libnuklear;

nk_str_at_char_const :: (unk0: *nk_str, pos: s32) -> *u8 #foreign libnuklear;

nk_str_at_const :: (unk0: *nk_str, pos: s32, unicode: *nk_rune, len: *s32) -> *u8 #foreign libnuklear;

nk_str_get :: (unk0: *nk_str) -> *u8 #foreign libnuklear;

nk_str_get_const :: (unk0: *nk_str) -> *u8 #foreign libnuklear;

nk_str_len :: (unk0: *nk_str) -> s32 #foreign libnuklear;

nk_str_len_char :: (unk0: *nk_str) -> s32 #foreign libnuklear;

nk_clipboard :: struct {
    userdata: nk_handle;
    paste: nk_plugin_paste;
    copy: nk_plugin_copy;
}

nk_text_undo_record :: struct {
    where: s32;
    insert_length: s16;
    delete_length: s16;
    char_storage: s16;
}

nk_text_undo_state :: struct {
    undo_rec: [99] nk_text_undo_record;
    undo_char: [999] nk_rune;
    undo_point: s16;
    redo_point: s16;
    undo_char_point: s16;
    redo_char_point: s16;
}

using nk_text_edit_type :: enum s32 {
    NK_TEXT_EDIT_SINGLE_LINE :: 0;
    NK_TEXT_EDIT_MULTI_LINE :: 1;
}

using nk_text_edit_mode :: enum s32 {
    NK_TEXT_EDIT_MODE_VIEW :: 0;
    NK_TEXT_EDIT_MODE_INSERT :: 1;
    NK_TEXT_EDIT_MODE_REPLACE :: 2;
}

nk_text_edit :: struct {
    clip: nk_clipboard;
    string: nk_str;
    filter: nk_plugin_filter;
    scrollbar: nk_vec2;
    cursor: s32;
    select_start: s32;
    select_end: s32;
    mode: u8;
    cursor_at_end_of_line: u8;
    initialized: u8;
    has_preferred_x: u8;
    single_line: u8;
    active: u8;
    padding1: u8;
    preferred_x: float32;
    undo: nk_text_undo_state;
}

nk_filter_default :: (unk0: *nk_text_edit, unicode: nk_rune) -> s32 #foreign libnuklear;

nk_filter_ascii :: (unk0: *nk_text_edit, unicode: nk_rune) -> s32 #foreign libnuklear;

nk_filter_float :: (unk0: *nk_text_edit, unicode: nk_rune) -> s32 #foreign libnuklear;

nk_filter_decimal :: (unk0: *nk_text_edit, unicode: nk_rune) -> s32 #foreign libnuklear;

nk_filter_hex :: (unk0: *nk_text_edit, unicode: nk_rune) -> s32 #foreign libnuklear;

nk_filter_oct :: (unk0: *nk_text_edit, unicode: nk_rune) -> s32 #foreign libnuklear;

nk_filter_binary :: (unk0: *nk_text_edit, unicode: nk_rune) -> s32 #foreign libnuklear;

nk_textedit_init :: (unk0: *nk_text_edit, unk1: *nk_allocator, size: nk_size) -> void #foreign libnuklear;

nk_textedit_init_fixed :: (unk0: *nk_text_edit, memory: *void, size: nk_size) -> void #foreign libnuklear;

nk_textedit_free :: (unk0: *nk_text_edit) -> void #foreign libnuklear;

nk_textedit_text :: (unk0: *nk_text_edit, unk1: *u8, total_len: s32) -> void #foreign libnuklear;

nk_textedit_delete :: (unk0: *nk_text_edit, where: s32, len: s32) -> void #foreign libnuklear;

nk_textedit_delete_selection :: (unk0: *nk_text_edit) -> void #foreign libnuklear;

nk_textedit_select_all :: (unk0: *nk_text_edit) -> void #foreign libnuklear;

nk_textedit_cut :: (unk0: *nk_text_edit) -> s32 #foreign libnuklear;

nk_textedit_paste :: (unk0: *nk_text_edit, unk1: *u8, len: s32) -> s32 #foreign libnuklear;

nk_textedit_undo :: (unk0: *nk_text_edit) -> void #foreign libnuklear;

nk_textedit_redo :: (unk0: *nk_text_edit) -> void #foreign libnuklear;

using nk_command_type :: enum s32 {
    NK_COMMAND_NOP :: 0;
    NK_COMMAND_SCISSOR :: 1;
    NK_COMMAND_LINE :: 2;
    NK_COMMAND_CURVE :: 3;
    NK_COMMAND_RECT :: 4;
    NK_COMMAND_RECT_FILLED :: 5;
    NK_COMMAND_RECT_MULTI_COLOR :: 6;
    NK_COMMAND_CIRCLE :: 7;
    NK_COMMAND_CIRCLE_FILLED :: 8;
    NK_COMMAND_ARC :: 9;
    NK_COMMAND_ARC_FILLED :: 10;
    NK_COMMAND_TRIANGLE :: 11;
    NK_COMMAND_TRIANGLE_FILLED :: 12;
    NK_COMMAND_POLYGON :: 13;
    NK_COMMAND_POLYGON_FILLED :: 14;
    NK_COMMAND_POLYLINE :: 15;
    NK_COMMAND_TEXT :: 16;
    NK_COMMAND_IMAGE :: 17;
    NK_COMMAND_CUSTOM :: 18;
}

nk_command :: struct {
    type: nk_command_type;
    next: nk_size;
}

nk_command_scissor :: struct {
    header: nk_command;
    x: s16;
    y: s16;
    w: u16;
    h: u16;
}

nk_command_line :: struct {
    header: nk_command;
    line_thickness: u16;
    begin: nk_vec2i;
    end: nk_vec2i;
    color: nk_color;
}

nk_command_curve :: struct {
    header: nk_command;
    line_thickness: u16;
    begin: nk_vec2i;
    end: nk_vec2i;
    ctrl: [2] nk_vec2i;
    color: nk_color;
}

nk_command_rect :: struct {
    header: nk_command;
    rounding: u16;
    line_thickness: u16;
    x: s16;
    y: s16;
    w: u16;
    h: u16;
    color: nk_color;
}

nk_command_rect_filled :: struct {
    header: nk_command;
    rounding: u16;
    x: s16;
    y: s16;
    w: u16;
    h: u16;
    color: nk_color;
}

nk_command_rect_multi_color :: struct {
    header: nk_command;
    x: s16;
    y: s16;
    w: u16;
    h: u16;
    left: nk_color;
    top: nk_color;
    bottom: nk_color;
    right: nk_color;
}

nk_command_triangle :: struct {
    header: nk_command;
    line_thickness: u16;
    a: nk_vec2i;
    b: nk_vec2i;
    c: nk_vec2i;
    color: nk_color;
}

nk_command_triangle_filled :: struct {
    header: nk_command;
    a: nk_vec2i;
    b: nk_vec2i;
    c: nk_vec2i;
    color: nk_color;
}

nk_command_circle :: struct {
    header: nk_command;
    x: s16;
    y: s16;
    line_thickness: u16;
    w: u16;
    h: u16;
    color: nk_color;
}

nk_command_circle_filled :: struct {
    header: nk_command;
    x: s16;
    y: s16;
    w: u16;
    h: u16;
    color: nk_color;
}

nk_command_arc :: struct {
    header: nk_command;
    cx: s16;
    cy: s16;
    r: u16;
    line_thickness: u16;
    a: [2] float32;
    color: nk_color;
}

nk_command_arc_filled :: struct {
    header: nk_command;
    cx: s16;
    cy: s16;
    r: u16;
    a: [2] float32;
    color: nk_color;
}

nk_command_polygon :: struct {
    header: nk_command;
    color: nk_color;
    line_thickness: u16;
    point_count: u16;
    points: [1] nk_vec2i;
}

nk_command_polygon_filled :: struct {
    header: nk_command;
    color: nk_color;
    point_count: u16;
    points: [1] nk_vec2i;
}

nk_command_polyline :: struct {
    header: nk_command;
    color: nk_color;
    line_thickness: u16;
    point_count: u16;
    points: [1] nk_vec2i;
}

nk_command_image :: struct {
    header: nk_command;
    x: s16;
    y: s16;
    w: u16;
    h: u16;
    img: nk_image;
    col: nk_color;
}

nk_command_custom_callback :: #type (a0: *void, a1: s16, a2: s16, a3: u16, a4: u16, a5: nk_handle) -> void #c_callback;

nk_command_custom :: struct {
    header: nk_command;
    x: s16;
    y: s16;
    w: u16;
    h: u16;
    callback_data: nk_handle;
    callback: nk_command_custom_callback;
}

nk_command_text :: struct {
    header: nk_command;
    font: *nk_user_font;
    background: nk_color;
    foreground: nk_color;
    x: s16;
    y: s16;
    w: u16;
    h: u16;
    height: float32;
    length: s32;
    string: [1] u8;
}

using nk_command_clipping :: enum s32 {
    NK_CLIPPING_OFF :: 0;
    NK_CLIPPING_ON :: 1;
}

nk_command_buffer :: struct {
    base: *nk_buffer;
    clip: nk_rect;
    use_clipping: s32;
    userdata: nk_handle;
    begin: nk_size;
    end: nk_size;
    last: nk_size;
}

nk_stroke_line :: (b: *nk_command_buffer, x0: float32, y0: float32, x1: float32, y1: float32, line_thickness: float32, unk0: nk_color) -> void #foreign libnuklear;

nk_stroke_curve :: (unk0: *nk_command_buffer, unk1: float32, unk2: float32, unk3: float32, unk4: float32, unk5: float32, unk6: float32, unk7: float32, unk8: float32, line_thickness: float32, unk9: nk_color) -> void #foreign libnuklear;

nk_stroke_rect :: (unk0: *nk_command_buffer, unk1: nk_rect, rounding: float32, line_thickness: float32, unk2: nk_color) -> void #foreign libnuklear;

nk_stroke_circle :: (unk0: *nk_command_buffer, unk1: nk_rect, line_thickness: float32, unk2: nk_color) -> void #foreign libnuklear;

nk_stroke_arc :: (unk0: *nk_command_buffer, cx: float32, cy: float32, radius: float32, a_min: float32, a_max: float32, line_thickness: float32, unk1: nk_color) -> void #foreign libnuklear;

nk_stroke_triangle :: (unk0: *nk_command_buffer, unk1: float32, unk2: float32, unk3: float32, unk4: float32, unk5: float32, unk6: float32, line_thichness: float32, unk7: nk_color) -> void #foreign libnuklear;

nk_stroke_polyline :: (unk0: *nk_command_buffer, points: *float32, point_count: s32, line_thickness: float32, col: nk_color) -> void #foreign libnuklear;

nk_stroke_polygon :: (unk0: *nk_command_buffer, unk1: *float32, point_count: s32, line_thickness: float32, unk2: nk_color) -> void #foreign libnuklear;

nk_fill_rect :: (unk0: *nk_command_buffer, unk1: nk_rect, rounding: float32, unk2: nk_color) -> void #foreign libnuklear;

nk_fill_rect_multi_color :: (unk0: *nk_command_buffer, unk1: nk_rect, left: nk_color, top: nk_color, right: nk_color, bottom: nk_color) -> void #foreign libnuklear;

nk_fill_circle :: (unk0: *nk_command_buffer, unk1: nk_rect, unk2: nk_color) -> void #foreign libnuklear;

nk_fill_arc :: (unk0: *nk_command_buffer, cx: float32, cy: float32, radius: float32, a_min: float32, a_max: float32, unk1: nk_color) -> void #foreign libnuklear;

nk_fill_triangle :: (unk0: *nk_command_buffer, x0: float32, y0: float32, x1: float32, y1: float32, x2: float32, y2: float32, unk1: nk_color) -> void #foreign libnuklear;

nk_fill_polygon :: (unk0: *nk_command_buffer, unk1: *float32, point_count: s32, unk2: nk_color) -> void #foreign libnuklear;

nk_draw_image :: (unk0: *nk_command_buffer, unk1: nk_rect, unk2: *nk_image, unk3: nk_color) -> void #foreign libnuklear;

nk_draw_text :: (unk0: *nk_command_buffer, unk1: nk_rect, text: *u8, len: s32, unk2: *nk_user_font, unk3: nk_color, unk4: nk_color) -> void #foreign libnuklear;

nk_push_scissor :: (unk0: *nk_command_buffer, unk1: nk_rect) -> void #foreign libnuklear;

nk_push_custom :: (unk0: *nk_command_buffer, unk1: nk_rect, unk2: nk_command_custom_callback, usr: nk_handle) -> void #foreign libnuklear;

nk_mouse_button :: struct {
    down: s32;
    clicked: u32;
    clicked_pos: nk_vec2;
}

nk_mouse :: struct {
    buttons: [4] nk_mouse_button;
    pos: nk_vec2;
    prev: nk_vec2;
    delta: nk_vec2;
    scroll_delta: nk_vec2;
    grab: u8;
    grabbed: u8;
    ungrab: u8;
}

nk_key :: struct {
    down: s32;
    clicked: u32;
}

nk_keyboard :: struct {
    keys: [30] nk_key;
    text: [16] u8;
    text_len: s32;
}

nk_input :: struct {
    keyboard: nk_keyboard;
    mouse: nk_mouse;
}

nk_input_has_mouse_click :: (unk0: *nk_input, unk1: nk_buttons) -> s32 #foreign libnuklear;

nk_input_has_mouse_click_in_rect :: (unk0: *nk_input, unk1: nk_buttons, unk2: nk_rect) -> s32 #foreign libnuklear;

nk_input_has_mouse_click_down_in_rect :: (unk0: *nk_input, unk1: nk_buttons, unk2: nk_rect, down: s32) -> s32 #foreign libnuklear;

nk_input_is_mouse_click_in_rect :: (unk0: *nk_input, unk1: nk_buttons, unk2: nk_rect) -> s32 #foreign libnuklear;

nk_input_is_mouse_click_down_in_rect :: (i: *nk_input, id: nk_buttons, b: nk_rect, down: s32) -> s32 #foreign libnuklear;

nk_input_any_mouse_click_in_rect :: (unk0: *nk_input, unk1: nk_rect) -> s32 #foreign libnuklear;

nk_input_is_mouse_prev_hovering_rect :: (unk0: *nk_input, unk1: nk_rect) -> s32 #foreign libnuklear;

nk_input_is_mouse_hovering_rect :: (unk0: *nk_input, unk1: nk_rect) -> s32 #foreign libnuklear;

nk_input_mouse_clicked :: (unk0: *nk_input, unk1: nk_buttons, unk2: nk_rect) -> s32 #foreign libnuklear;

nk_input_is_mouse_down :: (unk0: *nk_input, unk1: nk_buttons) -> s32 #foreign libnuklear;

nk_input_is_mouse_pressed :: (unk0: *nk_input, unk1: nk_buttons) -> s32 #foreign libnuklear;

nk_input_is_mouse_released :: (unk0: *nk_input, unk1: nk_buttons) -> s32 #foreign libnuklear;

nk_input_is_key_pressed :: (unk0: *nk_input, unk1: nk_keys) -> s32 #foreign libnuklear;

nk_input_is_key_released :: (unk0: *nk_input, unk1: nk_keys) -> s32 #foreign libnuklear;

nk_input_is_key_down :: (unk0: *nk_input, unk1: nk_keys) -> s32 #foreign libnuklear;

using nk_style_item_type :: enum s32 {
    NK_STYLE_ITEM_COLOR :: 0;
    NK_STYLE_ITEM_IMAGE :: 1;
}

nk_style_item_data :: union {
    image: nk_image;
    color: nk_color;
}

nk_style_item :: struct {
    type: nk_style_item_type;
    data: nk_style_item_data;
}

nk_style_text :: struct {
    color: nk_color;
    padding: nk_vec2;
}

nk_style_button :: struct {
    normal: nk_style_item;
    hover: nk_style_item;
    active: nk_style_item;
    border_color: nk_color;
    text_background: nk_color;
    text_normal: nk_color;
    text_hover: nk_color;
    text_active: nk_color;
    text_alignment: nk_flags;
    border: float32;
    rounding: float32;
    padding: nk_vec2;
    image_padding: nk_vec2;
    touch_padding: nk_vec2;
    userdata: nk_handle;
    draw_begin: #type (a0: *nk_command_buffer, a1: nk_handle) -> void #c_callback;
    draw_end: #type (a0: *nk_command_buffer, a1: nk_handle) -> void #c_callback;
}

nk_style_toggle :: struct {
    normal: nk_style_item;
    hover: nk_style_item;
    active: nk_style_item;
    border_color: nk_color;
    cursor_normal: nk_style_item;
    cursor_hover: nk_style_item;
    text_normal: nk_color;
    text_hover: nk_color;
    text_active: nk_color;
    text_background: nk_color;
    text_alignment: nk_flags;
    padding: nk_vec2;
    touch_padding: nk_vec2;
    spacing: float32;
    border: float32;
    userdata: nk_handle;
    draw_begin: #type (a0: *nk_command_buffer, a1: nk_handle) -> void #c_callback;
    draw_end: #type (a0: *nk_command_buffer, a1: nk_handle) -> void #c_callback;
}

nk_style_selectable :: struct {
    normal: nk_style_item;
    hover: nk_style_item;
    pressed: nk_style_item;
    normal_active: nk_style_item;
    hover_active: nk_style_item;
    pressed_active: nk_style_item;
    text_normal: nk_color;
    text_hover: nk_color;
    text_pressed: nk_color;
    text_normal_active: nk_color;
    text_hover_active: nk_color;
    text_pressed_active: nk_color;
    text_background: nk_color;
    text_alignment: nk_flags;
    rounding: float32;
    padding: nk_vec2;
    touch_padding: nk_vec2;
    image_padding: nk_vec2;
    userdata: nk_handle;
    draw_begin: #type (a0: *nk_command_buffer, a1: nk_handle) -> void #c_callback;
    draw_end: #type (a0: *nk_command_buffer, a1: nk_handle) -> void #c_callback;
}

nk_style_slider :: struct {
    normal: nk_style_item;
    hover: nk_style_item;
    active: nk_style_item;
    border_color: nk_color;
    bar_normal: nk_color;
    bar_hover: nk_color;
    bar_active: nk_color;
    bar_filled: nk_color;
    cursor_normal: nk_style_item;
    cursor_hover: nk_style_item;
    cursor_active: nk_style_item;
    border: float32;
    rounding: float32;
    bar_height: float32;
    padding: nk_vec2;
    spacing: nk_vec2;
    cursor_size: nk_vec2;
    show_buttons: s32;
    inc_button: nk_style_button;
    dec_button: nk_style_button;
    inc_symbol: nk_symbol_type;
    dec_symbol: nk_symbol_type;
    userdata: nk_handle;
    draw_begin: #type (a0: *nk_command_buffer, a1: nk_handle) -> void #c_callback;
    draw_end: #type (a0: *nk_command_buffer, a1: nk_handle) -> void #c_callback;
}

nk_style_progress :: struct {
    normal: nk_style_item;
    hover: nk_style_item;
    active: nk_style_item;
    border_color: nk_color;
    cursor_normal: nk_style_item;
    cursor_hover: nk_style_item;
    cursor_active: nk_style_item;
    cursor_border_color: nk_color;
    rounding: float32;
    border: float32;
    cursor_border: float32;
    cursor_rounding: float32;
    padding: nk_vec2;
    userdata: nk_handle;
    draw_begin: #type (a0: *nk_command_buffer, a1: nk_handle) -> void #c_callback;
    draw_end: #type (a0: *nk_command_buffer, a1: nk_handle) -> void #c_callback;
}

nk_style_scrollbar :: struct {
    normal: nk_style_item;
    hover: nk_style_item;
    active: nk_style_item;
    border_color: nk_color;
    cursor_normal: nk_style_item;
    cursor_hover: nk_style_item;
    cursor_active: nk_style_item;
    cursor_border_color: nk_color;
    border: float32;
    rounding: float32;
    border_cursor: float32;
    rounding_cursor: float32;
    padding: nk_vec2;
    show_buttons: s32;
    inc_button: nk_style_button;
    dec_button: nk_style_button;
    inc_symbol: nk_symbol_type;
    dec_symbol: nk_symbol_type;
    userdata: nk_handle;
    draw_begin: #type (a0: *nk_command_buffer, a1: nk_handle) -> void #c_callback;
    draw_end: #type (a0: *nk_command_buffer, a1: nk_handle) -> void #c_callback;
}

nk_style_edit :: struct {
    normal: nk_style_item;
    hover: nk_style_item;
    active: nk_style_item;
    border_color: nk_color;
    scrollbar: nk_style_scrollbar;
    cursor_normal: nk_color;
    cursor_hover: nk_color;
    cursor_text_normal: nk_color;
    cursor_text_hover: nk_color;
    text_normal: nk_color;
    text_hover: nk_color;
    text_active: nk_color;
    selected_normal: nk_color;
    selected_hover: nk_color;
    selected_text_normal: nk_color;
    selected_text_hover: nk_color;
    border: float32;
    rounding: float32;
    cursor_size: float32;
    scrollbar_size: nk_vec2;
    padding: nk_vec2;
    row_padding: float32;
}

nk_style_property :: struct {
    normal: nk_style_item;
    hover: nk_style_item;
    active: nk_style_item;
    border_color: nk_color;
    label_normal: nk_color;
    label_hover: nk_color;
    label_active: nk_color;
    sym_left: nk_symbol_type;
    sym_right: nk_symbol_type;
    border: float32;
    rounding: float32;
    padding: nk_vec2;
    edit: nk_style_edit;
    inc_button: nk_style_button;
    dec_button: nk_style_button;
    userdata: nk_handle;
    draw_begin: #type (a0: *nk_command_buffer, a1: nk_handle) -> void #c_callback;
    draw_end: #type (a0: *nk_command_buffer, a1: nk_handle) -> void #c_callback;
}

nk_style_chart :: struct {
    background: nk_style_item;
    border_color: nk_color;
    selected_color: nk_color;
    color: nk_color;
    border: float32;
    rounding: float32;
    padding: nk_vec2;
}

nk_style_combo :: struct {
    normal: nk_style_item;
    hover: nk_style_item;
    active: nk_style_item;
    border_color: nk_color;
    label_normal: nk_color;
    label_hover: nk_color;
    label_active: nk_color;
    symbol_normal: nk_color;
    symbol_hover: nk_color;
    symbol_active: nk_color;
    button: nk_style_button;
    sym_normal: nk_symbol_type;
    sym_hover: nk_symbol_type;
    sym_active: nk_symbol_type;
    border: float32;
    rounding: float32;
    content_padding: nk_vec2;
    button_padding: nk_vec2;
    spacing: nk_vec2;
}

nk_style_tab :: struct {
    background: nk_style_item;
    border_color: nk_color;
    text: nk_color;
    tab_maximize_button: nk_style_button;
    tab_minimize_button: nk_style_button;
    node_maximize_button: nk_style_button;
    node_minimize_button: nk_style_button;
    sym_minimize: nk_symbol_type;
    sym_maximize: nk_symbol_type;
    border: float32;
    rounding: float32;
    indent: float32;
    padding: nk_vec2;
    spacing: nk_vec2;
}

using nk_style_header_align :: enum s32 {
    NK_HEADER_LEFT :: 0;
    NK_HEADER_RIGHT :: 1;
}

nk_style_window_header :: struct {
    normal: nk_style_item;
    hover: nk_style_item;
    active: nk_style_item;
    close_button: nk_style_button;
    minimize_button: nk_style_button;
    close_symbol: nk_symbol_type;
    minimize_symbol: nk_symbol_type;
    maximize_symbol: nk_symbol_type;
    label_normal: nk_color;
    label_hover: nk_color;
    label_active: nk_color;
    align: nk_style_header_align;
    padding: nk_vec2;
    label_padding: nk_vec2;
    spacing: nk_vec2;
}

nk_style_window :: struct {
    header: nk_style_window_header;
    fixed_background: nk_style_item;
    background: nk_color;
    border_color: nk_color;
    popup_border_color: nk_color;
    combo_border_color: nk_color;
    contextual_border_color: nk_color;
    menu_border_color: nk_color;
    group_border_color: nk_color;
    tooltip_border_color: nk_color;
    scaler: nk_style_item;
    border: float32;
    combo_border: float32;
    contextual_border: float32;
    menu_border: float32;
    group_border: float32;
    tooltip_border: float32;
    popup_border: float32;
    min_row_height_padding: float32;
    rounding: float32;
    spacing: nk_vec2;
    scrollbar_size: nk_vec2;
    min_size: nk_vec2;
    padding: nk_vec2;
    group_padding: nk_vec2;
    popup_padding: nk_vec2;
    combo_padding: nk_vec2;
    contextual_padding: nk_vec2;
    menu_padding: nk_vec2;
    tooltip_padding: nk_vec2;
}

nk_style :: struct {
    font: *nk_user_font;
    cursors: [7] *nk_cursor;
    cursor_active: *nk_cursor;
    cursor_last: *nk_cursor;
    cursor_visible: s32;
    text: nk_style_text;
    button: nk_style_button;
    contextual_button: nk_style_button;
    menu_button: nk_style_button;
    option: nk_style_toggle;
    checkbox: nk_style_toggle;
    selectable: nk_style_selectable;
    slider: nk_style_slider;
    progress: nk_style_progress;
    property: nk_style_property;
    edit: nk_style_edit;
    chart: nk_style_chart;
    scrollh: nk_style_scrollbar;
    scrollv: nk_style_scrollbar;
    tab: nk_style_tab;
    combo: nk_style_combo;
    window: nk_style_window;
}

nk_style_item_image :: (img: nk_image) -> nk_style_item #foreign libnuklear;

nk_style_item_color :: (unk0: nk_color) -> nk_style_item #foreign libnuklear;

nk_style_item_hide :: () -> nk_style_item #foreign libnuklear;

using nk_panel_type :: enum s32 {
    NK_PANEL_NONE :: 0;
    NK_PANEL_WINDOW :: 1;
    NK_PANEL_GROUP :: 2;
    NK_PANEL_POPUP :: 4;
    NK_PANEL_CONTEXTUAL :: 16;
    NK_PANEL_COMBO :: 32;
    NK_PANEL_MENU :: 64;
    NK_PANEL_TOOLTIP :: 128;
}

using nk_panel_set :: enum s32 {
    NK_PANEL_SET_NONBLOCK :: 240;
    NK_PANEL_SET_POPUP :: 244;
    NK_PANEL_SET_SUB :: 246;
}

nk_chart_slot :: struct {
    type: nk_chart_type;
    color: nk_color;
    highlight: nk_color;
    min: float32;
    max: float32;
    range: float32;
    count: s32;
    last: nk_vec2;
    index: s32;
}

nk_chart :: struct {
    slot: s32;
    x: float32;
    y: float32;
    w: float32;
    h: float32;
    slots: [4] nk_chart_slot;
}

using nk_panel_row_layout_type :: enum s32 {
    NK_LAYOUT_DYNAMIC_FIXED :: 0;
    NK_LAYOUT_DYNAMIC_ROW :: 1;
    NK_LAYOUT_DYNAMIC_FREE :: 2;
    NK_LAYOUT_DYNAMIC :: 3;
    NK_LAYOUT_STATIC_FIXED :: 4;
    NK_LAYOUT_STATIC_ROW :: 5;
    NK_LAYOUT_STATIC_FREE :: 6;
    NK_LAYOUT_STATIC :: 7;
    NK_LAYOUT_TEMPLATE :: 8;
    NK_LAYOUT_COUNT :: 9;
}

nk_row_layout :: struct {
    type: nk_panel_row_layout_type;
    index: s32;
    height: float32;
    min_height: float32;
    columns: s32;
    ratio: *float32;
    item_width: float32;
    item_height: float32;
    item_offset: float32;
    filled: float32;
    item: nk_rect;
    tree_depth: s32;
    templates: [16] float32;
}

nk_popup_buffer :: struct {
    begin: nk_size;
    parent: nk_size;
    last: nk_size;
    end: nk_size;
    active: s32;
}

nk_menu_state :: struct {
    x: float32;
    y: float32;
    w: float32;
    h: float32;
    offset: nk_scroll;
}

nk_panel :: struct {
    type: nk_panel_type;
    flags: nk_flags;
    bounds: nk_rect;
    offset_x: *nk_uint;
    offset_y: *nk_uint;
    at_x: float32;
    at_y: float32;
    max_x: float32;
    footer_height: float32;
    header_height: float32;
    border: float32;
    has_scrolling: u32;
    clip: nk_rect;
    menu: nk_menu_state;
    row: nk_row_layout;
    chart: nk_chart;
    buffer: *nk_command_buffer;
    parent: *nk_panel;
}

using nk_window_flags :: enum s32 {
    NK_WINDOW_PRIVATE :: 2048;
    NK_WINDOW_DYNAMIC :: 2048;
    NK_WINDOW_ROM :: 4096;
    NK_WINDOW_NOT_INTERACTIVE :: 5120;
    NK_WINDOW_HIDDEN :: 8192;
    NK_WINDOW_CLOSED :: 16384;
    NK_WINDOW_MINIMIZED :: 32768;
    NK_WINDOW_REMOVE_ROM :: 65536;
}

nk_popup_state :: struct {
    win: *nk_window;
    type: nk_panel_type;
    buf: nk_popup_buffer;
    name: nk_hash;
    active: s32;
    combo_count: u32;
    con_count: u32;
    con_old: u32;
    active_con: u32;
    header: nk_rect;
}

nk_edit_state :: struct {
    name: nk_hash;
    seq: u32;
    old: u32;
    active: s32;
    prev: s32;
    cursor: s32;
    sel_start: s32;
    sel_end: s32;
    scrollbar: nk_scroll;
    mode: u8;
    single_line: u8;
}

nk_property_state :: struct {
    active: s32;
    prev: s32;
    buffer: [64] u8;
    length: s32;
    cursor: s32;
    select_start: s32;
    select_end: s32;
    name: nk_hash;
    seq: u32;
    old: u32;
    state: s32;
}

nk_window :: struct {
    seq: u32;
    name: nk_hash;
    name_string: [64] u8;
    flags: nk_flags;
    bounds: nk_rect;
    scrollbar: nk_scroll;
    buffer: nk_command_buffer;
    layout: *nk_panel;
    scrollbar_hiding_timer: float32;
    property: nk_property_state;
    popup: nk_popup_state;
    edit: nk_edit_state;
    scrolled: u32;
    tables: *nk_table;
    table_count: u32;
    next: *nk_window;
    prev: *nk_window;
    parent: *nk_window;
}

nk_config_stack_style_item_element :: struct {
    address: *nk_style_item;
    old_value: nk_style_item;
}

nk_config_stack_float_element :: struct {
    address: *float32;
    old_value: float32;
}

nk_config_stack_vec2_element :: struct {
    address: *nk_vec2;
    old_value: nk_vec2;
}

nk_config_stack_flags_element :: struct {
    address: *nk_flags;
    old_value: nk_flags;
}

nk_config_stack_color_element :: struct {
    address: *nk_color;
    old_value: nk_color;
}

nk_config_stack_user_font_element :: struct {
    address: **nk_user_font;
    old_value: *nk_user_font;
}

nk_config_stack_button_behavior_element :: struct {
    address: *nk_button_behavior;
    old_value: nk_button_behavior;
}

nk_config_stack_style_item :: struct {
    head: s32;
    elements: [16] nk_config_stack_style_item_element;
}

nk_config_stack_float :: struct {
    head: s32;
    elements: [32] nk_config_stack_float_element;
}

nk_config_stack_vec2 :: struct {
    head: s32;
    elements: [16] nk_config_stack_vec2_element;
}

nk_config_stack_flags :: struct {
    head: s32;
    elements: [32] nk_config_stack_flags_element;
}

nk_config_stack_color :: struct {
    head: s32;
    elements: [32] nk_config_stack_color_element;
}

nk_config_stack_user_font :: struct {
    head: s32;
    elements: [8] nk_config_stack_user_font_element;
}

nk_config_stack_button_behavior :: struct {
    head: s32;
    elements: [8] nk_config_stack_button_behavior_element;
}

nk_configuration_stacks :: struct {
    style_items: nk_config_stack_style_item;
    floats: nk_config_stack_float;
    vectors: nk_config_stack_vec2;
    flags: nk_config_stack_flags;
    colors: nk_config_stack_color;
    fonts: nk_config_stack_user_font;
    button_behaviors: nk_config_stack_button_behavior;
}

nk_table :: struct {
    seq: u32;
    size: u32;
    keys: [59] nk_hash;
    values: [59] nk_uint;
    next: *nk_table;
    prev: *nk_table;
}

nk_page_data :: union {
    tbl: nk_table;
    pan: nk_panel;
    win: nk_window;
}

nk_page_element :: struct {
    data: nk_page_data;
    next: *nk_page_element;
    prev: *nk_page_element;
}

nk_page :: struct {
    size: u32;
    next: *nk_page;
    win: [1] nk_page_element;
}

nk_pool :: struct {
    alloc: nk_allocator;
    type: nk_allocation_type;
    page_count: u32;
    pages: *nk_page;
    freelist: *nk_page_element;
    capacity: u32;
    size: nk_size;
    cap: nk_size;
}

nk_context :: struct {
    input: nk_input;
    style: nk_style;
    memory: nk_buffer;
    clip: nk_clipboard;
    last_widget_state: nk_flags;
    button_behavior: nk_button_behavior;
    stacks: nk_configuration_stacks;
    delta_time_seconds: float32;
    text_edit: nk_text_edit;
    overlay: nk_command_buffer;
    build: s32;
    use_pool: s32;
    pool: nk_pool;
    begin: *nk_window;
    end: *nk_window;
    active: *nk_window;
    current: *nk_window;
    freelist: *nk_page_element;
    count: u32;
    seq: u32;
}

