package j2d

import "core:math/linalg"

make_camera :: proc(pos: Vec2, scale: Vec2, rot: Rot) -> Mat3 {
	s := Mat3 {
		scale.x, 0,       0,
		0,       scale.y, 0,
		0,       0,       1,

	}

	t := Mat3 {
		1, 0, -pos.x,
		0, 1, -pos.y,
		0, 0, 1,
	}

	r := Mat3 {
		rot.c, -rot.s, 0,
		rot.s, rot.c,  0,
		0,     0,      1,
	}

	return t * s * r
}
