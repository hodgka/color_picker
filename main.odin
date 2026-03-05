package color_picker

import rl "vendor:raylib"
import "core:fmt"
import "core:os"

WINDOW_W :: 700
WINDOW_H :: 620

SV_SIZE   :: 280
HUE_BAR_H :: 20
MARGIN    :: 24
GAP       :: 14

SV_X :: MARGIN
SV_Y :: 50
HUE_Y :: SV_Y + SV_SIZE + GAP

RIGHT_X :: SV_X + SV_SIZE + 28
RIGHT_W :: WINDOW_W - RIGHT_X - MARGIN

PREVIEW_H :: 100

SWATCH_SZ       :: 32
SWATCH_GAP      :: 5
SWATCH_STRIDE   :: SWATCH_SZ + SWATCH_GAP
MAX_PALETTE     :: 48
PALETTE_LABEL_Y :: 454
PALETTE_Y       :: 476
PALETTE_FILE    :: "palette.txt"
COLS_PER_ROW    :: (WINDOW_W - 2 * MARGIN) / SWATCH_STRIDE

BG      :: rl.Color{24, 24, 37, 255}
SURFACE :: rl.Color{30, 30, 46, 255}
OVERLAY :: rl.Color{49, 50, 68, 255}
TEXT_CLR :: rl.Color{205, 214, 244, 255}
SUBTEXT :: rl.Color{166, 173, 200, 255}
ACCENT  :: rl.Color{137, 180, 250, 255}
DIM     :: rl.Color{88, 91, 112, 255}

// ── Color state ──

ColorState :: struct {
	hue, sat, val: f32,
	hex_buf:       [6]u8,
	hex_len:       int,
}

color_init :: proc(h: f32 = 0, s: f32 = 1, v: f32 = 1) -> ColorState {
	cs := ColorState{hue = h, sat = s, val = v}
	sync_hex(&cs.hex_buf, rl.ColorFromHSV(h, s, v))
	cs.hex_len = 6
	return cs
}

color_get :: proc(cs: ^ColorState) -> rl.Color {
	return rl.ColorFromHSV(cs.hue, cs.sat, cs.val)
}

// Sets color from HSV values. Syncs hex buffer.
// Used when input source is HSV (SV picker, hue bar, HSV sliders).
color_set_hsv :: proc(cs: ^ColorState, h, s, v: f32) {
	cs.hue = h
	cs.sat = s
	cs.val = v
	sync_hex(&cs.hex_buf, rl.ColorFromHSV(h, s, v))
	cs.hex_len = 6
}

// Sets color from an RGB value. Syncs hex buffer from the exact RGB input.
// When preserve_hue is true, keeps current hue if the color is achromatic.
// Used when input source is RGB (RGB sliders).
color_set_rgb :: proc(cs: ^ColorState, color: rl.Color, preserve_hue := false) {
	hsv := rl.ColorToHSV(color)
	if preserve_hue {
		if hsv.x != 0 || hsv.y > 0.01 do cs.hue = hsv.x
	} else {
		cs.hue = hsv.x
	}
	cs.sat = hsv.y
	cs.val = hsv.z
	sync_hex(&cs.hex_buf, color)
	cs.hex_len = 6
}

// Applies the current hex buffer to HSV without syncing hex back.
// Avoids overwriting user-typed hex values with HSV-roundtripped approximations.
// Used when input source is the hex field (typing, paste, enter).
color_apply_hex :: proc(cs: ^ColorState, preserve_hue := false) -> bool {
	if cs.hex_len != 6 do return false
	c, ok := parse_hex(cs.hex_buf[:6])
	if !ok do return false
	hsv := rl.ColorToHSV(c)
	if preserve_hue {
		if hsv.x != 0 || hsv.y > 0.01 do cs.hue = hsv.x
	} else {
		cs.hue = hsv.x
	}
	cs.sat = hsv.y
	cs.val = hsv.z
	return true
}

// ── Palette helpers ──

palette_add :: proc(palette: []rl.Color, count: ^int, color: rl.Color) -> bool {
	if count^ >= len(palette) do return false
	for i in 0 ..< count^ {
		if palette[i].r == color.r && palette[i].g == color.g && palette[i].b == color.b {
			return false
		}
	}
	palette[count^] = color
	count^ += 1
	return true
}

palette_remove :: proc(palette: []rl.Color, count: ^int, index: int) -> bool {
	if index < 0 || index >= count^ do return false
	for j in index ..< count^ - 1 {
		palette[j] = palette[j + 1]
	}
	count^ -= 1
	return true
}

// ── Main ──

main :: proc() {
	rl.SetConfigFlags({.MSAA_4X_HINT, .VSYNC_HINT})
	rl.InitWindow(WINDOW_W, WINDOW_H, "Color Picker")
	defer rl.CloseWindow()
	rl.SetTargetFPS(60)

	cs := color_init()

	hex_cursor := 6
	hex_focused := false
	hex_blink: f32 = 0

	drag_sv := false
	drag_hue := false
	drag_rgb: [3]bool
	drag_hsv: [3]bool

	copied_timer: f32 = 0

	palette: [MAX_PALETTE]rl.Color
	palette_count := 0
	palette_hover := -1

	sv_img := rl.GenImageColor(SV_SIZE, SV_SIZE, rl.WHITE)
	defer rl.UnloadImage(sv_img)
	rebuild_sv(&sv_img, cs.hue)
	sv_tex := rl.LoadTextureFromImage(sv_img)
	defer rl.UnloadTexture(sv_tex)

	hue_img := rl.GenImageColor(360, 1, rl.WHITE)
	hue_pixels := cast([^]rl.Color)hue_img.data
	for i in 0 ..< 360 {
		hue_pixels[i] = rl.ColorFromHSV(f32(i), 1, 1)
	}
	hue_tex := rl.LoadTextureFromImage(hue_img)
	rl.UnloadImage(hue_img)
	defer rl.UnloadTexture(hue_tex)

	palette_count = load_palette(palette[:], PALETTE_FILE)

	SLIDER_BASE_Y :: SV_Y + PREVIEW_H + 68
	SLIDER_SPACING :: 32
	HSV_SLIDER_Y :: SLIDER_BASE_Y + 3 * SLIDER_SPACING + 18

	for !rl.WindowShouldClose() {
		defer free_all(context.temp_allocator)

		dt := rl.GetFrameTime()
		mouse := rl.GetMousePosition()
		if copied_timer > 0 do copied_timer -= dt

		prev_hue := cs.hue
		slider_w := f32(RIGHT_W - 50)
		slider_x := f32(RIGHT_X + 24)

		// ── SV picker input ──
		sv_rect := rl.Rectangle{SV_X, SV_Y, SV_SIZE, SV_SIZE}
		hue_rect := rl.Rectangle{SV_X, HUE_Y, SV_SIZE, HUE_BAR_H}

		if rl.IsMouseButtonPressed(.LEFT) {
			if rl.CheckCollisionPointRec(mouse, sv_rect) {
				drag_sv = true
				hex_focused = false
			}
			if rl.CheckCollisionPointRec(mouse, hue_rect) {
				drag_hue = true
				hex_focused = false
			}
		}
		if rl.IsMouseButtonReleased(.LEFT) {
			drag_sv = false
			drag_hue = false
			drag_rgb = {}
			drag_hsv = {}
		}

		if drag_sv {
			new_s := clamp((mouse.x - SV_X) / SV_SIZE, 0, 1)
			new_v := 1 - clamp((mouse.y - SV_Y) / SV_SIZE, 0, 1)
			color_set_hsv(&cs, cs.hue, new_s, new_v)
		}
		if drag_hue {
			new_h := clamp((mouse.x - SV_X) / SV_SIZE * 360, 0, 359.99)
			color_set_hsv(&cs, new_h, cs.sat, cs.val)
		}

		// ── RGB slider input ──
		for i in 0 ..< 3 {
			sy := f32(SLIDER_BASE_Y) + f32(i) * SLIDER_SPACING
			sr := rl.Rectangle{slider_x, sy, slider_w, 16}

			if rl.IsMouseButtonPressed(.LEFT) && rl.CheckCollisionPointRec(mouse, sr) {
				drag_rgb[i] = true
				hex_focused = false
			}
			if drag_rgb[i] {
				c := color_get(&cs)
				nv := u8(clamp((mouse.x - sr.x) / sr.width * 255, 0, 255))
				switch i {
				case 0:
					c.r = nv
				case 1:
					c.g = nv
				case 2:
					c.b = nv
				}
				color_set_rgb(&cs, c, preserve_hue = true)
			}
		}

		// ── HSV slider input ──
		for i in 0 ..< 3 {
			sy := f32(HSV_SLIDER_Y) + f32(i) * SLIDER_SPACING
			sr := rl.Rectangle{slider_x, sy, slider_w, 16}

			if rl.IsMouseButtonPressed(.LEFT) && rl.CheckCollisionPointRec(mouse, sr) {
				drag_hsv[i] = true
				hex_focused = false
			}
			if drag_hsv[i] {
				ratio := clamp((mouse.x - sr.x) / sr.width, 0, 1)
				h, s, v := cs.hue, cs.sat, cs.val
				switch i {
				case 0:
					h = ratio * 359.99
				case 1:
					s = ratio
				case 2:
					v = ratio
				}
				color_set_hsv(&cs, h, s, v)
			}
		}

		// ── Hex input ──
		hex_field := rl.Rectangle {
			f32(RIGHT_X),
			f32(SV_Y + PREVIEW_H + 16),
			f32(RIGHT_W - 94),
			32,
		}
		copy_btn := rl.Rectangle {
			hex_field.x + hex_field.width + 10,
			hex_field.y,
			80,
			32,
		}

		if rl.IsMouseButtonPressed(.LEFT) {
			was_focused := hex_focused
			hex_focused = rl.CheckCollisionPointRec(mouse, hex_field)
			if hex_focused && !was_focused {
				hex_cursor = cs.hex_len
				hex_blink = 0
			}
			color := color_get(&cs)
			if rl.CheckCollisionPointRec(mouse, copy_btn) {
				rl.SetClipboardText(fmt.ctprintf("#%02X%02X%02X", color.r, color.g, color.b))
				copied_timer = 1.5
			}
		}

		if hex_focused {
			hex_blink += dt

			for ch := rl.GetCharPressed(); ch != 0; ch = rl.GetCharPressed() {
				c := u8(ch)
				if is_hex_char(c) && cs.hex_len < 6 {
					for j := cs.hex_len; j > hex_cursor; j -= 1 {
						cs.hex_buf[j] = cs.hex_buf[j - 1]
					}
					cs.hex_buf[hex_cursor] = upper_hex(c)
					hex_cursor += 1
					cs.hex_len += 1
					hex_blink = 0
				}
			}

			if rl.IsKeyPressed(.BACKSPACE) && hex_cursor > 0 {
				hex_cursor -= 1
				for j in hex_cursor ..< cs.hex_len - 1 {
					cs.hex_buf[j] = cs.hex_buf[j + 1]
				}
				cs.hex_len -= 1
				hex_blink = 0
			}
			if rl.IsKeyPressed(.DELETE) && hex_cursor < cs.hex_len {
				for j in hex_cursor ..< cs.hex_len - 1 {
					cs.hex_buf[j] = cs.hex_buf[j + 1]
				}
				cs.hex_len -= 1
				hex_blink = 0
			}
			if rl.IsKeyPressed(.LEFT) && hex_cursor > 0 {
				hex_cursor -= 1
				hex_blink = 0
			}
			if rl.IsKeyPressed(.RIGHT) && hex_cursor < cs.hex_len {
				hex_cursor += 1
				hex_blink = 0
			}

			if rl.IsKeyPressed(.ENTER) {
				if color_apply_hex(&cs) do hex_focused = false
			}

			color_apply_hex(&cs, preserve_hue = true)

			cmd :=
				rl.IsKeyDown(.LEFT_SUPER) ||
				rl.IsKeyDown(.RIGHT_SUPER) ||
				rl.IsKeyDown(.LEFT_CONTROL) ||
				rl.IsKeyDown(.RIGHT_CONTROL)
			if cmd && rl.IsKeyPressed(.V) {
				if clip := rl.GetClipboardText(); clip != nil {
					ps := string(clip)
					if len(ps) > 0 && ps[0] == '#' do ps = ps[1:]
					if len(ps) == 6 && all_hex_str(ps) {
						for j in 0 ..< 6 {
							cs.hex_buf[j] = upper_hex(ps[j])
						}
						cs.hex_len = 6
						hex_cursor = 6
						color_apply_hex(&cs)
					}
				}
			}
		}

		// ── Global shortcuts ──
		if !hex_focused {
			cmd :=
				rl.IsKeyDown(.LEFT_SUPER) ||
				rl.IsKeyDown(.RIGHT_SUPER) ||
				rl.IsKeyDown(.LEFT_CONTROL) ||
				rl.IsKeyDown(.RIGHT_CONTROL)
			if cmd && rl.IsKeyPressed(.C) {
				color := color_get(&cs)
				rl.SetClipboardText(fmt.ctprintf("#%02X%02X%02X", color.r, color.g, color.b))
				copied_timer = 1.5
			}
			if cmd && rl.IsKeyPressed(.S) {
				color := color_get(&cs)
				if palette_add(palette[:], &palette_count, color) {
					save_palette(palette[:palette_count], PALETTE_FILE)
				}
			}
		}

		// ── Palette input ──
		palette_hover = -1
		for i in 0 ..< palette_count {
			if rl.CheckCollisionPointRec(mouse, swatch_rect(i)) {
				palette_hover = i
				break
			}
		}

		add_btn := swatch_rect(palette_count)
		add_btn_hover := palette_count < MAX_PALETTE && rl.CheckCollisionPointRec(mouse, add_btn)

		if rl.IsMouseButtonPressed(.LEFT) {
			if add_btn_hover {
				color := color_get(&cs)
				if palette_add(palette[:], &palette_count, color) {
					save_palette(palette[:palette_count], PALETTE_FILE)
				}
				hex_focused = false
			} else if palette_hover >= 0 {
				color_set_rgb(&cs, palette[palette_hover])
				hex_focused = false
			}
		}
		if rl.IsMouseButtonPressed(.RIGHT) && palette_hover >= 0 {
			if palette_remove(palette[:], &palette_count, palette_hover) {
				save_palette(palette[:palette_count], PALETTE_FILE)
			}
		}

		// ── Centralized SV rebuild ──
		if cs.hue != prev_hue {
			rebuild_sv(&sv_img, cs.hue)
			rl.UpdateTexture(sv_tex, sv_img.data)
		}

		color := color_get(&cs)

		// ── Drawing ──
		rl.BeginDrawing()
		rl.ClearBackground(BG)

		rl.DrawText("Color Picker", MARGIN, 14, 22, TEXT_CLR)

		// SV picker
		rl.DrawRectangle(SV_X - 1, SV_Y - 1, SV_SIZE + 2, SV_SIZE + 2, OVERLAY)
		rl.DrawTexture(sv_tex, SV_X, SV_Y, rl.WHITE)

		sv_sel_x := i32(f32(SV_X) + cs.sat * SV_SIZE)
		sv_sel_y := i32(f32(SV_Y) + (1 - cs.val) * SV_SIZE)
		rl.DrawCircle(sv_sel_x, sv_sel_y, 8, {0, 0, 0, 100})
		rl.DrawCircleLines(sv_sel_x, sv_sel_y, 7, rl.WHITE)
		rl.DrawCircleLines(sv_sel_x, sv_sel_y, 8, {0, 0, 0, 200})

		// Hue bar
		rl.DrawRectangle(SV_X - 1, HUE_Y - 1, SV_SIZE + 2, HUE_BAR_H + 2, OVERLAY)
		rl.DrawTexturePro(
			hue_tex,
			{0, 0, 360, 1},
			{SV_X, HUE_Y, SV_SIZE, HUE_BAR_H},
			{0, 0},
			0,
			rl.WHITE,
		)

		hue_sel_x := i32(f32(SV_X) + cs.hue / 360 * SV_SIZE)
		rl.DrawRectangle(hue_sel_x - 2, HUE_Y - 2, 5, HUE_BAR_H + 4, rl.WHITE)
		rl.DrawRectangleLines(hue_sel_x - 3, HUE_Y - 3, 7, HUE_BAR_H + 6, {0, 0, 0, 180})

		// Color preview
		preview_rect := rl.Rectangle{f32(RIGHT_X), f32(SV_Y), f32(RIGHT_W), PREVIEW_H}
		border_rect := rl.Rectangle {
			preview_rect.x - 1,
			preview_rect.y - 1,
			preview_rect.width + 2,
			preview_rect.height + 2,
		}
		rl.DrawRectangleRounded(border_rect, 0.1, 8, OVERLAY)
		rl.DrawRectangleRounded(preview_rect, 0.1, 8, color)

		// Hex field
		hex_bg := hex_focused ? rl.Color{58, 58, 82, 255} : OVERLAY
		rl.DrawRectangleRounded(hex_field, 0.3, 6, hex_bg)
		if hex_focused {
			rl.DrawRectangleRounded(
				{hex_field.x - 1, hex_field.y - 1, hex_field.width + 2, hex_field.height + 2},
				0.3,
				6,
				ACCENT,
			)
			rl.DrawRectangleRounded(hex_field, 0.3, 6, hex_bg)
		}

		hash_x := i32(hex_field.x) + 10
		hash_y := i32(hex_field.y) + 7
		rl.DrawText("#", hash_x, hash_y, 18, SUBTEXT)

		hex_text_x := hash_x + 14
		for j in 0 ..< cs.hex_len {
			ch_str: [2]u8 = {cs.hex_buf[j], 0}
			rl.DrawText(cstring(&ch_str[0]), hex_text_x + i32(j) * 12, hash_y, 18, TEXT_CLR)
		}
		if hex_focused && int(hex_blink * 1.8) % 2 == 0 {
			cx := hex_text_x + i32(hex_cursor) * 12
			rl.DrawRectangle(cx, hash_y, 2, 18, ACCENT)
		}

		// Copy button
		copy_hover := rl.CheckCollisionPointRec(mouse, copy_btn)
		copy_bg := copy_hover ? ACCENT : OVERLAY
		copy_text := copy_hover ? BG : TEXT_CLR
		rl.DrawRectangleRounded(copy_btn, 0.3, 6, copy_bg)
		if copied_timer > 0 {
			rl.DrawText("Copied!", i32(copy_btn.x) + 8, i32(copy_btn.y) + 8, 16, copy_text)
		} else {
			rl.DrawText("Copy", i32(copy_btn.x) + 20, i32(copy_btn.y) + 8, 16, copy_text)
		}

		// RGB sliders
		rgb_labels := [3]cstring{"R", "G", "B"}
		rgb_values := [3]u8{color.r, color.g, color.b}
		left_colors := [3]rl.Color{
			{0, color.g, color.b, 255},
			{color.r, 0, color.b, 255},
			{color.r, color.g, 0, 255},
		}
		right_colors := [3]rl.Color{
			{255, color.g, color.b, 255},
			{color.r, 255, color.b, 255},
			{color.r, color.g, 255, 255},
		}

		for i in 0 ..< 3 {
			sy := i32(SLIDER_BASE_Y) + i32(i) * SLIDER_SPACING
			sx := i32(slider_x)
			sw := i32(slider_w)

			rl.DrawText(rgb_labels[i], RIGHT_X, sy + 1, 16, SUBTEXT)

			rl.DrawRectangle(sx, sy + 2, sw, 12, OVERLAY)
			rl.DrawRectangleGradientH(sx + 1, sy + 3, sw - 2, 10, left_colors[i], right_colors[i])

			knob_x := f32(sx) + f32(rgb_values[i]) / 255 * f32(sw)
			rl.DrawCircle(i32(knob_x), sy + 8, 9, rl.WHITE)
			rl.DrawCircle(i32(knob_x), sy + 8, 7, color)
			rl.DrawCircleLines(i32(knob_x), sy + 8, 9, {0, 0, 0, 80})

			rl.DrawText(fmt.ctprintf("%d", rgb_values[i]), sx + sw + 8, sy + 1, 16, SUBTEXT)
		}

		// HSV sliders
		hsv_labels := [3]cstring{"H", "S", "V"}
		hsv_ratios := [3]f32{cs.hue / 360, cs.sat, cs.val}

		for i in 0 ..< 3 {
			sy := i32(HSV_SLIDER_Y) + i32(i) * SLIDER_SPACING
			sx := i32(slider_x)
			sw := i32(slider_w)

			rl.DrawText(hsv_labels[i], RIGHT_X, sy + 1, 16, SUBTEXT)

			rl.DrawRectangle(sx, sy + 2, sw, 12, OVERLAY)
			switch i {
			case 0:
				rl.DrawTexturePro(
					hue_tex,
					{0, 0, 360, 1},
					{f32(sx + 1), f32(sy + 3), f32(sw - 2), 10},
					{0, 0},
					0,
					rl.WHITE,
				)
			case 1:
				rl.DrawRectangleGradientH(
					sx + 1, sy + 3, sw - 2, 10,
					rl.ColorFromHSV(cs.hue, 0, cs.val),
					rl.ColorFromHSV(cs.hue, 1, cs.val),
				)
			case 2:
				rl.DrawRectangleGradientH(
					sx + 1, sy + 3, sw - 2, 10,
					rl.ColorFromHSV(cs.hue, cs.sat, 0),
					rl.ColorFromHSV(cs.hue, cs.sat, 1),
				)
			}

			knob_x := f32(sx) + hsv_ratios[i] * f32(sw)
			rl.DrawCircle(i32(knob_x), sy + 8, 9, rl.WHITE)
			rl.DrawCircle(i32(knob_x), sy + 8, 7, color)
			rl.DrawCircleLines(i32(knob_x), sy + 8, 9, {0, 0, 0, 80})

			hsv_text: cstring
			switch i {
			case 0:
				hsv_text = fmt.ctprintf("%.0f\u00b0", cs.hue)
			case 1:
				hsv_text = fmt.ctprintf("%.0f%%", cs.sat * 100)
			case 2:
				hsv_text = fmt.ctprintf("%.0f%%", cs.val * 100)
			}
			rl.DrawText(hsv_text, sx + sw + 8, sy + 1, 16, SUBTEXT)
		}

		hint_y := i32(HSV_SLIDER_Y) + 3 * SLIDER_SPACING + 6
		rl.DrawText("\u2318+C copy  \u2318+V paste  \u2318+S save", RIGHT_X, hint_y, 12, DIM)

		// ── Palette ──
		rl.DrawLine(MARGIN, PALETTE_LABEL_Y - 10, WINDOW_W - MARGIN, PALETTE_LABEL_Y - 10, OVERLAY)
		rl.DrawText("Palette", MARGIN, PALETTE_LABEL_Y, 16, TEXT_CLR)
		if palette_count == 0 {
			rl.DrawText(
				"click + or \u2318+S to save colors, right-click to remove",
				MARGIN + 76,
				PALETTE_LABEL_Y + 3,
				12,
				DIM,
			)
		}

		for i in 0 ..< palette_count {
			sr := swatch_rect(i)
			c := palette[i]

			if i == palette_hover {
				rl.DrawRectangleRounded(
					{sr.x - 2, sr.y - 2, sr.width + 4, sr.height + 4},
					0.15,
					4,
					ACCENT,
				)
			} else {
				rl.DrawRectangleRounded(
					{sr.x - 1, sr.y - 1, sr.width + 2, sr.height + 2},
					0.15,
					4,
					{255, 255, 255, 15},
				)
			}
			rl.DrawRectangleRounded(sr, 0.15, 4, c)
		}

		if palette_count < MAX_PALETTE {
			rl.DrawRectangleRounded(
				{add_btn.x - 1, add_btn.y - 1, add_btn.width + 2, add_btn.height + 2},
				0.15,
				4,
				add_btn_hover ? ACCENT : rl.Color{255, 255, 255, 15},
			)
			rl.DrawRectangleRounded(add_btn, 0.15, 4, color)
			rl.DrawRectangleRounded(add_btn, 0.15, 4, {0, 0, 0, 90})

			pcx := i32(add_btn.x) + SWATCH_SZ / 2
			pcy := i32(add_btn.y) + SWATCH_SZ / 2
			plus_clr := add_btn_hover ? rl.Color{255, 255, 255, 255} : rl.Color{255, 255, 255, 180}
			rl.DrawRectangle(pcx - 7, pcy - 1, 14, 3, plus_clr)
			rl.DrawRectangle(pcx - 1, pcy - 7, 3, 14, plus_clr)
		}

		if palette_hover >= 0 {
			pc := palette[palette_hover]
			tip := fmt.ctprintf("#%02X%02X%02X", pc.r, pc.g, pc.b)
			sr := swatch_rect(palette_hover)
			tx := i32(sr.x)
			ty := i32(sr.y) - 20
			tw := rl.MeasureText(tip, 12)
			rl.DrawRectangleRounded(
				{f32(tx - 4), f32(ty - 2), f32(tw + 8), 18},
				0.3,
				4,
				SURFACE,
			)
			rl.DrawText(tip, tx, ty, 12, TEXT_CLR)
		}

		rl.EndDrawing()
	}
}

// ── Rendering helpers ──

rebuild_sv :: proc(img: ^rl.Image, hue: f32) {
	pixels := cast([^]rl.Color)img.data
	for y in 0 ..< SV_SIZE {
		for x in 0 ..< SV_SIZE {
			s := f32(x) / f32(SV_SIZE)
			v := 1 - f32(y) / f32(SV_SIZE)
			pixels[y * SV_SIZE + x] = rl.ColorFromHSV(hue, s, v)
		}
	}
}

swatch_rect :: proc(index: int) -> rl.Rectangle {
	row := index / COLS_PER_ROW
	col := index % COLS_PER_ROW
	return {
		f32(MARGIN) + f32(col) * f32(SWATCH_STRIDE),
		f32(PALETTE_Y) + f32(row) * f32(SWATCH_STRIDE),
		SWATCH_SZ,
		SWATCH_SZ,
	}
}

// ── Hex helpers ──

sync_hex :: proc(buf: ^[6]u8, color: rl.Color) {
	fmt.bprintf(buf[:], "%02X%02X%02X", color.r, color.g, color.b)
}

is_hex_char :: proc(c: u8) -> bool {
	switch c {
	case '0' ..= '9', 'a' ..= 'f', 'A' ..= 'F':
		return true
	case:
		return false
	}
}

upper_hex :: proc(c: u8) -> u8 {
	if c >= 'a' && c <= 'f' do return c - 32
	return c
}

all_hex_str :: proc(s: string) -> bool {
	for c in s {
		if !is_hex_char(u8(c)) do return false
	}
	return true
}

parse_hex :: proc(buf: []u8) -> (rl.Color, bool) {
	if len(buf) != 6 do return {}, false

	hex_val :: proc(c: u8) -> (u8, bool) {
		switch c {
		case '0' ..= '9':
			return c - '0', true
		case 'A' ..= 'F':
			return c - 'A' + 10, true
		case 'a' ..= 'f':
			return c - 'a' + 10, true
		case:
			return 0, false
		}
	}

	r1, ok1 := hex_val(buf[0])
	r2, ok2 := hex_val(buf[1])
	g1, ok3 := hex_val(buf[2])
	g2, ok4 := hex_val(buf[3])
	b1, ok5 := hex_val(buf[4])
	b2, ok6 := hex_val(buf[5])
	if !ok1 || !ok2 || !ok3 || !ok4 || !ok5 || !ok6 do return {}, false

	return rl.Color{r1 * 16 + r2, g1 * 16 + g2, b1 * 16 + b2, 255}, true
}

// ── File I/O ──

load_palette :: proc(palette: []rl.Color, path: string) -> int {
	data, err := os.read_entire_file_from_path(path, context.allocator)
	if err != nil do return 0
	defer delete(data)

	count := 0
	i := 0
	for i < len(data) && count < len(palette) {
		for i < len(data) && (data[i] == '\n' || data[i] == '\r' || data[i] == ' ' || data[i] == '\t') {
			i += 1
		}
		if i < len(data) && data[i] == '#' do i += 1
		if i + 6 <= len(data) {
			if c, parsed := parse_hex(data[i:i + 6]); parsed {
				palette[count] = c
				count += 1
			}
		}
		for i < len(data) && data[i] != '\n' && data[i] != '\r' {
			i += 1
		}
	}
	return count
}

save_palette :: proc(colors: []rl.Color, path: string) {
	buf: [MAX_PALETTE * 9]u8
	offset := 0
	for c in colors {
		s := fmt.bprintf(buf[offset:], "#%02X%02X%02X\n", c.r, c.g, c.b)
		offset += len(s)
	}
	_ = os.write_entire_file(path, buf[:offset])
}
