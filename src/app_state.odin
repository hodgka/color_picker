package color_picker

import rl "vendor:raylib"
import "color"
import "ui"
import "data"

PickerMode :: enum {
	Wheel,
	Square,
}

SlotTarget :: enum {
	None,
	FG,
	BG,
}

DragState :: struct {
	sv:    bool,
	hue:   bool,
	rgb:   [3]bool,
	hsv:   [3]bool,
	wheel: bool,
}

EXPORT_FORMATS :: [7]cstring{"ASE", "GPL", "CSS", "Tailwind", "JSON", "PNG", "TXT"}

PALETTE_UNDO_MAX :: 32

PaletteSnapshot :: struct {
	colors: [data.MAX_PALETTE]rl.Color,
	count:  int,
}

AppState :: struct {
	cs:              color.ColorState,
	picker_mode:     PickerMode,
	harmony_type:    int,
	harmony_open:    bool,
	harmony_colors:  [color.MAX_HARMONY]rl.Color,
	harmony_count:   int,
	harmony_req:     int,
	fg_slot:         rl.Color,
	bg_slot:         rl.Color,
	active_slot:     SlotTarget,
	shades:          [color.MAX_SHADES]rl.Color,
	shade_count:     int,
	shade_req:       int,
	shade_v_min:     f32,
	shade_v_max:     f32,
	history:         [data.HISTORY_MAX]rl.Color,
	history_count:   int,
	history_head:    int,
	palette:         [data.MAX_PALETTE]rl.Color,
	palette_count:   int,
	palette_hover:   int,
	extracted:        [data.EXTRACT_COUNT]rl.Color,
	extracted_count:  int,
	extract_open:     bool,
	extract_req:      int,
	extract_img:      rl.Image,
	extract_tex:      rl.Texture2D,
	extract_has_img:  bool,
	sv_img:          rl.Image,
	sv_tex:          rl.Texture2D,
	hue_tex:         rl.Texture2D,
	wheel_img:       rl.Image,
	wheel_tex:       rl.Texture2D,
	hex_input:       ui.TextInput,
	drags:           DragState,
	copied_timer:    f32,
	palette_drag:      int,
	palette_dragging:  bool,
	drop_flash_timer:  f32,
	eyedropper_active: bool,
	eyedropper_img:    rl.Image,
	eyedropper_tex:    rl.Texture2D,
	cvd_mode:          color.CvdType,
	cvd_open:          bool,
	prev_cvd:          color.CvdType,
	export_open:       bool,
	export_format:     int,
	export_fmt_open:   bool,
	export_name:       ui.TextInput,
	status_message:    cstring,
	status_timer:      f32,
	palette_undo:      [PALETTE_UNDO_MAX]PaletteSnapshot,
	palette_undo_count: int,
}

commit_color :: proc(app: ^AppState) {
	c := color.color_get(&app.cs)
	data.history_push(app.history[:], &app.history_count, &app.history_head, c)
	switch app.active_slot {
	case .FG:  app.fg_slot = c
	case .BG:  app.bg_slot = c
	case .None:
	}
}

update_harmony :: proc(app: ^AppState) {
	ht := color.HarmonyType(app.harmony_type)
	app.harmony_colors, app.harmony_count = color.compute_harmony(app.cs.hue, app.cs.sat, app.cs.val, ht, app.harmony_req)
	app.harmony_req = app.harmony_count
}

update_shades :: proc(app: ^AppState) {
	app.shades, app.shade_count = color.generate_shades(app.cs.hue, app.cs.sat, app.shade_req, app.shade_v_min, app.shade_v_max)
}

init_app_inputs :: proc(app: ^AppState) {
	app.hex_input = ui.text_input_init("FF0000", .Hex)
	app.export_name = ui.text_input_init("palette")
}

sync_hex_from_color :: proc(app: ^AppState) {
	if app.hex_input.focused do return
	c := color.color_get(&app.cs)
	hex_str := color.color_to_hex_string(c)
	ui.text_input_set_string(&app.hex_input, string(hex_str[1:7]))
}

set_status :: proc(app: ^AppState, msg: cstring, duration: f32 = 2.0) {
	app.status_message = msg
	app.status_timer = duration
}

save_palette_with_status :: proc(app: ^AppState) {
	if !data.save_palette(app.palette[:app.palette_count], data.PALETTE_FILE) {
		set_status(app, "Failed to save palette")
	}
}

palette_undo_push :: proc(app: ^AppState) {
	snap := PaletteSnapshot{app.palette, app.palette_count}
	if app.palette_undo_count > 0 {
		top := app.palette_undo[app.palette_undo_count - 1]
		if top.count == snap.count && top.colors == snap.colors do return
	}
	if app.palette_undo_count < PALETTE_UNDO_MAX {
		app.palette_undo[app.palette_undo_count] = snap
		app.palette_undo_count += 1
	} else {
		for i in 1 ..< PALETTE_UNDO_MAX {
			app.palette_undo[i - 1] = app.palette_undo[i]
		}
		app.palette_undo[PALETTE_UNDO_MAX - 1] = snap
	}
}

palette_undo_pop :: proc(app: ^AppState) -> bool {
	if app.palette_undo_count == 0 do return false
	app.palette_undo_count -= 1
	snap := app.palette_undo[app.palette_undo_count]
	app.palette = snap.colors
	app.palette_count = snap.count
	save_palette_with_status(app)
	return true
}

export_for_format :: proc(colors: []rl.Color, format: int) -> cstring {
	switch format {
	case 2: return data.export_css(colors)
	case 3: return data.export_tailwind(colors)
	case 4: return data.export_json(colors)
	case 6: return data.palette_to_hex_array(colors)
	case:   return data.palette_to_hex_array(colors)
	}
}
