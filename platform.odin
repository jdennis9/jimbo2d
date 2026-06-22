package j2d

get_clipboard_text :: proc() -> string {
	if _platform_impl_get_clipboard_text == nil do return ""
	return _platform_impl_get_clipboard_text()
}

set_clipboard_text :: proc(str: string) -> bool {
	if _platform_impl_set_clipboard_text == nil do return false
	return _platform_impl_set_clipboard_text(str)
}
