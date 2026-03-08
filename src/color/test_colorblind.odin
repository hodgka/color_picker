package color

import "core:testing"
import rl "vendor:raylib"

@(test)
test_cvd_none_passthrough :: proc(t: ^testing.T) {
	c := rl.Color{200, 100, 50, 255}
	result := simulate_cvd(c, .None)
	testing.expect_value(t, result, c)
}

@(test)
test_cvd_preserves_alpha :: proc(t: ^testing.T) {
	c := rl.Color{255, 0, 0, 128}
	for type in CvdType {
		result := simulate_cvd(c, type)
		testing.expect_value(t, result.a, u8(128))
	}
}

@(test)
test_cvd_protan_reduces_red :: proc(t: ^testing.T) {
	red := rl.Color{255, 0, 0, 255}
	sim := simulate_cvd(red, .Protanopia)
	testing.expect(t, sim.r < 200, "protanopia should reduce perceived red")
}

@(test)
test_cvd_black_stays_black :: proc(t: ^testing.T) {
	black := rl.Color{0, 0, 0, 255}
	for type in CvdType {
		result := simulate_cvd(black, type)
		testing.expect_value(t, result.r, u8(0))
		testing.expect_value(t, result.g, u8(0))
		testing.expect_value(t, result.b, u8(0))
	}
}

@(test)
test_cvd_white_stays_white :: proc(t: ^testing.T) {
	white := rl.Color{255, 255, 255, 255}
	for type in CvdType {
		if type == .None do continue
		result := simulate_cvd(white, type)
		dr := int(result.r) - 255
		dg := int(result.g) - 255
		db := int(result.b) - 255
		if dr < 0 do dr = -dr
		if dg < 0 do dg = -dg
		if db < 0 do db = -db
		testing.expect(t, dr <= 2 && dg <= 2 && db <= 2, "white should remain near-white")
	}
}

@(test)
test_distinguishable_similar_brightness_deutan :: proc(t: ^testing.T) {
	red := rl.Color{180, 60, 60, 255}
	green := rl.Color{60, 140, 60, 255}
	testing.expect(t, !colors_distinguishable(red, green, .Deuteranopia), "similar-brightness red/green should be confusable for deuteranopia")
}

@(test)
test_distinguishable_blue_yellow_deutan :: proc(t: ^testing.T) {
	blue := rl.Color{0, 0, 255, 255}
	yellow := rl.Color{255, 255, 0, 255}
	testing.expect(t, colors_distinguishable(blue, yellow, .Deuteranopia), "blue/yellow should be distinguishable for deuteranopia")
}

@(test)
test_distinguishable_same_color :: proc(t: ^testing.T) {
	c := rl.Color{128, 64, 200, 255}
	testing.expect(t, !colors_distinguishable(c, c, .Protanopia))
	testing.expect(t, !colors_distinguishable(c, c, .Deuteranopia))
	testing.expect(t, !colors_distinguishable(c, c, .Tritanopia))
}

@(test)
test_cvd_pair_safety_bw :: proc(t: ^testing.T) {
	safe, _ := cvd_pair_safety(rl.Color{0, 0, 0, 255}, rl.Color{255, 255, 255, 255})
	testing.expect(t, safe, "black/white should be safe for all types")
}

@(test)
test_cvd_pair_safety_red_green :: proc(t: ^testing.T) {
	safe, risky := cvd_pair_safety(rl.Color{180, 60, 60, 255}, rl.Color{60, 140, 60, 255})
	testing.expect(t, !safe, "similar-brightness red/green should not be safe")
	testing.expect(t, risky != .None)
}
