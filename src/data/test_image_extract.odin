package data

import "core:testing"
import rl "vendor:raylib"

@(test)
test_median_cut_single_color :: proc(t: ^testing.T) {
	pixels := [][3]u8{{255, 0, 0}, {255, 0, 0}, {255, 0, 0}, {255, 0, 0}}
	out: [EXTRACT_COUNT]rl.Color
	median_cut(&out, pixels, 1)
	testing.expect_value(t, out[0].r, u8(255))
	testing.expect_value(t, out[0].g, u8(0))
	testing.expect_value(t, out[0].b, u8(0))
}

@(test)
test_median_cut_two_clusters :: proc(t: ^testing.T) {
	pixels: [20][3]u8
	for i in 0 ..< 10 { pixels[i] = {255, 0, 0} }
	for i in 10 ..< 20 { pixels[i] = {0, 0, 255} }

	out: [EXTRACT_COUNT]rl.Color
	median_cut(&out, pixels[:], 2)

	has_red := false
	has_blue := false
	for i in 0 ..< 2 {
		if out[i].r > 200 && out[i].b < 50 do has_red = true
		if out[i].b > 200 && out[i].r < 50 do has_blue = true
	}
	testing.expect(t, has_red, "should find a red-ish cluster")
	testing.expect(t, has_blue, "should find a blue-ish cluster")
}

@(test)
test_median_cut_respects_count :: proc(t: ^testing.T) {
	pixels := [][3]u8{{10, 10, 10}, {200, 200, 200}, {100, 0, 0}, {0, 100, 0}}
	out: [EXTRACT_COUNT]rl.Color
	median_cut(&out, pixels, 4)

	non_black := 0
	for i in 0 ..< 4 {
		if out[i].a == 255 do non_black += 1
	}
	testing.expect(t, non_black >= 2, "should produce at least 2 non-zero colors")
}

@(test)
test_median_cut_single_pixel :: proc(t: ^testing.T) {
	pixels := [][3]u8{{42, 100, 200}}
	out: [EXTRACT_COUNT]rl.Color
	median_cut(&out, pixels, 1)
	testing.expect_value(t, out[0].r, u8(42))
	testing.expect_value(t, out[0].g, u8(100))
	testing.expect_value(t, out[0].b, u8(200))
}
