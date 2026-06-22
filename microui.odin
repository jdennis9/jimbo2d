#+private
package j2d

import mu "vendor:microui"

microui_init :: proc(ctx: ^mu.Context) {
	_set_clipboard :: proc(_: rawptr, text: string) -> bool {
		return set_clipboard_text(text)
	}

	_get_clipboard :: proc(_: rawptr) -> (string, bool) {
		s := get_clipboard_text()
		return s, s != ""
	}

	mu.init(ctx, _set_clipboard, _get_clipboard)
	
	ctx.text_width = proc(raw_font: mu.Font, str: string) -> i32 {
		font := cast(^Font_Atlas) raw_font
		return i32(calc_text_width(font != nil ? font : get_default_font(), str))
	}

	ctx.text_height = proc(raw_font: mu.Font) -> i32 {
		font := cast(^Font_Atlas) raw_font
		if font == nil do font = get_default_font()
		return i32(font.base_line_height) + 6
	}

}

microui_draw :: proc(ctx: ^mu.Context, drawlist: ^Drawlist) {
	cmd: ^mu.Command

	old_clip := drawlist_get_clip_rect(drawlist^)
	defer drawlist_set_clip_rect(drawlist, old_clip)

	for variant in mu.next_command_iterator(ctx, &cmd) {
		switch v in variant {
		case ^mu.Command_Rect:
			r: Rect
			r.min = {f32(v.rect.x), f32(v.rect.y)}
			r.max = r.min + {f32(v.rect.w), f32(v.rect.h)}
			draw_rect_filled(drawlist, r, transmute(Color) v.color)
		case ^mu.Command_Text:
			draw_text(drawlist, v.str, auto_cast v.pos, transmute(Color)v.color)
		case ^mu.Command_Clip:
			r: Rect
			r.min = {f32(v.rect.x), f32(v.rect.y)}
			r.max = r.min + {f32(v.rect.w), f32(v.rect.h)}
			drawlist_set_clip_rect(drawlist, r)
		case ^mu.Command_Jump:
		case ^mu.Command_Icon:
		}
	}
}
