package color_picker

import rl "vendor:raylib"

// Layout constants
WINDOW_W :: 960
WINDOW_H :: 780
MARGIN   :: 24

PICKER_SIZE :: 340
PICKER_X    :: MARGIN
PICKER_Y    :: 50
LEFT_W      :: PICKER_SIZE

RIGHT_X :: PICKER_X + LEFT_W + 28
RIGHT_W :: WINDOW_W - RIGHT_X - MARGIN

PREVIEW_H       :: 100
PREVIEW_Y       :: PICKER_Y
CONTRAST_INFO_Y :: PREVIEW_Y + PREVIEW_H + 8
HEX_FIELD_Y     :: CONTRAST_INFO_Y + 48
SLIDER_BASE_Y   :: HEX_FIELD_Y + 44
SLIDER_SPACING  :: 30
HSV_SLIDER_Y    :: SLIDER_BASE_Y + 3 * SLIDER_SPACING + 14
HINT_Y          :: HSV_SLIDER_Y + 3 * SLIDER_SPACING + 8

SV_SIZE   :: 280
HUE_BAR_H :: 20
SV_X      :: PICKER_X
SV_Y      :: PICKER_Y

HARMONY_SECTION_Y :: PICKER_Y + PICKER_SIZE + 46

HISTORY_Y  :: HINT_Y + 24
EXPORT_BTN_Y :: WINDOW_H - 44

COLS_PER_ROW :: (WINDOW_W - 2 * MARGIN) / SWATCH_STRIDE

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

AppState :: struct {
	cs:              ColorState,
	picker_mode:     PickerMode,
	harmony_type:    int,
	harmony_open:    bool,
	harmony_colors:  [MAX_HARMONY]rl.Color,
	harmony_count:   int,
	harmony_req:     int,
	fg_slot:         rl.Color,
	bg_slot:         rl.Color,
	active_slot:     SlotTarget,
	shades:          [MAX_SHADES]rl.Color,
	shade_count:     int,
	shade_req:       int,
	shade_v_min:     f32,
	shade_v_max:     f32,
	history:         [HISTORY_MAX]rl.Color,
	history_count:   int,
	history_head:    int,
	palette:         [MAX_PALETTE]rl.Color,
	palette_count:   int,
	palette_hover:   int,
	extracted:        [EXTRACT_COUNT]rl.Color,
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
	hex_cursor:       int,
	hex_focused:      bool,
	hex_blink:        f32,
	hex_select_all:   bool,
	hex_last_click:   f32,
	drags:           DragState,
	copied_timer:    f32,
	palette_drag:      int,
	palette_dragging:  bool,
	drop_flash_timer:  f32,
	error_timer:       f32,
	error_msg:         cstring,
	eyedropper_active: bool,
	eyedropper_img:    rl.Image,
	eyedropper_tex:    rl.Texture2D,
	cvd_mode:          CvdType,
	cvd_open:          bool,
	prev_cvd:          CvdType,
	export_open:       bool,
	export_format:     int,
	export_fmt_open:   bool,
	export_name:       TextInput,
	layout:            Layout,
	tooltip:           Tooltip,
}

commit_color :: proc(app: ^AppState) {
	c := color_get(&app.cs)
	history_push(app.history[:], &app.history_count, &app.history_head, c)
	switch app.active_slot {
	case .FG:  app.fg_slot = c
	case .BG:  app.bg_slot = c
	case .None:
	}
}

update_harmony :: proc(app: ^AppState) {
	ht := HarmonyType(app.harmony_type)
	app.harmony_colors, app.harmony_count = compute_harmony(app.cs.hue, app.cs.sat, app.cs.val, ht, app.harmony_req)
	app.harmony_req = app.harmony_count
}

update_shades :: proc(app: ^AppState) {
	app.shades, app.shade_count = generate_shades(app.cs.hue, app.cs.sat, app.shade_req, app.shade_v_min, app.shade_v_max)
}

init_app_inputs :: proc(app: ^AppState) {
	app.export_name = text_input_init("palette")
}
