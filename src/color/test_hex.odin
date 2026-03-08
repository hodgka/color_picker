package color

import "core:testing"
import rl "vendor:raylib"

@(test)
test_parse_hex_black :: proc(t: ^testing.T) {
	input := [6]u8{'0', '0', '0', '0', '0', '0'}
	c, ok := parse_hex(input[:])
	testing.expect(t, ok)
	testing.expect_value(t, c, rl.Color{0, 0, 0, 255})
}

@(test)
test_parse_hex_white :: proc(t: ^testing.T) {
	input := [6]u8{'F', 'F', 'F', 'F', 'F', 'F'}
	c, ok := parse_hex(input[:])
	testing.expect(t, ok)
	testing.expect_value(t, c, rl.Color{255, 255, 255, 255})
}

@(test)
test_parse_hex_primary_colors :: proc(t: ^testing.T) {
	red := [6]u8{'F', 'F', '0', '0', '0', '0'}
	c, ok := parse_hex(red[:])
	testing.expect(t, ok)
	testing.expect_value(t, c, rl.Color{255, 0, 0, 255})

	green := [6]u8{'0', '0', 'F', 'F', '0', '0'}
	c, ok = parse_hex(green[:])
	testing.expect(t, ok)
	testing.expect_value(t, c, rl.Color{0, 255, 0, 255})

	blue := [6]u8{'0', '0', '0', '0', 'F', 'F'}
	c, ok = parse_hex(blue[:])
	testing.expect(t, ok)
	testing.expect_value(t, c, rl.Color{0, 0, 255, 255})
}

@(test)
test_parse_hex_lowercase :: proc(t: ^testing.T) {
	input := [6]u8{'a', 'b', 'c', 'd', 'e', 'f'}
	c, ok := parse_hex(input[:])
	testing.expect(t, ok)
	testing.expect_value(t, c, rl.Color{0xAB, 0xCD, 0xEF, 255})
}

@(test)
test_parse_hex_mixed_case :: proc(t: ^testing.T) {
	input := [6]u8{'A', 'a', 'B', 'b', 'C', 'c'}
	c, ok := parse_hex(input[:])
	testing.expect(t, ok)
	testing.expect_value(t, c, rl.Color{0xAA, 0xBB, 0xCC, 255})
}

@(test)
test_parse_hex_always_sets_alpha_255 :: proc(t: ^testing.T) {
	input := [6]u8{'0', '0', '0', '0', '0', '0'}
	c, ok := parse_hex(input[:])
	testing.expect(t, ok)
	testing.expect_value(t, c.a, u8(255))
}

@(test)
test_parse_hex_rejects_invalid_chars :: proc(t: ^testing.T) {
	invalid := [6]u8{'G', 'G', '0', '0', '0', '0'}
	_, ok := parse_hex(invalid[:])
	testing.expect(t, !ok)
}

@(test)
test_parse_hex_rejects_wrong_length :: proc(t: ^testing.T) {
	short := [5]u8{'F', 'F', '0', '0', '0'}
	_, ok := parse_hex(short[:])
	testing.expect(t, !ok)

	_, ok3 := parse_hex(nil)
	testing.expect(t, !ok3)
}

@(test)
test_color_to_hex_string_black :: proc(t: ^testing.T) {
	buf := color_to_hex_string(rl.Color{0, 0, 0, 255})
	testing.expect_value(t, buf[1], u8('0'))
	testing.expect_value(t, buf[2], u8('0'))
	testing.expect_value(t, buf[3], u8('0'))
	testing.expect_value(t, buf[4], u8('0'))
	testing.expect_value(t, buf[5], u8('0'))
	testing.expect_value(t, buf[6], u8('0'))
}

@(test)
test_color_to_hex_string_white :: proc(t: ^testing.T) {
	buf := color_to_hex_string(rl.Color{255, 255, 255, 255})
	testing.expect_value(t, string(buf[1:7]), "FFFFFF")
}

@(test)
test_color_to_hex_string_specific :: proc(t: ^testing.T) {
	buf := color_to_hex_string(rl.Color{0xAB, 0xCD, 0xEF, 255})
	testing.expect_value(t, string(buf[1:7]), "ABCDEF")
}

@(test)
test_color_to_hex_string_zero_pads :: proc(t: ^testing.T) {
	buf := color_to_hex_string(rl.Color{1, 2, 3, 255})
	testing.expect_value(t, string(buf[1:7]), "010203")
}

@(test)
test_hex_roundtrip :: proc(t: ^testing.T) {
	colors := [?]rl.Color{
		{0, 0, 0, 255},
		{255, 255, 255, 255},
		{255, 0, 0, 255},
		{123, 45, 67, 255},
	}
	for original in colors {
		hex := color_to_hex_string(original)
		hex_slice: [6]u8
		for i in 0 ..< 6 do hex_slice[i] = hex[i + 1]
		recovered, ok := parse_hex(hex_slice[:])
		testing.expect(t, ok)
		testing.expect_value(t, recovered.r, original.r)
		testing.expect_value(t, recovered.g, original.g)
		testing.expect_value(t, recovered.b, original.b)
	}
}

@(test)
test_is_hex_char_valid :: proc(t: ^testing.T) {
	for c in '0' ..= '9' do testing.expect(t, is_hex_char(u8(c)))
	for c in 'a' ..= 'f' do testing.expect(t, is_hex_char(u8(c)))
	for c in 'A' ..= 'F' do testing.expect(t, is_hex_char(u8(c)))
}

@(test)
test_is_hex_char_invalid :: proc(t: ^testing.T) {
	testing.expect(t, !is_hex_char('g'))
	testing.expect(t, !is_hex_char('G'))
	testing.expect(t, !is_hex_char(' '))
	testing.expect(t, !is_hex_char('#'))
}

@(test)
test_upper_hex_converts_lowercase :: proc(t: ^testing.T) {
	testing.expect_value(t, upper_hex('a'), u8('A'))
	testing.expect_value(t, upper_hex('f'), u8('F'))
}

@(test)
test_upper_hex_preserves_nonlower :: proc(t: ^testing.T) {
	testing.expect_value(t, upper_hex('A'), u8('A'))
	testing.expect_value(t, upper_hex('0'), u8('0'))
}

@(test)
test_all_hex_str_valid :: proc(t: ^testing.T) {
	testing.expect(t, all_hex_str("ABCDEF"))
	testing.expect(t, all_hex_str(""))
}

@(test)
test_all_hex_str_invalid :: proc(t: ^testing.T) {
	testing.expect(t, !all_hex_str("GGGGGG"))
	testing.expect(t, !all_hex_str("#FF00FF"))
}
