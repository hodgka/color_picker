package color

import rl "vendor:raylib"
import "core:math"

CvdType :: enum {
	None,
	Protanopia,
	Deuteranopia,
	Tritanopia,
}

CVD_NAMES := [CvdType]cstring{
	.None         = "Normal",
	.Protanopia   = "Protanopia",
	.Deuteranopia = "Deuteranopia",
	.Tritanopia   = "Tritanopia",
}

// Machado 2009 severity-1.0 simulation matrices (more accurate full-severity model)
Mat3 :: [3][3]f64

PROTAN_MAT :: Mat3{
	{ 0.152286,  1.052583, -0.204868},
	{ 0.114503,  0.786281,  0.099216},
	{-0.003882, -0.048116,  1.051998},
}

DEUTAN_MAT :: Mat3{
	{ 0.367322,  0.860646, -0.227968},
	{ 0.280085,  0.672501,  0.047413},
	{-0.011820,  0.042940,  0.968881},
}

TRITAN_MAT :: Mat3{
	{ 1.255528, -0.076749, -0.178779},
	{-0.078411,  0.930809,  0.147602},
	{ 0.004733,  0.691367,  0.303900},
}

srgb_to_linear :: proc(v: f64) -> f64 {
	return v <= 0.04045 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4)
}

linear_to_srgb :: proc(v: f64) -> f64 {
	return v <= 0.0031308 ? v * 12.92 : 1.055 * math.pow(v, 1.0 / 2.4) - 0.055
}

simulate_cvd :: proc(c: rl.Color, type: CvdType) -> rl.Color {
	if type == .None do return c

	r := srgb_to_linear(f64(c.r) / 255.0)
	g := srgb_to_linear(f64(c.g) / 255.0)
	b := srgb_to_linear(f64(c.b) / 255.0)

	m: Mat3
	switch type {
	case .Protanopia:   m = PROTAN_MAT
	case .Deuteranopia: m = DEUTAN_MAT
	case .Tritanopia:   m = TRITAN_MAT
	case .None:         return c
	}

	nr := m[0][0] * r + m[0][1] * g + m[0][2] * b
	ng := m[1][0] * r + m[1][1] * g + m[1][2] * b
	nb := m[2][0] * r + m[2][1] * g + m[2][2] * b

	return {
		u8(clamp(linear_to_srgb(nr) * 255 + 0.5, 0, 255)),
		u8(clamp(linear_to_srgb(ng) * 255 + 0.5, 0, 255)),
		u8(clamp(linear_to_srgb(nb) * 255 + 0.5, 0, 255)),
		c.a,
	}
}

colors_distinguishable :: proc(a, b: rl.Color, type: CvdType, threshold: f64 = 40) -> bool {
	sa := simulate_cvd(a, type)
	sb := simulate_cvd(b, type)
	dr := f64(sa.r) - f64(sb.r)
	dg := f64(sa.g) - f64(sb.g)
	db := f64(sa.b) - f64(sb.b)
	return math.sqrt(dr * dr + dg * dg + db * db) > threshold
}

// Check a color pair against all three deficiency types
cvd_pair_safety :: proc(a, b: rl.Color) -> (safe: bool, risky_type: CvdType) {
	types := [3]CvdType{.Protanopia, .Deuteranopia, .Tritanopia}
	for t in types {
		if !colors_distinguishable(a, b, t) {
			return false, t
		}
	}
	return true, .None
}
