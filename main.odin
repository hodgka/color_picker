package color_picker

import rl "vendor:raylib"
import "core:fmt"

// ── Main ──

main :: proc() {
	rl.SetConfigFlags({.MSAA_4X_HINT, .VSYNC_HINT})
	rl.InitWindow(WINDOW_W, WINDOW_H, "Color Picker")
	defer rl.CloseWindow()
	rl.SetTargetFPS(60)

	app: AppState
	app.cs = color_init()
	app.hex_cursor = 6
	app.palette_hover = -1
	app.palette_drag = -1
	app.fg_slot = rl.Color{255, 255, 255, 255}
	app.bg_slot = rl.Color{0, 0, 0, 255}
	app.shade_req = 9
	app.shade_v_min = 0.05
	app.shade_v_max = 0.95
	init_app_inputs(&app)

	app.sv_img = rl.GenImageColor(SV_SIZE, SV_SIZE, rl.WHITE)
	rebuild_sv(&app.sv_img, app.cs.hue, SV_SIZE)
	app.sv_tex = rl.LoadTextureFromImage(app.sv_img)

	hue_img := rl.GenImageColor(360, 1, rl.WHITE)
	hp := cast([^]rl.Color)hue_img.data
	for i in 0 ..< 360 do hp[i] = rl.ColorFromHSV(f32(i), 1, 1)
	app.hue_tex = rl.LoadTextureFromImage(hue_img)
	rl.UnloadImage(hue_img)

	app.wheel_img = rl.GenImageColor(PICKER_SIZE, PICKER_SIZE, rl.BLANK)
	rebuild_wheel(&app.wheel_img, app.cs.val, PICKER_SIZE)
	app.wheel_tex = rl.LoadTextureFromImage(app.wheel_img)

	app.palette_count = load_palette(app.palette[:], PALETTE_FILE)
	update_harmony(&app)
	update_shades(&app)

	defer {
		rl.UnloadImage(app.sv_img)
		rl.UnloadTexture(app.sv_tex)
		rl.UnloadTexture(app.hue_tex)
		rl.UnloadImage(app.wheel_img)
		rl.UnloadTexture(app.wheel_tex)
		if app.eyedropper_active {
			rl.UnloadImage(app.eyedropper_img)
			rl.UnloadTexture(app.eyedropper_tex)
		}
		if app.extract_has_img {
			rl.UnloadImage(app.extract_img)
			rl.UnloadTexture(app.extract_tex)
		}
	}

	for !rl.WindowShouldClose() {
		defer free_all(context.temp_allocator)

		dt := rl.GetFrameTime()
		mouse := rl.GetMousePosition()
		if app.copied_timer > 0 do app.copied_timer -= dt

		// ── Eyedropper mode ──
		if app.eyedropper_active {
			rl.BeginDrawing()
			rl.DrawTexture(app.eyedropper_tex, 0, 0, rl.WHITE)
			cx, cy := i32(mouse.x), i32(mouse.y)
			rl.DrawCircleLines(cx, cy, 10, rl.WHITE)
			rl.DrawCircleLines(cx, cy, 11, rl.BLACK)
			rl.EndDrawing()

			if rl.IsMouseButtonPressed(.LEFT) {
				px := clamp(i32(mouse.x), 0, app.eyedropper_img.width - 1)
				py := clamp(i32(mouse.y), 0, app.eyedropper_img.height - 1)
				picked := rl.GetImageColor(app.eyedropper_img, px, py)
				color_set_rgb(&app.cs, picked)
				commit_color(&app)
				rl.UnloadImage(app.eyedropper_img)
				rl.UnloadTexture(app.eyedropper_tex)
				app.eyedropper_active = false
				update_harmony(&app)
				update_shades(&app)
				eyedropper_cleanup()
			}
			if rl.IsKeyPressed(.ESCAPE) {
				rl.UnloadImage(app.eyedropper_img)
				rl.UnloadTexture(app.eyedropper_tex)
				app.eyedropper_active = false
				eyedropper_cleanup()
			}
			continue
		}

		// ── File drop ──
		if rl.IsFileDropped() {
			files := rl.LoadDroppedFiles()
			defer rl.UnloadDroppedFiles(files)
			if files.count > 0 {
				img := rl.LoadImage(files.paths[0])
				if img.data != nil {
					if app.extract_has_img {
						rl.UnloadImage(app.extract_img)
						rl.UnloadTexture(app.extract_tex)
					}
					app.extract_img = img
					app.extract_tex = rl.LoadTextureFromImage(img)
					app.extract_has_img = true
					app.extract_open = true
					if app.extract_req < 2 do app.extract_req = EXTRACT_COUNT
					app.extracted, app.extracted_count = extract_palette_from_image(img, app.extract_req)
				}
			}
		}

		prev_hue := app.cs.hue
		prev_val := app.cs.val
		slider_w := f32(RIGHT_W - 80)
		slider_x := f32(RIGHT_X + 24)

		// ── Export panel input ──
		if app.export_open {
			if rl.IsKeyPressed(.ESCAPE) {
				app.export_open = false
				app.export_name.focused = false
				app.export_fmt_open = false
			}

			panel_w: f32 = 400
			panel_h: f32 = 220
			panel_x := f32(WINDOW_W) / 2 - panel_w / 2
			panel_y := f32(WINDOW_H) / 2 - panel_h / 2

			name_field := rl.Rectangle{panel_x + 20, panel_y + 56, panel_w - 40, 28}
			text_input_handle_click(&app.export_name, name_field, mouse, 14)
			text_input_update(&app.export_name, dt, 30)

			format_rect := rl.Rectangle{panel_x + 20, panel_y + 96, panel_w - 40, 28}
			// Format dropdown handled in drawing section

			save_rect := rl.Rectangle{panel_x + 20, panel_y + 150, 110, 30}
			copy_rect := rl.Rectangle{panel_x + 140, panel_y + 150, 110, 30}
			cancel_rect := rl.Rectangle{panel_x + panel_w - 90, panel_y + 150, 70, 30}

			if rl.IsMouseButtonPressed(.LEFT) && app.palette_count > 0 {
				colors := app.palette[:app.palette_count]
				name := text_input_get_string(&app.export_name)

				if rl.CheckCollisionPointRec(mouse, save_rect) {
					exts := [7]string{".ase", ".gpl", ".css", ".js", ".json", ".png", ".txt"}
					ext := exts[app.export_format]
					path := string(fmt.ctprintf("%s%s", name, ext))
					switch app.export_format {
					case 0: export_ase(colors, path)
					case 1: export_gpl(colors, path)
					case 5: export_png_strip(colors, path)
					case:
						text := export_for_format(colors, app.export_format)
						export_text_file(text, path)
					}
					app.export_open = false
					app.export_name.focused = false
					app.copied_timer = 1.5
				}
				if rl.CheckCollisionPointRec(mouse, copy_rect) {
					rl.SetClipboardText(export_for_format(colors, app.export_format))
					app.copied_timer = 1.5
					app.export_open = false
					app.export_name.focused = false
				}
			}
			if rl.IsMouseButtonPressed(.LEFT) && rl.CheckCollisionPointRec(mouse, cancel_rect) {
				app.export_open = false
				app.export_name.focused = false
			}
		}

		// ── Picker input ──
		if !app.export_open {
			if app.picker_mode == .Square {
				sv_rect := rl.Rectangle{SV_X, SV_Y, SV_SIZE, SV_SIZE}
				HUE_Y :: SV_Y + SV_SIZE + 14
				hue_rect := rl.Rectangle{SV_X, HUE_Y, SV_SIZE, HUE_BAR_H}

				if rl.IsMouseButtonPressed(.LEFT) {
					if rl.CheckCollisionPointRec(mouse, sv_rect) {
						app.drags.sv = true
						app.hex_focused = false
					}
					if rl.CheckCollisionPointRec(mouse, hue_rect) {
						app.drags.hue = true
						app.hex_focused = false
					}
				}
				if app.drags.sv {
					ns := clamp((mouse.x - SV_X) / SV_SIZE, 0, 1)
					nv := 1 - clamp((mouse.y - SV_Y) / SV_SIZE, 0, 1)
					color_set_hsv(&app.cs, app.cs.hue, ns, nv)
				}
				if app.drags.hue {
					nh := clamp((mouse.x - SV_X) / SV_SIZE * 360, 0, 359.99)
					color_set_hsv(&app.cs, nh, app.cs.sat, app.cs.val)
				}
			} else {
				center_x := f32(PICKER_X) + f32(PICKER_SIZE) / 2
				center_y := f32(PICKER_Y) + f32(PICKER_SIZE) / 2
				radius := f32(PICKER_SIZE) / 2

				if rl.IsMouseButtonPressed(.LEFT) {
					if _, _, ok := wheel_pick(mouse.x, mouse.y, center_x, center_y, radius); ok {
						app.drags.wheel = true
						app.hex_focused = false
					}
				}
				if app.drags.wheel {
					if h, s, ok := wheel_pick(mouse.x, mouse.y, center_x, center_y, radius); ok {
						color_set_hsv(&app.cs, h, s, app.cs.val)
					}
				}
			}

			if rl.IsMouseButtonReleased(.LEFT) {
				app.drags = {}
			}

			// ── RGB slider input ──
			for i in 0 ..< 3 {
				sy := f32(SLIDER_BASE_Y) + f32(i) * SLIDER_SPACING
				sr := rl.Rectangle{slider_x, sy, slider_w, 16}
				if rl.IsMouseButtonPressed(.LEFT) && rl.CheckCollisionPointRec(mouse, sr) {
					app.drags.rgb[i] = true
					app.hex_focused = false
				}
				if app.drags.rgb[i] {
					c := color_get(&app.cs)
					nv := u8(clamp((mouse.x - sr.x) / sr.width * 255, 0, 255))
					switch i {
					case 0: c.r = nv
					case 1: c.g = nv
					case 2: c.b = nv
					}
					color_set_rgb(&app.cs, c, preserve_hue = true)
				}
			}

			// ── HSV slider input ──
			for i in 0 ..< 3 {
				sy := f32(HSV_SLIDER_Y) + f32(i) * SLIDER_SPACING
				sr := rl.Rectangle{slider_x, sy, slider_w, 16}
				if rl.IsMouseButtonPressed(.LEFT) && rl.CheckCollisionPointRec(mouse, sr) {
					app.drags.hsv[i] = true
					app.hex_focused = false
				}
				if app.drags.hsv[i] {
					ratio := clamp((mouse.x - sr.x) / sr.width, 0, 1)
					h, s, v := app.cs.hue, app.cs.sat, app.cs.val
					switch i {
					case 0: h = ratio * 359.99
					case 1: s = ratio
					case 2: v = ratio
					}
					color_set_hsv(&app.cs, h, s, v)
				}
			}

			// ── Hex input ──
			hex_field := rl.Rectangle{f32(RIGHT_X), f32(HEX_FIELD_Y), f32(RIGHT_W - 90), 32}
			copy_btn := rl.Rectangle{hex_field.x + hex_field.width + 8, hex_field.y, 78, 32}

			if rl.IsMouseButtonPressed(.LEFT) {
				was := app.hex_focused
				app.hex_focused = rl.CheckCollisionPointRec(mouse, hex_field)
				if app.hex_focused {
					time_since := rl.GetTime() - f64(app.hex_last_click)
					app.hex_last_click = f32(rl.GetTime())
					if was && time_since < 0.35 {
						app.hex_select_all = true
					} else {
						app.hex_select_all = false
						app.hex_cursor = app.cs.hex_len
					}
					app.hex_blink = 0
				}
				if rl.CheckCollisionPointRec(mouse, copy_btn) {
					c := color_get(&app.cs)
					rl.SetClipboardText(fmt.ctprintf("#%02X%02X%02X", c.r, c.g, c.b))
					app.copied_timer = 1.5
					commit_color(&app)
				}
			}

			if app.hex_focused {
				app.hex_blink += dt

				// Cmd+A: select all
				if is_cmd_down() && rl.IsKeyPressed(.A) {
					app.hex_select_all = true
					app.hex_blink = 0
				}

				for ch := rl.GetCharPressed(); ch != 0; ch = rl.GetCharPressed() {
					c := u8(ch)
					if !is_hex_char(c) do continue

					if app.hex_select_all {
						app.cs.hex_len = 0
						app.hex_cursor = 0
						app.hex_select_all = false
					}

					if app.cs.hex_len < 6 {
						for j := app.cs.hex_len; j > app.hex_cursor; j -= 1 {
							app.cs.hex_buf[j] = app.cs.hex_buf[j - 1]
						}
						app.cs.hex_buf[app.hex_cursor] = upper_hex(c)
						app.hex_cursor += 1
						app.cs.hex_len += 1
						app.hex_blink = 0
					}
				}

				if rl.IsKeyPressed(.BACKSPACE) {
					if app.hex_select_all {
						app.cs.hex_len = 0
						app.hex_cursor = 0
						app.hex_select_all = false
					} else if is_cmd_down() {
						for j in app.hex_cursor ..< app.cs.hex_len {
							app.cs.hex_buf[j - app.hex_cursor] = app.cs.hex_buf[j]
						}
						app.cs.hex_len -= app.hex_cursor
						app.hex_cursor = 0
					} else if app.hex_cursor > 0 {
						app.hex_cursor -= 1
						for j in app.hex_cursor ..< app.cs.hex_len - 1 {
							app.cs.hex_buf[j] = app.cs.hex_buf[j + 1]
						}
						app.cs.hex_len -= 1
					}
					app.hex_blink = 0
				}
				if rl.IsKeyPressed(.DELETE) {
					if app.hex_select_all {
						app.cs.hex_len = 0
						app.hex_cursor = 0
						app.hex_select_all = false
					} else if app.hex_cursor < app.cs.hex_len {
						for j in app.hex_cursor ..< app.cs.hex_len - 1 {
							app.cs.hex_buf[j] = app.cs.hex_buf[j + 1]
						}
						app.cs.hex_len -= 1
					}
					app.hex_blink = 0
				}
				if rl.IsKeyPressed(.LEFT) {
					app.hex_select_all = false
					if is_cmd_down() { app.hex_cursor = 0 }
					else if app.hex_cursor > 0 { app.hex_cursor -= 1 }
					app.hex_blink = 0
				}
				if rl.IsKeyPressed(.RIGHT) {
					app.hex_select_all = false
					if is_cmd_down() { app.hex_cursor = app.cs.hex_len }
					else if app.hex_cursor < app.cs.hex_len { app.hex_cursor += 1 }
					app.hex_blink = 0
				}

				if rl.IsKeyPressed(.ENTER) {
					if color_apply_hex(&app.cs) {
						app.hex_focused = false
						app.hex_select_all = false
						commit_color(&app)
					}
				}
				color_apply_hex(&app.cs, preserve_hue = true)

				if is_cmd_down() && rl.IsKeyPressed(.V) {
					if clip := rl.GetClipboardText(); clip != nil {
						ps := string(clip)
						if len(ps) > 0 && ps[0] == '#' do ps = ps[1:]
						if len(ps) == 6 && all_hex_str(ps) {
							for j in 0 ..< 6 do app.cs.hex_buf[j] = upper_hex(ps[j])
							app.cs.hex_len = 6
							app.hex_cursor = 6
							app.hex_select_all = false
							color_apply_hex(&app.cs)
						}
					}
				}
			}

			// ── FG/BG well clicks ──
			fg_well := rl.Rectangle{f32(RIGHT_X + RIGHT_W - 76), f32(CONTRAST_INFO_Y - 2), 32, 24}
			bg_well := rl.Rectangle{fg_well.x + 40, fg_well.y, 32, 24}
			if rl.IsMouseButtonPressed(.LEFT) {
				if rl.CheckCollisionPointRec(mouse, fg_well) {
					app.active_slot = app.active_slot == .FG ? .None : .FG
				}
				if rl.CheckCollisionPointRec(mouse, bg_well) {
					app.active_slot = app.active_slot == .BG ? .None : .BG
				}
			}

			// ── Global shortcuts ──
			if !app.hex_focused && !app.export_name.focused {
				if is_cmd_down() && rl.IsKeyPressed(.C) {
					c := color_get(&app.cs)
					rl.SetClipboardText(fmt.ctprintf("#%02X%02X%02X", c.r, c.g, c.b))
					app.copied_timer = 1.5
					commit_color(&app)
				}
				if is_cmd_down() && rl.IsKeyPressed(.S) || rl.IsKeyPressed(.SPACE) {
					c := color_get(&app.cs)
					if palette_add(app.palette[:], &app.palette_count, c) {
						save_palette(app.palette[:app.palette_count], PALETTE_FILE)
						commit_color(&app)
					}
				}
			}

			// ── Palette input ──
		palette_base_y := f32(app.extracted_count > 0 ? 680 : 644)
		palette_label_y := palette_base_y - 30

		app.palette_hover = -1
			for i in 0 ..< app.palette_count {
				if rl.CheckCollisionPointRec(mouse, swatch_rect(i, palette_base_y, COLS_PER_ROW)) {
					app.palette_hover = i
					break
				}
			}

			add_btn := swatch_rect(app.palette_count, palette_base_y, COLS_PER_ROW)
			add_btn_hover := app.palette_count < MAX_PALETTE && rl.CheckCollisionPointRec(mouse, add_btn)

			if rl.IsMouseButtonPressed(.LEFT) {
				if add_btn_hover {
					c := color_get(&app.cs)
					if palette_add(app.palette[:], &app.palette_count, c) {
						save_palette(app.palette[:app.palette_count], PALETTE_FILE)
						commit_color(&app)
					}
					app.hex_focused = false
				} else if app.palette_hover >= 0 {
					app.palette_drag = app.palette_hover
					app.palette_dragging = true
				}
			}

			// Drop: reorder or just select
			if rl.IsMouseButtonReleased(.LEFT) && app.palette_dragging {
				if app.palette_hover >= 0 && app.palette_hover != app.palette_drag {
					palette_move(app.palette[:], app.palette_count, app.palette_drag, app.palette_hover)
					save_palette(app.palette[:app.palette_count], PALETTE_FILE)
				} else if app.palette_hover == app.palette_drag {
					color_set_rgb(&app.cs, app.palette[app.palette_hover])
					app.hex_focused = false
				}
				app.palette_dragging = false
				app.palette_drag = -1
			}

			if rl.IsMouseButtonPressed(.RIGHT) && app.palette_hover >= 0 {
				if palette_remove(app.palette[:], &app.palette_count, app.palette_hover) {
					save_palette(app.palette[:app.palette_count], PALETTE_FILE)
				}
			}
		}

		// ── Texture rebuilds ──
		cvd_changed := app.cvd_mode != app.prev_cvd
		if app.cs.hue != prev_hue || cvd_changed {
			rebuild_sv(&app.sv_img, app.cs.hue, SV_SIZE)
			if app.cvd_mode != .None {
				pixels := cast([^]rl.Color)app.sv_img.data
				for i in 0 ..< SV_SIZE * SV_SIZE {
					pixels[i] = simulate_cvd(pixels[i], app.cvd_mode)
				}
			}
			rl.UpdateTexture(app.sv_tex, app.sv_img.data)
			update_harmony(&app)
			update_shades(&app)
		}
		if app.cs.val != prev_val || app.cs.hue != prev_hue || cvd_changed {
			rebuild_wheel(&app.wheel_img, app.cs.val, PICKER_SIZE)
			if app.cvd_mode != .None {
				pixels := cast([^]rl.Color)app.wheel_img.data
				for i in 0 ..< PICKER_SIZE * PICKER_SIZE {
					if pixels[i].a > 0 {
						pixels[i] = simulate_cvd(pixels[i], app.cvd_mode)
					}
				}
			}
			rl.UpdateTexture(app.wheel_tex, app.wheel_img.data)
			if app.cs.val != prev_val || cvd_changed {
				update_harmony(&app)
				update_shades(&app)
			}
		}
		app.prev_cvd = app.cvd_mode

		color := color_get(&app.cs)
		display_color := app.cvd_mode != .None ? simulate_cvd(color, app.cvd_mode) : color

		// BG always tracks the current color unless FG is explicitly selected
		if app.active_slot == .FG {
			app.fg_slot = color
		} else {
			app.bg_slot = color
		}

		// ══════════════════ DRAWING ══════════════════
		rl.BeginDrawing()
		rl.ClearBackground(BG)

		draw_header()
		draw_picker(&app, mouse)
		harmony_toggled := draw_harmony_section(&app, mouse)
		draw_right_column(&app, mouse, color, display_color)
		export_toggled := draw_palette_section(&app, mouse, display_color)
		draw_export_panel(&app, mouse, export_toggled)
		draw_cvd_dropdown(&app, mouse)
		draw_harmony_dropdown(&app, mouse, harmony_toggled)
		draw_extract_modal(&app, mouse)

		rl.EndDrawing()
	}
}
