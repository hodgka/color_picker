package color_picker

import rl "vendor:raylib"
import "core:math"

rebuild_wheel :: proc(img: ^rl.Image, val: f32, size: i32) {
	pixels := cast([^]rl.Color)img.data
	center := f32(size) / 2
	radius := center
	aa_width: f32 = 1.5

	for y in 0 ..< size {
		for x in 0 ..< size {
			dx := f32(x) - center + 0.5
			dy := f32(y) - center + 0.5
			dist := math.sqrt(dx * dx + dy * dy)

			if dist > radius + aa_width {
				pixels[y * size + x] = {0, 0, 0, 0}
				continue
			}

			angle := math.atan2(dy, dx) * (180.0 / math.PI)
			if angle < 0 do angle += 360

			sat := clamp(dist / radius, 0, 1)
			c := rl.ColorFromHSV(angle, sat, val)

			if dist > radius - aa_width {
				alpha := clamp((radius - dist) / aa_width, 0, 1)
				c.a = u8(f32(c.a) * alpha)
			}

			pixels[y * size + x] = c
		}
	}
}

rebuild_sv :: proc(img: ^rl.Image, hue: f32, size: i32 = 280) {
	pixels := cast([^]rl.Color)img.data
	for y in 0 ..< size {
		for x in 0 ..< size {
			s := f32(x) / f32(size)
			v := 1 - f32(y) / f32(size)
			pixels[y * size + x] = rl.ColorFromHSV(hue, s, v)
		}
	}
}

wheel_pick :: proc(mx, my, cx, cy, radius: f32) -> (hue, sat: f32, inside: bool) {
	dx := mx - cx
	dy := my - cy
	dist := math.sqrt(dx * dx + dy * dy)
	if dist > radius do return 0, 0, false

	angle := math.atan2(dy, dx) * (180.0 / math.PI)
	if angle < 0 do angle += 360

	return angle, dist / radius, true
}
