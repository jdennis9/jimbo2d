#+private
package j2d

// Also initializes video backend
_platform_impl_create_window: proc() -> bool
_platform_impl_destroy_window: proc()
_platform_impl_poll_events: proc()
_platform_impl_present: proc()
_platform_impl_set_clipboard_text: proc(text: string) -> bool
_platform_impl_get_clipboard_text: proc() -> string
