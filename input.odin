package j2d

import "core:math/linalg"
import "core:log"
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

	Escape, Backspace, Enter, Tab, Space,

	Numlock, KpDivide, KpMultiply, KpSubtract, KpAdd, KpEnter, KpPeriod,
	Kp1, Kp2, Kp3, Kp4, Kp5, Kp6, Kp7, Kp8, Kp9, Kp0,

	Insert, Home, PageUp, PageDown, Delete, End,
}

Mouse_Button :: enum u8 {
	Unknown,
	Left, Right, Middle,
	X1, X2, X3, X4, X5, X6,
}

MAX_GAMEPADS :: 16

Gamepad_Button :: enum u8 {
	Unknown,
	DpadLeft, DpadRight, DpadUp, DpadDown,
	A, B, X, Y,
	Menu, Pause,
	RightShoulder, LeftShoulder,
	LeftStick, RightStick,
}

Gamepad_Axis :: enum u8 {
	LeftX, LeftY,
	RightX, RightY,
	LeftTrigger, RightTrigger,
}

Gamepad_State :: struct {
	buttons:       bit_set[Gamepad_Button],
	left_stick:    Vec2,
	right_stick:   Vec2,
	left_trigger:  f32,
	right_trigger: f32,
}

@(private="file")
_input: struct {
	keys:              [Key]bool,
	old_keys:          [Key]bool,
	mouse:             bit_set[Mouse_Button],
	old_mouse:         bit_set[Mouse_Button],
	mouse_pos:         Vec2,
	gamepads:          [MAX_GAMEPADS]Gamepad_State,
	old_gamepads:      [MAX_GAMEPADS]Gamepad_State,
	gamepad_connected: [MAX_GAMEPADS]bool,
	gamepad_deadzone:  f32,
}

@private
_input_pre_update :: proc() {
	_input.old_keys = _input.keys
	_input.old_mouse = _input.mouse

	for gp, i in _input.gamepads {
		_input.old_gamepads[i] = gp
	}
}

// -----------------------------------------------------------------------------
// Keyboard
// -----------------------------------------------------------------------------
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

// -----------------------------------------------------------------------------
// Mouse
// -----------------------------------------------------------------------------
send_mouse_motion :: proc "contextless" (pos: Vec2) {
	_input.mouse_pos = pos
}

get_mouse_pos :: proc "contextless" () -> Vec2 {
	return _input.mouse_pos
}

send_mouse_down :: proc "contextless" (button: Mouse_Button) {
	_input.mouse |= {button}
}

send_mouse_up :: proc "contextless" (button: Mouse_Button) {
	_input.mouse &= ~{button}
}

// -----------------------------------------------------------------------------
// Gamepad
// -----------------------------------------------------------------------------
set_gamepad_deadzone :: proc "contextless" (t: f32) {
	_input.gamepad_deadzone = t
}

send_gamepad_state :: proc "contextless" (index: int, state: Gamepad_State) {
	if index < 0 || index >= MAX_GAMEPADS do return

	if !_input.gamepad_connected[index] {
		// @TODO: Handle connection here
		_input.gamepad_connected[index] = true
	}

	state := state

	if linalg.length(state.left_stick) < _input.gamepad_deadzone {
		state.left_stick = {}
	}

	if linalg.length(state.right_stick) < _input.gamepad_deadzone {
		state.right_stick = {}
	}

	_input.gamepads[index] = state
}

is_gamepad_connected :: proc "contextless" (index: int) -> bool {
	return _input.gamepad_connected[index]
}

is_gamepad_button_down :: proc "contextless" (index: int, button: Gamepad_Button) -> bool {
	if index < 0 || index >= MAX_GAMEPADS do return false

	return button in _input.gamepads[index].buttons
}

was_gamepad_button_pressed :: proc "contextless" (index: int, button: Gamepad_Button) -> bool {
	if index < 0 || index >= MAX_GAMEPADS do return false

	cur := _input.gamepads[index]
	old := _input.old_gamepads[index]
	return button in cur.buttons && button not_in old.buttons
}

was_gamepad_button_released :: proc "contextless" (index: int, button: Gamepad_Button) -> bool {
	if index < 0 || index >= MAX_GAMEPADS do return false

	cur := _input.gamepads[index]
	old := _input.old_gamepads[index]
	return button not_in cur.buttons && button in old.buttons
}

