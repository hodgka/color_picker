package color

import rl "vendor:raylib"

MAX_SHADES :: 16

generate_shades :: proc(hue, sat: f32, count: int = 9, v_min: f32 = 0.05, v_max: f32 = 0.95) -> (result: [MAX_SHADES]rl.Color, n: int) {
	n = clamp(count, 2, MAX_SHADES)
	for i in 0 ..< n {
		t := f32(i) / f32(n - 1)
		v := v_min + t * (v_max - v_min)
		result[i] = rl.ColorFromHSV(hue, sat, clamp(v, 0, 1))
	}
	return
}
