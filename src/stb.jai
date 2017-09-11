
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

