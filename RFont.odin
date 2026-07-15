package RFont

when ODIN_OS == .Windows {
    @(extra_linker_flags="/NODEFAULTLIB:msvcrt")
		foreign import native {
			"lib/RFont_msvc.lib",
		}
} else when ODIN_OS == .Darwin {
    foreign import native {
        "lib/RFont.a",
    }
} else when (ODIN_OS == .Linux || ODIN_OS == .FreeBSD || ODIN_OS == .OpenBSD) {
    foreign import native {
        "lib/RFont.a",
    }
} else when (ODIN_OS == .JS) {
    foreign import native {
        "lib/RFont_wasm.o",
    }
}

import "core:c"

texture :: c.size_t
surface :: rawptr

MAX_GLYPHS :: 256
INIT_VERTS :: 20 * MAX_GLYPHS

render_data :: struct {
	verts : ^c.float,
	tcoords : ^c.float,
	elements : ^u16,

	atlas : texture,
	nverts : c.size_t,
	nelements : c.size_t
}

renderer_proc :: struct {
	size : #type proc "c" () -> c.size_t, /*!< get the size of the renderer context */
	initPtr : #type proc "c" (ctx: rawptr), /* any initalizations the renderer needs to do */
	create_atlas : #type proc "c" (ctx: rawptr, atlasWidth: u32, atlasHeight: u32) -> texture, /* create a bitmap texture based on the given size */
	free_atlas : #type proc "c" (ctx: rawptr, atlas: texture),
	bitmap_to_atlas : #type proc "c" (ctx: rawptr, atlas: texture, atlasWidth: u32, atlasHeight: u32, maxHeight : u32, bitmap : [^]u8, w: c.float, h : c.float, x: ^c.float, y: ^c.float), /* add the given bitmap to the texture based on the given coords and size data */
	render : #type proc "c" (ctx: rawptr, data: ^render_data), /* render the text, using the vertices, atlas texture, and texture coords given. */
	set_framebuffer : #type proc "c" (ctx: rawptr, width: u32, height: u32), /*!< set the frame buffer size (for ortho, for example) */
	set_color : #type proc "c" (ctx: rawptr, r : c.float, g : c.float, b : c.float, a : c.float), /*!< set the current rendering color */
	set_surface : #type proc "c" (ctx: rawptr, surface: surface),
	freePtr : #type proc "c" (ctx: rawptr) /* free any memory the renderer might need to free */
} 

renderer :: struct {
	ctx: rawptr, /*!< source renderer data */
	procdef: renderer_proc
}

glyph :: struct {
   codepoint : u32, /* the character (for checking) */
   size : c.size_t, /* the size of the glyph */
   x, x2, y, y2 : i32,  /* coords of the character on the texture */
   font: ^font, /* the font that the glyph belongs to */

   /* source glyph data */
   src : i32,
   w, h, x1, y1, advance : c.float
}

src :: struct {}

font :: struct {
	src : ^src, /* source stb font info */
	fheight, /* source font height */
	descent, /* font descent */
	numOfLongHorMetrics,
	space_adv: c.float,
	maxHeight: u32,

	glyphs: [MAX_GLYPHS]glyph, /* glyphs */
	glyph_len: c.size_t,

	atlas: texture, /* atlas texture */
	atlasWidth, atlasHeight: c.size_t,
	atlasX, atlasY: c.float, /* the current position inside the atlas */

	verts: [INIT_VERTS * 3]c.float,
	tcoords: [INIT_VERTS * 2]c.float,
	elements: [INIT_VERTS * 6]u16
}

glyph_fallback_callback :: #type proc "c" (renderer: ^renderer, font: ^font, codepoint : u32, size: c.size_t) -> glyph

@(default_calling_convention="c", link_prefix="RSGL_")
foreign {
    renderer_size :: proc(renderer: ^renderer) -> c.size_t ---

    renderer_init :: proc(procdef: renderer_proc) -> ^renderer ---
    renderer_initPtr :: proc(procdef: renderer_proc, ptr: rawptr, renderer: ^renderer) ---

    renderer_set_framebuffer :: proc(renderer: ^renderer, w: u32, h: u32) ---
    renderer_set_surface :: proc(renderer: ^renderer, surface: surface) ---
    renderer_set_color :: proc(renderer: ^renderer, r: c.float, g: c.float, b: c.float, a: c.float) ---

    renderer_free :: proc(renderer: ^renderer) ---
    renderer_freePtr :: proc(renderer: ^renderer) ---

    /**
    * @brief Converts a codepoint to a utf8 string.
    * @param codepoint The codepoint to convert to utf8.
    * @return The utf8 string.
    */
    codepoint_to_utf8 :: proc(codepoint: u32) -> cstring ---

    /**
    * @brief Init font stucture with a TTF file path.
    * @param font_name The TTF file path.
    * @param atlasWidth The width of the atlas texture.
    * @param atlasHeight The height of the atlas texture. (This should == the max text size)
    * @return The `font` created using the TTF file data.
    */
    font_init :: proc(renderer: ^renderer, font_name: cstring, maxHeight: u32, atlasWidth: c.size_t, atlasHeight: c.size_t) -> ^font ---
    /**
    * @brief Init a given font stucture with a TTF file path.
    * @param font_name The TTF file path.
    * @param atlasWidth The width of the atlas texture.
    * @param atlasHeight The height of the atlas texture. (This should == the max text size)
    * @pram ptr Pointer to the given font structure
    * @return returns the same pointer or NULL if the font failed to load
    */
    font_init_ptr :: proc(renderer: ^renderer, font_name: cstring, maxHeight: u32, atlasWidth: c.size_t, atlasHeight: c.size_t, font: ^font) -> ^font ---

    /**
    * @brief Init font stucture with raw TTF data.
    * @param font_data The raw TTF data.
    * @param atlasWidth The width of the atlas texture.
    * @param atlasHeight The height of the atlas texture. (This should == the max text size)
    * @return The `font` created from the data.
    */
    font_init_data :: proc(renderer: ^renderer, font_data: []u8, maxHeight: u32, atlasWidth: c.size_t, atlasHeight: c.size_t) -> ^font ---

    /**
    * @brief Init a given font stucture with raw TTF data.
    * @param font_data The raw TTF data.
    * @param atlasWidth The width of the atlas texture.
    * @param atlasHeight The height of the atlas texture. (This should == the max text size)
    * @return The `font` created from the data.
    * @return returns the same pointer or NULL if the font failed to load
    */
    font_init_data_ptr :: proc(renderer: ^renderer, font_data: []u8, maxHeight: u32, atlasWidth: c.size_t, atlasHeight: c.size_t, ptr: ^font) -> ^font ---

    /**
    * @brief Free data from the font stucture, including the stucture itself
    * @param font The font stucture to free
    */
    font_free :: proc(renderer: ^renderer, font: ^font) ---

    /**
    * @brief Free data from the font stucture only (not including the stucture)
    * @param font The strucutre with the font data  to free
    */
    font_free_ptr :: proc(renderer: ^renderer, font: ^font) ---

    set_glyph_fallback_callback :: proc(callback: glyph_fallback_callback) -> glyph_fallback_callback ---

    /**
    * @brief Add a character to the font's atlas.
    * @param font The font to use.
    * @param ch The character to add to the atlas.
    * @param size The size of the character.
    * @return The `glyph` created from the data and added to the atlas.
    */
    font_add_char :: proc(renderer: ^renderer,font: ^font, ch: c.char, size: c.size_t) -> glyph ---

    /**
    * @brief Add a codepoint to the font's atlas.
    * @param font The font to use.
    * @param codepoint The codepoint to add to the atlas.
    * @param size The size of the character.
    * @return The `glyph` created from the data and added to the atlas.
    */
    font_add_codepoint :: proc(renderer: ^renderer, font: ^font, codepoint: u32, size: c.size_t) -> glyph ---

    /**
    * @brief Add a codepoint to the font's atlas.
    * @param font The font to use.
    * @param codepoint The codepoint to add to the atlas.
    * @param size The size of the character.
    * @param fallback If the fallback function should not be called.
    * @return The `glyph` created from the data and added to the atlas.
    */
    font_add_codepoint_ex :: proc(renderer: ^renderer, font: ^font, codepoint: u32, size: c.size_t, fallback: b8) -> glyph ---

    /**
    * @brief Add a string to the font's atlas.
    * @param font The font to use.
    * @param ch The character to add to the atlas.
    * @param sizes The supported sizes of the character.
    * @param sizeLen length of the size array
    */
    font_add_string :: proc(renderer: ^renderer, font: ^font, string: cstring, sizes: c.size_t, sizeLen : c.size_t) ---

    /**
    * @brief Add a string to the font's atlas based on a given string length.
    * @param font The font to use.
    * @param ch The character to add to the atlas.
    * @param strLen length of the string
    * @param sizes The supported sizes of the character.
    * @param sizeLen length of the size array
    */
    font_add_string_len :: proc(renderer: ^renderer, font: ^font, string: cstring, strLen: c.size_t, sizes: ^c.size_t, sizeLen: c.size_t) ---

    /**
    * @brief Get the area of the text based on the size using the font.
    * @param font The font stucture to use for drawing
    * @param text The string to draw
    * @param size The size of the text
    * @param [OUTPUT] the output width
    * @param [OUTPUT] the output height
    */
    text_area :: proc(renderer: ^renderer, font: ^font, text: cstring, size: u32, w: ^u32, h: ^u32) ---

    /**
    * @brief Get the area of the text based on the size using the font, using a given length.
    * @param font The font stucture to use for drawing
    * @param text The string to draw
    * @param size The size of the text
    * @param spacing The spacing of the text
    * @param [OUTPUT] the output width
    * @param [OUTPUT] the output height
    */
    text_area_spacing :: proc(renderer: ^renderer, font: ^font, text: cstring, spacing: c.float, size: u32, w: ^u32, h: ^u32) ---

    /**
    * @brief Get the area of the text based on the size using the font, using a given length.
    * @param font The font stucture to use for drawing
    * @param text The string to draw
    * @param len The length of the string
    * @param size The size of the text
    * @param stopNL the number of \n s until it stops (0 = don't stop until the end)
    * @param spacing The spacing of the text
    * @param [OUTPUT] the output width
    * @param [OUTPUT] the output height
    */
    text_area_len :: proc(renderer: ^renderer, font: ^font, text: cstring, len: c.size_t, size: u32, stopNL : c.size_t, spacing: c.float, w: ^u32, h: ^u32) ---

    /**
    * @brief Draw a text string using the font.
    * @param font The font stucture to use for drawing
    * @param text The string to draw
    * @param x The x position of the text
    * @param y The y position of the text
    * @param size The size of the text
    * @return the number of verts rendered
    */
    draw_text :: proc(renderer: ^renderer, font: ^font, text: cstring, x: c.float, y: c.float, size: u32) -> c.size_t ---

    /**
    * @brief Draw a text string using the font and a given spacing.
    * @param font The font stucture to use for drawing
    * @param text The string to draw
    * @param x The x position of the text
    * @param y The y position of the text
    * @param size The size of the text
    * @param spacing The spacing of the text
    * @return the number of verts rendered
    */
    draw_text_spacing :: proc(renderer: ^renderer, font: ^font, text: cstring, x: c.float, y: c.float, size: u32, spacing: c.float) -> c.size_t ---

    /**
    * @brief Draw a text string using the font using a given length and a given spacing.
    * @param font The font stucture to use for drawing
    * @param text The string to draw
    * @param len The length of the string
    * @param x The x position of the text
    * @param y The y position of the text
    * @param size The size of the text
    * @param spacing The spacing of the text
    * @return the number of verts rendered
    */
    draw_text_len :: proc(renderer: ^renderer, font: ^font, text: cstring, len: c.size_t, x: c.float, y: c.float, size: u32, spacing: c.float) -> c.size_t ---
}