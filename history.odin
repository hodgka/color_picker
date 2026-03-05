package color_picker

import rl "vendor:raylib"

HISTORY_MAX :: 24

history_push :: proc(ring: []rl.Color, count: ^int, head: ^int, color: rl.Color) {
	if count^ > 0 {
		last := (head^ - 1 + len(ring)) % len(ring)
		prev := ring[last]
		if prev.r == color.r && prev.g == color.g && prev.b == color.b {
			return
		}
	}
	ring[head^] = color
	head^ = (head^ + 1) % len(ring)
	if count^ < len(ring) do count^ += 1
}

history_get :: proc(ring: []rl.Color, count, head, index: int) -> rl.Color {
	actual := (head - count + index + len(ring)) % len(ring)
	return ring[actual]
}
