package ui

import rl "vendor:raylib"

dropdown_update :: proc(
	rect: rl.Rectangle,
	items: []cstring,
	selected: ^int,
	is_open: ^bool,
	mouse: rl.Vector2,
) -> (changed: bool) {
	hovering := rl.CheckCollisionPointRec(mouse, rect)
	if hovering && rl.IsMouseButtonPressed(.LEFT) && !is_open^ {
		is_open^ = true
	} else if is_open^ {
		item_h: f32 = 28
		for i in 0 ..< len(items) {
			ir := rl.Rectangle{rect.x, rect.y + rect.height + f32(i) * item_h, rect.width, item_h}
			if rl.CheckCollisionPointRec(mouse, ir) && rl.IsMouseButtonPressed(.LEFT) {
				selected^ = i
				is_open^ = false
				changed = true
			}
		}
		if rl.IsMouseButtonPressed(.LEFT) && !rl.CheckCollisionPointRec(
			mouse,
			{rect.x, rect.y, rect.width, rect.height + f32(len(items)) * item_h},
		) {
			is_open^ = false
		}
	}
	return
}

dropdown_draw :: proc(
	rect: rl.Rectangle,
	items: []cstring,
	selected: int,
	is_open: bool,
	mouse: rl.Vector2,
) {
	hovering := rl.CheckCollisionPointRec(mouse, rect)
	bg := is_open || hovering ? rl.Color{58, 58, 82, 255} : OVERLAY
	rl.DrawRectangleRounded(rect, 0.3, 6, bg)

	if selected >= 0 && selected < len(items) {
		rl.DrawText(items[selected], i32(rect.x) + 10, i32(rect.y) + 6, 14, TEXT_CLR)
	}

	arrow_x := rect.x + rect.width - 18
	arrow_cy := rect.y + rect.height / 2
	if is_open {
		rl.DrawTriangle({arrow_x, arrow_cy + 3}, {arrow_x + 8, arrow_cy + 3}, {arrow_x + 4, arrow_cy - 3}, SUBTEXT)
	} else {
		rl.DrawTriangle({arrow_x + 8, arrow_cy - 3}, {arrow_x, arrow_cy - 3}, {arrow_x + 4, arrow_cy + 3}, SUBTEXT)
	}

	if is_open {
		item_h: f32 = 28
		for i in 0 ..< len(items) {
			ir := rl.Rectangle{rect.x, rect.y + rect.height + f32(i) * item_h, rect.width, item_h}
			item_hover := rl.CheckCollisionPointRec(mouse, ir)
			ibg := item_hover ? ACCENT : SURFACE
			itxt := item_hover ? BG : TEXT_CLR
			rl.DrawRectangleRounded(ir, 0.1, 4, ibg)
			rl.DrawText(items[i], i32(ir.x) + 10, i32(ir.y) + 6, 14, itxt)
		}
	}
}
