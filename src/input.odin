package color_picker

import rl "vendor:raylib"
import "color"
import "ui"
import "ui/layout"
import "data"

handle_picker_input :: proc(app: ^AppState, mouse: rl.Vector2, rects: []layout.Rect) {
	controls, _ := layout.find(rects, .Picker_Controls)
	toggle_rect := rl.Rectangle{controls.x, controls.y, 140, 26}

	if rl.IsMouseButtonPressed(.LEFT) {
		half_w := toggle_rect.width / 2
		for i in 0 ..< 2 {
			r := rl.Rectangle{toggle_rect.x + f32(i) * half_w, toggle_rect.y, half_w, toggle_rect.height}
			if rl.CheckCollisionPointRec(mouse, r) {
				app.picker_mode = PickerMode(i)
			}
		}
	}

	eye_btn := rl.Rectangle{toggle_rect.x + toggle_rect.width + 10, controls.y, 90, 26}
	if ui.button_update(eye_btn, mouse) {
		if data.eyedropper_capture() {
			app.eyedropper_img = rl.LoadImage(data.SCREENSHOT_PATH)
			if app.eyedropper_img.data != nil {
				app.eyedropper_tex = rl.LoadTextureFromImage(app.eyedropper_img)
				app.eyedropper_active = true
			}
		}
	}
}

handle_harmony_input :: proc(app: ^AppState, mouse: rl.Vector2, rects: []layout.Rect) {
	harmony_r, _ := layout.find(rects, .Harmony)
	hx := harmony_r.x
	hy := harmony_r.y

	dropdown_rect := rl.Rectangle{hx, hy, 160, 28}
	harmony_names_list: [8]cstring
	for ht in color.HarmonyType {
		harmony_names_list[int(ht)] = color.HARMONY_NAMES[ht]
	}
	if ui.dropdown_update(dropdown_rect, harmony_names_list[:], &app.harmony_type, &app.harmony_open, mouse) {
		update_harmony(app)
		update_shades(app)
	}

	if !app.harmony_open {
		harm_label_y := hy + 34

		ht := color.HarmonyType(app.harmony_type)
		if color.harmony_is_variable(ht) {
			new_req := ui.stepper_update(hx + 70, harm_label_y - 2, app.harmony_req, 2, color.MAX_HARMONY, mouse)
			if new_req != app.harmony_req {
				app.harmony_req = new_req
				update_harmony(app)
			}
		}

		harm_y := harm_label_y + 18
		for i in 0 ..< app.harmony_count {
			rx := hx + f32(i) * (28 + 3)
			r := rl.Rectangle{rx, harm_y, 28, 28}
			if rl.IsMouseButtonPressed(.LEFT) && rl.CheckCollisionPointRec(mouse, r) {
				color.color_set_rgb(&app.cs, app.harmony_colors[i])
				commit_color(app)
			}
		}

		shade_label_y := harm_y + 40

		new_shade := ui.stepper_update(hx + 50, shade_label_y - 2, app.shade_req, 3, color.MAX_SHADES, mouse)
		if new_shade != app.shade_req {
			app.shade_req = new_shade
			update_shades(app)
		}

		dark_btn := rl.Rectangle{hx + 122, shade_label_y - 2, 36, 16}
		light_btn := rl.Rectangle{dark_btn.x + 42, shade_label_y - 2, 36, 16}
		if ui.button_update(dark_btn, mouse) {
			app.shade_v_min = max(app.shade_v_min - 0.1, 0)
			app.shade_v_max = max(app.shade_v_max - 0.1, app.shade_v_min + 0.2)
			update_shades(app)
		}
		if ui.button_update(light_btn, mouse) {
			app.shade_v_max = min(app.shade_v_max + 0.1, 1)
			app.shade_v_min = min(app.shade_v_min + 0.1, app.shade_v_max - 0.2)
			update_shades(app)
		}

		shade_y := shade_label_y + 18
		for i in 0 ..< app.shade_count {
			rx := hx + f32(i) * (28 + 3)
			r := rl.Rectangle{rx, shade_y, 28, 28}
			if rl.IsMouseButtonPressed(.LEFT) && rl.CheckCollisionPointRec(mouse, r) {
				color.color_set_rgb(&app.cs, app.shades[i])
				commit_color(app)
			}
		}
	}

}

handle_right_column_input :: proc(app: ^AppState, mouse: rl.Vector2, rects: []layout.Rect) {
	rc, _ := layout.find(rects, .Right_Column)
	contrast_r, _ := layout.find(rects, .Contrast)
	history_r, _ := layout.find(rects, .History)

	cvd_btn := rl.Rectangle{rc.x + rc.w - 166, contrast_r.y, 86, 20}
	cvd_names: [4]cstring
	for ti in color.CvdType do cvd_names[int(ti)] = color.CVD_NAMES[ti]
	cvd_sel := int(app.cvd_mode)
	if ui.dropdown_update(cvd_btn, cvd_names[:], &cvd_sel, &app.cvd_open, mouse) {
		app.cvd_mode = color.CvdType(cvd_sel)
	}

	if app.history_count > 0 && !app.export_open {
		for i in 0 ..< app.history_count {
			hist_x := rc.x + f32(i) * 22
			hr := rl.Rectangle{hist_x, history_r.y + 16, 18, 18}
			if rl.IsMouseButtonPressed(.LEFT) && rl.CheckCollisionPointRec(mouse, hr) {
				c := data.history_get(app.history[:], app.history_count, app.history_head, i)
				color.color_set_rgb(&app.cs, c)
				app.hex_input.focused = false
			}
		}
	}
}

handle_palette_input :: proc(app: ^AppState, mouse: rl.Vector2, rects: []layout.Rect) -> (export_toggled: bool) {
	palette_r, _ := layout.find(rects, .Palette)
	export_r, _ := layout.find(rects, .Export_Button)
	pal_x := palette_r.x
	cpr := cols_per_row(palette_r)

	if app.extracted_count > 0 && !app.export_open {
		ext_y := palette_r.y
		for i in 0 ..< app.extracted_count {
			rx := pal_x + f32(i) * (26 + 4)
			r := rl.Rectangle{rx, ext_y, 26, 26}
			if rl.IsMouseButtonPressed(.LEFT) && rl.CheckCollisionPointRec(mouse, r) {
				color.color_set_rgb(&app.cs, app.extracted[i])
				commit_color(app)
			}
		}
	}

	swatch_start_y := palette_r.y + (app.extracted_count > 0 ? f32(30) : f32(0)) + 24
	palette_label_y := palette_r.y + (app.extracted_count > 0 ? f32(30) : f32(0))

	if app.palette_count > 0 {
		if ui.button_update({pal_x + 76, palette_label_y - 2, 64, 20}, mouse) {
			app.palette_count = 0
			data.save_palette(app.palette[:0], data.PALETTE_FILE)
		}
	}

	for i in 0 ..< app.palette_count {
		sr := data.swatch_rect(i, swatch_start_y, cpr, pal_x)
		if i == app.palette_hover && !app.palette_dragging {
			xr := rl.Rectangle{sr.x + sr.width - 12, sr.y - 4, 16, 16}
			if rl.IsMouseButtonPressed(.LEFT) && rl.CheckCollisionPointRec(mouse, xr) {
				data.palette_remove(app.palette[:], &app.palette_count, i)
				data.save_palette(app.palette[:app.palette_count], data.PALETTE_FILE)
				app.palette_hover = -1
			}
		}
	}

	if ui.button_update(to_rl_rect(export_r), mouse) {
		app.export_open = !app.export_open
		export_toggled = true
	}

	return
}

handle_export_input :: proc(app: ^AppState, mouse: rl.Vector2, export_toggled: bool, rects: []layout.Rect) {
	root_r, _ := layout.find(rects, .Root)

	if app.export_open {
		panel_x := root_r.w / 2 - 200
		panel_y := root_r.h / 2 - 110
		format_rect := rl.Rectangle{panel_x + 20, panel_y + 106, 360, 28}
		fmts := EXPORT_FORMATS
		ui.dropdown_update(format_rect, fmts[:], &app.export_format, &app.export_fmt_open, mouse)
	}
}

handle_extract_input :: proc(app: ^AppState, mouse: rl.Vector2, rects: []layout.Rect) {
	if !app.extract_open || !app.extract_has_img do return

	root_r, _ := layout.find(rects, .Root)

	panel_w: f32 = 520
	panel_h: f32 = 380
	px := root_r.w / 2 - panel_w / 2
	py := root_r.h / 2 - panel_h / 2

	count_y := py + 234
	new_ext := ui.stepper_update(px + 90, count_y, app.extract_req, 2, data.EXTRACT_COUNT, mouse, btn_w = 24, btn_h = 22, gap = 52)
	if new_ext != app.extract_req {
		app.extract_req = new_ext
		app.extracted, app.extracted_count = data.extract_palette_from_image(app.extract_img, app.extract_req)
	}

	swatch_y := count_y + 32
	btn_y := swatch_y + 44
	if ui.button_update({px + 20, btn_y, 100, 30}, mouse) {
		app.extract_open = false
	}
	if ui.button_update({px + 130, btn_y, 140, 30}, mouse) {
		for i in 0 ..< app.extracted_count {
			data.palette_add(app.palette[:], &app.palette_count, app.extracted[i])
		}
		data.save_palette(app.palette[:app.palette_count], data.PALETTE_FILE)
		app.extract_open = false
	}
	if ui.button_update({px + panel_w - 90, btn_y, 70, 30}, mouse) {
		app.extract_open = false
		app.extracted_count = 0
	}

	ui.modal_update(root_r.w, root_r.h, panel_w, panel_h, &app.extract_open, mouse)
}
