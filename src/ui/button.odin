package ui

import rl "vendor:raylib"

button_update :: proc(
	rect: rl.Rectangle,
	mouse: rl.Vector2,
	disabled: bool = false,
) -> (clicked: bool) {
	if disabled do return false
	return rl.CheckCollisionPointRec(mouse, rect) && rl.IsMouseButtonPressed(.LEFT)
}

button_draw :: proc(
	rect: rl.Rectangle,
	label: cstring,
	mouse: rl.Vector2,
	font_size: i32 = 14,
	disabled: bool = false,
) {
	hovering := !disabled && rl.CheckCollisionPointRec(mouse, rect)

	bg: rl.Color
	text: rl.Color
	if disabled {
		bg = DISABLED_BG
		text = DISABLED_TEXT
	} else if hovering {
		bg = ACCENT
		text = BG
	} else {
		bg = OVERLAY
		text = TEXT_CLR
	}
	rl.DrawRectangleRounded(rect, 0.3, 6, bg)
	tw := rl.MeasureText(label, font_size)
	tx := i32(rect.x) + (i32(rect.width) - tw) / 2
	ty := i32(rect.y) + (i32(rect.height) - font_size) / 2
	rl.DrawText(label, tx, ty, font_size, text)
}

draw_toggle :: proc(
	rect: rl.Rectangle,
	labels: [2]cstring,
	active: int,
	mouse: rl.Vector2,
) -> int {
	half_w := rect.width / 2
	result := active

	for i in 0 ..< 2 {
		r := rl.Rectangle{rect.x + f32(i) * half_w, rect.y, half_w, rect.height}
		hovering := rl.CheckCollisionPointRec(mouse, r)

		bg: rl.Color
		text: rl.Color
		if i == active {
			bg = ACCENT
			text = BG
		} else if hovering {
			bg = HOVER_BG
			text = TEXT_CLR
		} else {
			bg = OVERLAY
			text = SUBTEXT
		}

		rl.DrawRectangleRounded(r, 0.3, 4, bg)
		tw := rl.MeasureText(labels[i], 13)
		tx := i32(r.x) + (i32(r.width) - tw) / 2
		ty := i32(r.y) + (i32(r.height) - 13) / 2
		rl.DrawText(labels[i], tx, ty, 13, text)

		if hovering && rl.IsMouseButtonPressed(.LEFT) {
			result = i
		}
	}
	return result
}
