package color_picker

LayoutMode :: enum {
	Compact,
	Medium,
	Large,
}

BREAKPOINT_MEDIUM :: 960
BREAKPOINT_LARGE  :: 1200
MIN_WINDOW_W :: 700
MIN_WINDOW_H :: 500

Layout :: struct {
	mode:               LayoutMode,
	win_w, win_h:       i32,
	margin:             i32,
	picker_size:        i32,
	picker_x, picker_y: i32,
	right_x, right_w:   i32,
	preview_y:          i32,
	preview_h:          i32,
	contrast_info_y:    i32,
	hex_field_y:        i32,
	slider_base_y:      i32,
	slider_spacing:     i32,
	hsv_slider_y:       i32,
	hint_y:             i32,
	history_y:          i32,
	sv_size:            i32,
	sv_x, sv_y:         i32,
	harmony_section_y:  i32,
	export_btn_y:       i32,
	cols_per_row:       int,
	slider_w:           f32,
	slider_x:           f32,
}

MIN_RIGHT_W :: 460

compute_layout :: proc(w, h: i32) -> Layout {
	l: Layout
	l.win_w = max(w, MIN_WINDOW_W)
	l.win_h = max(h, MIN_WINDOW_H)

	if w >= BREAKPOINT_LARGE {
		l.mode = .Large
		l.margin = 28
	} else if w >= BREAKPOINT_MEDIUM {
		l.mode = .Medium
		l.margin = 24
	} else {
		l.mode = .Compact
		l.margin = 16
	}

	// ── Right column: guaranteed minimum width ──
	l.right_w = max(l.win_w * 55 / 100, MIN_RIGHT_W)
	l.right_w = min(l.right_w, l.win_w - l.margin * 2 - 200)

	// ── Picker: fills remaining left space ──
	gap: i32 = 24
	l.picker_x = l.margin
	l.picker_y = 50

	max_picker_w := l.win_w - l.right_w - l.margin * 2 - gap
	// Bottom budget: picker + controls(30) + harmony section(~160) + palette(~120) + export(50)
	bottom_budget: i32 = 30 + 160 + 120 + 50
	max_picker_h := l.win_h - l.picker_y - bottom_budget

	l.picker_size = min(max_picker_w, max_picker_h)
	l.picker_size = clamp(l.picker_size, 160, 440)

	l.right_x = l.picker_x + l.picker_size + gap
	l.right_w = l.win_w - l.right_x - l.margin

	// ── Right column vertical positions ──
	l.preview_y = l.picker_y
	l.preview_h = l.mode == .Compact ? 70 : 100
	l.contrast_info_y = l.preview_y + l.preview_h + 8
	l.hex_field_y = l.contrast_info_y + 48
	l.slider_base_y = l.hex_field_y + 40
	l.slider_spacing = l.mode == .Compact ? 24 : 30
	l.hsv_slider_y = l.slider_base_y + 3 * l.slider_spacing + 12
	l.hint_y = l.hsv_slider_y + 3 * l.slider_spacing + 8
	l.history_y = l.hint_y + 22

	// ── SV picker (square mode) ──
	l.sv_size = min(l.picker_size, 280)
	l.sv_x = l.picker_x
	l.sv_y = l.picker_y

	// ── Left column below picker ──
	l.harmony_section_y = l.picker_y + l.picker_size + 12

	// ── Bottom ──
	l.export_btn_y = l.win_h - 44

	// ── Grid ──
	l.cols_per_row = max(int(l.win_w - 2 * l.margin) / SWATCH_STRIDE, 1)

	// ── Sliders ──
	l.slider_w = f32(l.right_w - 80)
	l.slider_x = f32(l.right_x + 24)

	return l
}
