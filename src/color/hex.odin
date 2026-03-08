package color

import rl "vendor:raylib"

color_to_hex_string :: proc(color: rl.Color) -> [8]u8 {
	buf: [8]u8
	buf[0] = '#'
	hex_nibble :: proc(v: u8) -> u8 {
		return v < 10 ? ('0' + v) : ('A' + v - 10)
	}
	buf[1] = hex_nibble(color.r >> 4)
	buf[2] = hex_nibble(color.r & 0xF)
	buf[3] = hex_nibble(color.g >> 4)
	buf[4] = hex_nibble(color.g & 0xF)
	buf[5] = hex_nibble(color.b >> 4)
	buf[6] = hex_nibble(color.b & 0xF)
	buf[7] = 0
	return buf
}

is_hex_char :: proc(c: u8) -> bool {
	switch c {
	case '0' ..= '9', 'a' ..= 'f', 'A' ..= 'F':
		return true
	case:
		return false
	}
}

upper_hex :: proc(c: u8) -> u8 {
	if c >= 'a' && c <= 'f' do return c - 32
	return c
}

all_hex_str :: proc(s: string) -> bool {
	for c in s {
		if !is_hex_char(u8(c)) do return false
	}
	return true
}

parse_hex :: proc(buf: []u8) -> (rl.Color, bool) {
	if len(buf) != 6 do return {}, false

	hex_val :: proc(c: u8) -> (u8, bool) {
		switch c {
		case '0' ..= '9':
			return c - '0', true
		case 'A' ..= 'F':
			return c - 'A' + 10, true
		case 'a' ..= 'f':
			return c - 'a' + 10, true
		case:
			return 0, false
		}
	}

	r1, ok1 := hex_val(buf[0])
	r2, ok2 := hex_val(buf[1])
	g1, ok3 := hex_val(buf[2])
	g2, ok4 := hex_val(buf[3])
	b1, ok5 := hex_val(buf[4])
	b2, ok6 := hex_val(buf[5])
	if !ok1 || !ok2 || !ok3 || !ok4 || !ok5 || !ok6 do return {}, false

	return rl.Color{r1 * 16 + r2, g1 * 16 + g2, b1 * 16 + b2, 255}, true
}
