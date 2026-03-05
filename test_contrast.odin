package color_picker

import "core:testing"
import rl "vendor:raylib"

@(test)
test_contrast_black_white :: proc(t: ^testing.T) {
	ratio := contrast_ratio(rl.Color{0, 0, 0, 255}, rl.Color{255, 255, 255, 255})
	testing.expect(t, ratio >= 20.9 && ratio <= 21.1, "black/white should be ~21:1")
}

@(test)
test_contrast_same_color :: proc(t: ^testing.T) {
	ratio := contrast_ratio(rl.Color{128, 128, 128, 255}, rl.Color{128, 128, 128, 255})
	testing.expect(t, ratio >= 0.99 && ratio <= 1.01, "same color should be 1:1")
}

@(test)
test_contrast_symmetric :: proc(t: ^testing.T) {
	c1 := rl.Color{200, 50, 50, 255}
	c2 := rl.Color{50, 200, 50, 255}
	r1 := contrast_ratio(c1, c2)
	r2 := contrast_ratio(c2, c1)
	diff := r1 - r2
	if diff < 0 do diff = -diff
	testing.expect(t, diff < 0.01, "contrast ratio should be symmetric")
}

@(test)
test_wcag_rating_high_contrast :: proc(t: ^testing.T) {
	r := wcag_rating(21.0)
	testing.expect(t, r.aa_normal)
	testing.expect(t, r.aa_large)
	testing.expect(t, r.aaa_normal)
	testing.expect(t, r.aaa_large)
}

@(test)
test_wcag_rating_low_contrast :: proc(t: ^testing.T) {
	r := wcag_rating(2.0)
	testing.expect(t, !r.aa_normal)
	testing.expect(t, !r.aa_large)
	testing.expect(t, !r.aaa_normal)
	testing.expect(t, !r.aaa_large)
}

@(test)
test_wcag_rating_medium_contrast :: proc(t: ^testing.T) {
	r := wcag_rating(4.6)
	testing.expect(t, r.aa_normal)
	testing.expect(t, r.aa_large)
	testing.expect(t, !r.aaa_normal)
	testing.expect(t, r.aaa_large)
}

@(test)
test_luminance_black :: proc(t: ^testing.T) {
	l := relative_luminance(rl.Color{0, 0, 0, 255})
	testing.expect(t, l >= -0.001 && l <= 0.001)
}

@(test)
test_luminance_white :: proc(t: ^testing.T) {
	l := relative_luminance(rl.Color{255, 255, 255, 255})
	testing.expect(t, l >= 0.999 && l <= 1.001)
}
