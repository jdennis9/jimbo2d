package j2d

import win "core:sys/windows"
import gi "vendor:windows/GameInput"

Gamepad_Impl_GameInput_Gamepad_State :: struct {
	prev_reading: ^gi.IGameInputReading,
	reading: ^gi.IGameInputReading,
	device: ^gi.IGameInputDevice,
}

Gamepad_Impl_Data_GameInput :: struct {
	ctx: ^gi.IGameInput,
	gamepads: [MAX_GAMEPADS]Gamepad_Impl_GameInput_Gamepad_State,
}

@(private="file")
_gi: Gamepad_Impl_Data_GameInput

@(private="file")
_BUTTON_MAP := [gi.GamepadButtonsFlag]Gamepad_Button {
	.Menu            = .Menu,
	.View            = .Pause,
	.A               = .A,
	.B               = .B,
	.X               = .X,
	.Y               = .Y,
	.DPadUp          = .DpadUp,
	.DPadDown        = .DpadDown,
	.DPadLeft        = .DpadLeft,
	.DPadRight       = .DpadRight,
	.LeftShoulder    = .LeftShoulder,
	.RightShoulder   = .RightShoulder,
	.LeftThumbstick  = .LeftStick,
	.RightThumbstick = .RightStick,
}

@private
use_gamepad_impl_gameinput :: proc() -> bool {
	win32_check(gi.Create(&_gi.ctx)) or_return

	_gamepad.get_info = proc() -> Interface_Info {
		return {
			name      = GAMEPAD_IMPL_NAME_GAMEINPUT,
			data      = &_gi,
			data_type = Gamepad_Impl_Data_GameInput,
		}
	}

	_update :: proc() -> bool {
		gp := &_gi.gamepads[0]

		hr := _gi.ctx->GetCurrentReading({.Gamepad}, nil, &gp.reading)
		if win.SUCCEEDED(hr) {
			gp.reading->GetDevice(&gp.device)
			
			s: gi.GamepadState
			o: Gamepad_State

			gp.reading->GetGamepadState(&s)

			o.left_stick    = {s.leftThumbstickX, s.leftThumbstickY}
			o.right_stick   = {s.rightThumbstickX, s.rightThumbstickY}
			o.left_trigger  = s.leftTrigger
			o.right_trigger = s.rightTrigger

			for butt in gi.GamepadButtonsFlag {
				if butt in s.buttons {
					o.buttons |= {_BUTTON_MAP[butt]}
				}
				else {
					o.buttons &= ~{_BUTTON_MAP[butt]}
				}
			}

			send_gamepad_state(0, o)
		}
		else if hr != gi.READING_NOT_FOUND {
			gp.device = nil
			gp.prev_reading = nil
			return false
		}


		return true
	}

	_gamepad.update = proc() {
		_update()
	}

	return true
}
