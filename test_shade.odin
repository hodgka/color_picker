package color_picker

import "core:testing"
import rl "vendor:raylib"

@(test)
test_generate_shades_default :: proc(t: ^testing.T) {
	shades, n := generate_shades(0, 1)
	testing.expect_value(t, n, 9)
	for i in 0 ..< n {
		testing.expect(t, shades[i].a == 255)
	}
}

@(test)
test_generate_shades_custom_count :: proc(t: ^testing.T) {
	_, n3 := generate_shades(0, 1, 3)
	testing.expect_value(t, n3, 3)

	_, n12 := generate_shades(0, 1, 12)
	testing.expect_value(t, n12, 12)
}

@(test)
test_generate_shades_order :: proc(t: ^testing.T) {
	shades, n := generate_shades(0, 1)
	for i in 1 ..< n {
		prev_v := rl.ColorToHSV(shades[i - 1]).z
		curr_v := rl.ColorToHSV(shades[i]).z
		testing.expect(t, curr_v >= prev_v, "shades should increase in value")
	}
}

@(test)
test_generate_shades_range :: proc(t: ^testing.T) {
	shades, n := generate_shades(0, 1, 5, 0.3, 0.8)
	testing.expect_value(t, n, 5)
	first_v := rl.ColorToHSV(shades[0]).z
	last_v := rl.ColorToHSV(shades[n - 1]).z
	testing.expect(t, first_v >= 0.25, "first shade should be near v_min")
	testing.expect(t, last_v <= 0.85, "last shade should be near v_max")
}

@(test)
test_generate_shades_clamps_count :: proc(t: ^testing.T) {
	_, n1 := generate_shades(0, 1, 1)
	testing.expect_value(t, n1, 2)

	_, n99 := generate_shades(0, 1, 99)
	testing.expect_value(t, n99, MAX_SHADES)
}
