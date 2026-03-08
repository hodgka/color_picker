package color

import rl "vendor:raylib"
import "core:math"

MAX_HARMONY :: 16

HarmonyType :: enum {
	Analogous,
	Monochromatic,
	Complementary,
	Triadic,
	Split_Complement,
	Square,
	Compound,
	Shades,
}

HARMONY_NAMES := [HarmonyType]cstring {
	.Analogous        = "Analogous",
	.Monochromatic    = "Monochromatic",
	.Complementary    = "Complementary",
	.Triadic          = "Triadic",
	.Split_Complement = "Split Compl.",
	.Square           = "Square",
	.Compound         = "Compound",
	.Shades           = "Shades",
}

// Whether the harmony type supports a user-adjustable count
harmony_is_variable :: proc(type: HarmonyType) -> bool {
	#partial switch type {
	case .Monochromatic, .Shades, .Analogous:
		return true
	}
	return false
}

wrap_hue :: proc(h: f32) -> f32 {
	result := math.mod(h, 360.0)
	if result < 0 do result += 360
	return result
}

compute_harmony :: proc(
	base_hue, base_sat, base_val: f32,
	type: HarmonyType,
	requested: int = 0,
) -> (
	colors: [MAX_HARMONY]rl.Color,
	count: int,
) {
	h := base_hue
	s := base_sat
	v := base_val

	switch type {
	case .Analogous:
		n := requested > 0 ? clamp(requested, 2, MAX_HARMONY) : 3
		half := n / 2
		for i in 0 ..< n {
			offset := f32(i - half) * (60.0 / f32(n))
			colors[i] = rl.ColorFromHSV(wrap_hue(h + offset), s, v)
		}
		count = n

	case .Monochromatic:
		n := requested > 0 ? clamp(requested, 2, MAX_HARMONY) : 5
		for i in 0 ..< n {
			t := f32(i) / f32(n - 1)
			ms := clamp(s * (0.2 + t * 0.8), 0, 1)
			mv := clamp(v * (1.2 - t * 0.8), 0, 1)
			colors[i] = rl.ColorFromHSV(h, ms, mv)
		}
		count = n

	case .Complementary:
		colors[0] = rl.ColorFromHSV(h, s, v)
		colors[1] = rl.ColorFromHSV(wrap_hue(h + 180), s, v)
		count = 2

	case .Triadic:
		colors[0] = rl.ColorFromHSV(h, s, v)
		colors[1] = rl.ColorFromHSV(wrap_hue(h + 120), s, v)
		colors[2] = rl.ColorFromHSV(wrap_hue(h + 240), s, v)
		count = 3

	case .Split_Complement:
		colors[0] = rl.ColorFromHSV(h, s, v)
		colors[1] = rl.ColorFromHSV(wrap_hue(h + 150), s, v)
		colors[2] = rl.ColorFromHSV(wrap_hue(h + 210), s, v)
		count = 3

	case .Square:
		colors[0] = rl.ColorFromHSV(h, s, v)
		colors[1] = rl.ColorFromHSV(wrap_hue(h + 90), s, v)
		colors[2] = rl.ColorFromHSV(wrap_hue(h + 180), s, v)
		colors[3] = rl.ColorFromHSV(wrap_hue(h + 270), s, v)
		count = 4

	case .Compound:
		colors[0] = rl.ColorFromHSV(h, s, v)
		colors[1] = rl.ColorFromHSV(wrap_hue(h + 30), s, v)
		colors[2] = rl.ColorFromHSV(wrap_hue(h + 150), s, v)
		colors[3] = rl.ColorFromHSV(wrap_hue(h + 210), s, v)
		colors[4] = rl.ColorFromHSV(wrap_hue(h + 330), s, v)
		count = 5

	case .Shades:
		n := requested > 0 ? clamp(requested, 2, MAX_HARMONY) : 7
		for i in 0 ..< n {
			sv := f32(i + 1) / f32(n + 1)
			colors[i] = rl.ColorFromHSV(h, s, sv)
		}
		count = n
	}

	return
}

harmony_hue_offsets :: proc(type: HarmonyType, requested: int = 0) -> (offsets: [MAX_HARMONY]f32, count: int) {
	switch type {
	case .Analogous:
		n := requested > 0 ? clamp(requested, 2, MAX_HARMONY) : 3
		half := n / 2
		for i in 0 ..< n {
			offsets[i] = f32(i - half) * (60.0 / f32(n))
		}
		count = n
	case .Complementary:
		offsets[0] = 0; offsets[1] = 180
		count = 2
	case .Triadic:
		offsets[0] = 0; offsets[1] = 120; offsets[2] = 240
		count = 3
	case .Split_Complement:
		offsets[0] = 0; offsets[1] = 150; offsets[2] = 210
		count = 3
	case .Square:
		offsets[0] = 0; offsets[1] = 90; offsets[2] = 180; offsets[3] = 270
		count = 4
	case .Compound:
		offsets[0] = 0; offsets[1] = 30; offsets[2] = 150; offsets[3] = 210; offsets[4] = 330
		count = 5
	case .Monochromatic, .Shades:
		offsets[0] = 0
		count = 1
	}
	return
}
