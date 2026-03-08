package color

import rl "vendor:raylib"

ColorState :: struct {
	hue, sat, val: f32,
}

color_init :: proc(h: f32 = 0, s: f32 = 1, v: f32 = 1) -> ColorState {
	return ColorState{hue = h, sat = s, val = v}
}

color_get :: proc(cs: ^ColorState) -> rl.Color {
	return rl.ColorFromHSV(cs.hue, cs.sat, cs.val)
}

color_set_hsv :: proc(cs: ^ColorState, h, s, v: f32) {
	cs.hue = h
	cs.sat = s
	cs.val = v
}

color_set_rgb :: proc(cs: ^ColorState, color: rl.Color, preserve_hue := false) {
	hsv := rl.ColorToHSV(color)
	if preserve_hue {
		if hsv.x != 0 || hsv.y > 0.01 do cs.hue = hsv.x
	} else {
		cs.hue = hsv.x
	}
	cs.sat = hsv.y
	cs.val = hsv.z
}

color_apply_hex_str :: proc(cs: ^ColorState, hex: string, preserve_hue := false) -> bool {
	if len(hex) != 6 do return false
	buf: [6]u8
	for i in 0 ..< 6 do buf[i] = hex[i]
	c, ok := parse_hex(buf[:])
	if !ok do return false
	hsv := rl.ColorToHSV(c)
	if preserve_hue {
		if hsv.x != 0 || hsv.y > 0.01 do cs.hue = hsv.x
	} else {
		cs.hue = hsv.x
	}
	cs.sat = hsv.y
	cs.val = hsv.z
	return true
}
