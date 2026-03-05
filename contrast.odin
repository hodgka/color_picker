package color_picker

import rl "vendor:raylib"
import "core:math"

relative_luminance :: proc(c: rl.Color) -> f64 {
	linearize :: proc(channel: u8) -> f64 {
		s := f64(channel) / 255.0
		return s <= 0.03928 ? s / 12.92 : math.pow((s + 0.055) / 1.055, 2.4)
	}
	r := linearize(c.r)
	g := linearize(c.g)
	b := linearize(c.b)
	return 0.2126 * r + 0.7152 * g + 0.0722 * b
}

contrast_ratio :: proc(c1, c2: rl.Color) -> f64 {
	l1 := relative_luminance(c1)
	l2 := relative_luminance(c2)
	lighter := max(l1, l2)
	darker := min(l1, l2)
	return (lighter + 0.05) / (darker + 0.05)
}

WcagRating :: struct {
	aa_normal, aa_large, aaa_normal, aaa_large: bool,
}

wcag_rating :: proc(ratio: f64) -> WcagRating {
	return {
		aa_normal  = ratio >= 4.5,
		aa_large   = ratio >= 3.0,
		aaa_normal = ratio >= 7.0,
		aaa_large  = ratio >= 4.5,
	}
}
