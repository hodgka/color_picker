package data

import "core:testing"
import "core:strings"
import "core:os"
import rl "vendor:raylib"

RED   :: rl.Color{255, 0, 0, 255}
GREEN :: rl.Color{0, 255, 0, 255}
BLUE  :: rl.Color{0, 0, 255, 255}

@(test)
test_palette_to_hex_array_empty :: proc(t: ^testing.T) {
	result := string(palette_to_hex_array({}))
	testing.expect_value(t, result, "[]")
}

@(test)
test_palette_to_hex_array_single :: proc(t: ^testing.T) {
	colors := []rl.Color{RED}
	result := string(palette_to_hex_array(colors))
	testing.expect(t, strings.contains(result, "#FF0000"), "should contain #FF0000")
}

@(test)
test_palette_to_hex_array_multiple :: proc(t: ^testing.T) {
	colors := []rl.Color{RED, GREEN, BLUE}
	result := string(palette_to_hex_array(colors))
	testing.expect(t, strings.contains(result, "#FF0000"), "should contain red")
	testing.expect(t, strings.contains(result, "#00FF00"), "should contain green")
	testing.expect(t, strings.contains(result, "#0000FF"), "should contain blue")
}

@(test)
test_export_css_structure :: proc(t: ^testing.T) {
	colors := []rl.Color{RED, BLUE}
	result := string(export_css(colors))
	testing.expect(t, strings.contains(result, ":root {"), "should start with :root")
	testing.expect(t, strings.contains(result, "--color-1: #FF0000"), "should have color-1")
	testing.expect(t, strings.contains(result, "--color-2: #0000FF"), "should have color-2")
	testing.expect(t, strings.contains(result, "}"), "should close brace")
}

@(test)
test_export_tailwind_structure :: proc(t: ^testing.T) {
	colors := []rl.Color{RED}
	result := string(export_tailwind(colors))
	testing.expect(t, strings.contains(result, "module.exports"), "should have module.exports")
	testing.expect(t, strings.contains(result, "'color-1': '#FF0000'"), "should have color entry")
}

@(test)
test_export_json_structure :: proc(t: ^testing.T) {
	colors := []rl.Color{RED, GREEN}
	result := string(export_json(colors))
	testing.expect(t, strings.has_prefix(result, "["), "should start with [")
	testing.expect(t, strings.contains(result, "\"hex\":\"#FF0000\""), "should have red hex")
	testing.expect(t, strings.contains(result, "\"r\":255"), "should have r:255")
	testing.expect(t, strings.contains(result, "\"hex\":\"#00FF00\""), "should have green hex")
}

@(test)
test_export_gpl_roundtrip :: proc(t: ^testing.T) {
	path :: "/tmp/_test_colorpicker_export.gpl"
	defer os.remove(path)

	colors := []rl.Color{RED, GREEN}
	ok := export_gpl(colors, path)
	testing.expect(t, ok, "export_gpl should succeed")

	data, err := os.read_entire_file_from_path(path, context.allocator)
	testing.expect(t, err == nil, "should be able to read back GPL file")
	defer delete(data)

	content := string(data)
	testing.expect(t, strings.has_prefix(content, "GIMP Palette"), "should start with GIMP Palette header")
	testing.expect(t, strings.contains(content, "255"), "should contain red R component")
	testing.expect(t, strings.contains(content, "#FF0000"), "should contain red hex")
}

@(test)
test_export_ase_roundtrip :: proc(t: ^testing.T) {
	path :: "/tmp/_test_colorpicker_export.ase"
	defer os.remove(path)

	colors := []rl.Color{RED, BLUE}
	ok := export_ase(colors, path)
	testing.expect(t, ok, "export_ase should succeed")

	data, err := os.read_entire_file_from_path(path, context.allocator)
	testing.expect(t, err == nil, "should be able to read back ASE file")
	defer delete(data)

	testing.expect(t, len(data) > 12, "ASE file should have header + entries")
	testing.expect(t, data[0] == 0x41 && data[1] == 0x53 && data[2] == 0x45 && data[3] == 0x46, "ASE magic bytes")
}

@(test)
test_export_text_file_roundtrip :: proc(t: ^testing.T) {
	path :: "/tmp/_test_colorpicker_export.txt"
	defer os.remove(path)

	ok := export_text_file("hello world", path)
	testing.expect(t, ok, "export_text_file should succeed")

	data, err := os.read_entire_file_from_path(path, context.allocator)
	testing.expect(t, err == nil, "should be able to read back text file")
	defer delete(data)

	testing.expect_value(t, string(data), "hello world")
}
