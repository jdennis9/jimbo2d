package microui_example

import j2 "../.."
import mu "vendor:microui"

ui: ^mu.Context

run :: proc() -> bool {
	@static ctx: mu.Context
	ui = &ctx

	number: mu.Real
	slider_num: mu.Real

	j2.init({
		window_width    = 1280,
		window_height   = 720,
		window_title    = "microui example",
		microui_context = ui
	}) or_return
	defer j2.shutdown()

	for j2.update() {
		j2.clear_window(j2.COLOR_BLACK)

		mu.begin(ui)
		if mu.begin_window(ui, "A Window", {10, 10, 200, 400}) {
			mu.button(ui, "A button")
			mu.text(ui, "Some text")
			mu.number(ui, &number, 1)
			mu.slider(ui, &slider_num, 0, 10)
			mu.end_window(ui)
		}
		mu.end(ui)

		j2.present()
	}

	return true
}

main :: proc() {
	run()
}
