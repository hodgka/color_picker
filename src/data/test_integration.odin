package data

import "core:testing"
import "core:strings"
import "core:os"
import rl "vendor:raylib"
import "../color"

// ── Palette save → load round-trip ──

@(test)
test_palette_save_load_roundtrip :: proc(t: ^testing.T) {
	path :: "/tmp/_test_cp_roundtrip.txt"
	defer os.remove(path)

	src := [3]rl.Color{{255, 0, 0, 255}, {0, 128, 64, 255}, {10, 20, 30, 255}}
	ok := save_palette(src[:], path)
	testing.expect(t, ok, "save_palette should succeed")

	loaded: [MAX_PALETTE]rl.Color
	n := load_palette(loaded[:], path)
	testing.expect_value(t, n, 3)

	for i in 0 ..< 3 {
		testing.expect_value(t, loaded[i].r, src[i].r)
		testing.expect_value(t, loaded[i].g, src[i].g)
		testing.expect_value(t, loaded[i].b, src[i].b)
	}
}

@(test)
test_palette_save_load_empty :: proc(t: ^testing.T) {
	path :: "/tmp/_test_cp_empty.txt"
	defer os.remove(path)

	ok := save_palette([]rl.Color{}, path)
	testing.expect(t, ok, "save empty palette should succeed")

	loaded: [MAX_PALETTE]rl.Color
	n := load_palette(loaded[:], path)
	testing.expect_value(t, n, 0)
}

@(test)
test_load_palette_with_whitespace_and_hash :: proc(t: ^testing.T) {
	path :: "/tmp/_test_cp_whitespace.txt"
	defer os.remove(path)

	content := "  #FF0000\n\t#00FF00\n  0000FF\n"
	_ = os.write_entire_file(path, transmute([]u8)content)

	loaded: [MAX_PALETTE]rl.Color
	n := load_palette(loaded[:], path)
	testing.expect_value(t, n, 3)
	testing.expect_value(t, loaded[0], rl.Color{255, 0, 0, 255})
	testing.expect_value(t, loaded[1], rl.Color{0, 255, 0, 255})
	testing.expect_value(t, loaded[2], rl.Color{0, 0, 255, 255})
}

@(test)
test_load_palette_skips_invalid_hex :: proc(t: ^testing.T) {
	path :: "/tmp/_test_cp_invalid.txt"
	defer os.remove(path)

	content := "#FF0000\n#GGGGGG\n#0000FF\n"
	_ = os.write_entire_file(path, transmute([]u8)content)

	loaded: [MAX_PALETTE]rl.Color
	n := load_palette(loaded[:], path)
	testing.expect_value(t, n, 2)
	testing.expect_value(t, loaded[0], rl.Color{255, 0, 0, 255})
	testing.expect_value(t, loaded[1], rl.Color{0, 0, 255, 255})
}

@(test)
test_load_palette_missing_file :: proc(t: ^testing.T) {
	loaded: [MAX_PALETTE]rl.Color
	n := load_palette(loaded[:], "/tmp/_test_cp_nonexistent_42.txt")
	testing.expect_value(t, n, 0)
}

// ── Palette add → move → remove sequence ──

@(test)
test_palette_add_move_remove_sequence :: proc(t: ^testing.T) {
	palette: [MAX_PALETTE]rl.Color
	count := 0
	red   := rl.Color{255, 0, 0, 255}
	green := rl.Color{0, 255, 0, 255}
	blue  := rl.Color{0, 0, 255, 255}

	palette_add(palette[:], &count, red)
	palette_add(palette[:], &count, green)
	palette_add(palette[:], &count, blue)
	testing.expect_value(t, count, 3)

	palette_move(palette[:], count, 2, 0)
	testing.expect_value(t, palette[0], blue)
	testing.expect_value(t, palette[1], red)
	testing.expect_value(t, palette[2], green)

	palette_remove(palette[:], &count, 1)
	testing.expect_value(t, count, 2)
	testing.expect_value(t, palette[0], blue)
	testing.expect_value(t, palette[1], green)
}

@(test)
test_palette_move_forward_and_backward :: proc(t: ^testing.T) {
	a := rl.Color{10, 0, 0, 255}
	b := rl.Color{20, 0, 0, 255}
	c := rl.Color{30, 0, 0, 255}
	palette := [3]rl.Color{a, b, c}

	palette_move(palette[:], 3, 0, 2)
	testing.expect_value(t, palette[0], b)
	testing.expect_value(t, palette[1], c)
	testing.expect_value(t, palette[2], a)

	palette_move(palette[:], 3, 2, 0)
	testing.expect_value(t, palette[0], a)
	testing.expect_value(t, palette[1], b)
	testing.expect_value(t, palette[2], c)
}

// ── History → palette → export pipeline ──

@(test)
test_history_to_palette_to_css_export :: proc(t: ^testing.T) {
	ring: [HISTORY_MAX]rl.Color
	count, head := 0, 0

	red   := rl.Color{255, 0, 0, 255}
	green := rl.Color{0, 255, 0, 255}

	history_push(ring[:], &count, &head, red)
	history_push(ring[:], &count, &head, green)
	testing.expect_value(t, count, 2)

	palette: [MAX_PALETTE]rl.Color
	pal_count := 0
	for i in 0 ..< count {
		c := history_get(ring[:], count, head, i)
		palette_add(palette[:], &pal_count, c)
	}
	testing.expect_value(t, pal_count, 2)

	css := string(export_css(palette[:pal_count]))
	testing.expect(t, strings.contains(css, "--color-1: #FF0000"), "CSS should contain red")
	testing.expect(t, strings.contains(css, "--color-2: #00FF00"), "CSS should contain green")
}

@(test)
test_harmony_to_palette_to_json_export :: proc(t: ^testing.T) {
	harm_colors, harm_count := color.compute_harmony(0, 1, 1, .Triadic)
	testing.expect_value(t, harm_count, 3)

	palette: [MAX_PALETTE]rl.Color
	pal_count := 0
	for i in 0 ..< harm_count {
		palette_add(palette[:], &pal_count, harm_colors[i])
	}
	testing.expect_value(t, pal_count, 3)

	json := string(export_json(palette[:pal_count]))
	testing.expect(t, strings.contains(json, "\"hex\":\"#"), "JSON should contain hex entries")
	testing.expect(t, strings.contains(json, "\"r\":"), "JSON should contain r values")

	line_count := strings.count(json, "\"hex\":")
	testing.expect_value(t, line_count, 3)
}

// ── Palette save → load → export round-trip ──

@(test)
test_palette_save_load_export_roundtrip :: proc(t: ^testing.T) {
	path :: "/tmp/_test_cp_save_export.txt"
	defer os.remove(path)

	src := [2]rl.Color{{171, 205, 239, 255}, {50, 100, 150, 255}}
	save_palette(src[:], path)

	loaded: [MAX_PALETTE]rl.Color
	n := load_palette(loaded[:], path)
	testing.expect_value(t, n, 2)

	css := string(export_css(loaded[:n]))
	testing.expect(t, strings.contains(css, "--color-1: #ABCDEF"), "CSS should match original hex")
	testing.expect(t, strings.contains(css, "--color-2: #326496"), "CSS should match second color")
}

// ── GPL export structure ──

@(test)
test_gpl_export_load_roundtrip :: proc(t: ^testing.T) {
	gpl_path :: "/tmp/_test_cp_gpl_roundtrip.gpl"
	pal_path :: "/tmp/_test_cp_gpl_roundtrip.txt"
	defer os.remove(gpl_path)
	defer os.remove(pal_path)

	colors := [2]rl.Color{{255, 128, 0, 255}, {0, 64, 128, 255}}

	ok_gpl := export_gpl(colors[:], gpl_path)
	testing.expect(t, ok_gpl, "GPL export should succeed")

	ok_save := save_palette(colors[:], pal_path)
	testing.expect(t, ok_save, "palette save should succeed")

	loaded: [MAX_PALETTE]rl.Color
	n := load_palette(loaded[:], pal_path)
	testing.expect_value(t, n, 2)
	testing.expect_value(t, loaded[0], colors[0])
	testing.expect_value(t, loaded[1], colors[1])

	gpl_data, err := os.read_entire_file_from_path(gpl_path, context.allocator)
	testing.expect(t, err == nil, "should read GPL file")
	defer delete(gpl_data)
	gpl_str := string(gpl_data)
	testing.expect(t, strings.has_prefix(gpl_str, "GIMP Palette"), "GPL header")
	testing.expect(t, strings.contains(gpl_str, "#FF8000"), "GPL should contain first color hex")
	testing.expect(t, strings.contains(gpl_str, "#004080"), "GPL should contain second color hex")
}

// ── ASE header validation ──

@(test)
test_ase_export_entry_count :: proc(t: ^testing.T) {
	path :: "/tmp/_test_cp_ase_count.ase"
	defer os.remove(path)

	colors := [3]rl.Color{{255, 0, 0, 255}, {0, 255, 0, 255}, {0, 0, 255, 255}}
	ok := export_ase(colors[:], path)
	testing.expect(t, ok, "ASE export should succeed")

	data, err := os.read_entire_file_from_path(path, context.allocator)
	testing.expect(t, err == nil, "should read ASE file")
	defer delete(data)

	testing.expect(t, data[0] == 0x41, "ASE magic byte 0")
	testing.expect(t, data[1] == 0x53, "ASE magic byte 1")
	testing.expect(t, data[2] == 0x45, "ASE magic byte 2")
	testing.expect(t, data[3] == 0x46, "ASE magic byte 3")

	entry_count := u32(data[8]) << 24 | u32(data[9]) << 16 | u32(data[10]) << 8 | u32(data[11])
	testing.expect_value(t, entry_count, u32(3))
}

// ── Tailwind export structure ──

@(test)
test_tailwind_export_contains_all_colors :: proc(t: ^testing.T) {
	colors := [3]rl.Color{{10, 20, 30, 255}, {40, 50, 60, 255}, {70, 80, 90, 255}}
	tw := string(export_tailwind(colors[:]))

	testing.expect(t, strings.contains(tw, "'color-1': '#0A141E'"), "should have color-1")
	testing.expect(t, strings.contains(tw, "'color-2': '#28323C'"), "should have color-2")
	testing.expect(t, strings.contains(tw, "'color-3': '#46505A'"), "should have color-3")
}

// ── Export text file round-trip ──

@(test)
test_css_to_text_file_roundtrip :: proc(t: ^testing.T) {
	path :: "/tmp/_test_cp_css_file.css"
	defer os.remove(path)

	colors := [1]rl.Color{{255, 0, 0, 255}}
	css := export_css(colors[:])

	ok := export_text_file(css, path)
	testing.expect(t, ok, "text file export should succeed")

	data, err := os.read_entire_file_from_path(path, context.allocator)
	testing.expect(t, err == nil, "should read back CSS file")
	defer delete(data)

	content := string(data)
	testing.expect(t, strings.contains(content, ":root {"), "file should contain :root")
	testing.expect(t, strings.contains(content, "--color-1: #FF0000"), "file should contain color")
}
