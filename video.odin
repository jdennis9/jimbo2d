package j2d

import "core:log"
import "core:image"
import "core:image/png"
import "core:image/bmp"
import "core:image/jpeg"
import "core:image/tga"

Video_Impl_Info :: struct {
	name:      string,
	data:      rawptr,
	data_type: typeid,
}

Texture_Format :: enum {
	R8G8B8A8,
	R8,
}

Texture :: struct {
	impl: rawptr,
	width, height: int,
}

Sub_Image :: struct {
	x, y, w, h: i32,
	data: rawptr,
}

Texture_Desc_Flag :: enum {LinearSampling}
Texture_Desc_Flags :: bit_set[Texture_Desc_Flag; u32]

Texture_Desc :: struct {
	width:  int,
	height: int,
	format: Texture_Format,
	data:   []Sub_Image,
	flags:  Texture_Desc_Flags,
}

Shader_Stage :: enum {
	Vertex,
	Fragment,
}

Shader_Desc :: struct {
	stage: Shader_Stage,
	glsl:  string,
}

// @TODO: Support custom shaders
Shader :: struct {
	impl: rawptr,
}

Vertex :: struct {
	pos:   Vec2,
	uv:    Vec2,
	color: Color,
}

get_video_impl_info :: proc() -> Video_Impl_Info {
	if _video_impl_get_info != nil {
		return _video_impl_get_info()
	}

	return {}
}

load_texture_from_memory :: proc(bytes: []byte) -> (tex: Texture, ok: bool) {
	img, load_error := image.load_from_bytes(bytes, {.alpha_add_if_missing})
	if load_error != nil {
		log.error(load_error)
		return
	}
	defer image.destroy(img)

	return create_texture_from_image(img)
}

load_texture_from_file :: proc(path: string) -> (tex: Texture, ok: bool) {
	img, load_error := image.load_from_file(path, {.alpha_add_if_missing})
	if load_error != nil {
		log.error(load_error)
		return
	}
	defer image.destroy(img)

	return create_texture_from_image(img)
}

create_texture_from_image :: proc(img: ^image.Image) -> (tex: Texture, ok: bool) {
	if img.channels != 4 {
		log.error("Incorrect channels in image, expected 4, got", img.channels)
		return
	}

	si := Sub_Image {
		w = auto_cast img.width,
		h = auto_cast img.height,
		data = raw_data(img.pixels.buf),
	}

	desc := Texture_Desc {
		data   = {si},
		format = .R8G8B8A8,
		width  = img.width,
		height = img.height,
	}

	tex = create_texture(desc) or_return
	ok = true
	return
}

create_texture :: proc(desc: Texture_Desc) -> (tex: Texture, ok: bool) {
	tex.impl   = _video_impl_create_texture(desc) or_return
	tex.width  = desc.width
	tex.height = desc.height

	ok = true
	return
}

destroy_texture :: proc(tex: Texture) {
	if tex.impl != nil do _video_impl_destroy_texture(tex)
}

create_shader :: proc(desc: Shader_Desc) -> (s: Shader, ok: bool) {
	s.impl = _video_impl_create_shader(desc) or_return
	ok = true
	return
}

destroy_shader :: proc(s: Shader) {
	_video_impl_destroy_shader(s.impl)
}
