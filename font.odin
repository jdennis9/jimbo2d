package j2d

import "core:log"
import tt "vendor:stb/truetype"
import stbrp "vendor:stb/rect_pack"

FONT_ATLAS_MAX_WIDTH :: 512

Font_Atlas_Glyph :: struct {
	xoff, yoff, width, height: i16,
	advance: f32,
	uv: Rect,
}

Font_Mode :: enum {
	SDF,
	Bitmap,
}

Font_Atlas :: struct {
	texture:          Texture,
	mode:             Font_Mode,
	base_line_height: f32,
	pt_size:          f32,
	glyph_codes:      [dynamic]rune,
	glyphs:           [dynamic]Font_Atlas_Glyph,
}

load_font_from_memory :: proc(atlas: ^Font_Atlas, font_data: []byte, font_mode: Font_Mode, pixel_size: f32) -> bool {
	_Glyph :: struct {
		code: rune,
		xoff, yoff, width, height: f32,
		bitmap_x, bitmap_y: i32,
		advance: f32,
		data: [^]byte,
	}

	glyphs: [dynamic]_Glyph
	font: tt.fontinfo
	tt.InitFont(&font, raw_data(font_data), 0)

	scale := tt.ScaleForPixelHeight(&font, pixel_size)

	// Line height
	{
		y0, y1: i32
		tt.GetCodepointBitmapBox(&font, 'T', scale, scale, nil, &y0, nil, &y1)
		atlas.base_line_height = f32(y1 - y0)
	}


	glyph_ranges := [][2]rune {
		{0, 255}
	}

	defer {
		for g in glyphs {
			if g.data != nil do tt.FreeBitmap(g.data, nil)
		}
		delete(glyphs)
	}

	for range in glyph_ranges {
		glyph_loop: for glyph_code in range[0]..=range[1] {
			glyph_index := tt.FindGlyphIndex(&font, glyph_code)
			if glyph_index == 0 do continue

			glyph: _Glyph
			glyph.code = glyph_code
			
			// Metrics
			x_bearing, advance: i32
			y0, y1: i32
			tt.GetGlyphHMetrics(&font, glyph_index, &advance, &x_bearing)
			tt.GetGlyphBitmapBox(&font, glyph_index, scale, scale, nil, &y0, nil, &y1)


			glyph.advance = f32(advance) * scale
			glyph.xoff = f32(x_bearing) * scale
			glyph.yoff = f32(y0) + atlas.base_line_height

			// If a glyph is empty we just store its metrics and continue
			if tt.IsGlyphEmpty(&font, glyph_index) {
				append(&glyphs, glyph)
				continue glyph_loop
			}

			// Render
			xoff, yoff, width, height: i32
			bitmap_data: [^]byte
			switch font_mode {
			case .SDF:
				bitmap_data = tt.GetGlyphSDF(
					&font, scale, glyph_index, 3, 128, 12, &width, &height, &xoff, &yoff
				)
			case .Bitmap:
				bitmap_data = tt.GetGlyphBitmap(
					&font, scale, scale, glyph_index, &width, &height, &xoff, &yoff
				)
			}

			if bitmap_data == nil do continue glyph_loop

			glyph.width = auto_cast width
			glyph.height = auto_cast height
			glyph.data = bitmap_data

			append(&glyphs, glyph)
		}
	}

	// --------------------------------------------------------------------------
	// Pack rects
	// --------------------------------------------------------------------------
	
	rects: [dynamic]stbrp.Rect
	defer delete(rects)

	pack_nodes := make([]stbrp.Node, FONT_ATLAS_MAX_WIDTH)
	defer delete(pack_nodes)

	pack_context: stbrp.Context

	stbrp.init_target(&pack_context, FONT_ATLAS_MAX_WIDTH, FONT_ATLAS_MAX_WIDTH, raw_data(pack_nodes), auto_cast len(pack_nodes))

	glyph_spacing :: 1

	for glyph, i in glyphs {
		if glyph.width == 0 do continue
		append(&rects, stbrp.Rect {
			id = auto_cast i,
			w = auto_cast glyph.width + glyph_spacing,
			h = auto_cast glyph.height + glyph_spacing,
		})
	}

	stbrp.pack_rects(&pack_context, raw_data(rects), auto_cast len(rects))

	max_x: int
	max_y: int
	for rect in rects {
		max_x = max(max_x, int(rect.x + rect.w))
		max_y = max(max_y, int(rect.y + rect.h))
	}

	max_x = round_up_to_multiple(max_x, 32)
	max_y = round_up_to_multiple(max_y, 32)

	// Save glyphs to a texture
	sub_images: [dynamic]Sub_Image
	defer delete(sub_images)

	for rect in rects {
		if !rect.was_packed do continue
		glyph := &glyphs[rect.id]
		glyph.bitmap_x = auto_cast rect.x
		glyph.bitmap_y = auto_cast rect.y

		append(&sub_images, Sub_Image {
			data = glyph.data,
			x = auto_cast rect.x,
			y = auto_cast rect.y,
			w = auto_cast glyph.width,
			h = auto_cast glyph.height,
		})
	}

	atlas.texture = create_texture(Texture_Desc {
		width  = max_x,
		height = max_y,
		data   = sub_images[:],
		format = .R8,
		flags  = {.LinearSampling}
	}) or_return

	for glyph in glyphs {
		uv: Rect

		if glyph.width > 0 {
			uv.min.x = f32(glyph.bitmap_x) / f32(max_x)
			uv.min.y = f32(glyph.bitmap_y) / f32(max_y)
			uv.max.x = uv.min.x + (f32(glyph.width) / f32(max_x))
			uv.max.y = uv.min.y + (f32(glyph.height) / f32(max_y))
		}

		append(&atlas.glyph_codes, glyph.code)
		append(&atlas.glyphs, Font_Atlas_Glyph{
			advance = auto_cast glyph.advance,
			height  = auto_cast glyph.height,
			width   = auto_cast glyph.width,
			xoff    = auto_cast glyph.xoff,
			yoff    = auto_cast glyph.yoff,
			uv      = uv,
		})
	}

	atlas.mode = font_mode
	atlas.pt_size = pixel_size

	return true
}

font_get_glyph :: proc(font: Font_Atlas, code: rune) -> (glyph: Font_Atlas_Glyph, found: bool) {
	for gc, i in font.glyph_codes {
		if gc == code {
			return font.glyphs[i], true
		}
	}

	return
}

calc_text_width :: proc(font: ^Font_Atlas, str: string) -> f32 {
	w: f32
	for r in str {
		glyph := font_get_glyph(font^, r) or_continue
		w += f32(glyph.advance)
	}

	return w
}
