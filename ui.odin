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

// ── Reusable text input ──

TextInput :: struct {
	buf:        [64]u8,
	len:        int,
	cursor:     int,
	sel_start:  int,
	sel_end:    int,
	focused:    bool,
	blink:      f32,
	filter:     TextFilter,
	last_click: f64,
}

TextFilter :: enum {
	Any,
	Hex,
}

text_input_init :: proc(initial: string, filter: TextFilter = .Any) -> TextInput {
	ti: TextInput
	ti.filter = filter
	n := min(len(initial), 63)
	for i in 0 ..< n do ti.buf[i] = initial[i]
	ti.len = n
	ti.cursor = n
	ti.sel_start = -1
	ti.sel_end = -1
	return ti
}

text_input_has_selection :: proc(ti: ^TextInput) -> bool {
	return ti.sel_start >= 0 && ti.sel_end >= 0 && ti.sel_start != ti.sel_end
}

text_input_delete_selection :: proc(ti: ^TextInput) {
	if !text_input_has_selection(ti) do return
	lo := min(ti.sel_start, ti.sel_end)
	hi := max(ti.sel_start, ti.sel_end)
	for j in hi ..< ti.len {
		ti.buf[j - (hi - lo)] = ti.buf[j]
	}
	ti.len -= (hi - lo)
	ti.cursor = lo
	ti.sel_start = -1
	ti.sel_end = -1
}

text_input_select_all :: proc(ti: ^TextInput) {
	ti.sel_start = 0
	ti.sel_end = ti.len
	ti.cursor = ti.len
}

text_input_get_string :: proc(ti: ^TextInput) -> string {
	return string(ti.buf[:ti.len])
}

text_input_char_allowed :: proc(c: u8, filter: TextFilter) -> bool {
	if filter == .Hex {
		return is_hex_char(c)
	}
	return c >= 32 && c < 127
}

text_input_update :: proc(ti: ^TextInput, dt: f32, max_len: int = 63) {
	if !ti.focused do return
	ti.blink += dt

	// Character input
	for ch := rl.GetCharPressed(); ch != 0; ch = rl.GetCharPressed() {
		c := u8(ch)
		if !text_input_char_allowed(c, ti.filter) do continue

		if text_input_has_selection(ti) {
			text_input_delete_selection(ti)
		}

		if ti.len >= max_len do continue

		if ti.filter == .Hex do c = upper_hex(c)

		for j := ti.len; j > ti.cursor; j -= 1 {
			ti.buf[j] = ti.buf[j - 1]
		}
		ti.buf[ti.cursor] = c
		ti.cursor += 1
		ti.len += 1
		ti.blink = 0
		ti.sel_start = -1
		ti.sel_end = -1
	}

	// Backspace
	if rl.IsKeyPressed(.BACKSPACE) {
		if text_input_has_selection(ti) {
			text_input_delete_selection(ti)
		} else if is_cmd_down() {
			// Cmd+Backspace: delete everything before cursor
			for j in ti.cursor ..< ti.len {
				ti.buf[j - ti.cursor] = ti.buf[j]
			}
			ti.len -= ti.cursor
			ti.cursor = 0
		} else if ti.cursor > 0 {
			ti.cursor -= 1
			for j in ti.cursor ..< ti.len - 1 {
				ti.buf[j] = ti.buf[j + 1]
			}
			ti.len -= 1
		}
		ti.blink = 0
		ti.sel_start = -1
		ti.sel_end = -1
	}

	// Delete
	if rl.IsKeyPressed(.DELETE) {
		if text_input_has_selection(ti) {
			text_input_delete_selection(ti)
		} else if ti.cursor < ti.len {
			for j in ti.cursor ..< ti.len - 1 {
				ti.buf[j] = ti.buf[j + 1]
			}
			ti.len -= 1
		}
		ti.blink = 0
	}

	// Arrow keys
	if rl.IsKeyPressed(.LEFT) && ti.cursor > 0 {
		if is_cmd_down() {
			ti.cursor = 0
		} else {
			ti.cursor -= 1
		}
		ti.blink = 0
		ti.sel_start = -1
		ti.sel_end = -1
	}
	if rl.IsKeyPressed(.RIGHT) && ti.cursor < ti.len {
		if is_cmd_down() {
			ti.cursor = ti.len
		} else {
			ti.cursor += 1
		}
		ti.blink = 0
		ti.sel_start = -1
		ti.sel_end = -1
	}

	// Home / End
	if rl.IsKeyPressed(.HOME) { ti.cursor = 0; ti.blink = 0; ti.sel_start = -1; ti.sel_end = -1 }
	if rl.IsKeyPressed(.END) { ti.cursor = ti.len; ti.blink = 0; ti.sel_start = -1; ti.sel_end = -1 }

	// Cmd+A: select all
	if is_cmd_down() && rl.IsKeyPressed(.A) {
		text_input_select_all(ti)
		ti.blink = 0
	}
}

text_input_handle_click :: proc(ti: ^TextInput, rect: rl.Rectangle, mouse: rl.Vector2, font_size: i32, x_offset: i32 = 10) {
	if !rl.IsMouseButtonPressed(.LEFT) do return

	was_focused := ti.focused
	ti.focused = rl.CheckCollisionPointRec(mouse, rect)

	if !ti.focused {
		ti.sel_start = -1
		ti.sel_end = -1
		return
	}

	now := rl.GetTime()
	time_since := now - ti.last_click
	ti.last_click = now

	if was_focused && time_since < 0.35 {
		text_input_select_all(ti)
	} else {
		click_px := i32(mouse.x) - i32(rect.x) - x_offset
		best := ti.len
		tmp: [65]u8
		for j in 0 ..< ti.len do tmp[j] = ti.buf[j]
		for j in 0 ..= ti.len {
			tmp[j] = 0
			w := rl.MeasureText(cstring(&tmp[0]), font_size)
			if j < ti.len do tmp[j] = ti.buf[j]
			if click_px < w {
				best = max(j - 1, 0)
				break
			}
		}
		ti.cursor = clamp(best, 0, ti.len)
		ti.sel_start = -1
		ti.sel_end = -1
	}
	ti.blink = 0
}

text_input_draw :: proc(
	ti: ^TextInput,
	rect: rl.Rectangle,
	font_size: i32 = 18,
	prefix: cstring = "",
	x_offset: i32 = 10,
) {
	bg := ti.focused ? rl.Color{58, 58, 82, 255} : OVERLAY
	rl.DrawRectangleRounded(rect, 0.3, 6, bg)
	if ti.focused {
		rl.DrawRectangleRounded(
			{rect.x - 1, rect.y - 1, rect.width + 2, rect.height + 2},
			0.3, 6, ACCENT,
		)
		rl.DrawRectangleRounded(rect, 0.3, 6, bg)
	}

	tx := i32(rect.x) + x_offset
	ty := i32(rect.y) + (i32(rect.height) - font_size) / 2

	prefix_w: i32 = 0
	if prefix != "" {
		rl.DrawText(prefix, tx, ty, font_size, SUBTEXT)
		prefix_w = rl.MeasureText(prefix, font_size) + 4
	}

	char_x := tx + prefix_w

	// Measure position of each character using raylib's text measurement
	text_str: [65]u8
	for j in 0 ..< ti.len do text_str[j] = ti.buf[j]
	text_str[ti.len] = 0

	// Selection highlight
	if text_input_has_selection(ti) {
		lo := min(ti.sel_start, ti.sel_end)
		hi := max(ti.sel_start, ti.sel_end)
		lo_str := text_str
		lo_str[lo] = 0
		hi_str := text_str
		hi_str[hi] = 0
		sel_x := rl.MeasureText(cstring(&lo_str[0]), font_size)
		sel_w := rl.MeasureText(cstring(&hi_str[0]), font_size) - sel_x
		rl.DrawRectangle(char_x + sel_x, ty, sel_w, font_size, {137, 180, 250, 80})
	}

	rl.DrawText(cstring(&text_str[0]), char_x, ty, font_size, TEXT_CLR)

	if ti.focused && int(ti.blink * 1.8) % 2 == 0 {
		cursor_str := text_str
		cursor_str[ti.cursor] = 0
		cx := char_x + rl.MeasureText(cstring(&cursor_str[0]), font_size)
		rl.DrawRectangle(cx, ty, 2, font_size, ACCENT)
	}
}
