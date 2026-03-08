package ui

import rl "vendor:raylib"
import "core:fmt"

stepper_update :: proc(
	x, y: f32,
	value: int,
	lo, hi: int,
	mouse: rl.Vector2,
	btn_w: f32 = 18,
	btn_h: f32 = 16,
	gap: f32 = 42,
) -> int {
	minus_r := rl.Rectangle{x, y, btn_w, btn_h}
	plus_r := rl.Rectangle{x + gap, y, btn_w, btn_h}
	if rl.IsMouseButtonPressed(.LEFT) {
		if rl.CheckCollisionPointRec(mouse, minus_r) && value > lo {
			return value - 1
		}
		if rl.CheckCollisionPointRec(mouse, plus_r) && value < hi {
			return value + 1
		}
	}
	return value
}

stepper_draw :: proc(
	x, y: f32,
	value: int,
	lo, hi: int,
	mouse: rl.Vector2,
	font_size: i32 = 12,
	btn_w: f32 = 18,
	btn_h: f32 = 16,
	gap: f32 = 42,
) {
	minus_r := rl.Rectangle{x, y, btn_w, btn_h}
	plus_r := rl.Rectangle{x + gap, y, btn_w, btn_h}
	button_draw(minus_r, "-", mouse, font_size, disabled = value <= lo)
	rl.DrawText(fmt.ctprintf("%d", value), i32(x + btn_w + 4), i32(y + 2), font_size, TEXT_CLR)
	button_draw(plus_r, "+", mouse, font_size, disabled = value >= hi)
}
