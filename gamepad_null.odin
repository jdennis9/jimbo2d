package j2d

GAMEPAD_IMPL_NAME_NULL :: "null"

GAMEPAD_IMPL_NULL := Gamepad_Interface {
	update = proc() {},
	get_info = proc() -> Interface_Info {
		return Interface_Info {
			name = GAMEPAD_IMPL_NAME_NULL,
		}
	}
}
