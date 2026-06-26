#+private
package j2d

_video_impl_get_info: proc() -> Video_Impl_Info
_video_impl_shutdown: proc()
_video_impl_create_texture: proc(desc: Texture_Desc) -> (rawptr, bool)
_video_impl_destroy_texture: proc(tex: Texture)
_video_impl_create_shader: proc(desc: Shader_Desc) -> (rawptr, bool)
_video_impl_destroy_shader: proc(impl: rawptr)
_video_impl_clear: proc(color: Color)
_video_impl_render_frame: proc(drawlist: ^Drawlist)
