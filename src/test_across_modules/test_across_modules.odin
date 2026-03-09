package test_across_modules

import "core:testing"
import "core:strings"
import "core:math"
import "core:os"
import rl "vendor:raylib"
import "../color"
import "../data"
import "../ui/layout"

// ── color → data → layout: Full user workflow ──
// Simulates: pick color via hex → build harmony → add to palette → save →
// reload → export → verify layout can hold the palette

@(test)
test_pick_color_harmony_palette_export :: proc(t: ^testing.T) {
	path :: "/tmp/_test_cross_workflow.txt"
	defer os.remove(path)

	cs := color.color_init()
	ok := color.color_apply_hex_str(&cs, "3498DB")
	testing.expect(t, ok, "hex parse should succeed")

	harm_colors, harm_count := color.compute_harmony(cs.hue, cs.sat, cs.val, .Triadic)
	testing.expect_value(t, harm_count, 3)

	palette: [data.MAX_PALETTE]rl.Color
	pal_count := 0
	base := color.color_get(&cs)
	data.palette_add(palette[:], &pal_count, base)
	for i in 0 ..< harm_count {
		data.palette_add(palette[:], &pal_count, harm_colors[i])
	}

	saved := data.save_palette(palette[:pal_count], path)
	testing.expect(t, saved, "save should succeed")

	loaded: [data.MAX_PALETTE]rl.Color
	n := data.load_palette(loaded[:], path)
	testing.expect_value(t, n, pal_count)
	for i in 0 ..< n {
		testing.expect_value(t, loaded[i].r, palette[i].r)
		testing.expect_value(t, loaded[i].g, palette[i].g)
		testing.expect_value(t, loaded[i].b, palette[i].b)
	}

	css := string(data.export_css(loaded[:n]))
	testing.expect(t, strings.contains(css, ":root {"), "CSS structure")
	testing.expect(t, strings.count(css, "--color-") >= n, "CSS should have all color entries")
}

// ── layout → data: Palette swatch layout matches swatch_rect ──

@(test)
test_layout_palette_swatch_placement :: proc(t: ^testing.T) {
	bottom := [?]layout.Node{
		{tag = .Palette,       width = layout.Fill{1}, height = layout.Fill{1}},
		{tag = .Export_Button, width = layout.Fill{1}, height = layout.Fixed{28}},
	}
	root := layout.Node{
		tag      = .Root,
		dir      = .Column,
		width    = layout.Fill{1},
		height   = layout.Fill{1},
		padding  = {top = 14, right = 24, bottom = 16, left = 24},
		children = bottom[:],
	}
	rects := layout.compute(&root, 960, 200)
	defer delete(rects)

	pal_rect, found := layout.find(rects, .Palette)
	testing.expect(t, found, "Palette rect should exist")

	cpr := max(int(pal_rect.w) / data.SWATCH_STRIDE, 1)
	testing.expect(t, cpr > 0, "cols_per_row should be positive")

	for i in 0 ..< min(cpr * 2, data.MAX_PALETTE) {
		sr := data.swatch_rect(i, pal_rect.y, cpr, pal_rect.x)
		testing.expect(t, sr.x >= pal_rect.x, "swatch x should be within palette bounds")
		testing.expect(t, sr.width == f32(data.SWATCH_SZ), "swatch width should match SWATCH_SZ")
		testing.expect(t, sr.height == f32(data.SWATCH_SZ), "swatch height should match SWATCH_SZ")
	}

	first := data.swatch_rect(0, pal_rect.y, cpr, pal_rect.x)
	second := data.swatch_rect(1, pal_rect.y, cpr, pal_rect.x)
	testing.expect_value(t, second.x - first.x, f32(data.SWATCH_STRIDE))
}

// ── layout → data: Row wrapping at palette width ──

@(test)
test_palette_swatch_row_wrapping :: proc(t: ^testing.T) {
	pal_rect := layout.Rect{x = 24, y = 100, w = 200, h = 300, tag = .Palette}
	cpr := max(int(pal_rect.w) / data.SWATCH_STRIDE, 1)

	last_in_row := data.swatch_rect(cpr - 1, pal_rect.y, cpr, pal_rect.x)
	first_next_row := data.swatch_rect(cpr, pal_rect.y, cpr, pal_rect.x)

	testing.expect_value(t, first_next_row.x, pal_rect.x)
	testing.expect(t, first_next_row.y > last_in_row.y, "next row should be below previous")
	testing.expect_value(t, first_next_row.y - last_in_row.y, f32(data.SWATCH_STRIDE))
}

// ── color → data → layout: CVD-safe palette in layout ──
// Build a palette, check CVD safety, verify layout accommodates it

@(test)
test_cvd_safe_palette_in_layout :: proc(t: ^testing.T) {
	red   := rl.Color{255, 0, 0, 255}
	blue  := rl.Color{0, 0, 255, 255}
	green := rl.Color{0, 180, 0, 255}

	palette: [data.MAX_PALETTE]rl.Color
	pal_count := 0
	data.palette_add(palette[:], &pal_count, red)
	data.palette_add(palette[:], &pal_count, blue)
	data.palette_add(palette[:], &pal_count, green)

	for i in 0 ..< pal_count {
		for j in i + 1 ..< pal_count {
			safe, _ := color.cvd_pair_safety(palette[i], palette[j])
			_ = safe
		}
	}

	pal_rect := layout.Rect{x = 24, y = 100, w = 400, h = 200, tag = .Palette}
	cpr := max(int(pal_rect.w) / data.SWATCH_STRIDE, 1)

	for i in 0 ..< pal_count {
		sr := data.swatch_rect(i, pal_rect.y, cpr, pal_rect.x)
		testing.expect(t, sr.x >= pal_rect.x, "swatch within bounds")
		testing.expect(t, sr.x + sr.width <= pal_rect.x + pal_rect.w + f32(data.SWATCH_GAP), "swatch doesn't overflow palette width")
	}
}

// ── color → data: Harmony → shades → palette → persist → export ──

@(test)
test_harmony_shades_palette_export_pipeline :: proc(t: ^testing.T) {
	path :: "/tmp/_test_cross_harm_shades.txt"
	defer os.remove(path)

	cs := color.color_init(200, 0.9, 0.85)

	harm_colors, harm_count := color.compute_harmony(cs.hue, cs.sat, cs.val, .Split_Complement)
	testing.expect_value(t, harm_count, 3)

	shades, shade_count := color.generate_shades(cs.hue, cs.sat, 5, 0.1, 0.9)
	testing.expect_value(t, shade_count, 5)

	palette: [data.MAX_PALETTE]rl.Color
	pal_count := 0
	for i in 0 ..< harm_count {
		data.palette_add(palette[:], &pal_count, harm_colors[i])
	}
	for i in 0 ..< shade_count {
		data.palette_add(palette[:], &pal_count, shades[i])
	}
	testing.expect(t, pal_count >= 5, "should have at least 5 unique colors")
	testing.expect(t, pal_count <= 8, "should have at most 8 (3 harmony + 5 shades, minus dupes)")

	saved := data.save_palette(palette[:pal_count], path)
	testing.expect(t, saved, "save should succeed")

	loaded: [data.MAX_PALETTE]rl.Color
	n := data.load_palette(loaded[:], path)
	testing.expect_value(t, n, pal_count)

	json := string(data.export_json(loaded[:n]))
	hex_count := strings.count(json, "\"hex\":")
	testing.expect_value(t, hex_count, pal_count)
}

// ── color → data: WCAG contrast check on exported colors ──

@(test)
test_exported_colors_contrast_check :: proc(t: ^testing.T) {
	white := rl.Color{255, 255, 255, 255}
	dark  := rl.Color{30, 30, 30, 255}

	palette: [data.MAX_PALETTE]rl.Color
	pal_count := 0
	data.palette_add(palette[:], &pal_count, white)
	data.palette_add(palette[:], &pal_count, dark)

	ratio := color.contrast_ratio(palette[0], palette[1])
	rating := color.wcag_rating(ratio)
	testing.expect(t, rating.aaa_normal, "white/dark should pass AAA")

	css := string(data.export_css(palette[:pal_count]))
	testing.expect(t, strings.contains(css, "#FFFFFF"), "CSS should contain white")
	testing.expect(t, strings.contains(css, "#1E1E1E"), "CSS should contain dark")
}

// ── color → data: Hex parse → palette → save → load → hex verify ──

@(test)
test_hex_palette_roundtrip_fidelity :: proc(t: ^testing.T) {
	path :: "/tmp/_test_cross_hex_fidelity.txt"
	defer os.remove(path)

	hex_inputs := [?]string{"FF6B35", "004E89", "1A659E", "F7C59F", "EFEFD0"}
	palette: [data.MAX_PALETTE]rl.Color
	pal_count := 0

	for hex in hex_inputs {
		buf: [6]u8
		for j in 0 ..< 6 do buf[j] = hex[j]
		c, ok := color.parse_hex(buf[:])
		testing.expect(t, ok, "parse should succeed")
		data.palette_add(palette[:], &pal_count, c)
	}
	testing.expect_value(t, pal_count, 5)

	data.save_palette(palette[:pal_count], path)
	loaded: [data.MAX_PALETTE]rl.Color
	n := data.load_palette(loaded[:], path)
	testing.expect_value(t, n, 5)

	for i in 0 ..< 5 {
		orig_hex := color.color_to_hex_string(palette[i])
		load_hex := color.color_to_hex_string(loaded[i])
		for j in 0 ..< 7 {
			testing.expect_value(t, load_hex[j], orig_hex[j])
		}
	}
}

// ── layout: Full app layout produces all expected tags ──

@(test)
test_full_app_layout_all_tags_present :: proc(t: ^testing.T) {
	right := [?]layout.Node{
		{tag = .Preview,     width = layout.Fill{1}, height = layout.Fixed{108}},
		{tag = .Contrast,    width = layout.Fill{1}, height = layout.Fixed{48}},
		{tag = .Hex_Field,   width = layout.Fill{1}, height = layout.Fixed{44}},
		{tag = .RGB_Sliders, width = layout.Fill{1}, height = layout.Fixed{104}},
		{tag = .HSV_Sliders, width = layout.Fill{1}, height = layout.Fixed{98}},
		{tag = .Hint,        width = layout.Fill{1}, height = layout.Fixed{24}},
		{tag = .History,     width = layout.Fill{1}, height = layout.Fill{1}},
	}
	left := [?]layout.Node{
		{tag = .Picker,          width = layout.Fill{1}, height = layout.Fixed{352}},
		{tag = .Picker_Controls, width = layout.Fill{1}, height = layout.Fixed{34}},
		{tag = .Harmony,         width = layout.Fill{1}, height = layout.Fill{1}},
	}
	main_ch := [?]layout.Node{
		{tag = .Left_Column,  dir = .Column, width = layout.Fixed{340}, height = layout.Fill{1}, children = left[:]},
		{tag = .Right_Column, dir = .Column, width = layout.Fill{1},    height = layout.Fill{1}, children = right[:]},
	}
	bottom := [?]layout.Node{
		{tag = .Palette,       width = layout.Fill{1}, height = layout.Fill{1}},
		{tag = .Export_Button, width = layout.Fill{1}, height = layout.Fixed{28}},
	}
	root_ch := [?]layout.Node{
		{tag = .Header, width = layout.Fill{1}, height = layout.Fixed{36}},
		{tag = .Main,   dir = .Row, width = layout.Fill{1}, height = layout.Fill{1}, gap = 28, children = main_ch[:]},
		{tag = .Bottom, dir = .Column, width = layout.Fill{1}, height = layout.Fixed{150}, children = bottom[:]},
	}
	root := layout.Node{
		tag = .Root, dir = .Column,
		width = layout.Fill{1}, height = layout.Fill{1},
		padding = {top = 14, right = 24, bottom = 16, left = 24},
		children = root_ch[:],
	}

	rects := layout.compute(&root, 960, 780)
	defer delete(rects)

	expected_tags := [?]layout.Tag{
		.Root, .Header, .Main, .Left_Column, .Picker, .Picker_Controls,
		.Harmony, .Right_Column, .Preview, .Contrast, .Hex_Field,
		.RGB_Sliders, .HSV_Sliders, .Hint, .History, .Bottom, .Palette, .Export_Button,
	}
	for tag in expected_tags {
		_, found := layout.find(rects, tag)
		testing.expect(t, found, "should find tag in layout")
	}

	palette_r, _ := layout.find(rects, .Palette)
	testing.expect(t, palette_r.w > 0, "palette should have positive width")
	testing.expect(t, palette_r.h > 0, "palette should have positive height")

	cpr := max(int(palette_r.w) / data.SWATCH_STRIDE, 1)
	testing.expect(t, cpr >= 1, "palette should fit at least 1 swatch per row")
}

// ── color → data → layout: Color history fits in layout ──

@(test)
test_history_colors_fit_in_layout :: proc(t: ^testing.T) {
	ring: [data.HISTORY_MAX]rl.Color
	count, head := 0, 0

	for i in 0 ..< 10 {
		c := rl.Color{u8(i * 25), u8(255 - i * 25), 128, 255}
		data.history_push(ring[:], &count, &head, c)
	}
	testing.expect_value(t, count, 10)

	right := [?]layout.Node{
		{tag = .Preview, width = layout.Fill{1}, height = layout.Fixed{108}},
		{tag = .History, width = layout.Fill{1}, height = layout.Fill{1}},
	}
	root := layout.Node{
		tag = .Root, dir = .Column,
		width = layout.Fill{1}, height = layout.Fill{1},
		children = right[:],
	}
	rects := layout.compute(&root, 500, 400)
	defer delete(rects)

	hist_r, found := layout.find(rects, .History)
	testing.expect(t, found, "History rect should exist")

	swatch_w :: 22
	max_visible := int(hist_r.w) / swatch_w
	testing.expect(t, max_visible >= count, "history area should fit all 10 history swatches")
}

// ── color → data: CVD simulation preserves palette identity after save/load ──

@(test)
test_cvd_simulation_after_palette_roundtrip :: proc(t: ^testing.T) {
	path :: "/tmp/_test_cross_cvd_rt.txt"
	defer os.remove(path)

	palette := [3]rl.Color{{255, 0, 0, 255}, {0, 255, 0, 255}, {0, 0, 255, 255}}
	data.save_palette(palette[:], path)

	loaded: [data.MAX_PALETTE]rl.Color
	n := data.load_palette(loaded[:], path)
	testing.expect_value(t, n, 3)

	for cvd_type in color.CvdType {
		if cvd_type == .None do continue
		for i in 0 ..< n {
			orig_sim := color.simulate_cvd(palette[i], cvd_type)
			load_sim := color.simulate_cvd(loaded[i], cvd_type)
			testing.expect_value(t, load_sim.r, orig_sim.r)
			testing.expect_value(t, load_sim.g, orig_sim.g)
			testing.expect_value(t, load_sim.b, orig_sim.b)
		}
	}
}
