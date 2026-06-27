package j2d

Platform_Interface :: struct {
	get_info: proc() -> Interface_Info,
	create_window: proc() -> bool, // needs to initialize video backend
	destroy_window: proc(), // needs to clean up video backend
	poll_events: proc(), // sends key and mouse events
	present: proc(),
	set_clipboard_text: proc(text: string) -> bool, // optional
	get_clipboard_text: proc() -> string, // optional
}

// Preset platform names
PLATFORM_NAME_GLFW :: "glfw"

@private
_platform: Platform_Interface

get_clipboard_text :: proc() -> string {
	if _platform.get_clipboard_text == nil do return ""
	return _platform.get_clipboard_text()
}

set_clipboard_text :: proc(str: string) -> bool {
	if _platform.set_clipboard_text == nil do return false
	return _platform.set_clipboard_text(str)
}

get_platform_info :: proc() -> Interface_Info {
	if _platform.get_info != nil {
		return _platform.get_info()
	}

	return {}
}

@private
platform_create_window :: proc() -> bool {
	hooks := get_hooks()
	ok := _platform.create_window()
	if hooks.on_create_window != nil do hooks.on_create_window()
	return ok
}

@private
platform_destroy_window :: proc() {
	hooks := get_hooks()
	if hooks.on_destroy_window != nil do hooks.on_destroy_window()
	_platform.destroy_window()
}
