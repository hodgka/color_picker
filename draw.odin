package color_picker

import rl "vendor:raylib"
import "core:fmt"
import "core:math"

draw_frame :: proc(app: ^AppState, mouse: rl.Vector2, color: rl.Color, display_color: rl.Color) {
	L := app.layout
	slider_w := L.slider_w
	slider_x := L.slider_x

	rl.BeginDrawing()
	rl.ClearBackground(BG)

	// ── Header ──
	rl.DrawText("Color Picker", L.margin, 14, 22, TEXT_CLR)

	// ── Left column: Picker ──
	if app.picker_mode == .Square {
		rl.DrawRectangle(L.sv_x - 1, L.sv_y - 1, L.sv_size + 2, L.sv_size + 2, OVERLAY)
		rl.DrawTexture(app.sv_tex, L.sv_x, L.sv_y, rl.WHITE)

		sx := i32(f32(L.sv_x) + app.cs.sat * f32(L.sv_size))
		sy := i32(f32(L.sv_y) + (1 - app.cs.val) * f32(L.sv_size))
		rl.DrawCircle(sx, sy, 8, {0, 0, 0, 100})
		rl.DrawCircleLines(sx, sy, 7, rl.WHITE)
		rl.DrawCircleLines(sx, sy, 8, {0, 0, 0, 200})

		hue_bar_y := L.sv_y + L.sv_size + 14
		rl.DrawRectangle(L.sv_x - 1, hue_bar_y - 1, L.sv_size + 2, HUE_BAR_H + 2, OVERLAY)
		rl.DrawTexturePro(app.hue_tex, {0, 0, 360, 1}, {f32(L.sv_x), f32(hue_bar_y), f32(L.sv_size), HUE_BAR_H}, {0, 0}, 0, rl.WHITE)

		hx := i32(f32(L.sv_x) + app.cs.hue / 360 * f32(L.sv_size))
		rl.DrawRectangle(hx - 2, hue_bar_y - 2, 5, HUE_BAR_H + 4, rl.WHITE)
		rl.DrawRectangleLines(hx - 3, hue_bar_y - 3, 7, HUE_BAR_H + 6, {0, 0, 0, 180})
	} else {
		rl.DrawTexture(app.wheel_tex, L.picker_x, L.picker_y, rl.WHITE)
		center_x := f32(L.picker_x) + f32(L.picker_size) / 2
		center_y := f32(L.picker_y) + f32(L.picker_size) / 2
		radius := f32(L.picker_size) / 2

		offsets, off_count := harmony_hue_offsets(HarmonyType(app.harmony_type), app.harmony_req)
		for i in 0 ..< off_count {
			angle := (app.cs.hue + offsets[i]) * math.PI / 180.0
			px := center_x + math.cos(angle) * app.cs.sat * radius
			py := center_y + math.sin(angle) * app.cs.sat * radius
			rl.DrawCircleLines(i32(px), i32(py), 9, {0, 0, 0, 200})
			rl.DrawCircleLines(i32(px), i32(py), 8, rl.WHITE)
			rl.DrawCircleLines(i32(px), i32(py), 7, {0, 0, 0, 200})
			if i > 0 {
				prev_angle := (app.cs.hue + offsets[i - 1]) * math.PI / 180.0
				prev_x := center_x + math.cos(prev_angle) * app.cs.sat * radius
				prev_y := center_y + math.sin(prev_angle) * app.cs.sat * radius
				rl.DrawLine(i32(prev_x), i32(prev_y), i32(px), i32(py), {0, 0, 0, 160})
				rl.DrawLine(i32(prev_x) + 1, i32(prev_y), i32(px) + 1, i32(py), {255, 255, 255, 60})
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

	// ── Controls below picker: toggle + eyedropper ──
	controls_y := L.picker_y + L.picker_size + 12
	toggle_rect := rl.Rectangle{f32(L.picker_x), f32(controls_y), 140, 26}
	mode_idx := draw_toggle(toggle_rect, {"Wheel", "Square"}, int(app.picker_mode), mouse)
	app.picker_mode = PickerMode(mode_idx)

	eye_btn := rl.Rectangle{toggle_rect.x + toggle_rect.width + 10, f32(controls_y), 90, 26}
	if eye_clicked, _ := draw_button(eye_btn, "Eyedropper", mouse, 12); eye_clicked {
		rl.SetWindowState({.WINDOW_HIDDEN})
		rl.WaitTime(1.0)
		captured := eyedropper_capture()
		rl.ClearWindowState({.WINDOW_HIDDEN})
		if captured {
			app.eyedropper_img = rl.LoadImage(SCREENSHOT_PATH)
			if app.eyedropper_img.data != nil {
				app.eyedropper_tex = rl.LoadTextureFromImage(app.eyedropper_img)
				app.eyedropper_active = true
			} else {
				app.error_msg = "Failed to load screenshot"
				app.error_timer = 8
			}
		} else {
			app.error_msg = "Screen capture failed. Grant Screen Recording permission in System Settings."
			app.error_timer = 10
		}
	}

	// ── Harmony dropdown button + swatches ──
	harmony_names_list: [8]cstring
	for ht in HarmonyType {
		harmony_names_list[int(ht)] = HARMONY_NAMES[ht]
	}
	dropdown_rect := rl.Rectangle{f32(L.picker_x), f32(L.harmony_section_y), 160, 28}
	harmony_toggled_this_frame := false

	if rl.IsMouseButtonPressed(.LEFT) && rl.CheckCollisionPointRec(mouse, dropdown_rect) {
		app.harmony_open = !app.harmony_open
		harmony_toggled_this_frame = true
	}

	btn_bg := app.harmony_open || rl.CheckCollisionPointRec(mouse, dropdown_rect) ? rl.Color{58, 58, 82, 255} : OVERLAY
	rl.DrawRectangleRounded(dropdown_rect, 0.3, 6, btn_bg)
	if app.harmony_type >= 0 && app.harmony_type < len(harmony_names_list) {
		rl.DrawText(harmony_names_list[app.harmony_type], i32(dropdown_rect.x) + 10, i32(dropdown_rect.y) + 6, 14, TEXT_CLR)
	}
	arrow_x := dropdown_rect.x + dropdown_rect.width - 18
	arrow_cy := dropdown_rect.y + dropdown_rect.height / 2
	if app.harmony_open {
		rl.DrawTriangle({arrow_x, arrow_cy + 3}, {arrow_x + 8, arrow_cy + 3}, {arrow_x + 4, arrow_cy - 3}, SUBTEXT)
	} else {
		rl.DrawTriangle({arrow_x, arrow_cy - 3}, {arrow_x + 8, arrow_cy - 3}, {arrow_x + 4, arrow_cy + 3}, SUBTEXT)
	}

	if !app.harmony_open {
		harm_label_y := f32(L.harmony_section_y + 34)
		rl.DrawText("Harmonies", L.picker_x, i32(harm_label_y), 12, DIM)

		ht := HarmonyType(app.harmony_type)
		if harmony_is_variable(ht) {
			minus_h := rl.Rectangle{f32(L.picker_x + 70), harm_label_y - 2, 18, 16}
			plus_h := rl.Rectangle{minus_h.x + 42, harm_label_y - 2, 18, 16}
			if m_click, _ := draw_button(minus_h, "-", mouse, 12, disabled = app.harmony_count <= 2); m_click {
				app.harmony_req -= 1
				update_harmony(app)
			}
			rl.DrawText(fmt.ctprintf("%d", app.harmony_count), i32(minus_h.x) + 22, i32(harm_label_y), 12, TEXT_CLR)
			if p_click, _ := draw_button(plus_h, "+", mouse, 12, disabled = app.harmony_count >= MAX_HARMONY); p_click {
				app.harmony_req += 1
				update_harmony(app)
			}
		}

		harm_y := harm_label_y + 18
		harm_display: [MAX_HARMONY]rl.Color
		for hi in 0 ..< app.harmony_count {
			harm_display[hi] = app.cvd_mode != .None ? simulate_cvd(app.harmony_colors[hi], app.cvd_mode) : app.harmony_colors[hi]
		}
		clicked := draw_color_swatch_row(harm_display[:app.harmony_count], f32(L.picker_x), harm_y, 28, 3, mouse)
		if clicked >= 0 {
			color_set_rgb(&app.cs, app.harmony_colors[clicked])
			commit_color(app)
		}

		shade_label_y := harm_y + 40
		rl.DrawText("Shades", L.picker_x, i32(shade_label_y), 12, DIM)

		minus_s := rl.Rectangle{f32(L.picker_x + 50), shade_label_y - 2, 18, 16}
		plus_s := rl.Rectangle{minus_s.x + 42, shade_label_y - 2, 18, 16}
		if ms_click, _ := draw_button(minus_s, "-", mouse, 12, disabled = app.shade_count <= 3); ms_click {
			app.shade_req -= 1
			update_shades(app)
		}
		rl.DrawText(fmt.ctprintf("%d", app.shade_count), i32(minus_s.x) + 22, i32(shade_label_y), 12, TEXT_CLR)
		if ps_click, _ := draw_button(plus_s, "+", mouse, 12, disabled = app.shade_count >= MAX_SHADES); ps_click {
			app.shade_req += 1
			update_shades(app)
		}

		dark_btn := rl.Rectangle{plus_s.x + 30, shade_label_y - 2, 36, 16}
		light_btn := rl.Rectangle{dark_btn.x + 42, shade_label_y - 2, 36, 16}
		if dk_click, _ := draw_button(dark_btn, "Dark", mouse, 10); dk_click {
			app.shade_v_min = max(app.shade_v_min - 0.1, 0)
			app.shade_v_max = max(app.shade_v_max - 0.1, app.shade_v_min + 0.2)
			update_shades(app)
		}
		if lt_click, _ := draw_button(light_btn, "Light", mouse, 10); lt_click {
			app.shade_v_max = min(app.shade_v_max + 0.1, 1)
			app.shade_v_min = min(app.shade_v_min + 0.1, app.shade_v_max - 0.2)
			update_shades(app)
		}

		shade_y := shade_label_y + 18
		shade_display: [MAX_SHADES]rl.Color
		for si in 0 ..< app.shade_count {
			shade_display[si] = app.cvd_mode != .None ? simulate_cvd(app.shades[si], app.cvd_mode) : app.shades[si]
		}
		shade_clicked := draw_color_swatch_row(shade_display[:app.shade_count], f32(L.picker_x), shade_y, 28, 3, mouse)
		if shade_clicked >= 0 {
			color_set_rgb(&app.cs, app.shades[shade_clicked])
			commit_color(app)
		}
	}

	// ── Right column: Preview (contrast) ──
	preview_rect := rl.Rectangle{f32(L.right_x), f32(L.preview_y), f32(L.right_w), f32(L.preview_h)}
	border_rect := rl.Rectangle{preview_rect.x - 1, preview_rect.y - 1, preview_rect.width + 2, preview_rect.height + 2}
	rl.DrawRectangleRounded(border_rect, 0.1, 8, OVERLAY)
	rl.DrawRectangleRounded(preview_rect, 0.1, 8, app.bg_slot)

	sample_text :: "Aa Sample"
	stw := rl.MeasureText(sample_text, 28)
	rl.DrawText(sample_text, i32(preview_rect.x) + (i32(preview_rect.width) - stw) / 2, i32(preview_rect.y) + 36, 28, app.fg_slot)

	// ── Contrast info + FG/BG wells ──
	ratio := contrast_ratio(app.fg_slot, app.bg_slot)
	rating := wcag_rating(ratio)
	summary: cstring
	summary_clr: rl.Color
	if rating.aaa_normal {
		summary = "Excellent readability"
		summary_clr = GREEN
	} else if rating.aa_normal {
		summary = "Readable"
		summary_clr = YELLOW
	} else if rating.aa_large {
		summary = "Large text only"
		summary_clr = YELLOW
	} else {
		summary = "Poor readability"
		summary_clr = RED
	}
	ratio_text := fmt.ctprintf("Contrast: %.1f:1", ratio)
	ratio_tw := rl.MeasureText(ratio_text, 14)
	rl.DrawText(ratio_text, L.right_x, L.contrast_info_y + 4, 14, TEXT_CLR)
	rl.DrawText(summary, L.right_x + ratio_tw + 12, L.contrast_info_y + 6, 12, summary_clr)

	cb_safe, cb_risky := cvd_pair_safety(app.fg_slot, app.bg_slot)
	cb_label: cstring
	cb_clr: rl.Color
	if cb_safe {
		cb_label = "CB: Safe"
		cb_clr = GREEN
	} else {
		names := CVD_NAMES
		cb_label = fmt.ctprintf("CB: %s risk", names[cb_risky])
		cb_clr = YELLOW
	}
	sum_tw := rl.MeasureText(summary, 12)
	rl.DrawText(cb_label, L.right_x + ratio_tw + 12 + sum_tw + 12, L.contrast_info_y + 6, 12, cb_clr)

	cvd_btn_x := f32(L.right_x + L.right_w - 166)
	cvd_names_arr := CVD_NAMES
	cvd_btn := rl.Rectangle{cvd_btn_x, f32(L.contrast_info_y), 86, 20}
	cvd_hover := rl.CheckCollisionPointRec(mouse, cvd_btn)
	cvd_bg := app.cvd_mode != .None ? ACCENT : (cvd_hover ? rl.Color{58, 58, 82, 255} : OVERLAY)
	cvd_txt := app.cvd_mode != .None ? BG : (cvd_hover ? TEXT_CLR : SUBTEXT)
	rl.DrawRectangleRounded(cvd_btn, 0.3, 4, cvd_bg)
	rl.DrawText(cvd_names_arr[app.cvd_mode], i32(cvd_btn.x) + 6, i32(cvd_btn.y) + 3, 11, cvd_txt)
	if cvd_hover && rl.IsMouseButtonPressed(.LEFT) && !app.cvd_open {
		app.cvd_open = true
	} else if cvd_hover && rl.IsMouseButtonPressed(.LEFT) && app.cvd_open {
		app.cvd_open = false
	}

	fg_well := rl.Rectangle{f32(L.right_x + L.right_w - 76), f32(L.contrast_info_y - 2), 32, 24}
	bg_well := rl.Rectangle{fg_well.x + 40, fg_well.y, 32, 24}

	fg_border := app.active_slot == .FG ? ACCENT : rl.Color{255, 255, 255, 40}
	bg_border := app.active_slot == .BG ? ACCENT : rl.Color{255, 255, 255, 40}
	rl.DrawRectangleRounded({fg_well.x - 2, fg_well.y - 2, fg_well.width + 4, fg_well.height + 4}, 0.2, 4, fg_border)
	rl.DrawRectangleRounded(fg_well, 0.2, 4, app.fg_slot)
	rl.DrawRectangleRounded({bg_well.x - 2, bg_well.y - 2, bg_well.width + 4, bg_well.height + 4}, 0.2, 4, bg_border)
	rl.DrawRectangleRounded(bg_well, 0.2, 4, app.bg_slot)
	fg_lbl_clr := app.active_slot == .FG ? ACCENT : SUBTEXT
	bg_lbl_clr := app.active_slot == .BG ? ACCENT : SUBTEXT
	rl.DrawText("FG", i32(fg_well.x) + 8, i32(fg_well.y + fg_well.height) + 3, 10, fg_lbl_clr)
	rl.DrawText("BG", i32(bg_well.x) + 8, i32(bg_well.y + bg_well.height) + 3, 10, bg_lbl_clr)

	// ── Hex field ──
	hex_field := rl.Rectangle{f32(L.right_x), f32(L.hex_field_y), f32(L.right_w - 90), 32}
	copy_btn := rl.Rectangle{hex_field.x + hex_field.width + 8, hex_field.y, 78, 32}

	hex_bg := app.hex_focused ? rl.Color{58, 58, 82, 255} : OVERLAY
	rl.DrawRectangleRounded(hex_field, 0.3, 6, hex_bg)
	if app.hex_focused {
		rl.DrawRectangleRounded(
			{hex_field.x - 1, hex_field.y - 1, hex_field.width + 2, hex_field.height + 2},
			0.3, 6, ACCENT,
		)
		rl.DrawRectangleRounded(hex_field, 0.3, 6, hex_bg)
	}

	hash_x := i32(hex_field.x) + 10
	hash_y := i32(hex_field.y) + 7
	rl.DrawText("#", hash_x, hash_y, 18, SUBTEXT)
	hex_text_x := hash_x + 14

	if app.hex_focused && app.hex_select_all && app.cs.hex_len > 0 {
		rl.DrawRectangle(hex_text_x, hash_y, i32(app.cs.hex_len) * 12, 18, {137, 180, 250, 80})
	}
	for j in 0 ..< app.cs.hex_len {
		ch_str: [2]u8 = {app.cs.hex_buf[j], 0}
		rl.DrawText(cstring(&ch_str[0]), hex_text_x + i32(j) * 12, hash_y, 18, TEXT_CLR)
	}
	if app.hex_focused && int(app.hex_blink * 1.8) % 2 == 0 && !app.hex_select_all {
		rl.DrawRectangle(hex_text_x + i32(app.hex_cursor) * 12, hash_y, 2, 18, ACCENT)
	}

	copy_hover := rl.CheckCollisionPointRec(mouse, copy_btn)
	copy_bg_clr := copy_hover ? ACCENT : OVERLAY
	copy_text_clr := copy_hover ? BG : TEXT_CLR
	rl.DrawRectangleRounded(copy_btn, 0.3, 6, copy_bg_clr)
	cbx, cby := i32(copy_btn.x), i32(copy_btn.y)
	rl.DrawRectangleLines(cbx + 8, cby + 7, 10, 13, copy_text_clr)
	rl.DrawRectangleLines(cbx + 12, cby + 11, 10, 13, copy_text_clr)
	if app.copied_timer > 0 {
		rl.DrawText("Done", cbx + 26, cby + 8, 13, copy_text_clr)
	} else {
		rl.DrawText("Copy", cbx + 26, cby + 8, 13, copy_text_clr)
	}

	// ── RGB sliders ──
	rgb_labels := [3]cstring{"R", "G", "B"}
	dc := display_color
	rgb_values := [3]u8{color.r, color.g, color.b}
	left_colors := [3]rl.Color{{0, dc.g, dc.b, 255}, {dc.r, 0, dc.b, 255}, {dc.r, dc.g, 0, 255}}
	right_colors := [3]rl.Color{{255, dc.g, dc.b, 255}, {dc.r, 255, dc.b, 255}, {dc.r, dc.g, 255, 255}}

	for i in 0 ..< 3 {
		sy := L.slider_base_y + i32(i) * L.slider_spacing
		sx := i32(slider_x)
		sw := i32(slider_w)
		rl.DrawText(rgb_labels[i], L.right_x, sy + 1, 16, SUBTEXT)
		rl.DrawRectangle(sx, sy + 2, sw, 12, OVERLAY)
		rl.DrawRectangleGradientH(sx + 1, sy + 3, sw - 2, 10, left_colors[i], right_colors[i])
		knob_x := f32(sx) + f32(rgb_values[i]) / 255 * f32(sw)
		rl.DrawCircle(i32(knob_x), sy + 8, 9, rl.WHITE)
		rl.DrawCircle(i32(knob_x), sy + 8, 7, display_color)
		rl.DrawCircleLines(i32(knob_x), sy + 8, 9, {0, 0, 0, 80})
		rl.DrawText(fmt.ctprintf("%d", rgb_values[i]), sx + sw + 16, sy + 1, 16, SUBTEXT)
	}

	// ── HSV sliders ──
	hsv_labels := [3]cstring{"H", "S", "V"}
	hsv_ratios := [3]f32{app.cs.hue / 360, app.cs.sat, app.cs.val}
	for i in 0 ..< 3 {
		sy := L.hsv_slider_y + i32(i) * L.slider_spacing
		sx := i32(slider_x)
		sw := i32(slider_w)
		rl.DrawText(hsv_labels[i], L.right_x, sy + 1, 16, SUBTEXT)
		rl.DrawRectangle(sx, sy + 2, sw, 12, OVERLAY)
		switch i {
		case 0:
			rl.DrawTexturePro(app.hue_tex, {0, 0, 360, 1}, {f32(sx + 1), f32(sy + 3), f32(sw - 2), 10}, {0, 0}, 0, rl.WHITE)
		case 1:
			rl.DrawRectangleGradientH(sx + 1, sy + 3, sw - 2, 10, rl.ColorFromHSV(app.cs.hue, 0, app.cs.val), rl.ColorFromHSV(app.cs.hue, 1, app.cs.val))
		case 2:
			rl.DrawRectangleGradientH(sx + 1, sy + 3, sw - 2, 10, rl.ColorFromHSV(app.cs.hue, app.cs.sat, 0), rl.ColorFromHSV(app.cs.hue, app.cs.sat, 1))
		}
		knob_x := f32(sx) + hsv_ratios[i] * f32(sw)
		rl.DrawCircle(i32(knob_x), sy + 8, 9, rl.WHITE)
		rl.DrawCircle(i32(knob_x), sy + 8, 7, display_color)
		rl.DrawCircleLines(i32(knob_x), sy + 8, 9, {0, 0, 0, 80})

		hsv_text: cstring
		switch i {
		case 0: hsv_text = fmt.ctprintf("%.0f\u00b0", app.cs.hue)
		case 1: hsv_text = fmt.ctprintf("%.0f%%", app.cs.sat * 100)
		case 2: hsv_text = fmt.ctprintf("%.0f%%", app.cs.val * 100)
		}
		rl.DrawText(hsv_text, sx + sw + 16, sy + 1, 16, SUBTEXT)
	}

	rl.DrawText("\u2318+C copy  \u2318+V paste  \u2318+S save", L.right_x, L.hint_y, 12, DIM)

	// ── History (right column) ──
	rl.DrawText("History", L.right_x, L.history_y, 12, DIM)
	if app.history_count > 0 {
		for i in 0 ..< app.history_count {
			c := history_get(app.history[:], app.history_count, app.history_head, i)
			hx := f32(L.right_x) + f32(i) * 22
			hr := rl.Rectangle{hx, f32(L.history_y + 16), 18, 18}
			hovering := rl.CheckCollisionPointRec(mouse, hr)
			if hovering {
				rl.DrawRectangleRounded({hr.x - 1, hr.y - 1, hr.width + 2, hr.height + 2}, 0.2, 4, ACCENT)
			}
			rl.DrawRectangleRounded(hr, 0.2, 4, c)
			if hovering && rl.IsMouseButtonPressed(.LEFT) && !app.export_open {
				color_set_rgb(&app.cs, c)
				app.hex_focused = false
			}
		}
	}

	// ── Palette + Extracted positions ──
	palette_base_y := f32(L.export_btn_y - 80)
	if app.extracted_count > 0 do palette_base_y -= 36

	if app.extracted_count > 0 {
		ext_y := palette_base_y - 40
		rl.DrawText("Extracted", L.margin, i32(ext_y) - 14, 12, DIM)
		ext_clicked := draw_color_swatch_row(app.extracted[:app.extracted_count], f32(L.margin), ext_y, 26, 4, mouse)
		if ext_clicked >= 0 && !app.export_open {
			color_set_rgb(&app.cs, app.extracted[ext_clicked])
			commit_color(app)
		}
	}

	// ── Palette ──
	palette_label_y := palette_base_y - 30

	rl.DrawLine(L.margin, i32(palette_label_y) - 8, L.win_w - L.margin, i32(palette_label_y) - 8, OVERLAY)
	rl.DrawText("Palette", L.margin, i32(palette_label_y), 16, TEXT_CLR)

	if app.palette_count > 0 {
		clear_all_rect := rl.Rectangle{f32(L.margin + 76), palette_label_y - 2, 64, 20}
		if ca_click, _ := draw_button(clear_all_rect, "Clear All", mouse, 10); ca_click {
			app.palette_count = 0
			save_palette(app.palette[:0], PALETTE_FILE)
		}
	} else {
		rl.DrawText("click + or \u2318+S to save colors", L.margin + 76, i32(palette_label_y) + 3, 12, DIM)
	}

	for i in 0 ..< app.palette_count {
		sr := swatch_rect(i, palette_base_y, L.cols_per_row)
		c := app.palette[i]

		is_drag_source := app.palette_dragging && i == app.palette_drag
		is_drop_target := app.palette_dragging && i == app.palette_hover && i != app.palette_drag

		if is_drop_target {
			rl.DrawRectangleRounded({sr.x - 2, sr.y - 2, sr.width + 4, sr.height + 4}, 0.15, 4, ACCENT)
		} else if i == app.palette_hover && !app.palette_dragging {
			rl.DrawRectangleRounded({sr.x - 2, sr.y - 2, sr.width + 4, sr.height + 4}, 0.15, 4, ACCENT)
		} else {
			rl.DrawRectangleRounded({sr.x - 1, sr.y - 1, sr.width + 2, sr.height + 2}, 0.15, 4, {255, 255, 255, 15})
		}

		alpha: u8 = is_drag_source ? 100 : 255
		rl.DrawRectangleRounded(sr, 0.15, 4, {c.r, c.g, c.b, alpha})

		if i == app.palette_hover && !app.palette_dragging {
			xr := rl.Rectangle{sr.x + sr.width - 12, sr.y - 4, 16, 16}
			xr_hover := rl.CheckCollisionPointRec(mouse, xr)
			rl.DrawRectangleRounded(xr, 0.3, 4, xr_hover ? RED : rl.Color{60, 60, 80, 230})
			rl.DrawText("x", i32(xr.x) + 4, i32(xr.y) + 1, 12, rl.WHITE)
			if xr_hover && rl.IsMouseButtonPressed(.LEFT) {
				palette_remove(app.palette[:], &app.palette_count, i)
				save_palette(app.palette[:app.palette_count], PALETTE_FILE)
				app.palette_hover = -1
			}
		}

		if app.cvd_mode != .None {
			has_conflict := false
			for j in 0 ..< app.palette_count {
				if j == i do continue
				if !colors_distinguishable(c, app.palette[j], app.cvd_mode) {
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
					YELLOW,
				)
				rl.DrawText("!", wx + 3, wy + 1, 8, BG)
			}
		}
	}

	if app.palette_dragging && app.palette_drag >= 0 && app.palette_drag < app.palette_count {
		dc := app.palette[app.palette_drag]
		gr := rl.Rectangle{mouse.x - SWATCH_SZ / 2, mouse.y - SWATCH_SZ / 2, SWATCH_SZ, SWATCH_SZ}
		rl.DrawRectangleRounded(gr, 0.15, 4, {dc.r, dc.g, dc.b, 180})
		rl.DrawRectangleRounded({gr.x - 1, gr.y - 1, gr.width + 2, gr.height + 2}, 0.15, 4, {255, 255, 255, 60})
	}

	add_btn := swatch_rect(app.palette_count, palette_base_y, L.cols_per_row)
	add_btn_hover := app.palette_count < MAX_PALETTE && rl.CheckCollisionPointRec(mouse, add_btn)
	if app.palette_count < MAX_PALETTE {
		rl.DrawRectangleRounded({add_btn.x - 1, add_btn.y - 1, add_btn.width + 2, add_btn.height + 2}, 0.15, 4, add_btn_hover ? ACCENT : rl.Color{255, 255, 255, 15})
		rl.DrawRectangleRounded(add_btn, 0.15, 4, display_color)
		rl.DrawRectangleRounded(add_btn, 0.15, 4, {0, 0, 0, 90})
		pcx := i32(add_btn.x) + SWATCH_SZ / 2
		pcy := i32(add_btn.y) + SWATCH_SZ / 2
		plus_clr := add_btn_hover ? rl.Color{255, 255, 255, 255} : rl.Color{255, 255, 255, 180}
		rl.DrawRectangle(pcx - 7, pcy - 1, 14, 3, plus_clr)
		rl.DrawRectangle(pcx - 1, pcy - 7, 3, 14, plus_clr)
	}

	if app.palette_hover >= 0 {
		pc := app.palette[app.palette_hover]
		tip := format_hex_cstr(pc)
		sr := swatch_rect(app.palette_hover, palette_base_y, L.cols_per_row)
		tx := i32(sr.x)
		ty := i32(sr.y) - 20
		tw := rl.MeasureText(tip, 12)
		rl.DrawRectangleRounded({f32(tx - 4), f32(ty - 2), f32(tw + 8), 18}, 0.3, 4, SURFACE)
		rl.DrawText(tip, tx, ty, 12, TEXT_CLR)
	}

	// ── Export button ──
	export_btn_rect := rl.Rectangle{f32(L.margin), f32(L.export_btn_y), 120, 28}
	export_toggled := false
	if exp_click, _ := draw_button(export_btn_rect, "Export", mouse, 14); exp_click {
		app.export_open = !app.export_open
		export_toggled = true
	}
	rl.DrawText("Drop an image to extract colors", L.margin + 136, L.export_btn_y + 7, 12, DIM)

	// ── Export panel overlay ──
	if app.export_open {
		rl.DrawRectangle(0, 0, L.win_w, L.win_h, {0, 0, 0, 120})

		panel_w: f32 = 400
		panel_h: f32 = 220
		panel_x := f32(L.win_w) / 2 - panel_w / 2
		panel_y := f32(L.win_h) / 2 - panel_h / 2

		panel_rect := rl.Rectangle{panel_x, panel_y, panel_w, panel_h}
		if rl.IsMouseButtonPressed(.LEFT) && !export_toggled && !rl.CheckCollisionPointRec(mouse, panel_rect) && !app.export_fmt_open {
			app.export_open = false
			app.export_name.focused = false
		}

		rl.DrawRectangleRounded({panel_x - 1, panel_y - 1, panel_w + 2, panel_h + 2}, 0.05, 8, OVERLAY)
		rl.DrawRectangleRounded({panel_x, panel_y, panel_w, panel_h}, 0.05, 8, BG)

		rl.DrawText("Export Palette", i32(panel_x) + 20, i32(panel_y) + 16, 18, TEXT_CLR)

		rl.DrawText("Filename:", i32(panel_x) + 20, i32(panel_y) + 42, 12, SUBTEXT)
		name_field := rl.Rectangle{panel_x + 20, panel_y + 56, panel_w - 40, 28}
		text_input_draw(&app.export_name, name_field, 14)

		rl.DrawText("Format:", i32(panel_x) + 20, i32(panel_y) + 92, 12, SUBTEXT)
		format_rect := rl.Rectangle{panel_x + 20, panel_y + 106, panel_w - 40, 28}
		fmts := EXPORT_FORMATS

		fmt_hover := rl.CheckCollisionPointRec(mouse, format_rect)
		fmt_bg := app.export_fmt_open || fmt_hover ? rl.Color{58, 58, 82, 255} : OVERLAY
		rl.DrawRectangleRounded(format_rect, 0.3, 4, fmt_bg)
		rl.DrawText(fmts[app.export_format], i32(format_rect.x) + 8, i32(format_rect.y) + 6, 14, TEXT_CLR)
		arrow_fx := format_rect.x + format_rect.width - 18
		arrow_fcy := format_rect.y + format_rect.height / 2
		if app.export_fmt_open {
			rl.DrawTriangle({arrow_fx, arrow_fcy + 3}, {arrow_fx + 8, arrow_fcy + 3}, {arrow_fx + 4, arrow_fcy - 3}, SUBTEXT)
		} else {
			rl.DrawTriangle({arrow_fx, arrow_fcy - 3}, {arrow_fx + 8, arrow_fcy - 3}, {arrow_fx + 4, arrow_fcy + 3}, SUBTEXT)
		}

		if rl.IsMouseButtonPressed(.LEFT) && fmt_hover && !app.export_fmt_open {
			app.export_fmt_open = true
		} else if rl.IsMouseButtonPressed(.LEFT) && fmt_hover && app.export_fmt_open {
			app.export_fmt_open = false
		}

		save_rect := rl.Rectangle{panel_x + 20, panel_y + 150, 110, 30}
		copy_export := rl.Rectangle{panel_x + 140, panel_y + 150, 110, 30}
		cancel_rect := rl.Rectangle{panel_x + panel_w - 90, panel_y + 150, 70, 30}

		draw_button(save_rect, "Save File", mouse, 13)
		draw_button(copy_export, "Copy List", mouse, 13)
		draw_button(cancel_rect, "Cancel", mouse, 13)

		if app.palette_count == 0 {
			rl.DrawText("Add colors to palette first", i32(panel_x) + 20, i32(panel_y) + 192, 12, RED)
		}

		if app.export_fmt_open {
			item_h: f32 = 26
			menu_h := f32(len(fmts)) * item_h
			for i in 0 ..< len(fmts) {
				ir := rl.Rectangle{format_rect.x, format_rect.y + format_rect.height + f32(i) * item_h, format_rect.width, item_h}
				ih := rl.CheckCollisionPointRec(mouse, ir)
				rl.DrawRectangleRounded(ir, 0.1, 4, ih ? ACCENT : SURFACE)
				rl.DrawText(fmts[i], i32(ir.x) + 8, i32(ir.y) + 5, 14, ih ? BG : TEXT_CLR)
				if ih && rl.IsMouseButtonPressed(.LEFT) {
					app.export_format = i
					app.export_fmt_open = false
				}
			}
			if rl.IsMouseButtonPressed(.LEFT) {
				full := rl.Rectangle{format_rect.x, format_rect.y, format_rect.width, format_rect.height + menu_h}
				if !rl.CheckCollisionPointRec(mouse, full) {
					app.export_fmt_open = false
				}
			}
		}
	}

	// ── CVD dropdown menu (drawn last for z-order) ──
	if app.cvd_open {
		cvd_item_h: f32 = 24
		cvd_names_dd := CVD_NAMES
		for ti in CvdType {
			ir := rl.Rectangle{cvd_btn.x, cvd_btn.y + cvd_btn.height + f32(int(ti)) * cvd_item_h, cvd_btn.width, cvd_item_h}
			ih := rl.CheckCollisionPointRec(mouse, ir)
			rl.DrawRectangleRounded(ir, 0.1, 4, ih ? ACCENT : SURFACE)
			rl.DrawText(cvd_names_dd[ti], i32(ir.x) + 6, i32(ir.y) + 5, 11, ih ? BG : TEXT_CLR)
			if ih && rl.IsMouseButtonPressed(.LEFT) {
				app.cvd_mode = ti
				app.cvd_open = false
			}
		}
		if rl.IsMouseButtonPressed(.LEFT) {
			full := rl.Rectangle{cvd_btn.x, cvd_btn.y, cvd_btn.width, cvd_btn.height + 4 * cvd_item_h}
			if !rl.CheckCollisionPointRec(mouse, full) do app.cvd_open = false
		}
	}

	// ── Harmony dropdown menu (drawn last for z-order) ──
	if app.harmony_open {
		item_h: f32 = 28
		menu_rect := rl.Rectangle{dropdown_rect.x, dropdown_rect.y + dropdown_rect.height, dropdown_rect.width, f32(len(harmony_names_list)) * item_h}

		for i in 0 ..< len(harmony_names_list) {
			ir := rl.Rectangle{menu_rect.x, menu_rect.y + f32(i) * item_h, menu_rect.width, item_h}
			item_hover := rl.CheckCollisionPointRec(mouse, ir)
			ibg := item_hover ? ACCENT : SURFACE
			itxt := item_hover ? BG : TEXT_CLR
			rl.DrawRectangleRounded(ir, 0.1, 4, ibg)
			rl.DrawText(harmony_names_list[i], i32(ir.x) + 10, i32(ir.y) + 6, 14, itxt)

			if item_hover && rl.IsMouseButtonPressed(.LEFT) && !harmony_toggled_this_frame {
				app.harmony_type = i
				app.harmony_open = false
				update_harmony(app)
				update_shades(app)
			}
		}

		if rl.IsMouseButtonPressed(.LEFT) && !harmony_toggled_this_frame {
			full_area := rl.Rectangle{dropdown_rect.x, dropdown_rect.y, dropdown_rect.width, dropdown_rect.height + menu_rect.height}
			if !rl.CheckCollisionPointRec(mouse, full_area) {
				app.harmony_open = false
			}
		}
	}

	// ── Error message toast ──
	if app.error_timer > 0 && app.error_msg != nil {
		alpha := u8(clamp(app.error_timer, 0, 1) * 220)
		tw := rl.MeasureText(app.error_msg, 14)
		bw := tw + 30
		bx := (L.win_w - bw) / 2
		by: i32 = L.win_h - 80
		rl.DrawRectangleRounded({f32(bx), f32(by), f32(bw), 32}, 0.3, 6, {60, 20, 20, alpha})
		rl.DrawText(app.error_msg, bx + 15, by + 8, 14, {243, 139, 168, alpha})
	}

	// ── Image extraction overlay ──
	if app.extract_open && app.extract_has_img {
		rl.DrawRectangle(0, 0, L.win_w, L.win_h, {0, 0, 0, 150})

		panel_w: f32 = 520
		panel_h: f32 = 380
		px := f32(L.win_w) / 2 - panel_w / 2
		py := f32(L.win_h) / 2 - panel_h / 2

		rl.DrawRectangleRounded({px - 1, py - 1, panel_w + 2, panel_h + 2}, 0.05, 8, OVERLAY)
		rl.DrawRectangleRounded({px, py, panel_w, panel_h}, 0.05, 8, BG)

		rl.DrawText("Extract Colors", i32(px) + 20, i32(py) + 16, 18, TEXT_CLR)

		img_area := rl.Rectangle{px + 20, py + 44, panel_w - 40, 180}
		rl.DrawRectangleRounded(img_area, 0.05, 4, OVERLAY)

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
		rl.DrawText("Colors:", i32(px) + 20, i32(count_y) + 4, 14, SUBTEXT)
		minus_e := rl.Rectangle{px + 90, count_y, 24, 22}
		plus_e := rl.Rectangle{px + 142, count_y, 24, 22}
		if me_click, _ := draw_button(minus_e, "-", mouse, 14, disabled = app.extract_req <= 2); me_click {
			app.extract_req -= 1
			app.extracted, app.extracted_count = extract_palette_from_image(app.extract_img, app.extract_req)
		}
		rl.DrawText(fmt.ctprintf("%d", app.extracted_count), i32(px) + 120, i32(count_y) + 4, 14, TEXT_CLR)
		if pe_click, _ := draw_button(plus_e, "+", mouse, 14, disabled = app.extract_req >= EXTRACT_COUNT); pe_click {
			app.extract_req += 1
			app.extracted, app.extracted_count = extract_palette_from_image(app.extract_img, app.extract_req)
		}

		swatch_y := count_y + 32
		for i in 0 ..< app.extracted_count {
			sx := px + 20 + f32(i) * 36
			sr := rl.Rectangle{sx, swatch_y, 30, 30}
			hovering := rl.CheckCollisionPointRec(mouse, sr)
			if hovering {
				rl.DrawRectangleRounded({sr.x - 2, sr.y - 2, sr.width + 4, sr.height + 4}, 0.15, 4, ACCENT)
			} else {
				rl.DrawRectangleRounded({sr.x - 1, sr.y - 1, sr.width + 2, sr.height + 2}, 0.15, 4, {255, 255, 255, 15})
			}
			rl.DrawRectangleRounded(sr, 0.15, 4, app.extracted[i])

			if hovering {
				tip := format_hex_cstr(app.extracted[i])
				rl.DrawText(tip, i32(sr.x), i32(sr.y) - 16, 11, TEXT_CLR)
			}
		}

		btn_y := swatch_y + 44
		accept_rect := rl.Rectangle{px + 20, btn_y, 100, 30}
		add_all_rect := rl.Rectangle{px + 130, btn_y, 140, 30}
		cancel_rect := rl.Rectangle{px + panel_w - 90, btn_y, 70, 30}

		if acc_click, _ := draw_button(accept_rect, "Accept", mouse, 13); acc_click {
			app.extract_open = false
		}
		if aa_click, _ := draw_button(add_all_rect, "Add to Palette", mouse, 13); aa_click {
			for i in 0 ..< app.extracted_count {
				palette_add(app.palette[:], &app.palette_count, app.extracted[i])
			}
			save_palette(app.palette[:app.palette_count], PALETTE_FILE)
			app.extract_open = false
		}
		if cn_click, _ := draw_button(cancel_rect, "Cancel", mouse, 13); cn_click {
			app.extract_open = false
			app.extracted_count = 0
		}

		panel_rect := rl.Rectangle{px, py, panel_w, panel_h}
		if rl.IsMouseButtonPressed(.LEFT) && !rl.CheckCollisionPointRec(mouse, panel_rect) {
			app.extract_open = false
		}
		if rl.IsKeyPressed(.ESCAPE) {
			app.extract_open = false
		}
	}

	rl.EndDrawing()
}

export_for_format :: proc(colors: []rl.Color, format: int) -> cstring {
	switch format {
	case 2: return export_css(colors)
	case 3: return export_tailwind(colors)
	case 4: return export_json(colors)
	case 6: return palette_to_hex_array(colors)
	case:   return palette_to_hex_array(colors)
	}
}
