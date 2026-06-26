package j2d_test

import "core:log"
import j2 "../.."

vec2 :: [2]f32

run :: proc() -> bool {
	context.logger = log.create_console_logger()
	defer log.destroy_console_logger(context.logger)

	cam_pos: vec2

	j2.init({
		window_width  = 1920,
		window_height = 1080,
		window_title  = "Jimbo2D",
	}) or_return
	defer j2.shutdown()

	smiley := j2.load_texture_from_memory(#load("smiley.png")) or_return

	for j2.update() {
		dl := j2.get_main_drawlist()
		j2.clear_window(j2.COLOR_BLACK)

		if j2.was_key_pressed(.A) do cam_pos.x -= 20
		if j2.was_key_pressed(.D) do cam_pos.x += 20
		if j2.was_key_pressed(.W) do cam_pos.y -= 20
		if j2.was_key_pressed(.S) do cam_pos.y += 20

		j2.drawlist_set_scope_camera(dl, j2.make_camera(cam_pos, {1, 1}, {0, 1}))

		j2.draw_circle(dl, {200, 200}, 60, j2.COLOR_GREEN)
		j2.draw_box_filled(dl, {60, 200}, {30, 30}, j2.make_rot(0.2), j2.COLOR_RED)

		j2.drawlist_set_scope_font_size(dl, 18)
		j2.draw_text(dl, "This text is rendered using an SDF shader,", {800, 400}, j2.COLOR_WHITE)
		j2.drawlist_set_scope_font_size(dl, 24)
		j2.draw_text(dl, "allowing for dynamic text size without needing to render new glyphs", {800, 420}, j2.COLOR_WHITE)
		j2.drawlist_set_scope_font_size(dl, 48)
		j2.draw_text(dl, "Use WASD to move the camera", {800, 500}, j2.COLOR_WHITE)

		j2.draw_sprite(dl, smiley, {600, 800}, {0, 1})
		j2.draw_sprite(dl, smiley, {800, 800}, scale = 2)
		j2.draw_sprite(dl, smiley, {1200, 800}, scale = 0.5)

		j2.present()
	}

	return true
}

main :: proc() {
	run()
}
