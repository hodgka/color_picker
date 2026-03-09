package ui

import rl "vendor:raylib"

modal_update :: proc(
	screen_w, screen_h: f32,
	panel_w, panel_h: f32,
	is_open: ^bool,
	mouse: rl.Vector2,
	just_opened: bool = false,
) -> rl.Rectangle {
	px := screen_w / 2 - panel_w / 2
	py := screen_h / 2 - panel_h / 2
	panel := rl.Rectangle{px, py, panel_w, panel_h}

	if rl.IsKeyPressed(.ESCAPE) {
		is_open^ = false
	}
	if rl.IsMouseButtonPressed(.LEFT) && !just_opened && !rl.CheckCollisionPointRec(mouse, panel) {
		is_open^ = false
	}
	return panel
}

modal_draw :: proc(
	screen_w, screen_h: f32,
	panel_w, panel_h: f32,
	title: cstring,
) {
	rl.DrawRectangle(0, 0, i32(screen_w), i32(screen_h), OVERLAY_BG)

	px := screen_w / 2 - panel_w / 2
	py := screen_h / 2 - panel_h / 2

	rl.DrawRectangleRounded({px - 1, py - 1, panel_w + 2, panel_h + 2}, 0.05, 8, OVERLAY)
	rl.DrawRectangleRounded({px, py, panel_w, panel_h}, 0.05, 8, BG)

	rl.DrawText(title, i32(px) + 20, i32(py) + 16, 18, TEXT_CLR)
}
