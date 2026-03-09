package color_picker

import rl "vendor:raylib"
import "core:fmt"
import "core:os"
import "color"
import "ui"
import "ui/layout"
import "data"

VERSION :: #config(VERSION, "dev")

VERBOSE: bool

ALLOWED_IMAGE_EXTENSIONS :: [?]cstring{".png", ".jpg", ".jpeg", ".bmp", ".gif", ".tga", ".psd", ".hdr"}
MAX_DROP_FILE_SIZE :: 50 * 1024 * 1024

is_valid_image_drop :: proc(path: cstring) -> bool {
	ext := rl.GetFileExtension(path)
	if ext == nil do return false
	for allowed in ALLOWED_IMAGE_EXTENSIONS {
		if ext == allowed do return true
	}
	return false
}

log_info :: proc(msg: string, args: ..any) {
	if !VERBOSE do return
	fmt.eprintf("[INFO] ")
	fmt.eprintfln(msg, ..args)
}

log_error :: proc(msg: string, args: ..any) {
	fmt.eprintf("[ERROR] ")
	fmt.eprintfln(msg, ..args)
}

main :: proc() {
	for arg in os.args[1:] {
		if arg == "--version" || arg == "-v" {
			fmt.printfln("Color Picker %s", VERSION)
			return
		}
		if arg == "--verbose" {
			VERBOSE = true
		}
	}

	data.set_verbose(VERBOSE)
	log_info("Starting Color Picker %s", VERSION)

	rl.SetConfigFlags({.MSAA_4X_HINT, .VSYNC_HINT, .WINDOW_RESIZABLE})
	title := fmt.ctprintf("Color Picker %s", VERSION)
	rl.InitWindow(960, 780, title)
	defer rl.CloseWindow()
	rl.SetTargetFPS(60)

	app: AppState
	app.cs = color.color_init()
	app.palette_hover = -1
	app.palette_drag = -1
	app.fg_slot = rl.Color{255, 255, 255, 255}
	app.bg_slot = rl.Color{0, 0, 0, 255}
	app.shade_req = 9
	app.shade_v_min = 0.05
	app.shade_v_max = 0.95
	init_app_inputs(&app)

	app.sv_img = rl.GenImageColor(SV_TEX_SIZE, SV_TEX_SIZE, rl.WHITE)
	ui.rebuild_sv(&app.sv_img, app.cs.hue, SV_TEX_SIZE)
	app.sv_tex = rl.LoadTextureFromImage(app.sv_img)

	hue_img := rl.GenImageColor(360, 1, rl.WHITE)
	hp := cast([^]rl.Color)hue_img.data
	for i in 0 ..< 360 do hp[i] = rl.ColorFromHSV(f32(i), 1, 1)
	app.hue_tex = rl.LoadTextureFromImage(hue_img)
	rl.UnloadImage(hue_img)

	app.wheel_img = rl.GenImageColor(WHEEL_TEX_SIZE, WHEEL_TEX_SIZE, rl.BLANK)
	ui.rebuild_wheel(&app.wheel_img, app.cs.val, WHEEL_TEX_SIZE)
	app.wheel_tex = rl.LoadTextureFromImage(app.wheel_img)

	app.palette_count = data.load_palette(app.palette[:], data.PALETTE_FILE)
	log_info("Loaded %d palette colors from %s", app.palette_count, data.PALETTE_FILE)
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
		if app.status_timer > 0 do app.status_timer -= dt

		sw := f32(rl.GetScreenWidth())
		sh := f32(rl.GetScreenHeight())
		root_node := build_layout(sw, sh)
		rects := layout.compute(&root_node, sw, sh, context.temp_allocator)

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
				color.color_set_rgb(&app.cs, picked)
				commit_color(&app)
				rl.UnloadImage(app.eyedropper_img)
				rl.UnloadTexture(app.eyedropper_tex)
				app.eyedropper_active = false
				update_harmony(&app)
				update_shades(&app)
				data.eyedropper_cleanup()
			}
			if rl.IsKeyPressed(.ESCAPE) {
				rl.UnloadImage(app.eyedropper_img)
				rl.UnloadTexture(app.eyedropper_tex)
				app.eyedropper_active = false
				data.eyedropper_cleanup()
			}
			continue
		}

		// ── File drop ──
		if rl.IsFileDropped() {
			files := rl.LoadDroppedFiles()
			defer rl.UnloadDroppedFiles(files)
			if files.count > 0 {
				dropped_path := files.paths[0]
				log_info("File dropped: %s", dropped_path)

				valid_drop := is_valid_image_drop(dropped_path)
				if !valid_drop {
					set_status(&app, "Unsupported file type")
					log_info("Rejected file drop: unsupported extension")
				}

				img: rl.Image
				if valid_drop {
					img = rl.LoadImage(dropped_path)
				}
				if valid_drop && img.data != nil {
					if app.extract_has_img {
						rl.UnloadImage(app.extract_img)
						rl.UnloadTexture(app.extract_tex)
					}
					app.extract_img = img
					app.extract_tex = rl.LoadTextureFromImage(img)
					app.extract_has_img = true
					app.extract_open = true
					if app.extract_req < 2 do app.extract_req = data.EXTRACT_COUNT
					app.extracted, app.extracted_count = data.extract_palette_from_image(img, app.extract_req)
				} else if valid_drop {
					set_status(&app, "Failed to load image")
					log_error("LoadImage returned nil for dropped file")
				}
			}
		}

		// ── Delegated input handlers ──
		handle_picker_input(&app, mouse, rects)
		handle_harmony_input(&app, mouse, rects)
		handle_right_column_input(&app, mouse, rects)
		export_toggled := handle_palette_input(&app, mouse, rects)
		handle_export_input(&app, mouse, export_toggled, rects)
		handle_extract_input(&app, mouse, rects)

		prev_hue := app.cs.hue
		prev_val := app.cs.val

		rc, _ := layout.find(rects, .Right_Column)
		rgb_r, _ := layout.find(rects, .RGB_Sliders)
		hsv_r, _ := layout.find(rects, .HSV_Sliders)
		hex_fr, _ := layout.find(rects, .Hex_Field)
		contrast_r, _ := layout.find(rects, .Contrast)
		picker_r, _ := layout.find(rects, .Picker)
		palette_lr, _ := layout.find(rects, .Palette)
		root_r, _ := layout.find(rects, .Root)

		SLIDER_SPACING :: 30
		slider_w := rc.w - 80
		slider_x := rc.x + 24

		// ── Export panel input ──
		if app.export_open {
			panel := ui.modal_update(sw, sh, 400, 220, &app.export_open, mouse, just_opened = export_toggled)
			if !app.export_open {
				app.export_name.focused = false
				app.export_fmt_open = false
			}

			panel_x := panel.x
			panel_y := panel.y
			panel_w := panel.width

			name_field := rl.Rectangle{panel_x + 20, panel_y + 56, panel_w - 40, 28}
			ui.text_input_handle_click(&app.export_name, name_field, mouse, 14)
			ui.text_input_update(&app.export_name, dt, 30)

			save_rect := rl.Rectangle{panel_x + 20, panel_y + 150, 110, 30}
			copy_rect := rl.Rectangle{panel_x + 140, panel_y + 150, 110, 30}
			cancel_rect := rl.Rectangle{panel_x + panel_w - 90, panel_y + 150, 70, 30}

			if app.palette_count > 0 {
				colors := app.palette[:app.palette_count]
				name := ui.text_input_get_string(&app.export_name)

			if ui.button_update(save_rect, mouse) {
				exts := [7]string{".ase", ".gpl", ".css", ".js", ".json", ".png", ".txt"}
				ext := exts[app.export_format]
				path := string(fmt.ctprintf("%s%s", name, ext))
				ok: bool
				switch app.export_format {
				case 0: ok = data.export_ase(colors, path)
				case 1: ok = data.export_gpl(colors, path)
				case 5: ok = data.export_png_strip(colors, path)
				case:
					text := export_for_format(colors, app.export_format)
					ok = data.export_text_file(text, path)
				}
				if ok {
					set_status(&app, "Exported successfully")
				} else {
					set_status(&app, "Export failed")
				}
				app.export_open = false
				app.export_name.focused = false
				app.copied_timer = 1.5
			}
				if ui.button_update(copy_rect, mouse) {
					rl.SetClipboardText(export_for_format(colors, app.export_format))
					app.copied_timer = 1.5
					app.export_open = false
					app.export_name.focused = false
				}
			}
			if ui.button_update(cancel_rect, mouse) {
				app.export_open = false
				app.export_name.focused = false
			}
		}

		// ── Picker input ──
		if !app.export_open {
			if app.picker_mode == .Square {
				sv_size := f32(SV_TEX_SIZE)
				sv_rect := rl.Rectangle{picker_r.x, picker_r.y, sv_size, sv_size}
				hue_bar_y := picker_r.y + sv_size + 14
				hue_rect := rl.Rectangle{picker_r.x, hue_bar_y, sv_size, 20}

				if rl.IsMouseButtonPressed(.LEFT) {
					if rl.CheckCollisionPointRec(mouse, sv_rect) {
						app.drags.sv = true
						app.hex_input.focused = false
					}
					if rl.CheckCollisionPointRec(mouse, hue_rect) {
						app.drags.hue = true
						app.hex_input.focused = false
					}
				}
				if app.drags.sv {
					ns := clamp((mouse.x - picker_r.x) / sv_size, 0, 1)
					nv := 1 - clamp((mouse.y - picker_r.y) / sv_size, 0, 1)
					color.color_set_hsv(&app.cs, app.cs.hue, ns, nv)
				}
				if app.drags.hue {
					nh := clamp((mouse.x - picker_r.x) / sv_size * 360, 0, 359.99)
					color.color_set_hsv(&app.cs, nh, app.cs.sat, app.cs.val)
				}
			} else {
				wheel_size := f32(WHEEL_TEX_SIZE)
				center_x := picker_r.x + wheel_size / 2
				center_y := picker_r.y + wheel_size / 2
				radius := wheel_size / 2

				if rl.IsMouseButtonPressed(.LEFT) {
					if _, _, ok := ui.wheel_pick(mouse.x, mouse.y, center_x, center_y, radius); ok {
						app.drags.wheel = true
						app.hex_input.focused = false
					}
				}
				if app.drags.wheel {
					if h, s, ok := ui.wheel_pick(mouse.x, mouse.y, center_x, center_y, radius); ok {
						color.color_set_hsv(&app.cs, h, s, app.cs.val)
					}
				}
			}

			if rl.IsMouseButtonReleased(.LEFT) {
				app.drags = {}
			}

			// ── RGB slider input ──
			rgb_vals := [3]u8{color.color_get(&app.cs).r, color.color_get(&app.cs).g, color.color_get(&app.cs).b}
			for i in 0 ..< 3 {
				sr := rl.Rectangle{slider_x, rgb_r.y + f32(i) * SLIDER_SPACING, slider_w, 16}
				ratio, started := ui.color_slider_update(sr, mouse, &app.drags.rgb[i], f32(rgb_vals[i]) / 255)
				if started do app.hex_input.focused = false
				if app.drags.rgb[i] {
					c := color.color_get(&app.cs)
					nv := u8(ratio * 255)
					switch i {
					case 0: c.r = nv
					case 1: c.g = nv
					case 2: c.b = nv
					}
					color.color_set_rgb(&app.cs, c, preserve_hue = true)
				}
			}

			// ── HSV slider input ──
			hsv_ratios := [3]f32{app.cs.hue / 360, app.cs.sat, app.cs.val}
			for i in 0 ..< 3 {
				sr := rl.Rectangle{slider_x, hsv_r.y + f32(i) * SLIDER_SPACING, slider_w, 16}
				ratio, started := ui.color_slider_update(sr, mouse, &app.drags.hsv[i], hsv_ratios[i])
				if started do app.hex_input.focused = false
				if app.drags.hsv[i] {
					h, s, v := app.cs.hue, app.cs.sat, app.cs.val
					switch i {
					case 0: h = ratio * 359.99
					case 1: s = ratio
					case 2: v = ratio
					}
					color.color_set_hsv(&app.cs, h, s, v)
				}
			}

			// ── Hex input ──
			hex_field := rl.Rectangle{rc.x, hex_fr.y, rc.w - 90, 32}
			copy_btn := rl.Rectangle{hex_field.x + hex_field.width + 8, hex_field.y, 78, 32}

			ui.text_input_handle_click(&app.hex_input, hex_field, mouse, 18, 14)
			ui.text_input_update(&app.hex_input, dt, 6)

			if rl.IsMouseButtonPressed(.LEFT) && rl.CheckCollisionPointRec(mouse, copy_btn) {
				c := color.color_get(&app.cs)
				rl.SetClipboardText(fmt.ctprintf("#%02X%02X%02X", c.r, c.g, c.b))
				app.copied_timer = 1.5
				commit_color(&app)
			}

			if app.hex_input.committed {
				hex := ui.text_input_get_string(&app.hex_input)
				if color.color_apply_hex_str(&app.cs, hex) {
					commit_color(&app)
				}
				app.hex_input.focused = false
				app.hex_input.committed = false
			}
			if app.hex_input.changed {
				color.color_apply_hex_str(&app.cs, ui.text_input_get_string(&app.hex_input), preserve_hue = true)
				app.hex_input.changed = false
			}

			// ── FG/BG well clicks ──
			fg_well := rl.Rectangle{rc.x + rc.w - 76, contrast_r.y - 2, 32, 24}
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
			if !app.hex_input.focused && !app.export_name.focused {
				if ui.is_cmd_down() && rl.IsKeyPressed(.C) {
					c := color.color_get(&app.cs)
					rl.SetClipboardText(fmt.ctprintf("#%02X%02X%02X", c.r, c.g, c.b))
					app.copied_timer = 1.5
					commit_color(&app)
				}
				if ui.is_cmd_down() && rl.IsKeyPressed(.S) || rl.IsKeyPressed(.SPACE) {
					c := color.color_get(&app.cs)
					palette_undo_push(&app)
					if data.palette_add(app.palette[:], &app.palette_count, c) {
						save_palette_with_status(&app)
						commit_color(&app)
					}
				}
				if ui.is_cmd_down() && rl.IsKeyPressed(.Z) {
					if palette_undo_pop(&app) {
						set_status(&app, "Undo")
					}
				}
				if ui.is_cmd_down() && rl.IsKeyPressed(.E) {
					app.export_open = !app.export_open
				}
				if ui.is_cmd_down() && rl.IsKeyPressed(.D) {
					next := (int(app.cvd_mode) + 1) % (int(max(color.CvdType)) + 1)
					app.cvd_mode = color.CvdType(next)
				}
				if ui.is_cmd_down() && rl.IsKeyPressed(.I) {
					if data.eyedropper_capture() {
						app.eyedropper_img = rl.LoadImage(data.SCREENSHOT_PATH)
						if app.eyedropper_img.data != nil {
							app.eyedropper_tex = rl.LoadTextureFromImage(app.eyedropper_img)
							app.eyedropper_active = true
						}
					}
				}
				if rl.IsKeyPressed(.TAB) {
					ht_count := int(max(color.HarmonyType)) + 1
					if rl.IsKeyDown(.LEFT_SHIFT) || rl.IsKeyDown(.RIGHT_SHIFT) {
						app.harmony_type = (app.harmony_type - 1 + ht_count) % ht_count
					} else {
						app.harmony_type = (app.harmony_type + 1) % ht_count
					}
					update_harmony(&app)
					update_shades(&app)
				}
			}

			// ── Palette input ──
			cpr := cols_per_row(palette_lr)
			swatch_start_y := palette_lr.y + (app.extracted_count > 0 ? f32(30) : f32(0)) + 24

			app.palette_hover = -1
			for i in 0 ..< app.palette_count {
				if rl.CheckCollisionPointRec(mouse, data.swatch_rect(i, swatch_start_y, cpr, palette_lr.x)) {
					app.palette_hover = i
					break
				}
			}

			add_btn := data.swatch_rect(app.palette_count, swatch_start_y, cpr, palette_lr.x)
			add_btn_hover := app.palette_count < data.MAX_PALETTE && rl.CheckCollisionPointRec(mouse, add_btn)

			if rl.IsMouseButtonPressed(.LEFT) {
				if add_btn_hover {
					c := color.color_get(&app.cs)
					palette_undo_push(&app)
					if data.palette_add(app.palette[:], &app.palette_count, c) {
						save_palette_with_status(&app)
						commit_color(&app)
					}
					app.hex_input.focused = false
				} else if app.palette_hover >= 0 {
					app.palette_drag = app.palette_hover
					app.palette_dragging = true
				}
			}

			if rl.IsMouseButtonReleased(.LEFT) && app.palette_dragging {
				if app.palette_hover >= 0 && app.palette_hover != app.palette_drag {
					palette_undo_push(&app)
					data.palette_move(app.palette[:], app.palette_count, app.palette_drag, app.palette_hover)
					save_palette_with_status(&app)
				} else if app.palette_hover == app.palette_drag {
					color.color_set_rgb(&app.cs, app.palette[app.palette_hover])
					app.hex_input.focused = false
				}
				app.palette_dragging = false
				app.palette_drag = -1
			}

			if rl.IsMouseButtonPressed(.RIGHT) && app.palette_hover >= 0 {
				palette_undo_push(&app)
				if data.palette_remove(app.palette[:], &app.palette_count, app.palette_hover) {
					save_palette_with_status(&app)
				}
			}
		}

		// ── Texture rebuilds ──
		cvd_changed := app.cvd_mode != app.prev_cvd
		if app.cs.hue != prev_hue || cvd_changed {
			ui.rebuild_sv(&app.sv_img, app.cs.hue, SV_TEX_SIZE)
			if app.cvd_mode != .None {
				pixels := cast([^]rl.Color)app.sv_img.data
				for i in 0 ..< SV_TEX_SIZE * SV_TEX_SIZE {
					pixels[i] = color.simulate_cvd(pixels[i], app.cvd_mode)
				}
			}
			rl.UpdateTexture(app.sv_tex, app.sv_img.data)
			update_harmony(&app)
			update_shades(&app)
		}
		if app.cs.val != prev_val || app.cs.hue != prev_hue || cvd_changed {
			ui.rebuild_wheel(&app.wheel_img, app.cs.val, WHEEL_TEX_SIZE)
			if app.cvd_mode != .None {
				pixels := cast([^]rl.Color)app.wheel_img.data
				for i in 0 ..< WHEEL_TEX_SIZE * WHEEL_TEX_SIZE {
					if pixels[i].a > 0 {
						pixels[i] = color.simulate_cvd(pixels[i], app.cvd_mode)
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

		cur_color := color.color_get(&app.cs)
		display_color := app.cvd_mode != .None ? color.simulate_cvd(cur_color, app.cvd_mode) : cur_color
		sync_hex_from_color(&app)

		if app.active_slot == .FG {
			app.fg_slot = cur_color
		} else {
			app.bg_slot = cur_color
		}

		// ══════════════════ DRAWING ══════════════════
		rl.BeginDrawing()
		rl.ClearBackground(ui.BG)

		draw_header(rects)
		draw_picker(&app, mouse, rects)
		draw_harmony_section(&app, mouse, rects)
		draw_right_column(&app, mouse, cur_color, display_color, rects)
		draw_palette_section(&app, mouse, display_color, rects)
		draw_export_panel(&app, mouse, rects)
		draw_extract_modal(&app, mouse, rects)

		rl.EndDrawing()
	}
}
