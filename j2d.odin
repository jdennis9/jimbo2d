package j2d

import "core:math/linalg"
import "core:sys/linux"
import mu "vendor:microui"
import "core:time"
import "core:image"
import "base:runtime"
import "core:log"
import "core:mem"

DEFAULT_FONT_DATA :: #load("NotoSans-SemiBold.ttf")

DEFAULT_FRAME_ALLOCATOR_SIZE :: (128<<10)

Init_Params :: struct {
	window_width:         int,
	window_height:        int,
	window_title:         string,
	frame_allocator_size: Maybe(int),
	custom_platform:      Maybe(Platform_Interface),
}

@(private="file")
state: struct {
	init_params:      Init_Params,
	frame_allocator:  mem.Scratch,
	default_font:     Font_Atlas,
	drawlist:         Drawlist,
	window_size:      Vec2,
	ctx:              runtime.Context,
	last_frame_start: time.Tick,
	last_frame_time:  time.Duration,
	frame_count:      int,
}

init :: proc(
	params: Init_Params,
	allocator := context.allocator,
) -> bool {
	state.ctx = context
	state.init_params = params

	mem.scratch_init(&state.frame_allocator, params.frame_allocator_size.? or_else DEFAULT_FRAME_ALLOCATOR_SIZE, allocator)

	if params.custom_platform != nil {
		_platform = params.custom_platform.?
	}
	else {
		use_platform_glfw()
	}

	assert(_platform.get_info != nil)
	assert(_platform.create_window != nil)
	assert(_platform.destroy_window != nil)
	assert(_platform.poll_events != nil)
	assert(_platform.present != nil)

	_platform.create_window() or_return

	state.window_size.x = f32(params.window_width)
	state.window_size.y = f32(params.window_height)

	load_font_from_memory(&state.default_font, DEFAULT_FONT_DATA, .SDF, 24)

	reserve(&state.drawlist.commands, 128)
	reserve(&state.drawlist.indices, 16<<10)
	reserve(&state.drawlist.vertices, 16<<10)

	load_builtin_shaders() or_return

	return true
}

shutdown :: proc() {
	_platform.destroy_window()
	mem.scratch_destroy(&state.frame_allocator)
}

present :: proc() {
	drawlist_flush(&state.drawlist)
	_video.render_frame(&state.drawlist)
	_platform.present()
}

clear_window :: proc(color: Color) {
	_video.clear(color)
}

update :: proc() -> bool {
	if state.frame_count > 0 {
		state.last_frame_time = time.tick_since(state.last_frame_start)
	}
	else {
		state.last_frame_time = 16 * time.Millisecond
	}
	
	state.frame_count += 1

	frame_start := time.tick_now()
	state.last_frame_start = frame_start

	_input_pre_update()
	drawlist_clear(&state.drawlist)
	mem.scratch_free_all(&state.frame_allocator)
	_platform.poll_events()

	return true
}

get_frame_time :: proc() -> f32 {
	return auto_cast time.duration_seconds(state.last_frame_time)
}

get_frame_count :: proc() -> int {
	return state.frame_count
}

frame_allocator :: proc() -> mem.Allocator {
	return mem.scratch_allocator(&state.frame_allocator)
}

get_default_font :: proc "contextless" () -> ^Font_Atlas {return &state.default_font}
get_window_size :: proc "contextless" () -> Vec2 {return state.window_size}
get_main_drawlist :: proc "contextless" () -> ^Drawlist {return &state.drawlist}
get_context :: proc "contextless" () -> runtime.Context {return state.ctx}
get_init_params :: proc "contextless" () -> Init_Params {return state.init_params}

sine_pulse :: proc(vmin, vmax, freq: f32, offset: f64 = 0) -> f32 {
	x := time.duration_seconds(time.tick_diff({}, state.last_frame_start))
	y := f32(linalg.sin((x * f64(freq)) + offset))
	return linalg.lerp(vmin, vmax, y)
}
