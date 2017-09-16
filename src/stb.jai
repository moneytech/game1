
#scope_file
stb :: #foreign_library "stb";
#scope_export

stbtt_bakedchar :: struct {
	x0, y0, x1, y1: u16;
	xoff, yoff, xadvance: float;
}

stbtt_BakeFontBitmap :: (data: *u8, offset: s32,
						pixel_height: float, pixels: *u8,
						pw: s32, ph: s32, first_char: s32, num_chars: s32,
						chardata: *stbtt_bakedchar) -> s32 #foreign stb;

stbtt_aligned_quad :: struct {
	x0, y0, s0, t0: float;
	x1, y1, s1, t1: float;
}

stbtt_GetBakedQuad :: (chardata: *stbtt_bakedchar, pw: s32, ph: s32,
                       	char_index: s32, xpos: *float, ypos: *float,
                       	q: *stbtt_aligned_quad, opengl_fillrule: s32) #foreign stb;

stbi_load :: (filename: *u8, x: *s32, y: *s32, channels_in_file: *s32, desired_channels: s32) -> *u8 #foreign stb;
stbi_load_from_memory :: (data: *u8, len: s32, x: *s32, y: *s32, channels_in_file: *s32, desired_channels: s32) -> *u8 #foreign stb;
stbi_image_free :: (retval_from_stbi_load: *void) #foreign stb;
stbi_failure_reason :: () -> *u8 #foreign stb;
