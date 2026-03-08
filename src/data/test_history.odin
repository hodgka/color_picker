package data

import "core:testing"
import rl "vendor:raylib"

@(test)
test_history_push_and_get :: proc(t: ^testing.T) {
	ring: [4]rl.Color
	count, head := 0, 0

	history_push(ring[:], &count, &head, rl.Color{255, 0, 0, 255})
	history_push(ring[:], &count, &head, rl.Color{0, 255, 0, 255})
	testing.expect_value(t, count, 2)

	c0 := history_get(ring[:], count, head, 0)
	testing.expect_value(t, c0, rl.Color{255, 0, 0, 255})
	c1 := history_get(ring[:], count, head, 1)
	testing.expect_value(t, c1, rl.Color{0, 255, 0, 255})
}

@(test)
test_history_skips_duplicate :: proc(t: ^testing.T) {
	ring: [4]rl.Color
	count, head := 0, 0

	history_push(ring[:], &count, &head, rl.Color{255, 0, 0, 255})
	history_push(ring[:], &count, &head, rl.Color{255, 0, 0, 255})
	testing.expect_value(t, count, 1)
}

@(test)
test_history_wraps :: proc(t: ^testing.T) {
	ring: [3]rl.Color
	count, head := 0, 0

	history_push(ring[:], &count, &head, rl.Color{1, 0, 0, 255})
	history_push(ring[:], &count, &head, rl.Color{2, 0, 0, 255})
	history_push(ring[:], &count, &head, rl.Color{3, 0, 0, 255})
	history_push(ring[:], &count, &head, rl.Color{4, 0, 0, 255})
	testing.expect_value(t, count, 3)

	oldest := history_get(ring[:], count, head, 0)
	testing.expect_value(t, oldest.r, u8(2))
	newest := history_get(ring[:], count, head, 2)
	testing.expect_value(t, newest.r, u8(4))
}

@(test)
test_history_single_element :: proc(t: ^testing.T) {
	ring: [4]rl.Color
	count, head := 0, 0

	history_push(ring[:], &count, &head, rl.Color{42, 42, 42, 255})
	testing.expect_value(t, count, 1)

	c := history_get(ring[:], count, head, 0)
	testing.expect_value(t, c, rl.Color{42, 42, 42, 255})
}
