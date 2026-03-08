package ui

import rl "vendor:raylib"
import "core:fmt"

draw_color_swatch_row :: proc(
	colors: []rl.Color,
	x, y: f32,
	size: f32 = 28,
	gap: f32 = 4,
	mouse: rl.Vector2,
	selected_idx: int = -1,
) -> int {
	clicked := -1
	for c, i in colors {
		rx := x + f32(i) * (size + gap)
		r := rl.Rectangle{rx, y, size, size}
		hovering := rl.CheckCollisionPointRec(mouse, r)

		if hovering || i == selected_idx {
			rl.DrawRectangleRounded(
				{r.x - 2, r.y - 2, r.width + 4, r.height + 4},
				0.15,
				4,
				hovering ? ACCENT : TEXT_CLR,
			)
		} else {
			rl.DrawRectangleRounded(
				{r.x - 1, r.y - 1, r.width + 2, r.height + 2},
				0.15,
				4,
				{255, 255, 255, 15},
			)
		}
		rl.DrawRectangleRounded(r, 0.15, 4, c)

		if hovering && rl.IsMouseButtonPressed(.LEFT) {
			clicked = i
		}
	}
	return clicked
}

format_hex_cstr :: proc(color: rl.Color) -> cstring {
	return fmt.ctprintf("#%02X%02X%02X", color.r, color.g, color.b)
}
