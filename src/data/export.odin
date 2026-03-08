package data

import rl "vendor:raylib"
import "core:fmt"
import "core:os"

palette_to_hex_array :: proc(colors: []rl.Color) -> cstring {
	if len(colors) == 0 do return "[]"
	return fmt.ctprintf("[%s]", _hex_list(colors))
}

_hex_list :: proc(colors: []rl.Color) -> string {
	buf: [MAX_PALETTE * 14]u8
	offset := 0
	for c, i in colors {
		if i > 0 {
			s := fmt.bprintf(buf[offset:], ", ")
			offset += len(s)
		}
		s := fmt.bprintf(buf[offset:], "\"#%02X%02X%02X\"", c.r, c.g, c.b)
		offset += len(s)
	}
	return fmt.tprintf("%s", string(buf[:offset]))
}

export_gpl :: proc(colors: []rl.Color, path: string) {
	buf: [MAX_PALETTE * 20 + 64]u8
	offset := 0

	s := fmt.bprintf(buf[offset:], "GIMP Palette\nName: Color Picker\nColumns: %d\n#\n", len(colors))
	offset += len(s)

	for c in colors {
		s2 := fmt.bprintf(buf[offset:], "%3d %3d %3d\t#%02X%02X%02X\n", c.r, c.g, c.b, c.r, c.g, c.b)
		offset += len(s2)
	}
	_ = os.write_entire_file(path, buf[:offset])
}

export_css :: proc(colors: []rl.Color) -> cstring {
	buf: [MAX_PALETTE * 40 + 16]u8
	offset := 0

	s := fmt.bprintf(buf[offset:], ":root {{\n")
	offset += len(s)

	for c, i in colors {
		s2 := fmt.bprintf(buf[offset:], "  --color-%d: #%02X%02X%02X;\n", i + 1, c.r, c.g, c.b)
		offset += len(s2)
	}

	s3 := fmt.bprintf(buf[offset:], "}}\n")
	offset += len(s3)

	return fmt.ctprintf("%s", string(buf[:offset]))
}

export_tailwind :: proc(colors: []rl.Color) -> cstring {
	buf: [MAX_PALETTE * 40 + 128]u8
	offset := 0

	s := fmt.bprintf(buf[offset:], "module.exports = {{\n  theme: {{\n    colors: {{\n")
	offset += len(s)

	for c, i in colors {
		s2 := fmt.bprintf(
			buf[offset:],
			"      'color-%d': '#%02X%02X%02X',\n",
			i + 1,
			c.r,
			c.g,
			c.b,
		)
		offset += len(s2)
	}

	s3 := fmt.bprintf(buf[offset:], "    }}\n  }}\n}}\n")
	offset += len(s3)

	return fmt.ctprintf("%s", string(buf[:offset]))
}

export_json :: proc(colors: []rl.Color) -> cstring {
	buf: [MAX_PALETTE * 64 + 8]u8
	offset := 0

	s := fmt.bprintf(buf[offset:], "[\n")
	offset += len(s)

	for c, i in colors {
		comma: string = i < len(colors) - 1 ? "," : ""
		s2 := fmt.bprintf(
			buf[offset:],
			"  {{\"hex\":\"#%02X%02X%02X\",\"r\":%d,\"g\":%d,\"b\":%d}}%s\n",
			c.r,
			c.g,
			c.b,
			c.r,
			c.g,
			c.b,
			comma,
		)
		offset += len(s2)
	}

	s3 := fmt.bprintf(buf[offset:], "]\n")
	offset += len(s3)

	return fmt.ctprintf("%s", string(buf[:offset]))
}

export_text_file :: proc(text: cstring, path: string) {
	s := string(text)
	_ = os.write_entire_file(path, transmute([]u8)s)
}

export_png_strip :: proc(colors: []rl.Color, path: string, swatch_w: i32 = 50, swatch_h: i32 = 50) {
	if len(colors) == 0 do return
	w := swatch_w * i32(len(colors))
	img := rl.GenImageColor(w, swatch_h, rl.BLANK)
	defer rl.UnloadImage(img)

	for c, i in colors {
		rl.ImageDrawRectangle(&img, i32(i) * swatch_w, 0, swatch_w, swatch_h, c)
	}

	rl.ExportImage(img, fmt.ctprintf("%s", path))
}

export_ase :: proc(colors: []rl.Color, path: string) {
	n := len(colors)
	header_size :: 12
	entry_size :: 36

	buf: [header_size + MAX_PALETTE * entry_size]u8
	write_be16 :: proc(b: []u8, offset: ^int, val: u16) {
		b[offset^] = u8(val >> 8)
		b[offset^ + 1] = u8(val)
		offset^ += 2
	}
	write_be32 :: proc(b: []u8, offset: ^int, val: u32) {
		b[offset^] = u8(val >> 24)
		b[offset^ + 1] = u8(val >> 16)
		b[offset^ + 2] = u8(val >> 8)
		b[offset^ + 3] = u8(val)
		offset^ += 4
	}
	write_be_f32 :: proc(b: []u8, offset: ^int, val: f32) {
		bits := transmute(u32)val
		write_be32(b, offset, bits)
	}

	off := 0
	write_be32(buf[:], &off, 0x41534546)
	write_be16(buf[:], &off, 1)
	write_be16(buf[:], &off, 0)
	write_be32(buf[:], &off, u32(n))

	for c in colors {
		write_be16(buf[:], &off, 0x0001)
		write_be32(buf[:], &off, 22)
		write_be16(buf[:], &off, 1)
		write_be16(buf[:], &off, 0)
		write_be32(buf[:], &off, 0x52474220)
		write_be_f32(buf[:], &off, f32(c.r) / 255.0)
		write_be_f32(buf[:], &off, f32(c.g) / 255.0)
		write_be_f32(buf[:], &off, f32(c.b) / 255.0)
		write_be16(buf[:], &off, 0)
	}

	_ = os.write_entire_file(path, buf[:off])
}
