package j2d

import "core:math/linalg"

round_up_to_multiple :: proc "contextless" (v: $T, m: T) -> T {
	x := v % m
	return x == 0 ? v : v + (m - x)
}

rect_intersects :: proc "contextless" (a, b: Rect) -> bool {
	return a.max.x >= b.min.x && 
		b.max.x >= a.min.x && 
		a.max.y >= b.min.y && 
		b.max.y >= a.min.y
}

rect_center :: proc "contextless" (r: Rect) -> Vec2 {
	return r.min + ((r.max - r.min) * 0.5)
}

rect_correct :: proc "contextless" (r: Rect) -> Rect {
	return {
		{min(r.min.x, r.max.x), min(r.min.y, r.max.y)},
		{max(r.min.x, r.max.x), max(r.min.y, r.max.y)},
	}
}

vec2_angle :: proc "contextless" (v: Vec2) -> f32 {
	return linalg.atan2(v.y, v.x) - (linalg.PI/2)
}

make_rot :: proc "contextless" (a: f32) -> Rot {
	return {c = linalg.cos(a), s = linalg.sin(a)}
}

rot_to_mat2 :: proc "contextless" (r: Rot) -> Mat2 {
	return {
		r.c, -r.s,
		r.s, r.c,
	}
}

mat2_to_rot :: proc "contextless" (m: Mat2) -> Rot {
	return {
		s = m[1][0],
		c = m[0][0],
	}
}

vec2_rotate :: proc "contextless" (v: Vec2, r: Rot) -> Vec2 {
	return {
		v.x * r.c - v.y * r.s,
		v.x * r.s + v.y * r.c,
	}
}
