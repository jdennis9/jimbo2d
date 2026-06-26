package j2d

import mu "vendor:microui"

Key :: enum u8 {
	Unknown,

	_0, _1, _2, _3, _4, _5, _6, _7, _8, _9,

	A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z,

	F1, F2, F3, F4, F5, F6, F7, F8, F9, F10, F11, F12,

	Shift, Alt, Ctrl,

	Up, Down, Left, Right,

	Minus, Equals, Grave, LeftBrace, RightBrace, SemiColon, Apostrophe,
	Comma, Period, Slash, Backslash,

	Escape, Backspace, Enter, Tab,

	Numlock, KpDivide, KpMultiply, KpSubtract, KpAdd, KpEnter, KpPeriod,
	Kp1, Kp2, Kp3, Kp4, Kp5, Kp6, Kp7, Kp8, Kp9, Kp0,

	Insert, Home, PageUp, PageDown, Delete, End,
}

Mouse_Button :: enum u8 {
	Unknown,
	Left, Right, Middle,
	X1, X2, X3, X4, X5, X6,
}

@(private="file")
_input: struct {
	keys:      [Key]bool,
	old_keys:  [Key]bool,
	mouse:     [Mouse_Button]bool,
	old_mouse: [Mouse_Button]bool,
	mouse_pos: Vec2,
}

@private
_input_pre_update :: proc() {
	_input.old_keys = _input.keys
	_input.old_mouse = _input.mouse
}

send_key_down :: proc "contextless" (k: Key) {
	_input.keys[k] = true
}

send_key_up :: proc "contextless" (k: Key) {
	_input.keys[k] = false
}

is_key_down :: proc "contextless" (k: Key) -> bool {
	return _input.keys[k]
}

was_key_pressed :: proc "contextless" (k: Key) -> bool {
	return _input.keys[k] && !_input.old_keys[k]
}

was_key_released :: proc "contextless" (k: Key) -> bool {
	return !_input.keys[k] && _input.old_keys[k]
}

send_mouse_motion :: proc "contextless" (pos: Vec2) {
	_input.mouse_pos = pos
}

get_mouse_pos :: proc "contextless" () -> Vec2 {
	return _input.mouse_pos
}

send_mouse_down :: proc "contextless" (button: Mouse_Button) {
	_input.mouse[button] = true
}

send_mouse_up :: proc "contextless" (button: Mouse_Button) {
	_input.mouse[button] = false
}
