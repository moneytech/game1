
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

stbtt_packedchar :: struct {
    x0, y0, x1, y1: u16; // coordinates of bbox in bitmap
    xoff, yoff, xadvance: float;
    xoff2, yoff2: float; 
}

stbrp_rect :: struct {
    id: s32;
    w, h: stbrp_coord;
    x, y: stbrp_coord;
    was_packed: s32;  // non-zero if valid packing
}

// must match stb.cpp
STBRP_LARGE_RECTS :: false;
#if STBRP_LARGE_RECTS {
    stbrp_coord :: s32;
} else {
    stbrp_coord :: u16;
}

stbtt_PackBegin :: (spc: *stbtt_pack_context, pixels: *u8, width: s32, height: s32, stride_in_bytes: s32, padding: s32, alloc_context: *void) -> s32 #foreign stb;

stbtt_PackEnd :: (spc: *stbtt_pack_context) #foreign stb;

STBTT_POINT_SIZE :: inline (x: $T) -> T { return -x; }

stbtt_PackFontRange :: (spc: *stbtt_pack_context, fontdata: *u8, font_index: s32, font_size: float,
                                first_unicode_char_in_range: s32, num_chars_in_range: s32, chardata_for_range: *stbtt_packedchar) -> s32 #foreign stb;

stbtt_pack_range :: struct {
    font_size: float;
    first_unicode_codepoint_in_range: s32;  // if non-zero, then the chars are continuous, and this is the first codepoint
    array_of_unicode_codepoints: *s32;       // if non-zero, then this is an array of unicode codepoints
    num_chars: s32;
    chardata_for_range: *stbtt_packedchar; // output
    h_oversample, v_oversample: u8; // don't set these, they're used internally
}

stbtt_PackFontRanges :: (spc: *stbtt_pack_context, fontdata: *u8, font_index: s32, ranges: *stbtt_pack_range, num_ranges: s32) -> s32 #foreign stb;

stbtt_PackSetOversampling :: (spc: *stbtt_pack_context, h_oversample: u32, v_oversample: u32) #foreign stb;

stbtt_GetPackedQuad :: (chardata: *stbtt_packedchar, pw: s32, ph: s32,  // same data as above
                               char_index: s32,             // character to display
                               xpos: *float, ypos: *float,   // pointers to current position in screen pixel space
                               q: *stbtt_aligned_quad,      // output: quad to draw
                               align_to_integer: s32) #foreign stb;

stbtt_PackFontRangesGatherRects :: (spc: *stbtt_pack_context, info: *stbtt_fontinfo, ranges: *stbtt_pack_range, num_ranges: s32, rects: *stbrp_rect) -> s32 #foreign stb;
stbtt_PackFontRangesPackRects :: (spc: *stbtt_pack_context, rects: *stbrp_rect, num_rects: s32) #foreign stb;
stbtt_PackFontRangesRenderIntoRects :: (spc: *stbtt_pack_context, info: *stbtt_fontinfo, ranges: *stbtt_pack_range, num_ranges: s32, rects: *stbrp_rect) -> s32 #foreign stb;

stbtt_pack_context :: struct {
    user_allocator_context: *void;
    pack_info: *void;
    width: s32;
    height: s32;
    stride_in_bytes: s32;
    padding: s32;
    h_oversample, v_oversample: u32;
    pixels: *u8;
    nodes: *void;
}

stbtt_fontinfo :: struct {
    userdata: *void;
    data: *u8;              // pointer to .ttf file
    fontstart: s32;         // offset of start of font

    numGlyphs: s32;                     // number of glyphs, needed for range checking

    loca, head, glyf, hhea, hmtx, kern: s32; // table locations as offset from start of .ttf
    index_map: s32;                     // a cmap mapping for our chosen character encoding
    indexToLocFormat: s32;              // format needed to map from glyph index to glyph

    cff: stbtt__buf;                    // cff font data
    charstrings: stbtt__buf;            // the charstring index
    gsubrs: stbtt__buf;                 // global charstring subroutines index
    subrs: stbtt__buf;                  // private charstring subroutines index
    fontdicts: stbtt__buf;              // array of font dicts
    fdselect: stbtt__buf;               // map from glyph to fontdict
}

stbtt__buf :: struct {
    data: *u8;
    cursor: s32;
    size: s32;
}

stbi_load :: (filename: *u8, x: *s32, y: *s32, channels_in_file: *s32, desired_channels: s32) -> *u8 #foreign stb;
stbi_load_from_memory :: (data: *u8, len: s32, x: *s32, y: *s32, channels_in_file: *s32, desired_channels: s32) -> *u8 #foreign stb;
stbi_image_free :: (retval_from_stbi_load: *void) #foreign stb;
stbi_failure_reason :: () -> *u8 #foreign stb;
