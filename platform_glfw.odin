#+private file
package j2d

import "core:strings"
import "vendor:glfw"

_glfw: struct {
	window: glfw.WindowHandle,
}

_KEY_MAP := [glfw.KEY_LAST+1]Key {
	glfw.KEY_1             = ._1,
	glfw.KEY_2             = ._2,
	glfw.KEY_3             = ._3,
	glfw.KEY_4             = ._4,
	glfw.KEY_5             = ._5,
	glfw.KEY_6             = ._6,
	glfw.KEY_7             = ._7,
	glfw.KEY_8             = ._8,
	glfw.KEY_9             = ._9,
	glfw.KEY_0             = ._0,
	glfw.KEY_A             = .A,
	glfw.KEY_B             = .B,
	glfw.KEY_C             = .C,
	glfw.KEY_D             = .D,
	glfw.KEY_E             = .E,
	glfw.KEY_F             = .F,
	glfw.KEY_G             = .G,
	glfw.KEY_H             = .H,
	glfw.KEY_I             = .I,
	glfw.KEY_J             = .J,
	glfw.KEY_K             = .K,
	glfw.KEY_L             = .L,
	glfw.KEY_M             = .M,
	glfw.KEY_N             = .N,
	glfw.KEY_O             = .O,
	glfw.KEY_P             = .P,
	glfw.KEY_Q             = .Q,
	glfw.KEY_R             = .R,
	glfw.KEY_S             = .S,
	glfw.KEY_T             = .T,
	glfw.KEY_U             = .U,
	glfw.KEY_V             = .V,
	glfw.KEY_W             = .W,
	glfw.KEY_X             = .X,
	glfw.KEY_Y             = .Y,
	glfw.KEY_Z             = .Z,
	glfw.KEY_LEFT_SHIFT    = .Shift,
	glfw.KEY_RIGHT_SHIFT   = .Shift,
	glfw.KEY_LEFT_ALT      = .Alt,
	glfw.KEY_RIGHT_ALT     = .Alt,
	glfw.KEY_LEFT_CONTROL  = .Ctrl,
	glfw.KEY_RIGHT_CONTROL = .Ctrl,
	glfw.KEY_UP            = .Up,
	glfw.KEY_DOWN          = .Down,
	glfw.KEY_LEFT          = .Left,
	glfw.KEY_RIGHT         = .Right,
	glfw.KEY_MINUS         = .Minus,
	glfw.KEY_EQUAL         = .Equals,
	glfw.KEY_GRAVE_ACCENT  = .Grave,
	glfw.KEY_LEFT_BRACKET  = .LeftBrace,
	glfw.KEY_RIGHT_BRACKET = .RightBrace,
	glfw.KEY_SEMICOLON     = .SemiColon,
	glfw.KEY_APOSTROPHE    = .Apostrophe,
	glfw.KEY_COMMA         = .Comma,
	glfw.KEY_PERIOD        = .Period,
	glfw.KEY_SLASH         = .Slash,
	glfw.KEY_BACKSLASH     = .Backslash,
	glfw.KEY_ESCAPE        = .Escape,
	glfw.KEY_BACKSPACE     = .Backspace,
	glfw.KEY_ENTER         = .Enter,
	glfw.KEY_TAB           = .Tab,
	glfw.KEY_NUM_LOCK      = .Numlock,
	glfw.KEY_KP_DIVIDE     = .KpDivide,
	glfw.KEY_KP_MULTIPLY   = .KpMultiply,
	glfw.KEY_KP_SUBTRACT   = .KpSubtract,
	glfw.KEY_KP_ADD        = .KpAdd,
	glfw.KEY_KP_ENTER      = .KpEnter,
	glfw.KEY_KP_DECIMAL    = .KpPeriod,
	glfw.KEY_KP_0          = .Kp0,
	glfw.KEY_KP_1          = .Kp1,
	glfw.KEY_KP_2          = .Kp2,
	glfw.KEY_KP_3          = .Kp3,
	glfw.KEY_KP_4          = .Kp4,
	glfw.KEY_KP_5          = .Kp5,
	glfw.KEY_KP_6          = .Kp6,
	glfw.KEY_KP_7          = .Kp7,
	glfw.KEY_KP_8          = .Kp8,
	glfw.KEY_KP_9          = .Kp9,
	glfw.KEY_INSERT        = .Insert,
	glfw.KEY_HOME          = .Home,
	glfw.KEY_PAGE_UP       = .PageUp,
	glfw.KEY_PAGE_DOWN     = .PageDown,
	glfw.KEY_DELETE        = .Delete,
	glfw.KEY_END           = .End,
}

@private
platform_use_glfw :: proc() {
	glfw.Init()

	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 3)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 0)
	
	_key_proc :: proc "c" (window: glfw.WindowHandle, key, scancode, action, mods: i32) {
		if action == glfw.PRESS do send_key_down(_map_key(key))
		else if action == glfw.RELEASE do send_key_up(_map_key(key))
	}

	_cursor_pos_proc :: proc "c" (window: glfw.WindowHandle, x, y: f64) {
		send_mouse_motion({f32(x), f32(y)})
	}

	_mouse_button_proc :: proc "c" (window: glfw.WindowHandle, button, action, mods: i32) {
		butt := _map_mouse_button(button)
		if action == glfw.PRESS do send_mouse_down(butt)
		else if action == glfw.RELEASE do send_mouse_up(butt)
	}
	
	_platform_impl_create_window = proc() -> bool {
		ip := get_init_params()
		
		_glfw.window = glfw.CreateWindow(
			auto_cast ip.window_width, auto_cast ip.window_height, strings.clone_to_cstring(ip.window_title, frame_allocator()),
			nil, nil
		)
		
		
		if _glfw.window == nil do return false
		
		glfw.SetKeyCallback(_glfw.window, _key_proc)
		glfw.SetCursorPosCallback(_glfw.window, _cursor_pos_proc)
		glfw.SetMouseButtonCallback(_glfw.window, _mouse_button_proc)

		glfw.MakeContextCurrent(_glfw.window)
		glfw.SwapInterval(1)

		_video_init_opengl(glfw.gl_set_proc_address)
		return true
	}

	_platform_impl_destroy_window = proc() {
		if _glfw.window != nil {
			glfw.DestroyWindow(_glfw.window)
			_video_impl_shutdown()
		}
	}

	_platform_impl_poll_events = proc() {
		glfw.PollEvents()
	}

	_platform_impl_present = proc() {
		glfw.SwapBuffers(_glfw.window)
	}

	_platform_impl_set_clipboard_text = proc(text: string) -> bool {
		if _glfw.window == nil do return false
		glfw.SetClipboardString(_glfw.window, strings.clone_to_cstring(text, frame_allocator()))
		return true
	}

	_platform_impl_get_clipboard_text = proc() -> string {
		if _glfw.window == nil do return ""
		return string(glfw.GetClipboardString(_glfw.window))
	}
}

_map_key :: proc "contextless" (k: i32) -> Key {
	if k >= len(_KEY_MAP) || k < 0 do return .Unknown
	return _KEY_MAP[k]
}

_map_mouse_button :: proc "contextless" (b: i32) -> Mouse_Button {
	switch b {
	case glfw.MOUSE_BUTTON_LEFT: return .Left
	case glfw.MOUSE_BUTTON_RIGHT: return .Right
	case glfw.MOUSE_BUTTON_MIDDLE: return .Middle
	case glfw.MOUSE_BUTTON_4: return .X1
	case glfw.MOUSE_BUTTON_5: return .X2
	case glfw.MOUSE_BUTTON_6: return .X3
	case glfw.MOUSE_BUTTON_7: return .X4
	case glfw.MOUSE_BUTTON_8: return .X5
	}

	return .Unknown
}
