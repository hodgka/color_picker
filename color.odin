package color_picker

import rl "vendor:raylib"

ColorState :: struct {
	hue, sat, val: f32,
	hex_buf:       [6]u8,
	hex_len:       int,
}

color_init :: proc(h: f32 = 0, s: f32 = 1, v: f32 = 1) -> ColorState {
	cs := ColorState{hue = h, sat = s, val = v}
	sync_hex(&cs.hex_buf, rl.ColorFromHSV(h, s, v))
	cs.hex_len = 6
	return cs
}

color_get :: proc(cs: ^ColorState) -> rl.Color {
	return rl.ColorFromHSV(cs.hue, cs.sat, cs.val)
}

color_set_hsv :: proc(cs: ^ColorState, h, s, v: f32) {
	cs.hue = h
	cs.sat = s
	cs.val = v
	sync_hex(&cs.hex_buf, rl.ColorFromHSV(h, s, v))
	cs.hex_len = 6
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
	sync_hex(&cs.hex_buf, color)
	cs.hex_len = 6
}

color_apply_hex :: proc(cs: ^ColorState, preserve_hue := false) -> bool {
	if cs.hex_len != 6 do return false
	c, ok := parse_hex(cs.hex_buf[:6])
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
