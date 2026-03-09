package color

import "core:testing"
import "core:math"
import rl "vendor:raylib"

// ── Hex → color → hex round-trip ──

@(test)
test_hex_color_hex_roundtrip :: proc(t: ^testing.T) {
	cases := [?][6]u8{
		{'F', 'F', '0', '0', '0', '0'},
		{'0', '0', 'F', 'F', '0', '0'},
		{'0', '0', '0', '0', 'F', 'F'},
		{'A', 'B', 'C', 'D', 'E', 'F'},
		{'0', '0', '0', '0', '0', '0'},
		{'F', 'F', 'F', 'F', 'F', 'F'},
	}
	for &hex_in in cases {
		c, ok := parse_hex(hex_in[:])
		testing.expect(t, ok, "parse_hex should succeed")

		hex_out := color_to_hex_string(c)
		for i in 0 ..< 6 {
			testing.expect_value(t, hex_out[i + 1], hex_in[i])
		}
	}
}

// ── Set HSV → get RGB → set RGB → compare HSV ──

@(test)
test_hsv_rgb_hsv_roundtrip :: proc(t: ^testing.T) {
	cs := color_init(120, 0.8, 0.9)
	c := color_get(&cs)

	cs2: ColorState
	color_set_rgb(&cs2, c)

	testing.expect(t, math.abs(cs2.hue - cs.hue) < 1.0, "hue should round-trip within 1 degree")
	testing.expect(t, math.abs(cs2.sat - cs.sat) < 0.02, "saturation should round-trip within 0.02")
	testing.expect(t, math.abs(cs2.val - cs.val) < 0.02, "value should round-trip within 0.02")
}

// ── Apply hex string → get color → verify ──

@(test)
test_apply_hex_then_get_color :: proc(t: ^testing.T) {
	cs := color_init()
	ok := color_apply_hex_str(&cs, "ABCDEF")
	testing.expect(t, ok, "should parse ABCDEF")

	c := color_get(&cs)
	testing.expect_value(t, c.r, u8(171))
	testing.expect_value(t, c.g, u8(205))
	testing.expect_value(t, c.b, u8(239))
}

@(test)
test_apply_hex_preserves_hue_on_grey :: proc(t: ^testing.T) {
	cs := color_init(200, 1, 1)
	original_hue := cs.hue

	color_apply_hex_str(&cs, "808080", preserve_hue = true)
	testing.expect_value(t, cs.hue, original_hue)
}

// ── Hex → color → harmony → verify distinct colors ──

@(test)
test_hex_to_harmony_pipeline :: proc(t: ^testing.T) {
	cs := color_init()
	color_apply_hex_str(&cs, "FF0000")

	harm_colors, harm_count := compute_harmony(cs.hue, cs.sat, cs.val, .Triadic)
	testing.expect_value(t, harm_count, 3)

	for i in 0 ..< harm_count {
		for j in i + 1 ..< harm_count {
			same := harm_colors[i].r == harm_colors[j].r &&
			        harm_colors[i].g == harm_colors[j].g &&
			        harm_colors[i].b == harm_colors[j].b
			testing.expect(t, !same, "triadic colors should be distinct")
		}
	}
}

@(test)
test_complementary_harmony_opposite_hue :: proc(t: ^testing.T) {
	cs := color_init(60, 1, 1)
	harm_colors, harm_count := compute_harmony(cs.hue, cs.sat, cs.val, .Complementary)
	testing.expect_value(t, harm_count, 2)

	c1_hsv := rl.ColorToHSV(harm_colors[0])
	c2_hsv := rl.ColorToHSV(harm_colors[1])
	hue_diff := math.abs(c2_hsv.x - c1_hsv.x)
	testing.expect(t, math.abs(hue_diff - 180) < 2, "complementary hue difference should be ~180")
}

// ── Hex → color → shades → verify gradient ──

@(test)
test_hex_to_shades_pipeline :: proc(t: ^testing.T) {
	cs := color_init()
	color_apply_hex_str(&cs, "FF6600")

	shades, shade_count := generate_shades(cs.hue, cs.sat, 7, 0.1, 0.9)
	testing.expect_value(t, shade_count, 7)

	for i in 1 ..< shade_count {
		prev_hsv := rl.ColorToHSV(shades[i - 1])
		curr_hsv := rl.ColorToHSV(shades[i])
		testing.expect(t, curr_hsv.z >= prev_hsv.z - 0.01, "shades should increase in value")
	}
}

@(test)
test_shades_respect_vmin_vmax :: proc(t: ^testing.T) {
	shades, count := generate_shades(0, 1, 5, 0.2, 0.8)
	testing.expect_value(t, count, 5)

	first := rl.ColorToHSV(shades[0])
	last := rl.ColorToHSV(shades[count - 1])
	testing.expect(t, math.abs(first.z - 0.2) < 0.02, "first shade should be near v_min")
	testing.expect(t, math.abs(last.z - 0.8) < 0.02, "last shade should be near v_max")
}

// ── Harmony type sweep: every type produces non-zero count ──

@(test)
test_all_harmony_types_produce_colors :: proc(t: ^testing.T) {
	for ht in HarmonyType {
		_, count := compute_harmony(120, 0.8, 0.8, ht)
		testing.expect(t, count >= 2, "every harmony type should produce at least 2 colors")
	}
}

// ── WCAG contrast checks on generated harmonies ──

@(test)
test_contrast_ratio_black_vs_white :: proc(t: ^testing.T) {
	ratio := contrast_ratio(rl.Color{0, 0, 0, 255}, rl.Color{255, 255, 255, 255})
	testing.expect(t, ratio >= 20.0, "black vs white should have ratio >= 20")

	rating := wcag_rating(ratio)
	testing.expect(t, rating.aaa_normal, "black vs white should pass AAA normal")
	testing.expect(t, rating.aaa_large, "black vs white should pass AAA large")
}

@(test)
test_contrast_identical_colors :: proc(t: ^testing.T) {
	ratio := contrast_ratio(rl.Color{128, 128, 128, 255}, rl.Color{128, 128, 128, 255})
	testing.expect_value(t, ratio, f64(1.0))

	rating := wcag_rating(ratio)
	testing.expect(t, !rating.aa_large, "identical colors should fail all WCAG levels")
}

// ── Color → harmony → hex verification ──

@(test)
test_square_harmony_produces_four_distinct_hex :: proc(t: ^testing.T) {
	cs := color_init(0, 1, 1)
	harm_colors, harm_count := compute_harmony(cs.hue, cs.sat, cs.val, .Square)
	testing.expect_value(t, harm_count, 4)

	hexes: [4][8]u8
	for i in 0 ..< 4 {
		hexes[i] = color_to_hex_string(harm_colors[i])
	}

	for i in 0 ..< 4 {
		for j in i + 1 ..< 4 {
			same := true
			for k in 1 ..< 7 {
				if hexes[i][k] != hexes[j][k] { same = false; break }
			}
			testing.expect(t, !same, "square harmony hex values should be distinct")
		}
	}
}

// ── Variable harmony count ──

@(test)
test_variable_harmony_respects_requested_count :: proc(t: ^testing.T) {
	for req in 2 ..= 8 {
		_, count := compute_harmony(0, 1, 1, .Analogous, req)
		testing.expect_value(t, count, req)
	}
}

@(test)
test_monochromatic_preserves_hue :: proc(t: ^testing.T) {
	target_hue: f32 = 240
	harm_colors, harm_count := compute_harmony(target_hue, 0.8, 0.9, .Monochromatic, 5)
	testing.expect_value(t, harm_count, 5)

	for i in 0 ..< harm_count {
		hsv := rl.ColorToHSV(harm_colors[i])
		if hsv.y > 0.05 {
			testing.expect(t, math.abs(hsv.x - target_hue) < 2, "monochromatic should preserve hue")
		}
	}
}
