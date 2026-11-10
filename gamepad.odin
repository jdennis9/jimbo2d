package j2d

GAMEPAD_IMPL_NAME_GAMEINPUT :: "GameInput"

Gamepad_Interface :: struct {
	get_info: proc() -> Interface_Info,
	update: proc(), // calls send_gamepad_state
}

@private
_gamepad: Gamepad_Interface

@private
use_gamepad_interface :: proc(iface: Gamepad_Interface) {
	_gamepad = iface
}
