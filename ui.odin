package color_picker

import rl "vendor:raylib"
import "core:fmt"

is_cmd_down :: proc() -> bool {
	return(
		rl.IsKeyDown(.LEFT_SUPER) ||
		rl.IsKeyDown(.RIGHT_SUPER) ||
		rl.IsKeyDown(.LEFT_CONTROL) ||
		rl.IsKeyDown(.RIGHT_CONTROL) \
	)
}

draw_button :: proc(
	rect: rl.Rectangle,
	label: cstring,
	mouse: rl.Vector2,
	font_size: i32 = 14,
	disabled: bool = false,
) -> (
	clicked: bool,
	hovering: bool,
) {
	hovering = !disabled && rl.CheckCollisionPointRec(mouse, rect)
	clicked = hovering && rl.IsMouseButtonPressed(.LEFT)

	bg: rl.Color
	text: rl.Color
	if disabled {
		bg = rl.Color{35, 35, 48, 255}
		text = rl.Color{70, 70, 90, 255}
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
	return
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
			bg = rl.Color{58, 58, 82, 255}
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

draw_dropdown :: proc(
	rect: rl.Rectangle,
	items: []cstring,
	selected: ^int,
	is_open: ^bool,
	mouse: rl.Vector2,
) {
	hovering := rl.CheckCollisionPointRec(mouse, rect)
	bg := is_open^ ? rl.Color{58, 58, 82, 255} : (hovering ? rl.Color{58, 58, 82, 255} : OVERLAY)
	rl.DrawRectangleRounded(rect, 0.3, 6, bg)

	if selected^ >= 0 && selected^ < len(items) {
		rl.DrawText(items[selected^], i32(rect.x) + 10, i32(rect.y) + 6, 14, TEXT_CLR)
	}

	arrow_x := i32(rect.x + rect.width) - 18
	arrow_y := i32(rect.y) + i32(rect.height) / 2
	if is_open^ {
		rl.DrawTriangle(
			{f32(arrow_x), f32(arrow_y + 3)},
			{f32(arrow_x + 8), f32(arrow_y + 3)},
			{f32(arrow_x + 4), f32(arrow_y - 3)},
			SUBTEXT,
		)
	} else {
		rl.DrawTriangle(
			{f32(arrow_x), f32(arrow_y - 3)},
			{f32(arrow_x + 8), f32(arrow_y - 3)},
			{f32(arrow_x + 4), f32(arrow_y + 3)},
			SUBTEXT,
		)
	}

	if hovering && rl.IsMouseButtonPressed(.LEFT) && !is_open^ {
		is_open^ = true
	} else if is_open^ {
		item_h: f32 = 28
		for i in 0 ..< len(items) {
			ir := rl.Rectangle{rect.x, rect.y + rect.height + f32(i) * item_h, rect.width, item_h}
			item_hover := rl.CheckCollisionPointRec(mouse, ir)
			ibg := item_hover ? ACCENT : SURFACE
			itxt := item_hover ? BG : TEXT_CLR
			rl.DrawRectangleRounded(ir, 0.1, 4, ibg)
			rl.DrawText(items[i], i32(ir.x) + 10, i32(ir.y) + 6, 14, itxt)

			if item_hover && rl.IsMouseButtonPressed(.LEFT) {
				selected^ = i
				is_open^ = false
			}
		}

		if rl.IsMouseButtonPressed(.LEFT) && !rl.CheckCollisionPointRec(
			mouse,
			{rect.x, rect.y, rect.width, rect.height + f32(len(items)) * item_h},
		) {
			is_open^ = false
		}
	}
}

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
