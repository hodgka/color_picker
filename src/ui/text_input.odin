package ui

import rl "vendor:raylib"
import "../color"

UNDO_MAX :: 64

TextSnapshot :: struct {
	buf:    [64]u8,
	len:    int,
	cursor: int,
}

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
	changed:    bool,
	committed:  bool,
	undo:       [UNDO_MAX]TextSnapshot,
	undo_count: int,
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

text_input_set_string :: proc(ti: ^TextInput, s: string) {
	n := min(len(s), 63)
	for i in 0 ..< n do ti.buf[i] = s[i]
	ti.len = n
	ti.cursor = n
	ti.sel_start = -1
	ti.sel_end = -1
}

undo_push :: proc(ti: ^TextInput) {
	snap := TextSnapshot{ti.buf, ti.len, ti.cursor}
	if ti.undo_count > 0 {
		top := ti.undo[ti.undo_count - 1]
		if top.buf == snap.buf && top.len == snap.len && top.cursor == snap.cursor {
			return
		}
	}
	if ti.undo_count < UNDO_MAX {
		ti.undo[ti.undo_count] = snap
		ti.undo_count += 1
	} else {
		for i in 1 ..< UNDO_MAX {
			ti.undo[i - 1] = ti.undo[i]
		}
		ti.undo[UNDO_MAX - 1] = snap
	}
}

undo_pop :: proc(ti: ^TextInput) -> bool {
	if ti.undo_count == 0 do return false
	ti.undo_count -= 1
	snap := ti.undo[ti.undo_count]
	ti.buf = snap.buf
	ti.len = snap.len
	ti.cursor = snap.cursor
	ti.sel_start = -1
	ti.sel_end = -1
	return true
}

text_input_char_allowed :: proc(c: u8, filter: TextFilter) -> bool {
	if filter == .Hex {
		return color.is_hex_char(c)
	}
	return c >= 32 && c < 127
}

text_input_update :: proc(ti: ^TextInput, dt: f32, max_len: int = 63) {
	if !ti.focused do return
	ti.blink += dt

	prev_len := ti.len
	prev_buf := ti.buf

	for ch := rl.GetCharPressed(); ch != 0; ch = rl.GetCharPressed() {
		c := u8(ch)
		if !text_input_char_allowed(c, ti.filter) do continue
		undo_push(ti)

		if text_input_has_selection(ti) {
			text_input_delete_selection(ti)
		}

		if ti.len >= max_len do continue

		if ti.filter == .Hex do c = color.upper_hex(c)

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

	if rl.IsKeyPressed(.BACKSPACE) {
		undo_push(ti)
		if text_input_has_selection(ti) {
			text_input_delete_selection(ti)
		} else if is_cmd_down() {
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

	if rl.IsKeyPressed(.DELETE) {
		undo_push(ti)
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

	if rl.IsKeyPressed(.HOME) { ti.cursor = 0; ti.blink = 0; ti.sel_start = -1; ti.sel_end = -1 }
	if rl.IsKeyPressed(.END) { ti.cursor = ti.len; ti.blink = 0; ti.sel_start = -1; ti.sel_end = -1 }

	if is_cmd_down() && rl.IsKeyPressed(.A) {
		text_input_select_all(ti)
		ti.blink = 0
	}

	if is_cmd_down() && rl.IsKeyPressed(.Z) {
		if undo_pop(ti) {
			ti.blink = 0
		}
	}

	if is_cmd_down() && rl.IsKeyPressed(.V) {
		if clip := rl.GetClipboardText(); clip != nil {
			ps := string(clip)
			if len(ps) > 0 {
				undo_push(ti)
				if text_input_has_selection(ti) {
					text_input_delete_selection(ti)
				}
				for ch in ps {
					c := u8(ch)
					if !text_input_char_allowed(c, ti.filter) do continue
					if ti.len >= max_len do break
					if ti.filter == .Hex do c = color.upper_hex(c)
					for j := ti.len; j > ti.cursor; j -= 1 {
						ti.buf[j] = ti.buf[j - 1]
					}
					ti.buf[ti.cursor] = c
					ti.cursor += 1
					ti.len += 1
				}
				ti.blink = 0
				ti.sel_start = -1
				ti.sel_end = -1
			}
		}
	}

	if rl.IsKeyPressed(.ENTER) {
		ti.committed = true
	}

	if ti.len != prev_len || ti.buf != prev_buf {
		ti.changed = true
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
	bg := ti.focused ? HOVER_BG : OVERLAY
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

	text_str: [65]u8
	for j in 0 ..< ti.len do text_str[j] = ti.buf[j]
	text_str[ti.len] = 0

	if text_input_has_selection(ti) {
		lo := min(ti.sel_start, ti.sel_end)
		hi := max(ti.sel_start, ti.sel_end)
		lo_str := text_str
		lo_str[lo] = 0
		hi_str := text_str
		hi_str[hi] = 0
		sel_x := rl.MeasureText(cstring(&lo_str[0]), font_size)
		sel_w := rl.MeasureText(cstring(&hi_str[0]), font_size) - sel_x
		rl.DrawRectangle(char_x + sel_x, ty, sel_w, font_size, SELECTION_HL)
	}

	rl.DrawText(cstring(&text_str[0]), char_x, ty, font_size, TEXT_CLR)

	if ti.focused && int(ti.blink * 1.8) % 2 == 0 {
		cursor_str := text_str
		cursor_str[ti.cursor] = 0
		cx := char_x + rl.MeasureText(cstring(&cursor_str[0]), font_size)
		rl.DrawRectangle(cx, ty, 2, font_size, ACCENT)
	}
}
