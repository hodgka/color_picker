package color_picker

import rl "vendor:raylib"
import "ui/layout"
import "data"

SV_TEX_SIZE    :: 280
WHEEL_TEX_SIZE :: 340

build_layout :: proc(screen_w, screen_h: f32) -> layout.Node {
	right := make([]layout.Node, 7, context.temp_allocator)
	right[0] = {tag = .Preview,     width = layout.Fill{1}, height = layout.Fixed{108}}
	right[1] = {tag = .Contrast,    width = layout.Fill{1}, height = layout.Fixed{48}}
	right[2] = {tag = .Hex_Field,   width = layout.Fill{1}, height = layout.Fixed{44}}
	right[3] = {tag = .RGB_Sliders, width = layout.Fill{1}, height = layout.Fixed{104}}
	right[4] = {tag = .HSV_Sliders, width = layout.Fill{1}, height = layout.Fixed{98}}
	right[5] = {tag = .Hint,        width = layout.Fill{1}, height = layout.Fixed{24}}
	right[6] = {tag = .History,     width = layout.Fill{1}, height = layout.Fill{1}}

	left := make([]layout.Node, 3, context.temp_allocator)
	left[0] = {tag = .Picker,          width = layout.Fill{1}, height = layout.Fixed{352}}
	left[1] = {tag = .Picker_Controls, width = layout.Fill{1}, height = layout.Fixed{34}}
	left[2] = {tag = .Harmony,         width = layout.Fill{1}, height = layout.Fill{1}}

	main_ch := make([]layout.Node, 2, context.temp_allocator)
	main_ch[0] = {
		tag = .Left_Column, dir = .Column,
		width = layout.Fixed{340}, height = layout.Fill{1},
		children = left,
	}
	main_ch[1] = {
		tag = .Right_Column, dir = .Column,
		width = layout.Fill{1}, height = layout.Fill{1},
		children = right,
	}

	bottom := make([]layout.Node, 2, context.temp_allocator)
	bottom[0] = {tag = .Palette,       width = layout.Fill{1}, height = layout.Fill{1}}
	bottom[1] = {tag = .Export_Button, width = layout.Fill{1}, height = layout.Fixed{28}}

	root_ch := make([]layout.Node, 3, context.temp_allocator)
	root_ch[0] = {tag = .Header, width = layout.Fill{1}, height = layout.Fixed{36}}
	root_ch[1] = {
		tag = .Main, dir = .Row,
		width = layout.Fill{1}, height = layout.Fill{1},
		gap = 28, children = main_ch,
	}
	root_ch[2] = {
		tag = .Bottom, dir = .Column,
		width = layout.Fill{1}, height = layout.Fixed{150},
		children = bottom,
	}

	return layout.Node{
		tag     = .Root,
		dir     = .Column,
		width   = layout.Fill{1},
		height  = layout.Fill{1},
		padding = {top = 14, right = 24, bottom = 16, left = 24},
		children = root_ch,
	}
}

to_rl_rect :: proc(r: layout.Rect) -> rl.Rectangle {
	return {r.x, r.y, r.w, r.h}
}

cols_per_row :: proc(palette_rect: layout.Rect) -> int {
	return max(int(palette_rect.w) / data.SWATCH_STRIDE, 1)
}
