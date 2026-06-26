package j2d

Platform_Impl_Info :: struct {
	name:      string,
	data:      rawptr,
	data_type: typeid,
}

Platform_Interface :: struct {
	get_info: proc() -> Platform_Impl_Info,
	create_window: proc() -> bool, // needs to initialize video backend
	destroy_window: proc(), // needs to clean up video backend
	poll_events: proc(), // sends key and mouse events
	present: proc(),
	set_clipboard_text: proc(text: string) -> bool, // optional
	get_clipboard_text: proc() -> string, // optional
}

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

get_platform_info :: proc() -> Platform_Impl_Info {
	if _platform.get_info != nil {
		return _platform.get_info()
	}

	return {}
}
