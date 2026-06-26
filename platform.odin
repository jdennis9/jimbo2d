package j2d

Platform_Impl_Info :: struct {
	name:      string,
	data:      rawptr,
	data_type: typeid,
}

get_clipboard_text :: proc() -> string {
	if _platform_impl_get_clipboard_text == nil do return ""
	return _platform_impl_get_clipboard_text()
}

set_clipboard_text :: proc(str: string) -> bool {
	if _platform_impl_set_clipboard_text == nil do return false
	return _platform_impl_set_clipboard_text(str)
}

get_platform_info :: proc() -> Platform_Impl_Info {
	if _platform_impl_get_info != nil {
		return _platform_impl_get_info()
	}

	return {}
}
