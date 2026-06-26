package j2d

import "core:log"
import "core:math/linalg"

Vertex_Mode :: enum {
	Triangles,
	Lines,
}

Draw_State :: struct {
	vertex_mode:  Vertex_Mode,
	clip_rect:    Maybe(Rect),
	scissor_rect: Maybe(Rect),
	texture:      Maybe(Texture),
	vert_shader:  Shader,
	frag_shader:  Shader,
}

Draw_Command :: struct {
	first_vertex, first_index: i32,
	vertex_count, index_count: i32,
	state: Draw_State,
}

Drawlist :: struct {
	commands:         [dynamic]Draw_Command,
	vertices:         [dynamic]Vertex,
	indices:          [dynamic]u32,
	cmd:              Draw_Command,
	camera:           Mat3,
	base_state:       Draw_State,
	font:             ^Font_Atlas,
	font_scale:       Maybe(f32),
	target_font_size: Maybe(f32),
	name:             string,
}

drawlist_clear :: proc(d: ^Drawlist) {
	clear(&d.commands)
	clear(&d.vertices)
	clear(&d.indices)
	d.cmd = {}
	d.font = nil
	d.camera = {}
}

drawlist_flush :: proc(d: ^Drawlist) {
	if d.cmd.vertex_count == 0 do return
	append(&d.commands, d.cmd)
	d.cmd.first_vertex = auto_cast len(d.vertices)
	d.cmd.first_index = auto_cast len(d.indices)
	d.cmd.index_count = 0
	d.cmd.vertex_count = 0
}

drawlist_destroy :: proc(d: ^Drawlist) {
	delete(d.commands)
	delete(d.indices)
	delete(d.vertices)
	d^ = {}
}

drawlist_get_font :: proc(d: Drawlist) -> ^Font_Atlas {
	return d.font != nil ? d.font : get_default_font()
}

@require_results
drawlist_calc_font_scale :: proc(d: Drawlist) -> f32 {
	scale: f32 = 1

	if d.target_font_size != nil {
		targ := d.target_font_size.?
		font := drawlist_get_font(d)
		scale = targ / font.pt_size
	}

	scale *= d.font_scale.? or_else 1

	return scale
}

@(deferred_in_out=_drawlist_set_scope_camera_exit)
drawlist_set_scope_camera :: proc(d: ^Drawlist, cam: Mat3) -> (old_cam: Mat3) {
	old_cam = d.camera
	d.camera = cam
	return
}

@(private="file")
_drawlist_set_scope_camera_exit :: proc(d: ^Drawlist, cam: Mat3, old_cam: Mat3) {
	d.camera = old_cam
}

@(deferred_in_out=_drawlist_set_scope_texture_exit)
drawlist_set_scope_texture :: proc(
	d: ^Drawlist, tex: Texture
) -> (old_value: Maybe(Texture)) {
	old_value = d.base_state.texture
	d.base_state.texture = tex
	return
}

@(private="file")
_drawlist_set_scope_texture_exit :: proc(
	d: ^Drawlist, tex: Texture, old_value: Maybe(Texture)
) {
	d.base_state.texture = old_value
}

@(deferred_in_out=_drawlist_set_scope_font_size_exit)
drawlist_set_scope_font_size :: proc(d: ^Drawlist, size: f32) -> Maybe(f32) {
	old_size := d.target_font_size
	d.target_font_size = size
	return old_size
}

@(private="file")
_drawlist_set_scope_font_size_exit :: proc(
	d: ^Drawlist, _: f32, old_size: Maybe(f32),
) {
	d.target_font_size = old_size
}

@(deferred_in_out=_drawlist_set_scope_font_scale_exit)
drawlist_set_scope_font_scale :: proc(d: ^Drawlist, scale: f32) -> Maybe(f32) {
	old_scale := d.font_scale
	d.font_scale = scale
	return old_scale
}

@(private="file")
_drawlist_set_scope_font_scale_exit :: proc(
	d: ^Drawlist, _: f32, old_scale: Maybe(f32),
) {
	d.font_scale = old_scale
}

drawlist_set_scope_clip_rect :: proc(d: ^Drawlist, rect: Rect) -> Maybe(Rect) {
	old := d.base_state.clip_rect
	d.base_state.clip_rect = rect
	return old
}

drawlist_get_clip_rect :: proc(d: Drawlist) -> Maybe(Rect) {
	return d.base_state.clip_rect
}

drawlist_set_clip_rect :: proc(d: ^Drawlist, rect: Maybe(Rect)) {
	d.base_state.clip_rect = rect
}

@(private="file")
_drawlist_set_scope_clip_rect_exit :: proc(d: ^Drawlist, _: Rect, old_value: Maybe(Rect)) {
	d.base_state.clip_rect = old_value
}

draw_geometry :: proc(d: ^Drawlist, vertices: []Vertex, indices: []u32, state: Draw_State) {
	if d.cmd.state != state do drawlist_flush(d)

	d.cmd.state = state
	index_offset := u32(len(d.vertices))

	if d.camera[0,0] == 0 {
		d.camera = {
			1, 0, 0,
			0, 1, 0,
			0, 0, 1
		}
	}

	for vi in vertices {
		v := vi
		v.pos = (d.camera * [3]f32{v.pos.x, v.pos.y, 1}).xy
		append(&d.vertices, v)
	}
	for i in indices do append(&d.indices, i + index_offset)

	d.cmd.vertex_count += auto_cast len(vertices)
	d.cmd.index_count += auto_cast len(indices)
}

draw_quad_filled :: proc(d: ^Drawlist, positions: [4]Vec2, colors: [4]Color) {
	vertices := [4]Vertex {
		{pos = positions[0], color = colors[0]},
		{pos = positions[1], color = colors[1]},
		{pos = positions[2], color = colors[2]},
		{pos = positions[3], color = colors[3]},
	}

	indices := [6]u32 {0, 1, 2, 0, 2, 3}

	state := d.base_state
	state.vertex_mode = .Triangles
	state.vert_shader = SHADER_DEFAULT_VERT
	state.frag_shader = SHADER_DEFAULT_FRAG

	draw_geometry(d, vertices[:], indices[:], state)
}

draw_quad :: proc(d: ^Drawlist, positions: [4]Vec2, colors: [4]Color) {
	vertices := [4]Vertex {
		{pos = positions[0], color = colors[0]},
		{pos = positions[1], color = colors[1]},
		{pos = positions[2], color = colors[2]},
		{pos = positions[3], color = colors[3]},
	}

	indices := [8]u32 {0, 1, 1, 2, 2, 3, 3, 0}

	state := d.base_state
	state.vertex_mode = .Lines
	state.vert_shader = SHADER_DEFAULT_VERT
	state.frag_shader = SHADER_DEFAULT_FRAG

	draw_geometry(d, vertices[:], indices[:], state)
}

draw_rect :: proc(d: ^Drawlist, r: Rect, color: Color) {
	draw_quad(d,
		{
			r.min,
			{r.max.x, r.min.y},
			r.max,
			{r.min.x, r.max.y},
		},
		color,
	)
}

draw_rect_filled :: proc(d: ^Drawlist, r: Rect, color: Color) {
	draw_quad_filled(d,
		{
			r.min,
			{r.max.x, r.min.y},
			r.max,
			{r.min.x, r.max.y},
		},
		color,
	)
}

draw_line :: proc(d: ^Drawlist, p1, p2: Vec2, color: Color) {
	vertices := [2]Vertex {
		{pos = p1, color = color},
		{pos = p2, color = color},
	}

	indices := [2]u32 {0, 1}

	state := d.base_state
	state.vertex_mode = .Lines
	state.vert_shader = SHADER_DEFAULT_VERT
	state.frag_shader = SHADER_DEFAULT_FRAG

	draw_geometry(d, vertices[:], indices[:], state)
}

draw_circle :: proc(d: ^Drawlist, center: Vec2, radius: f32, color: Color, segments := 12) {
	vertices: [2]Vertex
	indices := [2]u32 {0, 1}

	vertices[0].color = color
	vertices[1].color = color

	state := d.base_state
	state.vertex_mode = .Lines
	state.vert_shader = SHADER_DEFAULT_VERT
	state.frag_shader = SHADER_DEFAULT_FRAG

	m := 1.0 / f32(segments)

	for i in 0..<segments {
		theta0 := (2.0 * linalg.PI * cast(f32) i) * m
		theta1 := (2.0 * linalg.PI * cast(f32) (i+1)) * m
		vertices[0].pos.x = (radius * linalg.cos(theta0)) + center.x
		vertices[0].pos.y = (radius * linalg.sin(theta0)) + center.y
		vertices[1].pos.x = (radius * linalg.cos(theta1)) + center.x
		vertices[1].pos.y = (radius * linalg.sin(theta1)) + center.y

		draw_geometry(d, vertices[:], indices[:], state)
	}
}

draw_circle_filled :: proc(d: ^Drawlist, center: Vec2, radius: f32, color: Color, segments := 12) {
	draw_circle_filled_multicolor(d, center, radius, color, color, segments)
}

draw_circle_filled_multicolor :: proc(d: ^Drawlist, center: Vec2, radius: f32, edge_color: Color, center_color: Color, segments := 12) {
	vertices: [3]Vertex
	indices := [3]u32 {0, 1, 2}

	vertices[0].color = edge_color
	vertices[1].color = edge_color
	vertices[2].pos   = center
	vertices[2].color = center_color

	state := d.base_state
	state.vertex_mode = .Triangles
	state.vert_shader = SHADER_DEFAULT_VERT
	state.frag_shader = SHADER_DEFAULT_FRAG

	m := 1.0 / f32(segments)

	for i in 0..<segments {
		theta0 := (2.0 * linalg.PI * cast(f32) i) * m
		theta1 := (2.0 * linalg.PI * cast(f32) (i+1)) * m
		vertices[0].pos.x = (radius * linalg.cos(theta0)) + center.x
		vertices[0].pos.y = (radius * linalg.sin(theta0)) + center.y
		vertices[1].pos.x = (radius * linalg.cos(theta1)) + center.x
		vertices[1].pos.y = (radius * linalg.sin(theta1)) + center.y

		draw_geometry(d, vertices[:], indices[:], state)
	}
}

draw_capsule :: proc(d: ^Drawlist, p1, p2: Vec2, radius: f32, color: Color) {
	draw_circle(d, p1, radius, color)
	draw_circle(d, p2, radius, color)

	up    := Vec2{0, radius}
	angle := vec2_angle(p2 - p1)
	v1    := p1 + vec2_rotate(up, make_rot(angle + linalg.PI/2))
	v2    := p1 + vec2_rotate(up, make_rot(angle - linalg.PI/2))
	v3    := p2 + vec2_rotate(up, make_rot(angle + linalg.PI/2))
	v4    := p2 + vec2_rotate(up, make_rot(angle - linalg.PI/2))

	draw_line(d, v1, v3, color)
	draw_line(d, v2, v4, color)
}

draw_text :: proc(d: ^Drawlist, text: string, position: Vec2, color: Color, wrap_width: Maybe(f32) = nil) {
	pen := position
	font := drawlist_get_font(d^)
	scale := drawlist_calc_font_scale(d^)
	state := d.base_state

	state.vertex_mode = .Triangles
	state.vert_shader = SHADER_DEFAULT_VERT
	state.texture = font.texture

	switch font.mode {
	case .SDF:    state.frag_shader = SHADER_SDF
	case .Bitmap: state.frag_shader = SHADER_TEXTURE_FRAG
	}

	for codepoint in text {
		if codepoint == '\n' {
			pen.x = position.x
			pen.y += font.base_line_height * scale
			continue
		}

		if wrap_width != nil && (pen.x - position.x) > wrap_width.? {
			pen.x = position.y
			pen.y += font.base_line_height * scale
		}

		glyph := font_get_glyph(font^, codepoint) or_continue
		defer pen.x += glyph.advance * scale
		if glyph.width <= 0 do continue

		pmin := pen + {f32(glyph.xoff), f32(glyph.yoff)} * scale
		pmax := pmin + {f32(glyph.width), f32(glyph.height)} * scale
		umin := glyph.uv.min
		umax := glyph.uv.max

		//draw_rect_filled(d, rect, color)
		vertices := []Vertex {
			{pos = pmin,             uv = umin,             color = color},
			{pos = {pmax.x, pmin.y}, uv = {umax.x, umin.y}, color = color},
			{pos = pmax,             uv = umax,             color = color},
			{pos = {pmin.x, pmax.y}, uv = {umin.x, umax.y}, color = color},
		}
		indices := []u32 {0, 1, 2, 0, 2, 3}

		draw_geometry(d, vertices, indices, state)
	}
}

draw_text_centered :: proc(d: ^Drawlist, text: string, position: Vec2, color: Color) {
	size := drawlist_calc_text_size(d, text)
	draw_text(d, text, position - (size * 0.5), color)
}

drawlist_calc_text_size :: proc(d: ^Drawlist, text: string) -> Vec2 {
	font := drawlist_get_font(d^)
	pen: Vec2
	max_x: f32
	scale := drawlist_calc_font_scale(d^)

	for codepoint in text {
		max_x = max(pen.x, max_x)
		if codepoint == '\n' {
			pen.x = 0
			pen.y += font.base_line_height * scale
			continue
		}

		glyph := font_get_glyph(font^, codepoint) or_continue
		pen.x += glyph.advance * scale
	}

	return {max_x, pen.y + font.base_line_height}
}

draw_box_filled :: proc(d: ^Drawlist, center: Vec2, size: Vec2, rot: Rot, color: Color, uv: Rect = {}) {
	hs := size * 0.5
	r := rot_to_mat2(rot)
	draw_quad_filled(d, {
		center + r * -hs,
		center + r * Vec2{hs.x, -hs.y},
		center + r * hs,
		center + r * Vec2{-hs.x, hs.y},
	}, color)
}

// Automatically tiles a sprite across a rectangle. Assumes the rectangles size is divisible by
// the tile size.
// @Optimization: This could generate a lot less vertices if each tile shared the same corner vertices and just
// indexed into them (there are max 4 copies of each vertex)
draw_texture_auto_tiled :: proc(d: ^Drawlist, rect: Rect, color: Color, tile_size: Vec2, texture: Texture, uv: Rect) {
	state := d.base_state
	old_state := state

	if tile_size.x <= 0 || tile_size.y <= 0 do return

	state.texture = texture
	state.vertex_mode = .Triangles
	state.vert_shader = SHADER_DEFAULT_VERT
	state.frag_shader = SHADER_TEXTURE_FRAG

	d.base_state = state
	defer d.base_state = old_state

	x_count := int(rect.max.x - rect.min.x) / int(tile_size.x)
	y_count := int(rect.max.y - rect.min.y) / int(tile_size.y)

	for y in 0..<y_count {
		for x in 0..<x_count {
			//offset := Vec2{f32(x), f32(y)} * tile_size
			//draw_rect_filled(d, {rect.min + offset, rect.min + offset + tile_size}, color)
		}
	}
}

// @TODO
/*draw_grid_lines :: proc(
	drawlist: ^Drawlist, cell_size: f32, display_size: [2]f32, color: u32
) {
	screen_rect := camera_rect(drawlist.camera, display_size)
	x_count := int(linalg.ceil((screen_rect.max.x - screen_rect.min.x) / cell_size))+1
	y_count := int(linalg.ceil((screen_rect.max.y - screen_rect.min.y) / cell_size))+1
	start_pos: Vec2 = {
		linalg.floor(screen_rect.min.x / cell_size) * cell_size,
		linalg.floor(screen_rect.min.y / cell_size) * cell_size,
	}

	width := f32(x_count) * cell_size
	height := f32(y_count) * cell_size
	
	p := start_pos
	for y in 0..<y_count {
		draw_line(drawlist, p, {p.x + width, p.y}, color)
		p.y += cell_size
	}

	p = start_pos
	for x in 0..<x_count {
		draw_line(drawlist, p, {p.x, p.y + height}, color)
		p.x += cell_size
	}
}*/

// `source` is the rect of the sprite within the texture described in pixels
draw_sprite :: proc(
	d: ^Drawlist, texture: Texture, pos: Vec2, rotation: Rot = ROT_IDENTITY, source: Maybe(Rect) = nil, tint: Color = COLOR_WHITE, scale: f32 = 1,
) {
	tex_size := Vec2{f32(texture.width), f32(texture.height)}
	r := source.? or_else Rect{{0, 0}, tex_size}

	sprite_size := r.max - r.min

	r.min /= tex_size
	r.max /= tex_size

	state := d.base_state
	state.vertex_mode = .Triangles
	state.vert_shader = SHADER_DEFAULT_VERT
	state.frag_shader = SHADER_TEXTURE_FRAG
	state.texture     = texture

	rmat := rot_to_mat2(rotation)
	hs := sprite_size * 0.5 * scale

	vertices := []Vertex {
		{pos = pos + rmat * -hs,               uv = r.min,              color = tint},
		{pos = pos + rmat * Vec2{hs.x, -hs.y}, uv = {r.max.x, r.min.y}, color = tint},
		{pos = pos + rmat * hs,                uv = r.max,              color = tint},
		{pos = pos + rmat * Vec2{-hs.x, hs.y}, uv = {r.min.x, r.max.y}, color = tint},
	}

	indices := []u32 {0, 1, 2, 0, 2, 3}

	draw_geometry(d, vertices, indices, state)
}

