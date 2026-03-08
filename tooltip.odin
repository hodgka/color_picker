package color_picker

import rl "vendor:raylib"

TOOLTIP_DELAY :: 0.4

Tooltip :: struct {
	text:     cstring,
	x, y:     f32,
	active:   bool,
	timer:    f32,
	last_ref: rawptr,
}

tooltip_reset :: proc(tt: ^Tooltip) {
	tt.active = false
	tt.timer = 0
	tt.text = nil
	tt.last_ref = nil
}

tooltip_hover :: proc(tt: ^Tooltip, rect: rl.Rectangle, mouse: rl.Vector2, text: cstring, dt: f32, ref: rawptr = nil) {
	if !rl.CheckCollisionPointRec(mouse, rect) {
		if tt.last_ref == ref || ref == nil {
			tt.timer = 0
			tt.active = false
		}
		return
	}

	if ref != nil && tt.last_ref != ref {
		tt.timer = 0
		tt.active = false
		tt.last_ref = ref
	}

	tt.timer += dt
	if tt.timer >= TOOLTIP_DELAY {
		tt.active = true
		tt.text = text
		tt.x = mouse.x + 12
		tt.y = mouse.y - 22
	}
}

tooltip_draw :: proc(tt: ^Tooltip) {
	if !tt.active || tt.text == nil do return

	tw := rl.MeasureText(tt.text, 12)
	px := i32(tt.x)
	py := i32(tt.y)

	rl.DrawRectangleRounded(
		{f32(px - 4), f32(py - 2), f32(tw + 8), 18},
		0.3, 4, SURFACE,
	)
	rl.DrawRectangleRounded(
		{f32(px - 5), f32(py - 3), f32(tw + 10), 20},
		0.3, 4, {255, 255, 255, 15},
	)
	rl.DrawRectangleRounded(
		{f32(px - 4), f32(py - 2), f32(tw + 8), 18},
		0.3, 4, SURFACE,
	)
	rl.DrawText(tt.text, px, py, 12, TEXT_CLR)
}
