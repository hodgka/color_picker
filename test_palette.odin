package color_picker

import "core:testing"
import rl "vendor:raylib"

@(test)
test_palette_add_basic :: proc(t: ^testing.T) {
	palette: [4]rl.Color
	count := 0
	ok := palette_add(palette[:], &count, rl.Color{255, 0, 0, 255})
	testing.expect(t, ok)
	testing.expect_value(t, count, 1)
}

@(test)
test_palette_add_rejects_duplicate :: proc(t: ^testing.T) {
	palette: [4]rl.Color
	count := 0
	palette_add(palette[:], &count, rl.Color{255, 0, 0, 255})
	ok := palette_add(palette[:], &count, rl.Color{255, 0, 0, 255})
	testing.expect(t, !ok)
	testing.expect_value(t, count, 1)
}

@(test)
test_palette_add_respects_capacity :: proc(t: ^testing.T) {
	palette: [2]rl.Color
	count := 0
	palette_add(palette[:], &count, rl.Color{255, 0, 0, 255})
	palette_add(palette[:], &count, rl.Color{0, 255, 0, 255})
	ok := palette_add(palette[:], &count, rl.Color{0, 0, 255, 255})
	testing.expect(t, !ok)
	testing.expect_value(t, count, 2)
}

@(test)
test_palette_remove_basic :: proc(t: ^testing.T) {
	palette := [3]rl.Color{{255, 0, 0, 255}, {0, 255, 0, 255}, {0, 0, 255, 255}}
	count := 3
	ok := palette_remove(palette[:], &count, 1)
	testing.expect(t, ok)
	testing.expect_value(t, count, 2)
	testing.expect_value(t, palette[1], rl.Color{0, 0, 255, 255})
}

@(test)
test_palette_remove_out_of_bounds :: proc(t: ^testing.T) {
	palette: [2]rl.Color
	count := 1
	testing.expect(t, !palette_remove(palette[:], &count, -1))
	testing.expect(t, !palette_remove(palette[:], &count, 5))
}

@(test)
test_swatch_rect_first :: proc(t: ^testing.T) {
	r := swatch_rect(0, 100, 17)
	testing.expect_value(t, r.x, f32(24))
	testing.expect_value(t, r.y, f32(100))
	testing.expect_value(t, r.width, f32(SWATCH_SZ))
	testing.expect_value(t, r.height, f32(SWATCH_SZ))
}

@(test)
test_swatch_rect_sequential :: proc(t: ^testing.T) {
	r0 := swatch_rect(0, 100, 17)
	r1 := swatch_rect(1, 100, 17)
	testing.expect_value(t, r1.x, r0.x + f32(SWATCH_STRIDE))
	testing.expect_value(t, r1.y, r0.y)
}

@(test)
test_swatch_rect_row_wrap :: proc(t: ^testing.T) {
	r := swatch_rect(17, 100, 17)
	testing.expect_value(t, r.x, f32(24))
	testing.expect_value(t, r.y, f32(100) + f32(SWATCH_STRIDE))
}
