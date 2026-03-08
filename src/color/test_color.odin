package color

import "core:testing"
import rl "vendor:raylib"

@(test)
test_color_init_defaults :: proc(t: ^testing.T) {
	cs := color_init()
	testing.expect_value(t, cs.hue, f32(0))
	testing.expect_value(t, cs.sat, f32(1))
	testing.expect_value(t, cs.val, f32(1))
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
test_color_apply_hex_str_updates_hsv :: proc(t: ^testing.T) {
	cs := color_init()
	ok := color_apply_hex_str(&cs, "00FF00")
	testing.expect(t, ok)
	c := color_get(&cs)
	testing.expect_value(t, c.g, u8(255))
}

@(test)
test_color_apply_hex_str_fails_on_short :: proc(t: ^testing.T) {
	cs := color_init()
	ok := color_apply_hex_str(&cs, "00FF")
	testing.expect(t, !ok)
}

@(test)
test_color_get_returns_correct_color :: proc(t: ^testing.T) {
	cs := color_init(h = 0, s = 0, v = 0)
	c := color_get(&cs)
	testing.expect_value(t, c, rl.Color{0, 0, 0, 255})
}
