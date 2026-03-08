package data

import rl "vendor:raylib"
import "core:slice"

EXTRACT_COUNT :: 8

ColorBucket :: struct {
	pixels:     [dynamic][3]u8,
}

extract_palette_from_image :: proc(img: rl.Image, count: int = EXTRACT_COUNT) -> (result: [EXTRACT_COUNT]rl.Color, n: int) {
	w := int(img.width)
	h := int(img.height)
	total := w * h
	if total == 0 do return result, 0

	pixels := cast([^]rl.Color)img.data
	step := max(1, total / 4096)

	sampled: [dynamic][3]u8
	defer delete(sampled)

	for i := 0; i < total; i += step {
		p := pixels[i]
		if p.a < 128 do continue
		append(&sampled, [3]u8{p.r, p.g, p.b})
	}

	if len(sampled) == 0 do return result, 0

	n = min(count, EXTRACT_COUNT)
	median_cut(&result, sampled[:], n)
	return
}

median_cut :: proc(out: ^[EXTRACT_COUNT]rl.Color, pixels: [][3]u8, target: int) {
	Bucket :: struct {
		start, end: int,
	}

	working := make([][3]u8, len(pixels))
	defer delete(working)
	copy(working, pixels)

	buckets: [EXTRACT_COUNT * 2]Bucket
	bucket_count := 1
	buckets[0] = {0, len(working)}

	for bucket_count < target {
		best_idx := -1
		best_range := -1

		for bi in 0 ..< bucket_count {
			b := buckets[bi]
			if b.end - b.start < 2 do continue

			for ch in 0 ..< 3 {
				lo, hi: u8 = 255, 0
				for i in b.start ..< b.end {
					v := working[i][ch]
					if v < lo do lo = v
					if v > hi do hi = v
				}
				r := int(hi) - int(lo)
				if r > best_range {
					best_range = r
					best_idx = bi
				}
			}
		}

		if best_idx < 0 do break

		b := buckets[best_idx]

		best_ch := 0
		best_ch_range := -1
		for ch in 0 ..< 3 {
			lo, hi: u8 = 255, 0
			for i in b.start ..< b.end {
				v := working[i][ch]
				if v < lo do lo = v
				if v > hi do hi = v
			}
			r := int(hi) - int(lo)
			if r > best_ch_range {
				best_ch_range = r
				best_ch = ch
			}
		}

		sub := working[b.start:b.end]
		slice.sort_by(sub, proc(a, b: [3]u8) -> bool {
			// Uses channel from context - we sort by all channels combined as approximation
			sa := int(a[0]) + int(a[1]) + int(a[2])
			sb := int(b[0]) + int(b[1]) + int(b[2])
			return sa < sb
		})

		mid := b.start + (b.end - b.start) / 2
		buckets[best_idx] = {b.start, mid}
		buckets[bucket_count] = {mid, b.end}
		bucket_count += 1
	}

	for bi in 0 ..< min(bucket_count, EXTRACT_COUNT) {
		b := buckets[bi]
		rr, gg, bb := 0, 0, 0
		cnt := b.end - b.start
		if cnt == 0 do continue
		for i in b.start ..< b.end {
			rr += int(working[i][0])
			gg += int(working[i][1])
			bb += int(working[i][2])
		}
		out[bi] = rl.Color{u8(rr / cnt), u8(gg / cnt), u8(bb / cnt), 255}
	}
}
