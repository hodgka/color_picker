package color_picker

import "core:testing"
import rl "vendor:raylib"

// ── parse_hex ──

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
test_parse_hex_specific_value :: proc(t: ^testing.T) {
	input := [6]u8{'7', 'B', '2', 'D', '8', '3'}
	c, ok := parse_hex(input[:])
	testing.expect(t, ok)
	testing.expect_value(t, c, rl.Color{0x7B, 0x2D, 0x83, 255})
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
	testing.expect(t, !ok, "should reject 'G'")

	invalid2 := [6]u8{'0', '0', 'Z', '0', '0', '0'}
	_, ok2 := parse_hex(invalid2[:])
	testing.expect(t, !ok2, "should reject 'Z'")

	invalid3 := [6]u8{'0', '0', '0', ' ', '0', '0'}
	_, ok3 := parse_hex(invalid3[:])
	testing.expect(t, !ok3, "should reject space")
}

@(test)
test_parse_hex_rejects_wrong_length :: proc(t: ^testing.T) {
	short := [5]u8{'F', 'F', '0', '0', '0'}
	_, ok := parse_hex(short[:])
	testing.expect(t, !ok, "should reject len 5")

	long := [7]u8{'F', 'F', '0', '0', '0', '0', 'F'}
	_, ok2 := parse_hex(long[:])
	testing.expect(t, !ok2, "should reject len 7")

	_, ok3 := parse_hex(nil)
	testing.expect(t, !ok3, "should reject nil")
}

// ── sync_hex ──

@(test)
test_sync_hex_black :: proc(t: ^testing.T) {
	buf: [6]u8
	sync_hex(&buf, rl.Color{0, 0, 0, 255})
	testing.expect_value(t, buf, [6]u8{'0', '0', '0', '0', '0', '0'})
}

@(test)
test_sync_hex_white :: proc(t: ^testing.T) {
	buf: [6]u8
	sync_hex(&buf, rl.Color{255, 255, 255, 255})
	testing.expect_value(t, buf, [6]u8{'F', 'F', 'F', 'F', 'F', 'F'})
}

@(test)
test_sync_hex_specific_color :: proc(t: ^testing.T) {
	buf: [6]u8
	sync_hex(&buf, rl.Color{0xAB, 0xCD, 0xEF, 255})
	testing.expect_value(t, buf, [6]u8{'A', 'B', 'C', 'D', 'E', 'F'})
}

@(test)
test_sync_hex_zero_pads :: proc(t: ^testing.T) {
	buf: [6]u8
	sync_hex(&buf, rl.Color{1, 2, 3, 255})
	testing.expect_value(t, buf, [6]u8{'0', '1', '0', '2', '0', '3'})
}

// ── roundtrip ──

@(test)
test_hex_roundtrip :: proc(t: ^testing.T) {
	colors := [?]rl.Color{
		{0, 0, 0, 255},
		{255, 255, 255, 255},
		{255, 0, 0, 255},
		{0, 255, 0, 255},
		{0, 0, 255, 255},
		{123, 45, 67, 255},
		{0xAB, 0xCD, 0xEF, 255},
		{1, 1, 1, 255},
	}
	for original in colors {
		buf: [6]u8
		sync_hex(&buf, original)
		recovered, ok := parse_hex(buf[:])
		testing.expect(t, ok)
		testing.expect_value(t, recovered.r, original.r)
		testing.expect_value(t, recovered.g, original.g)
		testing.expect_value(t, recovered.b, original.b)
	}
}

// ── is_hex_char ──

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
	testing.expect(t, !is_hex_char('z'))
	testing.expect(t, !is_hex_char('/'))
	testing.expect(t, !is_hex_char(':'))
	testing.expect(t, !is_hex_char('@'))
	testing.expect(t, !is_hex_char('['))
	testing.expect(t, !is_hex_char('`'))
}

// ── upper_hex ──

@(test)
test_upper_hex_converts_lowercase :: proc(t: ^testing.T) {
	testing.expect_value(t, upper_hex('a'), u8('A'))
	testing.expect_value(t, upper_hex('b'), u8('B'))
	testing.expect_value(t, upper_hex('c'), u8('C'))
	testing.expect_value(t, upper_hex('d'), u8('D'))
	testing.expect_value(t, upper_hex('e'), u8('E'))
	testing.expect_value(t, upper_hex('f'), u8('F'))
}

@(test)
test_upper_hex_preserves_nonlower :: proc(t: ^testing.T) {
	testing.expect_value(t, upper_hex('A'), u8('A'))
	testing.expect_value(t, upper_hex('F'), u8('F'))
	testing.expect_value(t, upper_hex('0'), u8('0'))
	testing.expect_value(t, upper_hex('9'), u8('9'))
}

// ── all_hex_str ──

@(test)
test_all_hex_str_valid :: proc(t: ^testing.T) {
	testing.expect(t, all_hex_str("0123456789abcdef"))
	testing.expect(t, all_hex_str("ABCDEF"))
	testing.expect(t, all_hex_str("FF00FF"))
	testing.expect(t, all_hex_str(""))
}

@(test)
test_all_hex_str_invalid :: proc(t: ^testing.T) {
	testing.expect(t, !all_hex_str("GGGGGG"))
	testing.expect(t, !all_hex_str("#FF00FF"))
	testing.expect(t, !all_hex_str("hello!"))
	testing.expect(t, !all_hex_str("12345z"))
}

// ── swatch_rect ──

@(test)
test_swatch_rect_first :: proc(t: ^testing.T) {
	r := swatch_rect(0)
	testing.expect_value(t, r.x, f32(MARGIN))
	testing.expect_value(t, r.y, f32(PALETTE_Y))
	testing.expect_value(t, r.width, f32(SWATCH_SZ))
	testing.expect_value(t, r.height, f32(SWATCH_SZ))
}

@(test)
test_swatch_rect_sequential :: proc(t: ^testing.T) {
	r0 := swatch_rect(0)
	r1 := swatch_rect(1)
	testing.expect_value(t, r1.x, r0.x + f32(SWATCH_STRIDE))
	testing.expect_value(t, r1.y, r0.y)
}

@(test)
test_swatch_rect_row_wrap :: proc(t: ^testing.T) {
	r := swatch_rect(COLS_PER_ROW)
	testing.expect_value(t, r.x, f32(MARGIN))
	testing.expect_value(t, r.y, f32(PALETTE_Y) + f32(SWATCH_STRIDE))
}

@(test)
test_swatch_rect_second_row_offset :: proc(t: ^testing.T) {
	r := swatch_rect(COLS_PER_ROW + 2)
	testing.expect_value(t, r.x, f32(MARGIN) + 2 * f32(SWATCH_STRIDE))
	testing.expect_value(t, r.y, f32(PALETTE_Y) + f32(SWATCH_STRIDE))
}

// ── ColorState ──

@(test)
test_color_init_defaults :: proc(t: ^testing.T) {
	cs := color_init()
	testing.expect_value(t, cs.hue, f32(0))
	testing.expect_value(t, cs.sat, f32(1))
	testing.expect_value(t, cs.val, f32(1))
	testing.expect_value(t, cs.hex_len, 6)
}

@(test)
test_color_init_custom :: proc(t: ^testing.T) {
	cs := color_init(h = 120, s = 0.5, v = 0.75)
	testing.expect_value(t, cs.hue, f32(120))
	testing.expect_value(t, cs.sat, f32(0.5))
	testing.expect_value(t, cs.val, f32(0.75))
	testing.expect_value(t, cs.hex_len, 6)
}

@(test)
test_color_set_hsv_updates_hex :: proc(t: ^testing.T) {
	cs := color_init()
	color_set_hsv(&cs, 0, 1, 1)
	testing.expect_value(t, cs.hex_buf, [6]u8{'F', 'F', '0', '0', '0', '0'})
	testing.expect_value(t, cs.hex_len, 6)
}

@(test)
test_color_set_hsv_stores_values :: proc(t: ^testing.T) {
	cs := color_init()
	color_set_hsv(&cs, 180, 0.5, 0.75)
	testing.expect_value(t, cs.hue, f32(180))
	testing.expect_value(t, cs.sat, f32(0.5))
	testing.expect_value(t, cs.val, f32(0.75))
}

@(test)
test_color_set_rgb_exact :: proc(t: ^testing.T) {
	cs := color_init()
	color_set_rgb(&cs, rl.Color{255, 0, 0, 255})
	testing.expect_value(t, cs.hex_buf, [6]u8{'F', 'F', '0', '0', '0', '0'})
	testing.expect_value(t, cs.hex_len, 6)
}

@(test)
test_color_set_rgb_preserve_hue_for_gray :: proc(t: ^testing.T) {
	cs := color_init()
	color_set_hsv(&cs, 120, 1, 1)
	original_hue := cs.hue

	color_set_rgb(&cs, rl.Color{128, 128, 128, 255}, preserve_hue = true)
	testing.expect_value(t, cs.hue, original_hue)
}

@(test)
test_color_set_rgb_no_preserve_hue_for_gray :: proc(t: ^testing.T) {
	cs := color_init()
	color_set_hsv(&cs, 120, 1, 1)

	color_set_rgb(&cs, rl.Color{128, 128, 128, 255}, preserve_hue = false)
	testing.expect_value(t, cs.hue, f32(0))
}

@(test)
test_color_apply_hex_updates_hsv :: proc(t: ^testing.T) {
	cs := color_init()
	cs.hex_buf = {'0', '0', 'F', 'F', '0', '0'}
	cs.hex_len = 6

	ok := color_apply_hex(&cs)
	testing.expect(t, ok)
	c := color_get(&cs)
	testing.expect_value(t, c.g, u8(255))
}

@(test)
test_color_apply_hex_fails_on_short :: proc(t: ^testing.T) {
	cs := color_init()
	cs.hex_len = 4
	ok := color_apply_hex(&cs)
	testing.expect(t, !ok)
}

@(test)
test_color_apply_hex_preserves_buffer :: proc(t: ^testing.T) {
	cs := color_init()
	cs.hex_buf = {'A', 'B', 'C', 'D', 'E', 'F'}
	cs.hex_len = 6
	color_apply_hex(&cs)
	testing.expect_value(t, cs.hex_buf, [6]u8{'A', 'B', 'C', 'D', 'E', 'F'})
}

@(test)
test_color_get_returns_correct_color :: proc(t: ^testing.T) {
	cs := color_init(h = 0, s = 0, v = 0)
	c := color_get(&cs)
	testing.expect_value(t, c, rl.Color{0, 0, 0, 255})
}

// ── palette_add ──

@(test)
test_palette_add_basic :: proc(t: ^testing.T) {
	palette: [4]rl.Color
	count := 0

	ok := palette_add(palette[:], &count, rl.Color{255, 0, 0, 255})
	testing.expect(t, ok)
	testing.expect_value(t, count, 1)
	testing.expect_value(t, palette[0], rl.Color{255, 0, 0, 255})
}

@(test)
test_palette_add_rejects_duplicate :: proc(t: ^testing.T) {
	palette: [4]rl.Color
	count := 0

	palette_add(palette[:], &count, rl.Color{255, 0, 0, 255})
	ok := palette_add(palette[:], &count, rl.Color{255, 0, 0, 255})
	testing.expect(t, !ok, "should reject duplicate")
	testing.expect_value(t, count, 1)
}

@(test)
test_palette_add_respects_capacity :: proc(t: ^testing.T) {
	palette: [2]rl.Color
	count := 0

	palette_add(palette[:], &count, rl.Color{255, 0, 0, 255})
	palette_add(palette[:], &count, rl.Color{0, 255, 0, 255})
	ok := palette_add(palette[:], &count, rl.Color{0, 0, 255, 255})
	testing.expect(t, !ok, "should reject when full")
	testing.expect_value(t, count, 2)
}

@(test)
test_palette_add_distinguishes_colors :: proc(t: ^testing.T) {
	palette: [4]rl.Color
	count := 0

	palette_add(palette[:], &count, rl.Color{255, 0, 0, 255})
	ok := palette_add(palette[:], &count, rl.Color{255, 0, 1, 255})
	testing.expect(t, ok, "should accept different color")
	testing.expect_value(t, count, 2)
}

// ── palette_remove ──

@(test)
test_palette_remove_basic :: proc(t: ^testing.T) {
	palette := [3]rl.Color{{255, 0, 0, 255}, {0, 255, 0, 255}, {0, 0, 255, 255}}
	count := 3

	ok := palette_remove(palette[:], &count, 1)
	testing.expect(t, ok)
	testing.expect_value(t, count, 2)
	testing.expect_value(t, palette[0], rl.Color{255, 0, 0, 255})
	testing.expect_value(t, palette[1], rl.Color{0, 0, 255, 255})
}

@(test)
test_palette_remove_first :: proc(t: ^testing.T) {
	palette := [2]rl.Color{{255, 0, 0, 255}, {0, 255, 0, 255}}
	count := 2

	palette_remove(palette[:], &count, 0)
	testing.expect_value(t, count, 1)
	testing.expect_value(t, palette[0], rl.Color{0, 255, 0, 255})
}

@(test)
test_palette_remove_last :: proc(t: ^testing.T) {
	palette := [2]rl.Color{{255, 0, 0, 255}, {0, 255, 0, 255}}
	count := 2

	palette_remove(palette[:], &count, 1)
	testing.expect_value(t, count, 1)
	testing.expect_value(t, palette[0], rl.Color{255, 0, 0, 255})
}

@(test)
test_palette_remove_out_of_bounds :: proc(t: ^testing.T) {
	palette: [2]rl.Color
	count := 1

	testing.expect(t, !palette_remove(palette[:], &count, -1))
	testing.expect(t, !palette_remove(palette[:], &count, 1))
	testing.expect(t, !palette_remove(palette[:], &count, 5))
	testing.expect_value(t, count, 1)
}
