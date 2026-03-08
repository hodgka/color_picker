package layout

import "core:testing"
import "core:math"

approx_eq :: proc(a, b: f32, eps: f32 = 0.01) -> bool {
	return math.abs(a - b) < eps
}

// --- Fixed sizing ---

@(test)
test_single_fixed_node :: proc(t: ^testing.T) {
	root := Node{
		tag    = .Root,
		width  = Fixed{200},
		height = Fixed{100},
	}
	rects := compute(&root, 800, 600)
	defer delete(rects)

	testing.expect_value(t, len(rects), 1)
	r := rects[0]
	testing.expect(t, approx_eq(r.w, 200), "width should be 200")
	testing.expect(t, approx_eq(r.h, 100), "height should be 100")
	testing.expect_value(t, r.tag, Tag.Root)
}

// --- Fill sizing ---

@(test)
test_fill_takes_full_space :: proc(t: ^testing.T) {
	root := Node{
		tag    = .Root,
		width  = Fill{1},
		height = Fill{1},
	}
	rects := compute(&root, 800, 600)
	defer delete(rects)

	r := rects[0]
	testing.expect(t, approx_eq(r.w, 800), "fill width should be screen width")
	testing.expect(t, approx_eq(r.h, 600), "fill height should be screen height")
}

// --- Percent sizing ---

@(test)
test_percent_sizing :: proc(t: ^testing.T) {
	root := Node{
		tag    = .Root,
		width  = Percent{0.5},
		height = Percent{0.25},
	}
	rects := compute(&root, 800, 600)
	defer delete(rects)

	r := rects[0]
	testing.expect(t, approx_eq(r.w, 400), "50% of 800 = 400")
	testing.expect(t, approx_eq(r.h, 150), "25% of 600 = 150")
}

// --- Column layout with fixed children ---

@(test)
test_column_fixed_children :: proc(t: ^testing.T) {
	children := [?]Node{
		{tag = .Header,  height = Fixed{40},  width = Fill{1}},
		{tag = .Preview, height = Fixed{100}, width = Fill{1}},
	}
	root := Node{
		tag      = .Root,
		dir      = .Column,
		width    = Fill{1},
		height   = Fill{1},
		children = children[:],
	}
	rects := compute(&root, 800, 600)
	defer delete(rects)

	testing.expect_value(t, len(rects), 3)

	header, hok := find(rects, .Header)
	testing.expect(t, hok, "header should exist")
	testing.expect(t, approx_eq(header.y, 0), "header at y=0")
	testing.expect(t, approx_eq(header.h, 40), "header height 40")
	testing.expect(t, approx_eq(header.w, 800), "header full width")

	preview, pok := find(rects, .Preview)
	testing.expect(t, pok, "preview should exist")
	testing.expect(t, approx_eq(preview.y, 40), "preview below header")
	testing.expect(t, approx_eq(preview.h, 100), "preview height 100")
}

// --- Row layout with fixed and fill ---

@(test)
test_row_fixed_and_fill :: proc(t: ^testing.T) {
	children := [?]Node{
		{tag = .Left_Column,  width = Fixed{300}, height = Fill{1}},
		{tag = .Right_Column, width = Fill{1},     height = Fill{1}},
	}
	root := Node{
		tag      = .Root,
		dir      = .Row,
		width    = Fill{1},
		height   = Fill{1},
		children = children[:],
	}
	rects := compute(&root, 800, 600)
	defer delete(rects)

	left, lok := find(rects, .Left_Column)
	testing.expect(t, lok)
	testing.expect(t, approx_eq(left.x, 0))
	testing.expect(t, approx_eq(left.w, 300), "left fixed 300")
	testing.expect(t, approx_eq(left.h, 600), "left full height")

	right, rok := find(rects, .Right_Column)
	testing.expect(t, rok)
	testing.expect(t, approx_eq(right.x, 300), "right starts after left")
	testing.expect(t, approx_eq(right.w, 500), "right fills remaining 500")
}

// --- Fill weight distribution ---

@(test)
test_fill_weight_distribution :: proc(t: ^testing.T) {
	children := [?]Node{
		{tag = .Left_Column,  width = Fill{1}, height = Fill{1}},
		{tag = .Right_Column, width = Fill{3}, height = Fill{1}},
	}
	root := Node{
		tag      = .Root,
		dir      = .Row,
		width    = Fill{1},
		height   = Fill{1},
		children = children[:],
	}
	rects := compute(&root, 800, 600)
	defer delete(rects)

	left, _ := find(rects, .Left_Column)
	right, _ := find(rects, .Right_Column)
	testing.expect(t, approx_eq(left.w, 200), "weight 1/4 of 800 = 200")
	testing.expect(t, approx_eq(right.w, 600), "weight 3/4 of 800 = 600")
}

// --- Gap ---

@(test)
test_column_gap :: proc(t: ^testing.T) {
	children := [?]Node{
		{tag = .Header,  height = Fixed{40}, width = Fill{1}},
		{tag = .Preview, height = Fixed{60}, width = Fill{1}},
		{tag = .Hint,    height = Fill{1},   width = Fill{1}},
	}
	root := Node{
		tag      = .Root,
		dir      = .Column,
		width    = Fill{1},
		height   = Fill{1},
		gap      = 10,
		children = children[:],
	}
	rects := compute(&root, 400, 300)
	defer delete(rects)

	header, _ := find(rects, .Header)
	preview, _ := find(rects, .Preview)
	hint, _ := find(rects, .Hint)

	testing.expect(t, approx_eq(header.y, 0))
	testing.expect(t, approx_eq(preview.y, 50), "40 + 10 gap = 50")
	testing.expect(t, approx_eq(hint.y, 120), "50 + 60 + 10 gap = 120")
	// remaining: 300 - 40 - 60 - 20(gaps) = 180
	testing.expect(t, approx_eq(hint.h, 180), "fill takes remaining 180")
}

@(test)
test_row_gap :: proc(t: ^testing.T) {
	children := [?]Node{
		{tag = .Left_Column,  width = Fixed{100}, height = Fill{1}},
		{tag = .Right_Column, width = Fill{1},     height = Fill{1}},
	}
	root := Node{
		tag      = .Root,
		dir      = .Row,
		width    = Fill{1},
		height   = Fill{1},
		gap      = 20,
		children = children[:],
	}
	rects := compute(&root, 500, 300)
	defer delete(rects)

	left, _ := find(rects, .Left_Column)
	right, _ := find(rects, .Right_Column)

	testing.expect(t, approx_eq(left.x, 0))
	testing.expect(t, approx_eq(left.w, 100))
	testing.expect(t, approx_eq(right.x, 120), "100 + 20 gap = 120")
	testing.expect(t, approx_eq(right.w, 380), "500 - 100 - 20 = 380")
}

// --- Padding ---

@(test)
test_padding_offsets_children :: proc(t: ^testing.T) {
	children := [?]Node{
		{tag = .Header, height = Fill{1}, width = Fill{1}},
	}
	root := Node{
		tag      = .Root,
		dir      = .Column,
		width    = Fill{1},
		height   = Fill{1},
		padding  = {top = 10, right = 20, bottom = 30, left = 40},
		children = children[:],
	}
	rects := compute(&root, 400, 300)
	defer delete(rects)

	header, _ := find(rects, .Header)
	testing.expect(t, approx_eq(header.x, 40), "left padding")
	testing.expect(t, approx_eq(header.y, 10), "top padding")
	testing.expect(t, approx_eq(header.w, 340), "400 - 40 - 20 = 340")
	testing.expect(t, approx_eq(header.h, 260), "300 - 10 - 30 = 260")
}

// --- Min/Max constraints ---

@(test)
test_min_width_clamp :: proc(t: ^testing.T) {
	children := [?]Node{
		{tag = .Left_Column, width = Fill{1}, height = Fill{1}, min_w = 200},
		{tag = .Right_Column, width = Fill{1}, height = Fill{1}},
	}
	root := Node{
		tag      = .Root,
		dir      = .Row,
		width    = Fill{1},
		height   = Fill{1},
		children = children[:],
	}
	// With 300px total, equal fill would give 150 each, but min_w=200 clamps.
	rects := compute(&root, 300, 200)
	defer delete(rects)

	left, _ := find(rects, .Left_Column)
	testing.expect(t, approx_eq(left.w, 200), "min_w clamp to 200")
}

@(test)
test_max_width_clamp :: proc(t: ^testing.T) {
	root := Node{
		tag    = .Root,
		width  = Fill{1},
		height = Fill{1},
		max_w  = 500,
	}
	rects := compute(&root, 800, 600)
	defer delete(rects)

	r := rects[0]
	testing.expect(t, approx_eq(r.w, 500), "max_w clamp to 500")
}

// --- Nested layout (app-like structure) ---

@(test)
test_nested_two_column_layout :: proc(t: ^testing.T) {
	right_children := [?]Node{
		{tag = .Preview,  height = Fixed{100}, width = Fill{1}},
		{tag = .Contrast, height = Fixed{48},  width = Fill{1}},
		{tag = .History,  height = Fill{1},     width = Fill{1}},
	}
	main_children := [?]Node{
		{tag = .Left_Column,  width = Fixed{340}, height = Fill{1}, dir = .Column},
		{
			tag      = .Right_Column,
			width    = Fill{1},
			height   = Fill{1},
			dir      = .Column,
			gap      = 8,
			children = right_children[:],
		},
	}
	top_children := [?]Node{
		{tag = .Header, height = Fixed{40}, width = Fill{1}},
		{
			tag      = .Main,
			dir      = .Row,
			width    = Fill{1},
			height   = Fill{1},
			gap      = 28,
			children = main_children[:],
		},
	}
	root := Node{
		tag      = .Root,
		dir      = .Column,
		width    = Fill{1},
		height   = Fill{1},
		padding  = edges_uniform(24),
		children = top_children[:],
	}

	rects := compute(&root, 960, 780)
	defer delete(rects)

	// Root should be full screen.
	root_r, _ := find(rects, .Root)
	testing.expect(t, approx_eq(root_r.w, 960))
	testing.expect(t, approx_eq(root_r.h, 780))

	// Header inside padding.
	header, _ := find(rects, .Header)
	testing.expect(t, approx_eq(header.x, 24), "header x = left padding")
	testing.expect(t, approx_eq(header.y, 24), "header y = top padding")
	testing.expect(t, approx_eq(header.h, 40))
	// width = 960 - 24 - 24 = 912
	testing.expect(t, approx_eq(header.w, 912))

	// Main area below header, fills remaining.
	main_r, _ := find(rects, .Main)
	testing.expect(t, approx_eq(main_r.y, 64), "24 padding + 40 header = 64")
	// height = 780 - 24 - 24 - 40 = 692
	testing.expect(t, approx_eq(main_r.h, 692))

	// Left column fixed at 340.
	left, _ := find(rects, .Left_Column)
	testing.expect(t, approx_eq(left.w, 340))

	// Right column fills remaining: 912 - 340 - 28(gap) = 544.
	right, _ := find(rects, .Right_Column)
	testing.expect(t, approx_eq(right.w, 544))

	// Preview inside right column.
	preview, _ := find(rects, .Preview)
	testing.expect(t, approx_eq(preview.h, 100))
	testing.expect(t, approx_eq(preview.w, 544))

	// Contrast below preview with gap.
	contrast, _ := find(rects, .Contrast)
	testing.expect(t, approx_eq(contrast.h, 48))
	testing.expect(t, approx_eq(contrast.y, preview.y + 100 + 8))

	// History fills remaining in right column.
	history, _ := find(rects, .History)
	expected_history_h := 692 - 100 - 48 - 16 // 16 = 2 gaps
	testing.expect(t, approx_eq(history.h, f32(expected_history_h)), "history fills rest")
}

// --- find returns false for missing tag ---

@(test)
test_find_missing_tag :: proc(t: ^testing.T) {
	root := Node{tag = .Root, width = Fixed{100}, height = Fixed{100}}
	rects := compute(&root, 800, 600)
	defer delete(rects)

	_, ok := find(rects, .Palette)
	testing.expect(t, !ok, "palette tag should not be found")
}

// --- Responsive: same tree, different screen sizes ---

@(test)
test_responsive_fill_adapts :: proc(t: ^testing.T) {
	children := [?]Node{
		{tag = .Left_Column,  width = Fixed{300}, height = Fill{1}},
		{tag = .Right_Column, width = Fill{1},     height = Fill{1}},
	}
	root := Node{
		tag      = .Root,
		dir      = .Row,
		width    = Fill{1},
		height   = Fill{1},
		children = children[:],
	}

	// Small screen.
	rects_small := compute(&root, 600, 400)
	defer delete(rects_small)
	right_s, _ := find(rects_small, .Right_Column)
	testing.expect(t, approx_eq(right_s.w, 300), "600 - 300 = 300")

	// Large screen.
	rects_large := compute(&root, 1200, 800)
	defer delete(rects_large)
	right_l, _ := find(rects_large, .Right_Column)
	testing.expect(t, approx_eq(right_l.w, 900), "1200 - 300 = 900")
}

// --- Edge case: zero children ---

@(test)
test_leaf_node_no_children :: proc(t: ^testing.T) {
	root := Node{
		tag      = .Root,
		dir      = .Column,
		width    = Fill{1},
		height   = Fill{1},
	}
	rects := compute(&root, 400, 300)
	defer delete(rects)

	testing.expect_value(t, len(rects), 1)
	testing.expect(t, approx_eq(rects[0].w, 400))
	testing.expect(t, approx_eq(rects[0].h, 300))
}

// --- Edge case: single child ---

@(test)
test_single_fill_child :: proc(t: ^testing.T) {
	children := [?]Node{
		{tag = .Header, width = Fill{1}, height = Fill{1}},
	}
	root := Node{
		tag      = .Root,
		dir      = .Column,
		width    = Fill{1},
		height   = Fill{1},
		children = children[:],
	}
	rects := compute(&root, 400, 300)
	defer delete(rects)

	header, _ := find(rects, .Header)
	testing.expect(t, approx_eq(header.w, 400))
	testing.expect(t, approx_eq(header.h, 300))
}
