package color_picker

import rl "vendor:raylib"
import "core:fmt"
import "core:os"

SWATCH_SZ     :: 32
SWATCH_GAP    :: 5
SWATCH_STRIDE :: SWATCH_SZ + SWATCH_GAP
MAX_PALETTE   :: 48
PALETTE_FILE  :: "palette.txt"

palette_add :: proc(palette: []rl.Color, count: ^int, color: rl.Color) -> bool {
	if count^ >= len(palette) do return false
	for i in 0 ..< count^ {
		if palette[i].r == color.r && palette[i].g == color.g && palette[i].b == color.b {
			return false
		}
	}
	palette[count^] = color
	count^ += 1
	return true
}

palette_move :: proc(palette: []rl.Color, count: int, from, to: int) {
	if from < 0 || from >= count || to < 0 || to >= count || from == to do return
	c := palette[from]
	if from < to {
		for i in from ..< to {
			palette[i] = palette[i + 1]
		}
	} else {
		for i := from; i > to; i -= 1 {
			palette[i] = palette[i - 1]
		}
	}
	palette[to] = c
}

palette_remove :: proc(palette: []rl.Color, count: ^int, index: int) -> bool {
	if index < 0 || index >= count^ do return false
	for j in index ..< count^ - 1 {
		palette[j] = palette[j + 1]
	}
	count^ -= 1
	return true
}

swatch_rect :: proc(index: int, base_y: f32, cols_per_row: int, margin: f32 = 24) -> rl.Rectangle {
	row := index / cols_per_row
	col := index % cols_per_row
	return {
		margin + f32(col) * f32(SWATCH_STRIDE),
		base_y + f32(row) * f32(SWATCH_STRIDE),
		SWATCH_SZ,
		SWATCH_SZ,
	}
}

load_palette :: proc(palette: []rl.Color, path: string) -> int {
	data, err := os.read_entire_file_from_path(path, context.allocator)
	if err != nil do return 0
	defer delete(data)

	count := 0
	i := 0
	for i < len(data) && count < len(palette) {
		for i < len(data) && (data[i] == '\n' || data[i] == '\r' || data[i] == ' ' || data[i] == '\t') {
			i += 1
		}
		if i < len(data) && data[i] == '#' do i += 1
		if i + 6 <= len(data) {
			if c, parsed := parse_hex(data[i:i + 6]); parsed {
				palette[count] = c
				count += 1
			}
		}
		for i < len(data) && data[i] != '\n' && data[i] != '\r' {
			i += 1
		}
	}
	return count
}

save_palette :: proc(colors: []rl.Color, path: string) {
	buf: [MAX_PALETTE * 9]u8
	offset := 0
	for c in colors {
		s := fmt.bprintf(buf[offset:], "#%02X%02X%02X\n", c.r, c.g, c.b)
		offset += len(s)
	}
	_ = os.write_entire_file(path, buf[:offset])
}
