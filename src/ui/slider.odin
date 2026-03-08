package ui

import rl "vendor:raylib"
import "core:fmt"

color_slider_update :: proc(
	track_rect: rl.Rectangle,
	mouse: rl.Vector2,
	dragging: ^bool,
	value: f32,
) -> (new_value: f32, started: bool) {
	new_value = value
	if rl.IsMouseButtonPressed(.LEFT) && rl.CheckCollisionPointRec(mouse, track_rect) {
		dragging^ = true
		started = true
	}
	if dragging^ {
		new_value = clamp((mouse.x - track_rect.x) / track_rect.width, 0, 1)
	}
	if rl.IsMouseButtonReleased(.LEFT) {
		dragging^ = false
	}
	return
}

color_slider_draw :: proc(
	label_x: f32,
	track_rect: rl.Rectangle,
	value: f32,
	left_color, right_color: rl.Color,
	knob_color: rl.Color,
	label: cstring,
	value_text: cstring,
	hue_tex: rl.Texture2D = {},
) {
	sx := i32(track_rect.x)
	sy := i32(track_rect.y)
	sw := i32(track_rect.width)

	rl.DrawText(label, i32(label_x), sy + 1, 16, SUBTEXT)
	rl.DrawRectangle(sx, sy + 2, sw, 12, OVERLAY)

	if hue_tex.width > 0 {
		rl.DrawTexturePro(
			hue_tex,
			{0, 0, f32(hue_tex.width), 1},
			{track_rect.x + 1, f32(sy + 3), f32(sw - 2), 10},
			{0, 0}, 0, rl.WHITE,
		)
	} else {
		rl.DrawRectangleGradientH(sx + 1, sy + 3, sw - 2, 10, left_color, right_color)
	}

	knob_x := track_rect.x + value * track_rect.width
	rl.DrawCircle(i32(knob_x), sy + 8, 9, rl.WHITE)
	rl.DrawCircle(i32(knob_x), sy + 8, 7, knob_color)
	rl.DrawCircleLines(i32(knob_x), sy + 8, 9, {0, 0, 0, 80})
	rl.DrawText(value_text, sx + sw + 16, sy + 1, 16, SUBTEXT)
}
