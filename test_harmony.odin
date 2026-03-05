package color_picker

import "core:testing"
import rl "vendor:raylib"

@(test)
test_harmony_complementary :: proc(t: ^testing.T) {
	colors, count := compute_harmony(0, 1, 1, .Complementary)
	testing.expect_value(t, count, 2)
	testing.expect_value(t, colors[0], rl.ColorFromHSV(0, 1, 1))
	testing.expect_value(t, colors[1], rl.ColorFromHSV(180, 1, 1))
}

@(test)
test_harmony_triadic :: proc(t: ^testing.T) {
	_, count := compute_harmony(60, 1, 1, .Triadic)
	testing.expect_value(t, count, 3)
}

@(test)
test_harmony_square :: proc(t: ^testing.T) {
	_, count := compute_harmony(0, 1, 1, .Square)
	testing.expect_value(t, count, 4)
}

@(test)
test_harmony_monochromatic_default :: proc(t: ^testing.T) {
	_, count := compute_harmony(0, 1, 1, .Monochromatic)
	testing.expect_value(t, count, 5)
}

@(test)
test_harmony_monochromatic_custom :: proc(t: ^testing.T) {
	_, count := compute_harmony(0, 1, 1, .Monochromatic, 7)
	testing.expect_value(t, count, 7)
}

@(test)
test_harmony_shades_custom :: proc(t: ^testing.T) {
	_, count := compute_harmony(0, 1, 1, .Shades, 3)
	testing.expect_value(t, count, 3)
}

@(test)
test_harmony_analogous_custom :: proc(t: ^testing.T) {
	_, count := compute_harmony(0, 1, 1, .Analogous, 5)
	testing.expect_value(t, count, 5)
}

@(test)
test_harmony_is_variable :: proc(t: ^testing.T) {
	testing.expect(t, harmony_is_variable(.Monochromatic))
	testing.expect(t, harmony_is_variable(.Shades))
	testing.expect(t, harmony_is_variable(.Analogous))
	testing.expect(t, !harmony_is_variable(.Complementary))
	testing.expect(t, !harmony_is_variable(.Triadic))
}

@(test)
test_wrap_hue_positive :: proc(t: ^testing.T) {
	testing.expect(t, wrap_hue(390) >= 29 && wrap_hue(390) <= 31)
}

@(test)
test_wrap_hue_negative :: proc(t: ^testing.T) {
	testing.expect(t, wrap_hue(-30) >= 329 && wrap_hue(-30) <= 331)
}
