package layout

import "core:math"

Direction :: enum {
	Row,
	Column,
}

Fixed :: struct {
	px: f32,
}

Percent :: struct {
	pct: f32,
}

Fill :: struct {
	weight: f32,
}

Fit :: struct {}

Size :: union {
	Fixed,
	Percent,
	Fill,
	Fit,
}

Tag :: enum {
	None,
	Root,
	Header,
	Main,
	Left_Column,
	Picker,
	Picker_Controls,
	Harmony,
	Right_Column,
	Preview,
	Contrast,
	Hex_Field,
	RGB_Sliders,
	HSV_Sliders,
	Hint,
	History,
	Bottom,
	Palette,
	Export_Button,
}

Edges :: struct {
	top, right, bottom, left: f32,
}

Node :: struct {
	tag:      Tag,
	dir:      Direction,
	width:    Size,
	height:   Size,
	min_w:    f32,
	min_h:    f32,
	max_w:    f32,
	max_h:    f32,
	padding:  Edges,
	gap:      f32,
	children: []Node,
}

Rect :: struct {
	x, y, w, h: f32,
	tag:         Tag,
}

edges_uniform :: proc(v: f32) -> Edges {
	return {v, v, v, v}
}

edges_xy :: proc(x, y: f32) -> Edges {
	return {y, x, y, x}
}

// Count the total number of nodes in a tree rooted at `node`.
count_nodes :: proc(node: ^Node) -> int {
	n := 1
	for &child in node.children {
		n += count_nodes(&child)
	}
	return n
}

// Resolve a Size value against the available space.
resolve_size :: proc(s: Size, available: f32) -> f32 {
	switch v in s {
	case Fixed:
		return v.px
	case Percent:
		return available * clamp(v.pct, 0, 1)
	case Fill:
		return 0
	case Fit:
		return 0
	case:
		return 0
	}
}

is_fill :: proc(s: Size) -> bool {
	_, ok := s.(Fill)
	return ok
}

fill_weight :: proc(s: Size) -> f32 {
	if f, ok := s.(Fill); ok {
		return math.max(f.weight, 0)
	}
	return 0
}

// Measure pass (bottom-up): compute preferred sizes for each node.
// Returns (preferred_w, preferred_h) for the given node.
measure :: proc(node: ^Node, avail_w, avail_h: f32) -> (f32, f32) {
	pad_h := node.padding.left + node.padding.right
	pad_v := node.padding.top + node.padding.bottom
	inner_w := math.max(avail_w - pad_h, 0)
	inner_h := math.max(avail_h - pad_v, 0)

	child_count := len(node.children)
	total_gap: f32 = 0
	if child_count > 1 {
		total_gap = node.gap * f32(child_count - 1)
	}

	content_w: f32 = 0
	content_h: f32 = 0

	if child_count > 0 {
		if node.dir == .Row {
			child_avail_w := math.max(inner_w - total_gap, 0)
			for &child in node.children {
				cw, ch := measure(&child, child_avail_w, inner_h)
				content_w += cw
				content_h = math.max(content_h, ch)
			}
			content_w += total_gap
		} else {
			child_avail_h := math.max(inner_h - total_gap, 0)
			for &child in node.children {
				cw, ch := measure(&child, inner_w, child_avail_h)
				content_w = math.max(content_w, cw)
				content_h += ch
			}
			content_h += total_gap
		}
	}

	pref_w := resolve_size(node.width, avail_w)
	if pref_w == 0 {
		pref_w = content_w + pad_h
	}
	pref_h := resolve_size(node.height, avail_h)
	if pref_h == 0 {
		pref_h = content_h + pad_v
	}

	if node.min_w > 0 { pref_w = math.max(pref_w, node.min_w) }
	if node.min_h > 0 { pref_h = math.max(pref_h, node.min_h) }
	if node.max_w > 0 { pref_w = math.min(pref_w, node.max_w) }
	if node.max_h > 0 { pref_h = math.min(pref_h, node.max_h) }

	return pref_w, pref_h
}

// Layout pass (top-down): assign concrete (x, y, w, h) to each node and its children.
layout_node :: proc(node: ^Node, x, y, w, h: f32, out: ^[dynamic]Rect) {
	final_w := w
	final_h := h

	if node.min_w > 0 { final_w = math.max(final_w, node.min_w) }
	if node.min_h > 0 { final_h = math.max(final_h, node.min_h) }
	if node.max_w > 0 { final_w = math.min(final_w, node.max_w) }
	if node.max_h > 0 { final_h = math.min(final_h, node.max_h) }

	append(out, Rect{x, y, final_w, final_h, node.tag})

	child_count := len(node.children)
	if child_count == 0 { return }

	inner_x := x + node.padding.left
	inner_y := y + node.padding.top
	inner_w := math.max(final_w - node.padding.left - node.padding.right, 0)
	inner_h := math.max(final_h - node.padding.top - node.padding.bottom, 0)

	total_gap: f32 = 0
	if child_count > 1 {
		total_gap = node.gap * f32(child_count - 1)
	}

	is_row := node.dir == .Row

	// First pass: measure fixed/percent children, sum fill weights.
	fixed_total: f32 = 0
	fill_total: f32 = 0
	child_sizes := make([]f32, child_count, context.temp_allocator)

	for &child, i in node.children {
		main_size: Size = child.width if is_row else child.height
		avail := inner_w if is_row else inner_h

		if is_fill(main_size) {
			fill_total += fill_weight(main_size)
			child_sizes[i] = -1 // sentinel for fill
		} else {
			pref_w, pref_h := measure(&child, inner_w, inner_h)
			sz := pref_w if is_row else pref_h
			child_sizes[i] = sz
			fixed_total += sz
		}
	}

	remaining := (inner_w if is_row else inner_h) - fixed_total - total_gap
	remaining = math.max(remaining, 0)

	// Second pass: resolve fill children.
	for &child, i in node.children {
		if child_sizes[i] < 0 {
			main_size: Size = child.width if is_row else child.height
			w_frac := fill_weight(main_size)
			if fill_total > 0 {
				child_sizes[i] = remaining * (w_frac / fill_total)
			} else {
				child_sizes[i] = 0
			}
		}

		// Clamp to min/max.
		min_main := child.min_w if is_row else child.min_h
		max_main := child.max_w if is_row else child.max_h
		if min_main > 0 { child_sizes[i] = math.max(child_sizes[i], min_main) }
		if max_main > 0 { child_sizes[i] = math.min(child_sizes[i], max_main) }
	}

	// Third pass: position children.
	cursor: f32 = 0
	for &child, i in node.children {
		cx, cy, cw, ch: f32

		if is_row {
			cx = inner_x + cursor
			cy = inner_y
			cw = child_sizes[i]
			ch = inner_h
		} else {
			cx = inner_x
			cy = inner_y + cursor
			cw = inner_w
			ch = child_sizes[i]
		}

		// Resolve cross-axis size from the child's own declaration.
		if is_row {
			cross := resolve_size(child.height, inner_h)
			if cross > 0 {
				ch = cross
			}
		} else {
			cross := resolve_size(child.width, inner_w)
			if cross > 0 {
				cw = cross
			}
		}

		layout_node(&child, cx, cy, cw, ch, out)
		cursor += child_sizes[i] + node.gap
	}
}

// Compute the layout for the entire tree. Returns a flat slice of Rects.
compute :: proc(root: ^Node, screen_w, screen_h: f32, allocator := context.allocator) -> []Rect {
	n := count_nodes(root)
	out := make([dynamic]Rect, 0, n, allocator)

	root_w := resolve_size(root.width, screen_w)
	if root_w == 0 { root_w = screen_w }
	root_h := resolve_size(root.height, screen_h)
	if root_h == 0 { root_h = screen_h }

	if root.min_w > 0 { root_w = math.max(root_w, root.min_w) }
	if root.min_h > 0 { root_h = math.max(root_h, root.min_h) }
	if root.max_w > 0 { root_w = math.min(root_w, root.max_w) }
	if root.max_h > 0 { root_h = math.min(root_h, root.max_h) }

	layout_node(root, 0, 0, root_w, root_h, &out)
	return out[:]
}

// Find a rect by tag. Returns the rect and true if found.
find :: proc(rects: []Rect, tag: Tag) -> (Rect, bool) {
	for &r in rects {
		if r.tag == tag { return r, true }
	}
	return {}, false
}
