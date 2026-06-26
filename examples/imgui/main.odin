package j2d_imgui

import j2 "../.."
import imgui "odin-imgui"
import imgui_glfw "odin-imgui/imgui_impl_glfw"
import imgui_gl "odin-imgui/imgui_impl_opengl3"

on_create_window :: proc() {
	platform := j2.get_platform_info()
	video := j2.get_video_impl_info()
	platform_ok, video_ok: bool

	switch platform.name {
	case j2.PLATFORM_NAME_GLFW:
		data := cast(^j2.Platform_Impl_Data_GLFW) platform.data

		switch video.name {
		case j2.VIDEO_IMPL_NAME_OPENGL3:
			platform_ok = imgui_glfw.InitForOpenGL(data.window, true)
		}
	}

	switch video.name {
	case j2.VIDEO_IMPL_NAME_OPENGL3:
		video_ok = imgui_gl.Init()
	}

	assert(platform_ok && video_ok)
}

on_destroy_window :: proc() {
	platform := j2.get_platform_info()
	video := j2.get_video_impl_info()

	switch video.name {
	case j2.VIDEO_IMPL_NAME_OPENGL3:
		imgui_gl.Shutdown()
	}

	switch platform.name {
	case j2.PLATFORM_NAME_GLFW:
		imgui_glfw.Shutdown()
	}
}

post_render :: proc() {
	if draw_data := imgui.GetDrawData(); draw_data != nil {
		imgui_gl.RenderDrawData(draw_data)
	}
}

main :: proc() {
	imgui.CreateContext()
	defer imgui.DestroyContext()

	j2.init({
		hooks = {
			on_create_window = on_create_window,
			on_destroy_window = on_destroy_window,
			post_render = post_render,
		},
		window_width = 1280,
		window_height = 720,
		window_title = "J2D with ImGui",
	})
	defer j2.shutdown()

	for {
		j2.update() or_break

		imgui_glfw.NewFrame()
		imgui_gl.NewFrame()
		imgui.NewFrame()

		j2.clear_window(j2.COLOR_BLACK)

		imgui.ShowDemoWindow()
		imgui.Render()

		j2.present()
	}
}
