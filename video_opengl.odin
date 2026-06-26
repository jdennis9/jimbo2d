package j2d

import "core:log"
import gl "vendor:OpenGL"

GL_Program_Key :: struct {vert_shader, frag_shader: u32}

GL_Texture :: struct {
	gl_handle: u32,
	bind_enum: i32,
}

GL_Shader :: struct {
	gl_handle: u32,
}

Video_Impl_Data_OpenGL :: struct {
	vao:                 u32,
	programs:            map[GL_Program_Key]u32,
	vertex_buffer:       u32,
	index_buffer:        u32,
	vertex_buffer_size:  int,
	index_buffer_size:   int,
}

@(private="file")
_gl: Video_Impl_Data_OpenGL

opengl_init :: proc(
	set_proc_address: gl.Set_Proc_Address_Type,
) -> bool {
	log.debug("Loading OpenGL 3.3")

	gl.load_up_to(3, 3, set_proc_address)
	gl.GenVertexArrays(1, &_gl.vao)

	_video.create_texture  = _create_texture
	_video.destroy_texture = _destroy_texture
	_video.create_shader   = _create_shader
	_video.destroy_shader  = _destroy_shader

	_video.clear = proc(color: Color) {
		gl.ClearColor(f32(color.r) / 255.0, f32(color.g) / 255.0, f32(color.b) / 255.0, f32(color.a) / 255.0)
		gl.Clear(gl.COLOR_BUFFER_BIT)
	}

	_video.get_info = proc() -> Video_Impl_Info {
		return {
			name = "opengl3",
			data = &_gl,
			data_type = Video_Impl_Data_OpenGL,
		}
	}

	_video.render_frame = _render_frame

	log.debug("OpenGL ready")

	return true
}

@(private="file")
_create_texture :: proc(desc: Texture_Desc) -> (tex_ptr: rawptr, ok: bool) {
	tex := new(GL_Texture)
	defer if !ok do free(tex)
	// For texture data with pitch not aligned to 4 bytes
	pix_buf: [dynamic]u8
	defer delete(pix_buf)

	tex.bind_enum = gl.TEXTURE_2D
	gl.GenTextures(1, &tex.gl_handle)
	if tex.gl_handle == 0 do return

	defer if !ok do gl.DeleteTextures(1, &tex.gl_handle)

	gl.BindTexture(gl.TEXTURE_2D, tex.gl_handle)
	defer gl.BindTexture(gl.TEXTURE_2D, 0)

	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)

	if .LinearSampling in desc.flags {
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
	}
	else {
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)
	}

	internal_formats := [Texture_Format]i32 {
		.R8G8B8A8 = gl.RGBA8,
		.R8 = gl.R8,
	}

	data_formats := [Texture_Format]u32 {
		.R8G8B8A8 = gl.RGBA,
		.R8 = gl.RED,
	}

	gl.TexImage2D(
		gl.TEXTURE_2D, 0, internal_formats[desc.format],
		auto_cast desc.width, auto_cast desc.height, 0,
		data_formats[desc.format], gl.UNSIGNED_BYTE, nil
	)

	for data in desc.data {
		pitch_corrected := false

		if desc.format == .R8 && data.w % 4 != 0 {
			pitch_corrected = true
			in_pixels := cast([^]u8) data.data
			corrected_width := round_up_to_multiple(data.w, 4)
			resize(&pix_buf, corrected_width * data.h)
			for y in 0..<data.h {
				for x in 0..<data.w {
					pix_buf[(y * corrected_width) + x] = in_pixels[(y * data.w) + x]
				}
			}
		}

		gl.TexSubImage2D(
			gl.TEXTURE_2D, 0, auto_cast data.x, auto_cast data.y,
			auto_cast data.w, auto_cast data.h, data_formats[desc.format],
			gl.UNSIGNED_BYTE, pitch_corrected ? raw_data(pix_buf) : data.data
		)
	}

	tex_ptr = tex
	ok = true
	return
}

@(private="file")
_destroy_texture :: proc(tex: Texture) {
	tex := cast(^GL_Texture) tex.impl
	gl.DeleteTextures(1, &tex.gl_handle)
}

@(private="file")
_create_shader :: proc(desc: Shader_Desc) -> (impl: rawptr, ok: bool) {
	compile_ok: bool
	s := new(GL_Shader)
	defer if !ok do free(s)

	assert(desc.glsl != "")

	stages := [Shader_Stage]gl.Shader_Type {
		.Vertex = .VERTEX_SHADER,
		.Fragment = .FRAGMENT_SHADER,
	}

	s.gl_handle, compile_ok = gl.compile_shader_from_source(desc.glsl, stages[desc.stage])

	if !compile_ok {
		message, _ := gl.get_last_error_message()
		log.error(message)
		return
	}

	impl = s
	ok = true
	return
}

@(private="file")
_destroy_shader :: proc(impl: rawptr) {
	if impl == nil do return
	s := cast(^GL_Shader) impl
	gl.DeleteShader(s.gl_handle)
	free(s)
}

@(private="file")
_render_frame :: proc(drawlist: ^Drawlist) {
	display_size := get_window_size()

	apply_state :: proc(s: Draw_State) -> (program: u32, ok: bool) {
		have_program: bool
		shaders: GL_Program_Key

		shaders.vert_shader = _get_shader_handle(s.vert_shader)
		shaders.frag_shader = _get_shader_handle(s.frag_shader)

		if shaders.frag_shader == 0 || shaders.vert_shader == 0 do return

		program, have_program = _gl.programs[shaders]

		if have_program {
			gl.UseProgram(program)
		}
		else {
			log.debug("New program:", shaders)

			program, ok = gl.create_and_link_program({
				shaders.vert_shader, 
				shaders.frag_shader,
			})

			if !ok {
				message, _ := gl.get_last_error_message()
				log.error(message)
				return
			}

			_gl.programs[shaders] = program

			gl.UseProgram(program)
		}

		gl.Enable(gl.BLEND)
		gl.BlendFuncSeparate(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ZERO)
		gl.BlendEquation(gl.FUNC_ADD)

		ok = true
		return
	}

	vertex_data_size := size_of(Vertex) * len(drawlist.vertices)
	index_data_size := size_of(u32) * len(drawlist.indices)

	if _gl.vertex_buffer == 0 {
		gl.GenBuffers(1, &_gl.vertex_buffer)
	}

	if _gl.index_buffer == 0 {
		gl.GenBuffers(1, &_gl.index_buffer)
	}

	gl.BindVertexArray(_gl.vao)
	gl.BindBuffer(gl.ARRAY_BUFFER, _gl.vertex_buffer)
	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, _gl.index_buffer)

	if _gl.vertex_buffer_size < vertex_data_size {
		s := round_up_to_multiple(vertex_data_size, 64<<10)
		gl.BufferData(gl.ARRAY_BUFFER, s, nil, gl.STREAM_DRAW)
		_gl.vertex_buffer_size = s
	}

	if _gl.index_buffer_size < index_data_size {
		s := round_up_to_multiple(index_data_size, 64<<10)
		gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, s, nil, gl.STREAM_DRAW)
		_gl.index_buffer_size = s
	}

	if vertex_data_size > 0 && index_data_size > 0 {
		gl.BufferSubData(gl.ARRAY_BUFFER, 0, vertex_data_size, raw_data(drawlist.vertices))
		gl.BufferSubData(gl.ELEMENT_ARRAY_BUFFER, 0, index_data_size, raw_data(drawlist.indices))
	}


	gl.EnableVertexAttribArray(0)
	gl.EnableVertexAttribArray(1)
	gl.EnableVertexAttribArray(2)

	gl.VertexAttribPointer(0, 2, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, pos))
	gl.VertexAttribPointer(1, 2, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, uv))
	gl.VertexAttribPointer(2, 4, gl.UNSIGNED_BYTE, true, size_of(Vertex), offset_of(Vertex, color))

	for cmd in drawlist.commands {
		program := apply_state(cmd.state) or_continue
		uniforms := gl.get_uniforms_from_program(program)
		defer gl.destroy_uniforms(uniforms)

		// Update uniforms
		if u, found := uniforms["viewport_scale"]; found {
			s := 1 / display_size
			gl.Uniform2fv(u.location, 1, &s[0])
		}

		// Bind texture
		if cmd.state.texture != nil {
			tex := cast(^GL_Texture) cmd.state.texture.?.impl
			if tex != nil {
				gl.ActiveTexture(gl.TEXTURE0)
				gl.BindTexture(gl.TEXTURE_2D, tex.gl_handle)
			}
		}

		// Draw
		draw_modes := [Vertex_Mode]u32 {
			.Triangles = gl.TRIANGLES,
			.Lines = gl.LINES,
		}

		gl.DrawElements(
			draw_modes[cmd.state.vertex_mode],
			auto_cast cmd.index_count,
			gl.UNSIGNED_INT,
			cast(rawptr) uintptr(cmd.first_index * size_of(u32))
		)

		// Unbind texture
		if cmd.state.texture != nil {
			gl.ActiveTexture(gl.TEXTURE0)
			gl.BindTexture(gl.TEXTURE_2D, 0)
		}
	}
}

@(private="file")
_get_shader_handle :: proc(s: Shader) -> u32 {
	g := cast(^GL_Shader) s.impl
	if g == nil do return 0
	return g.gl_handle
}

GL_SHADER_DEFAULT_VERT ::
`
#version 330 core

layout(location = 0) in vec2 in_position;
layout(location = 1) in vec2 in_uv;
layout(location = 2) in vec4 in_color;

out vec2 vertex_position;
out vec4 vertex_color;
out vec2 vertex_uv;

uniform vec2 viewport_scale;

void main() {
	gl_Position.xy = (in_position * viewport_scale * vec2(2, 2)) - vec2(1, 1);
	gl_Position.y = -gl_Position.y;
	gl_Position.z = 0;
	gl_Position.w = 1;
	vertex_position = in_position * viewport_scale;
	vertex_color = in_color;
	vertex_uv = in_uv;
}
`

GL_SHADER_COLOR_FRAG ::
`
#version 330 core

layout(location=0) out vec4 out_color;

in vec4 vertex_color;

void main() {
	out_color = vertex_color;
}
`

GL_SHADER_TEXTURE_FRAG ::
`
#version 330 core

layout(location=0) out vec4 out_color;

in vec4 vertex_color;
in vec2 vertex_uv;

uniform sampler2D in_texture;

void main() {
	out_color = texture(in_texture, vertex_uv) * vertex_color;
}
`

GL_SHADER_SDF_FRAG ::
`
#version 330 core

layout(location=0) out vec4 out_color;

in vec4 vertex_color;
in vec2 vertex_uv;

uniform sampler2D in_texture;

void main() {
	float smoothing = 0.5/16.0;
	out_color.rgb = vertex_color.rgb;
	out_color.a = smoothstep(0.5 - smoothing, 0.5 + smoothing, texture(in_texture, vertex_uv).r);
}
`

