package color_picker

import rl "vendor:raylib"
import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"

SETTINGS_DIR  :: ".config/color_picker"
SETTINGS_FILE_NAME :: "settings.json"

Settings :: struct {
	window_x:       i32,
	window_y:       i32,
	window_w:       i32,
	window_h:       i32,
	font_path:      [256]u8,
	font_path_len:  int,
	font_size:      i32,
	picker_mode:    int,
	harmony_type:   int,
	cvd_mode:       int,
	shade_count:    int,
	recent_palettes: [8][256]u8,
	recent_lens:     [8]int,
	recent_count:    int,
	valid:           bool,
}

default_settings :: proc() -> Settings {
	return Settings{
		window_x    = 100,
		window_y    = 100,
		window_w    = WINDOW_W,
		window_h    = WINDOW_H,
		font_size   = 0,
		picker_mode = 0,
		shade_count = 9,
		valid       = false,
	}
}

settings_path :: proc() -> string {
	home := os.get_env("HOME", context.temp_allocator)
	return fmt.tprintf("%s/%s/%s", home, SETTINGS_DIR, SETTINGS_FILE_NAME)
}

settings_dir_path :: proc() -> string {
	home := os.get_env("HOME", context.temp_allocator)
	return fmt.tprintf("%s/%s", home, SETTINGS_DIR)
}

load_settings :: proc() -> Settings {
	s := default_settings()
	path := settings_path()

	data, err := os.read_entire_file_from_path(path, context.temp_allocator)
	if err != nil do return s

	text := string(data)
	s.valid = true

	s.window_x = _json_int(text, "window_x", s.window_x)
	s.window_y = _json_int(text, "window_y", s.window_y)
	s.window_w = _json_int(text, "window_w", s.window_w)
	s.window_h = _json_int(text, "window_h", s.window_h)
	s.font_size = _json_int(text, "font_size", s.font_size)
	s.picker_mode = int(_json_int(text, "picker_mode", i32(s.picker_mode)))
	s.harmony_type = int(_json_int(text, "harmony_type", i32(s.harmony_type)))
	s.cvd_mode = int(_json_int(text, "cvd_mode", i32(s.cvd_mode)))
	s.shade_count = int(_json_int(text, "shade_count", i32(s.shade_count)))

	fp := _json_str(text, "font_path")
	if len(fp) > 0 {
		n := min(len(fp), 255)
		for i in 0 ..< n do s.font_path[i] = fp[i]
		s.font_path_len = n
	}

	for ri in 0 ..< 8 {
		key := fmt.tprintf("recent_%d", ri)
		rp := _json_str(text, key)
		if len(rp) == 0 do break
		n := min(len(rp), 255)
		for i in 0 ..< n do s.recent_palettes[ri][i] = rp[i]
		s.recent_lens[ri] = n
		s.recent_count = ri + 1
	}

	return s
}

save_settings :: proc(s: ^Settings) {
	dir := settings_dir_path()
	os.make_directory(dir)

	buf: [4096]u8
	offset := 0

	w :: proc(b: []u8, off: ^int, text: string) {
		for i in 0 ..< len(text) {
			b[off^] = text[i]
			off^ += 1
		}
	}

	w(buf[:], &offset, "{\n")

	line :: proc(b: []u8, off: ^int, key: string, val: i32, last := false) {
		s := fmt.bprintf(b[off^:], "  \"%s\": %d%s\n", key, val, last ? "" : ",")
		off^ += len(s)
	}
	str_line :: proc(b: []u8, off: ^int, key: string, val: string, last := false) {
		s := fmt.bprintf(b[off^:], "  \"%s\": \"%s\"%s\n", key, val, last ? "" : ",")
		off^ += len(s)
	}

	line(buf[:], &offset, "window_x", s.window_x)
	line(buf[:], &offset, "window_y", s.window_y)
	line(buf[:], &offset, "window_w", s.window_w)
	line(buf[:], &offset, "window_h", s.window_h)

	fp := string(s.font_path[:s.font_path_len])
	str_line(buf[:], &offset, "font_path", fp)
	line(buf[:], &offset, "font_size", s.font_size)
	line(buf[:], &offset, "picker_mode", i32(s.picker_mode))
	line(buf[:], &offset, "harmony_type", i32(s.harmony_type))
	line(buf[:], &offset, "cvd_mode", i32(s.cvd_mode))
	line(buf[:], &offset, "shade_count", i32(s.shade_count))

	for ri in 0 ..< s.recent_count {
		key := fmt.tprintf("recent_%d", ri)
		val := string(s.recent_palettes[ri][:s.recent_lens[ri]])
		is_last := ri == s.recent_count - 1
		str_line(buf[:], &offset, key, val, last = is_last)
	}

	if s.recent_count == 0 {
		back := offset - 1
		for back > 0 && buf[back] != ',' do back -= 1
		if back > 0 && buf[back] == ',' {
			buf[back] = ' '
		}
	}

	w(buf[:], &offset, "}\n")

	path := settings_path()
	_ = os.write_entire_file(path, buf[:offset])
}

apply_settings :: proc(app: ^AppState, s: ^Settings) {
	app.picker_mode = PickerMode(clamp(s.picker_mode, 0, 1))
	app.harmony_type = clamp(s.harmony_type, 0, 7)
	app.cvd_mode = CvdType(clamp(s.cvd_mode, 0, 3))
	if s.shade_count >= 3 && s.shade_count <= MAX_SHADES {
		app.shade_req = s.shade_count
	}
}

capture_settings :: proc(app: ^AppState) -> Settings {
	s := default_settings()
	pos := rl.GetWindowPosition()
	s.window_x = i32(pos.x)
	s.window_y = i32(pos.y)
	s.window_w = i32(rl.GetScreenWidth())
	s.window_h = i32(rl.GetScreenHeight())
	s.picker_mode = int(app.picker_mode)
	s.harmony_type = app.harmony_type
	s.cvd_mode = int(app.cvd_mode)
	s.shade_count = app.shade_req
	s.valid = true
	return s
}

// Minimal JSON field parsers (no full parser needed for flat key-value)
_json_int :: proc(text: string, key: string, fallback: i32) -> i32 {
	needle := fmt.tprintf("\"%s\":", key)
	idx := strings.index(text, needle)
	if idx < 0 do return fallback
	rest := text[idx + len(needle):]
	rest = strings.trim_left_space(rest)
	end := 0
	for end < len(rest) && (rest[end] >= '0' && rest[end] <= '9' || rest[end] == '-') {
		end += 1
	}
	if end == 0 do return fallback
	val, ok := strconv.parse_int(rest[:end])
	if !ok do return fallback
	return i32(val)
}

_json_str :: proc(text: string, key: string) -> string {
	needle := fmt.tprintf("\"%s\":", key)
	idx := strings.index(text, needle)
	if idx < 0 do return ""
	rest := text[idx + len(needle):]
	rest = strings.trim_left_space(rest)
	if len(rest) == 0 || rest[0] != '"' do return ""
	rest = rest[1:]
	end := strings.index(rest, "\"")
	if end < 0 do return ""
	return rest[:end]
}
