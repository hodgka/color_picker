package color_picker

import rl "vendor:raylib"
import "core:fmt"
import "core:math"
import "color"
import "ui"
import "ui/layout"
import "data"

draw_header :: proc(rects: []layout.Rect) {
	header, _ := layout.find(rects, .Header)
	rl.DrawText("Color Picker", i32(header.x), i32(header.y), 22, ui.TEXT_CLR)
}

draw_picker :: proc(app: ^AppState, mouse: rl.Vector2, rects: []layout.Rect) {
	picker, _ := layout.find(rects, .Picker)
	controls, _ := layout.find(rects, .Picker_Controls)

	px := i32(picker.x)
	py := i32(picker.y)

	if app.picker_mode == .Square {
		sv_size := i32(SV_TEX_SIZE)
		HUE_BAR_H :: 20

		rl.DrawRectangle(px - 1, py - 1, sv_size + 2, sv_size + 2, ui.OVERLAY)
		rl.DrawTexture(app.sv_tex, px, py, rl.WHITE)

		sx := i32(picker.x + app.cs.sat * f32(sv_size))
		sy := i32(picker.y + (1 - app.cs.val) * f32(sv_size))
		rl.DrawCircle(sx, sy, 8, {0, 0, 0, 100})
		rl.DrawCircleLines(sx, sy, 7, rl.WHITE)
		rl.DrawCircleLines(sx, sy, 8, {0, 0, 0, 200})

		hue_bar_y := py + sv_size + 14
		rl.DrawRectangle(px - 1, hue_bar_y - 1, sv_size + 2, HUE_BAR_H + 2, ui.OVERLAY)
		rl.DrawTexturePro(app.hue_tex, {0, 0, 360, 1}, {picker.x, f32(hue_bar_y), f32(sv_size), HUE_BAR_H}, {0, 0}, 0, rl.WHITE)

		hx := i32(picker.x + app.cs.hue / 360 * f32(sv_size))
		rl.DrawRectangle(hx - 2, hue_bar_y - 2, 5, HUE_BAR_H + 4, rl.WHITE)
		rl.DrawRectangleLines(hx - 3, hue_bar_y - 3, 7, HUE_BAR_H + 6, {0, 0, 0, 180})
	} else {
		wheel_size := i32(WHEEL_TEX_SIZE)
		rl.DrawTexture(app.wheel_tex, px, py, rl.WHITE)
		center_x := picker.x + f32(wheel_size) / 2
		center_y := picker.y + f32(wheel_size) / 2
		radius := f32(wheel_size) / 2

		offsets, off_count := color.harmony_hue_offsets(color.HarmonyType(app.harmony_type), app.harmony_req)
		for i in 0 ..< off_count {
			angle := (app.cs.hue + offsets[i]) * math.PI / 180.0
			hpx := center_x + math.cos(angle) * app.cs.sat * radius
			hpy := center_y + math.sin(angle) * app.cs.sat * radius
			rl.DrawCircleLines(i32(hpx), i32(hpy), 9, {0, 0, 0, 200})
			rl.DrawCircleLines(i32(hpx), i32(hpy), 8, rl.WHITE)
			rl.DrawCircleLines(i32(hpx), i32(hpy), 7, {0, 0, 0, 200})
			if i > 0 {
				prev_angle := (app.cs.hue + offsets[i - 1]) * math.PI / 180.0
				prev_x := center_x + math.cos(prev_angle) * app.cs.sat * radius
				prev_y := center_y + math.sin(prev_angle) * app.cs.sat * radius
				rl.DrawLine(i32(prev_x), i32(prev_y), i32(hpx), i32(hpy), {0, 0, 0, 160})
				rl.DrawLine(i32(prev_x) + 1, i32(prev_y), i32(hpx) + 1, i32(hpy), {255, 255, 255, 60})
			}
		}
		if off_count > 2 {
			first_angle := (app.cs.hue + offsets[0]) * math.PI / 180.0
			last_angle := (app.cs.hue + offsets[off_count - 1]) * math.PI / 180.0
			fx := i32(center_x + math.cos(first_angle) * app.cs.sat * radius)
			fy := i32(center_y + math.sin(first_angle) * app.cs.sat * radius)
			lx := i32(center_x + math.cos(last_angle) * app.cs.sat * radius)
			ly := i32(center_y + math.sin(last_angle) * app.cs.sat * radius)
			rl.DrawLine(lx, ly, fx, fy, {0, 0, 0, 160})
			rl.DrawLine(lx + 1, ly, fx + 1, fy, {255, 255, 255, 60})
		}

		sel_angle := app.cs.hue * math.PI / 180.0
		sel_x := center_x + math.cos(sel_angle) * app.cs.sat * radius
		sel_y := center_y + math.sin(sel_angle) * app.cs.sat * radius
		rl.DrawCircle(i32(sel_x), i32(sel_y), 9, {0, 0, 0, 180})
		rl.DrawCircleLines(i32(sel_x), i32(sel_y), 8, rl.WHITE)
		rl.DrawCircleLines(i32(sel_x), i32(sel_y), 9, {0, 0, 0, 220})
	}

	toggle_rect := rl.Rectangle{controls.x, controls.y, 140, 26}
	ui.draw_toggle(toggle_rect, {"Wheel", "Square"}, int(app.picker_mode), mouse)

	eye_btn := rl.Rectangle{toggle_rect.x + toggle_rect.width + 10, controls.y, 90, 26}
	ui.button_draw(eye_btn, "Eyedropper", mouse, 12)
}

draw_harmony_section :: proc(app: ^AppState, mouse: rl.Vector2, rects: []layout.Rect) {
	harmony, _ := layout.find(rects, .Harmony)
	hx := harmony.x
	hy := harmony.y

	harmony_names_list: [8]cstring
	for ht in color.HarmonyType {
		harmony_names_list[int(ht)] = color.HARMONY_NAMES[ht]
	}
	dropdown_rect := rl.Rectangle{hx, hy, 160, 28}
	ui.dropdown_draw(dropdown_rect, harmony_names_list[:], app.harmony_type, app.harmony_open, mouse)

	if !app.harmony_open {
		harm_label_y := hy + 34
		rl.DrawText("Harmonies", i32(hx), i32(harm_label_y), 12, ui.DIM)

		ht := color.HarmonyType(app.harmony_type)
		if color.harmony_is_variable(ht) {
			ui.stepper_draw(hx + 70, harm_label_y - 2, app.harmony_count, 2, color.MAX_HARMONY, mouse)
		}

		harm_y := harm_label_y + 18
		harm_display: [color.MAX_HARMONY]rl.Color
		for hi in 0 ..< app.harmony_count {
			harm_display[hi] = app.cvd_mode != .None ? color.simulate_cvd(app.harmony_colors[hi], app.cvd_mode) : app.harmony_colors[hi]
		}
		ui.draw_color_swatch_row(harm_display[:app.harmony_count], hx, harm_y, 28, 3, mouse)

		shade_label_y := harm_y + 40
		rl.DrawText("Shades", i32(hx), i32(shade_label_y), 12, ui.DIM)

		ui.stepper_draw(hx + 50, shade_label_y - 2, app.shade_count, 3, color.MAX_SHADES, mouse)

		dark_btn := rl.Rectangle{hx + 122, shade_label_y - 2, 36, 16}
		light_btn := rl.Rectangle{dark_btn.x + 42, shade_label_y - 2, 36, 16}
		ui.button_draw(dark_btn, "Dark", mouse, 10)
		ui.button_draw(light_btn, "Light", mouse, 10)

		shade_y := shade_label_y + 18
		shade_display: [color.MAX_SHADES]rl.Color
		for si in 0 ..< app.shade_count {
			shade_display[si] = app.cvd_mode != .None ? color.simulate_cvd(app.shades[si], app.cvd_mode) : app.shades[si]
		}
		ui.draw_color_swatch_row(shade_display[:app.shade_count], hx, shade_y, 28, 3, mouse)
	}
}

draw_right_column :: proc(app: ^AppState, mouse: rl.Vector2, cur_color: rl.Color, display_color: rl.Color, rects: []layout.Rect) {
	rc, _ := layout.find(rects, .Right_Column)
	preview_r, _ := layout.find(rects, .Preview)
	contrast_r, _ := layout.find(rects, .Contrast)
	hex_r, _ := layout.find(rects, .Hex_Field)
	rgb_r, _ := layout.find(rects, .RGB_Sliders)
	hsv_r, _ := layout.find(rects, .HSV_Sliders)
	hint_r, _ := layout.find(rects, .Hint)
	history_r, _ := layout.find(rects, .History)

	SLIDER_SPACING :: 30
	rx := rc.x
	rw := rc.w
	slider_w := rw - 80
	slider_x := rx + 24

	preview_rect := rl.Rectangle{preview_r.x, preview_r.y, preview_r.w, 100}
	border_rect := rl.Rectangle{preview_rect.x - 1, preview_rect.y - 1, preview_rect.width + 2, preview_rect.height + 2}
	rl.DrawRectangleRounded(border_rect, 0.1, 8, ui.OVERLAY)
	rl.DrawRectangleRounded(preview_rect, 0.1, 8, app.bg_slot)

	sample_text :: "Aa Sample"
	stw := rl.MeasureText(sample_text, 28)
	rl.DrawText(sample_text, i32(preview_rect.x) + (i32(preview_rect.width) - stw) / 2, i32(preview_rect.y) + 36, 28, app.fg_slot)

	contrast_y := contrast_r.y
	ratio := color.contrast_ratio(app.fg_slot, app.bg_slot)
	rating := color.wcag_rating(ratio)
	summary: cstring
	summary_clr: rl.Color
	if rating.aaa_normal {
		summary = "Excellent readability"
		summary_clr = ui.GREEN
	} else if rating.aa_normal {
		summary = "Readable"
		summary_clr = ui.YELLOW
	} else if rating.aa_large {
		summary = "Large text only"
		summary_clr = ui.YELLOW
	} else {
		summary = "Poor readability"
		summary_clr = ui.RED
	}
	ratio_text := fmt.ctprintf("Contrast: %.1f:1", ratio)
	ratio_tw := rl.MeasureText(ratio_text, 14)
	rl.DrawText(ratio_text, i32(rx), i32(contrast_y) + 4, 14, ui.TEXT_CLR)
	rl.DrawText(summary, i32(rx) + ratio_tw + 12, i32(contrast_y) + 6, 12, summary_clr)

	cb_safe, cb_risky := color.cvd_pair_safety(app.fg_slot, app.bg_slot)
	cb_label: cstring
	cb_clr: rl.Color
	if cb_safe {
		cb_label = "CB: Safe"
		cb_clr = ui.GREEN
	} else {
		names := color.CVD_NAMES
		cb_label = fmt.ctprintf("CB: %s risk", names[cb_risky])
		cb_clr = ui.YELLOW
	}
	sum_tw := rl.MeasureText(summary, 12)
	rl.DrawText(cb_label, i32(rx) + ratio_tw + 12 + sum_tw + 12, i32(contrast_y) + 6, 12, cb_clr)

	cvd_btn := rl.Rectangle{rx + rw - 166, contrast_y, 86, 20}
	cvd_names: [4]cstring
	for ti in color.CvdType do cvd_names[int(ti)] = color.CVD_NAMES[ti]
	ui.dropdown_draw(cvd_btn, cvd_names[:], int(app.cvd_mode), app.cvd_open, mouse)

	fg_well := rl.Rectangle{rx + rw - 76, contrast_y - 2, 32, 24}
	bg_well := rl.Rectangle{fg_well.x + 40, fg_well.y, 32, 24}

	fg_border := app.active_slot == .FG ? ui.ACCENT : rl.Color{255, 255, 255, 40}
	bg_border := app.active_slot == .BG ? ui.ACCENT : rl.Color{255, 255, 255, 40}
	rl.DrawRectangleRounded({fg_well.x - 2, fg_well.y - 2, fg_well.width + 4, fg_well.height + 4}, 0.2, 4, fg_border)
	rl.DrawRectangleRounded(fg_well, 0.2, 4, app.fg_slot)
	rl.DrawRectangleRounded({bg_well.x - 2, bg_well.y - 2, bg_well.width + 4, bg_well.height + 4}, 0.2, 4, bg_border)
	rl.DrawRectangleRounded(bg_well, 0.2, 4, app.bg_slot)
	fg_lbl_clr := app.active_slot == .FG ? ui.ACCENT : ui.SUBTEXT
	bg_lbl_clr := app.active_slot == .BG ? ui.ACCENT : ui.SUBTEXT
	rl.DrawText("FG", i32(fg_well.x) + 8, i32(fg_well.y + fg_well.height) + 3, 10, fg_lbl_clr)
	rl.DrawText("BG", i32(bg_well.x) + 8, i32(bg_well.y + bg_well.height) + 3, 10, bg_lbl_clr)

	hex_y := hex_r.y
	hex_field := rl.Rectangle{rx, hex_y, rw - 90, 32}
	copy_btn := rl.Rectangle{hex_field.x + hex_field.width + 8, hex_field.y, 78, 32}

	ui.text_input_draw(&app.hex_input, hex_field, 18, "#")

	copy_hover := rl.CheckCollisionPointRec(mouse, copy_btn)
	copy_bg_clr := copy_hover ? ui.ACCENT : ui.OVERLAY
	copy_text_clr := copy_hover ? ui.BG : ui.TEXT_CLR
	rl.DrawRectangleRounded(copy_btn, 0.3, 6, copy_bg_clr)
	cbx, cby := i32(copy_btn.x), i32(copy_btn.y)
	rl.DrawRectangleLines(cbx + 8, cby + 7, 10, 13, copy_text_clr)
	rl.DrawRectangleLines(cbx + 12, cby + 11, 10, 13, copy_text_clr)
	if app.copied_timer > 0 {
		rl.DrawText("Done", cbx + 26, cby + 8, 13, copy_text_clr)
	} else {
		rl.DrawText("Copy", cbx + 26, cby + 8, 13, copy_text_clr)
	}

	rgb_labels := [3]cstring{"R", "G", "B"}
	dc := display_color
	rgb_values := [3]u8{cur_color.r, cur_color.g, cur_color.b}
	left_colors := [3]rl.Color{{0, dc.g, dc.b, 255}, {dc.r, 0, dc.b, 255}, {dc.r, dc.g, 0, 255}}
	right_colors := [3]rl.Color{{255, dc.g, dc.b, 255}, {dc.r, 255, dc.b, 255}, {dc.r, dc.g, 255, 255}}

	for i in 0 ..< 3 {
		sr := rl.Rectangle{slider_x, rgb_r.y + f32(i) * SLIDER_SPACING, slider_w, 16}
		ui.color_slider_draw(rx, sr, f32(rgb_values[i]) / 255, left_colors[i], right_colors[i], display_color, rgb_labels[i], fmt.ctprintf("%d", rgb_values[i]))
	}

	hsv_labels := [3]cstring{"H", "S", "V"}
	hsv_ratios := [3]f32{app.cs.hue / 360, app.cs.sat, app.cs.val}
	hsv_left := [3]rl.Color{{}, rl.ColorFromHSV(app.cs.hue, 0, app.cs.val), rl.ColorFromHSV(app.cs.hue, app.cs.sat, 0)}
	hsv_right := [3]rl.Color{{}, rl.ColorFromHSV(app.cs.hue, 1, app.cs.val), rl.ColorFromHSV(app.cs.hue, app.cs.sat, 1)}
	hsv_texts := [3]cstring{
		fmt.ctprintf("%.0f\u00b0", app.cs.hue),
		fmt.ctprintf("%.0f%%", app.cs.sat * 100),
		fmt.ctprintf("%.0f%%", app.cs.val * 100),
	}

	for i in 0 ..< 3 {
		sr := rl.Rectangle{slider_x, hsv_r.y + f32(i) * SLIDER_SPACING, slider_w, 16}
		tex := i == 0 ? app.hue_tex : rl.Texture2D{}
		ui.color_slider_draw(rx, sr, hsv_ratios[i], hsv_left[i], hsv_right[i], display_color, hsv_labels[i], hsv_texts[i], tex)
	}

	rl.DrawText("\u2318+C copy  \u2318+V paste  \u2318+Z undo  \u2318+S save", i32(rx), i32(hint_r.y), 12, ui.DIM)

	rl.DrawText("History", i32(rx), i32(history_r.y), 12, ui.DIM)
	if app.history_count > 0 {
		for i in 0 ..< app.history_count {
			c := data.history_get(app.history[:], app.history_count, app.history_head, i)
			hist_x := rx + f32(i) * 22
			hr := rl.Rectangle{hist_x, history_r.y + 16, 18, 18}
			hovering := rl.CheckCollisionPointRec(mouse, hr)
			if hovering {
				rl.DrawRectangleRounded({hr.x - 1, hr.y - 1, hr.width + 2, hr.height + 2}, 0.2, 4, ui.ACCENT)
			}
			rl.DrawRectangleRounded(hr, 0.2, 4, c)
		}
	}
}

draw_palette_section :: proc(app: ^AppState, mouse: rl.Vector2, display_color: rl.Color, rects: []layout.Rect) {
	palette_r, _ := layout.find(rects, .Palette)
	export_r, _ := layout.find(rects, .Export_Button)
	root_r, _ := layout.find(rects, .Root)

	pal_x := palette_r.x
	pal_w := palette_r.w
	cpr := cols_per_row(palette_r)

	if app.extracted_count > 0 {
		ext_y := palette_r.y
		rl.DrawText("Extracted", i32(pal_x), i32(ext_y) - 14, 12, ui.DIM)
		ui.draw_color_swatch_row(app.extracted[:app.extracted_count], pal_x, ext_y, 26, 4, mouse)
	}

	palette_base_y := palette_r.y + (app.extracted_count > 0 ? f32(30) : f32(0))
	palette_label_y := palette_base_y

	rl.DrawLine(i32(pal_x), i32(palette_label_y) - 8, i32(pal_x + pal_w), i32(palette_label_y) - 8, ui.OVERLAY)
	rl.DrawText("Palette", i32(pal_x), i32(palette_label_y), 16, ui.TEXT_CLR)

	swatch_start_y := palette_label_y + 24

	if app.palette_count > 0 {
		ui.button_draw({pal_x + 76, palette_label_y - 2, 64, 20}, "Clear All", mouse, 10)
	} else {
		rl.DrawText("click + or \u2318+S to save colors", i32(pal_x) + 76, i32(palette_label_y) + 3, 12, ui.DIM)
	}

	for i in 0 ..< app.palette_count {
		sr := data.swatch_rect(i, swatch_start_y, cpr, pal_x)
		c := app.palette[i]

		is_drag_source := app.palette_dragging && i == app.palette_drag
		is_drop_target := app.palette_dragging && i == app.palette_hover && i != app.palette_drag

		if is_drop_target {
			rl.DrawRectangleRounded({sr.x - 2, sr.y - 2, sr.width + 4, sr.height + 4}, 0.15, 4, ui.ACCENT)
		} else if i == app.palette_hover && !app.palette_dragging {
			rl.DrawRectangleRounded({sr.x - 2, sr.y - 2, sr.width + 4, sr.height + 4}, 0.15, 4, ui.ACCENT)
		} else {
			rl.DrawRectangleRounded({sr.x - 1, sr.y - 1, sr.width + 2, sr.height + 2}, 0.15, 4, {255, 255, 255, 15})
		}

		alpha: u8 = is_drag_source ? 100 : 255
		rl.DrawRectangleRounded(sr, 0.15, 4, {c.r, c.g, c.b, alpha})

		if i == app.palette_hover && !app.palette_dragging {
			xr := rl.Rectangle{sr.x + sr.width - 12, sr.y - 4, 16, 16}
			xr_hover := rl.CheckCollisionPointRec(mouse, xr)
			rl.DrawRectangleRounded(xr, 0.3, 4, xr_hover ? ui.RED : rl.Color{60, 60, 80, 230})
			rl.DrawText("x", i32(xr.x) + 4, i32(xr.y) + 1, 12, rl.WHITE)
		}

		if app.cvd_mode != .None {
			has_conflict := false
			for j in 0 ..< app.palette_count {
				if j == i do continue
				if !color.colors_distinguishable(c, app.palette[j], app.cvd_mode) {
					has_conflict = true
					break
				}
			}
			if has_conflict {
				wx := i32(sr.x) + 1
				wy := i32(sr.y + sr.height) - 12
				rl.DrawTriangle(
					{f32(wx), f32(wy + 10)},
					{f32(wx + 10), f32(wy + 10)},
					{f32(wx + 5), f32(wy)},
					ui.YELLOW,
				)
				rl.DrawText("!", wx + 3, wy + 1, 8, ui.BG)
			}
		}
	}

	if app.palette_dragging && app.palette_drag >= 0 && app.palette_drag < app.palette_count {
		dc := app.palette[app.palette_drag]
		gr := rl.Rectangle{mouse.x - data.SWATCH_SZ / 2, mouse.y - data.SWATCH_SZ / 2, data.SWATCH_SZ, data.SWATCH_SZ}
		rl.DrawRectangleRounded(gr, 0.15, 4, {dc.r, dc.g, dc.b, 180})
		rl.DrawRectangleRounded({gr.x - 1, gr.y - 1, gr.width + 2, gr.height + 2}, 0.15, 4, {255, 255, 255, 60})
	}

	add_btn := data.swatch_rect(app.palette_count, swatch_start_y, cpr, pal_x)
	add_btn_hover := app.palette_count < data.MAX_PALETTE && rl.CheckCollisionPointRec(mouse, add_btn)
	if app.palette_count < data.MAX_PALETTE {
		rl.DrawRectangleRounded({add_btn.x - 1, add_btn.y - 1, add_btn.width + 2, add_btn.height + 2}, 0.15, 4, add_btn_hover ? ui.ACCENT : rl.Color{255, 255, 255, 15})
		rl.DrawRectangleRounded(add_btn, 0.15, 4, display_color)
		rl.DrawRectangleRounded(add_btn, 0.15, 4, {0, 0, 0, 90})
		pcx := i32(add_btn.x) + data.SWATCH_SZ / 2
		pcy := i32(add_btn.y) + data.SWATCH_SZ / 2
		plus_clr := add_btn_hover ? rl.Color{255, 255, 255, 255} : rl.Color{255, 255, 255, 180}
		rl.DrawRectangle(pcx - 7, pcy - 1, 14, 3, plus_clr)
		rl.DrawRectangle(pcx - 1, pcy - 7, 3, 14, plus_clr)
	}

	if app.palette_hover >= 0 {
		pc := app.palette[app.palette_hover]
		tip := ui.format_hex_cstr(pc)
		sr := data.swatch_rect(app.palette_hover, swatch_start_y, cpr, pal_x)
		tx := i32(sr.x)
		ty := i32(sr.y) - 20
		tw := rl.MeasureText(tip, 12)
		rl.DrawRectangleRounded({f32(tx - 4), f32(ty - 2), f32(tw + 8), 18}, 0.3, 4, ui.SURFACE)
		rl.DrawText(tip, tx, ty, 12, ui.TEXT_CLR)
	}

	ui.button_draw(to_rl_rect(export_r), "Export", mouse, 14)
	rl.DrawText("Drop an image to extract colors", i32(export_r.x) + 136, i32(export_r.y) + 7, 12, ui.DIM)
}

draw_export_panel :: proc(app: ^AppState, mouse: rl.Vector2, rects: []layout.Rect) {
	if !app.export_open do return

	root_r, _ := layout.find(rects, .Root)

	panel_w: f32 = 400
	panel_h: f32 = 220
	ui.modal_draw(root_r.w, root_r.h, panel_w, panel_h, "Export Palette")

	panel_x := root_r.w / 2 - panel_w / 2
	panel_y := root_r.h / 2 - panel_h / 2

	rl.DrawText("Filename:", i32(panel_x) + 20, i32(panel_y) + 42, 12, ui.SUBTEXT)
	name_field := rl.Rectangle{panel_x + 20, panel_y + 56, panel_w - 40, 28}
	ui.text_input_draw(&app.export_name, name_field, 14)

	rl.DrawText("Format:", i32(panel_x) + 20, i32(panel_y) + 92, 12, ui.SUBTEXT)
	format_rect := rl.Rectangle{panel_x + 20, panel_y + 106, panel_w - 40, 28}
	fmts := EXPORT_FORMATS
	ui.dropdown_draw(format_rect, fmts[:], app.export_format, app.export_fmt_open, mouse)

	save_rect := rl.Rectangle{panel_x + 20, panel_y + 150, 110, 30}
	copy_export := rl.Rectangle{panel_x + 140, panel_y + 150, 110, 30}
	cancel_rect := rl.Rectangle{panel_x + panel_w - 90, panel_y + 150, 70, 30}

	ui.button_draw(save_rect, "Save File", mouse, 13)
	ui.button_draw(copy_export, "Copy List", mouse, 13)
	ui.button_draw(cancel_rect, "Cancel", mouse, 13)

	if app.palette_count == 0 {
		rl.DrawText("Add colors to palette first", i32(panel_x) + 20, i32(panel_y) + 192, 12, ui.RED)
	}
}



draw_extract_modal :: proc(app: ^AppState, mouse: rl.Vector2, rects: []layout.Rect) {
	if !app.extract_open || !app.extract_has_img do return

	root_r, _ := layout.find(rects, .Root)

	panel_w: f32 = 520
	panel_h: f32 = 380
	ui.modal_draw(root_r.w, root_r.h, panel_w, panel_h, "Extract Colors")

	px := root_r.w / 2 - panel_w / 2
	py := root_r.h / 2 - panel_h / 2

	img_area := rl.Rectangle{px + 20, py + 44, panel_w - 40, 180}
	rl.DrawRectangleRounded(img_area, 0.05, 4, ui.OVERLAY)

	iw := f32(app.extract_tex.width)
	ih := f32(app.extract_tex.height)
	scale := min((img_area.width - 8) / iw, (img_area.height - 8) / ih)
	draw_w := iw * scale
	draw_h := ih * scale
	draw_x := img_area.x + (img_area.width - draw_w) / 2
	draw_y := img_area.y + (img_area.height - draw_h) / 2
	rl.DrawTexturePro(
		app.extract_tex,
		{0, 0, iw, ih},
		{draw_x, draw_y, draw_w, draw_h},
		{0, 0}, 0, rl.WHITE,
	)

	count_y := py + 234
	rl.DrawText("Colors:", i32(px) + 20, i32(count_y) + 4, 14, ui.SUBTEXT)
	ui.stepper_draw(px + 90, count_y, app.extracted_count, 2, data.EXTRACT_COUNT, mouse, font_size = 14, btn_w = 24, btn_h = 22, gap = 52)

	swatch_y := count_y + 32
	for i in 0 ..< app.extracted_count {
		sx := px + 20 + f32(i) * 36
		sr := rl.Rectangle{sx, swatch_y, 30, 30}
		hovering := rl.CheckCollisionPointRec(mouse, sr)
		if hovering {
			rl.DrawRectangleRounded({sr.x - 2, sr.y - 2, sr.width + 4, sr.height + 4}, 0.15, 4, ui.ACCENT)
		} else {
			rl.DrawRectangleRounded({sr.x - 1, sr.y - 1, sr.width + 2, sr.height + 2}, 0.15, 4, {255, 255, 255, 15})
		}
		rl.DrawRectangleRounded(sr, 0.15, 4, app.extracted[i])

		if hovering {
			tip := ui.format_hex_cstr(app.extracted[i])
			rl.DrawText(tip, i32(sr.x), i32(sr.y) - 16, 11, ui.TEXT_CLR)
		}
	}

	btn_y := swatch_y + 44
	ui.button_draw({px + 20, btn_y, 100, 30}, "Accept", mouse, 13)
	ui.button_draw({px + 130, btn_y, 140, 30}, "Add to Palette", mouse, 13)
	ui.button_draw({px + panel_w - 90, btn_y, 70, 30}, "Cancel", mouse, 13)
}
