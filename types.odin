package j2d

import "core:mem"
import "core:os"

Vec2 :: [2]f32
Rect :: struct {min, max: Vec2}
Rot  :: struct {s, c: f32}
Mat2 :: matrix[2, 2]f32
Mat3 :: matrix[3, 3]f32
Color :: [4]u8

ROT_IDENTITY :: Rot{s = 0, c = 1}

COLOR_WHITE :: Color{255, 255, 255, 255}
COLOR_BLACK :: Color{0, 0, 0, 255}
COLOR_RED   :: Color{255, 0, 0, 255}
COLOR_GREEN :: Color{0, 255, 0, 255}
COLOR_BLUE  :: Color{0, 0, 255, 255}

Video_Backend :: enum {
	OpenGL,
}

Platform_Backend :: enum {
	GLFW,
}
