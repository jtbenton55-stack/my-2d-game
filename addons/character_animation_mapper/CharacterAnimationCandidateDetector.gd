extends RefCounted

## Semi-automated contiguous clip detection for PVGames-style sheets (editor-only).

const MIN_CLIP_FRAMES := 3
const MAX_CLIP_FRAMES := 40
const EMPTY_COVERAGE := 0.012
const STILL_DIFF := 0.01
const BREAK_DIFF := 0.045
const MOTION_DIFF := 0.04
const THUMB_SIZE := 24


static func detect_from_image(
	img: Image,
	frame_width: int,
	frame_height: int,
	columns: int,
	rows: int
) -> Array[Dictionary]:
	if img == null or img.is_empty() or columns <= 0 or rows <= 0:
		return []
	var fw := maxi(1, frame_width)
	var fh := maxi(1, frame_height)
	var total := columns * rows
	var thumbs: Array = []
	thumbs.resize(total)
	for g: int in range(total):
		thumbs[g] = _frame_thumb(img, g, fw, fh, columns)
	var coverages: PackedFloat32Array = PackedFloat32Array()
	coverages.resize(total)
	for g: int in range(total):
		coverages[g] = float(thumbs[g].get("coverage", 0.0))
	var diffs: PackedFloat32Array = PackedFloat32Array()
	diffs.resize(maxi(0, total - 1))
	for g: int in range(total - 1):
		diffs[g] = _thumb_diff(thumbs[g], thumbs[g + 1])
	var active_runs: Array[Dictionary] = []
	var run_start := -1
	for g: int in range(total):
		if coverages[g] > EMPTY_COVERAGE:
			if run_start < 0:
				run_start = g
		else:
			if run_start >= 0:
				active_runs.append({"start": run_start, "end": g - 1})
				run_start = -1
	if run_start >= 0:
		active_runs.append({"start": run_start, "end": total - 1})
	var pieces: Array[Dictionary] = []
	for run: Dictionary in active_runs:
		for piece: Dictionary in _split_run_on_motion(run, diffs, coverages, total):
			pieces.append(piece)
	var candidates: Array[Dictionary] = []
	var index := 1
	for r: Dictionary in pieces:
		var start_g: int = int(r.start)
		var end_g: int = int(r.end)
		if end_g - start_g + 1 < MIN_CLIP_FRAMES:
			continue
		var frames := PackedInt32Array()
		for g: int in range(start_g, end_g + 1):
			frames.append(g)
		var reason := _reason_for_range(start_g, end_g, diffs, coverages)
		var notes := (
			"detected_by=image_signature; reason=%s; start=%d; end=%d; frame_count=%d"
			% [reason, start_g, end_g, frames.size()]
		)
		candidates.append({
			"animation_name": "candidate_%03d" % index,
			"start_frame": start_g,
			"end_frame": end_g,
			"frames": _packed_to_array(frames),
			"fps": 10.0,
			"loop": true,
			"review_status": "needs_review",
			"notes": notes,
		})
		index += 1
	return candidates


static func _split_run_on_motion(run: Dictionary, diffs: PackedFloat32Array, coverages: PackedFloat32Array, total: int) -> Array[Dictionary]:
	var start_g: int = int(run.start)
	var end_g: int = int(run.end)
	var length := end_g - start_g + 1
	if length <= MAX_CLIP_FRAMES:
		return [run]
	var pieces: Array[Dictionary] = []
	var cursor := start_g
	while cursor <= end_g:
		var chunk_end := mini(cursor + MAX_CLIP_FRAMES - 1, end_g)
		if chunk_end >= end_g:
			pieces.append({"start": cursor, "end": end_g})
			break
		var best_cut := chunk_end
		var best_score := -1.0
		for g: int in range(cursor + MIN_CLIP_FRAMES - 1, chunk_end):
			if g >= total - 1:
				break
			var score := diffs[g]
			if coverages[g] <= EMPTY_COVERAGE or coverages[g + 1] <= EMPTY_COVERAGE:
				score += 0.5
			if score > best_score:
				best_score = score
				best_cut = g
		if best_cut <= cursor:
			best_cut = chunk_end
		pieces.append({"start": cursor, "end": best_cut})
		cursor = best_cut + 1
	var refined: Array[Dictionary] = []
	for piece: Dictionary in pieces:
		for sub: Dictionary in _split_still_subclips(piece, diffs):
			if int(sub.end) - int(sub.start) + 1 >= MIN_CLIP_FRAMES:
				refined.append(sub)
	return refined


static func _split_still_subclips(run: Dictionary, diffs: PackedFloat32Array) -> Array[Dictionary]:
	var start_g: int = int(run.start)
	var end_g: int = int(run.end)
	if end_g - start_g + 1 < MIN_CLIP_FRAMES * 2:
		return [run]
	var segments: Array[Dictionary] = []
	var seg_start := start_g
	for g: int in range(start_g, end_g):
		if g < diffs.size() and diffs[g] < STILL_DIFF:
			if g - seg_start + 1 >= MIN_CLIP_FRAMES:
				segments.append({"start": seg_start, "end": g})
			seg_start = g + 1
	if end_g - seg_start + 1 >= MIN_CLIP_FRAMES:
		segments.append({"start": seg_start, "end": end_g})
	if segments.is_empty():
		return [run]
	return segments


static func _packed_to_array(frames: PackedInt32Array) -> Array:
	var out: Array = []
	for g: int in frames:
		out.append(g)
	return out


static func _frame_thumb(img: Image, global_index: int, fw: int, fh: int, columns: int) -> Dictionary:
	var row: int = global_index / columns
	var col: int = global_index % columns
	var region := Rect2i(col * fw, row * fh, fw, fh)
	region = region.intersection(Rect2i(Vector2i.ZERO, img.get_size()))
	if region.size.x <= 0 or region.size.y <= 0:
		return {"coverage": 0.0, "avg": Color(0, 0, 0, 0), "bins": PackedFloat32Array()}
	var sub := img.get_region(region)
	if sub.is_empty():
		return {"coverage": 0.0, "avg": Color(0, 0, 0, 0), "bins": PackedFloat32Array()}
	sub.resize(THUMB_SIZE, THUMB_SIZE, Image.INTERPOLATE_BILINEAR)
	var w := sub.get_width()
	var h := sub.get_height()
	var opaque := 0
	var r_sum := 0.0
	var g_sum := 0.0
	var b_sum := 0.0
	var bins := PackedFloat32Array()
	bins.resize(16)
	for y: int in range(h):
		for x: int in range(w):
			var c: Color = sub.get_pixel(x, y)
			if c.a < 0.08:
				continue
			opaque += 1
			r_sum += c.r
			g_sum += c.g
			b_sum += c.b
			var bin_idx := clampi(int((c.r + c.g + c.b) * 5.0), 0, 15)
			bins[bin_idx] += 1.0
	var pixel_count := w * h
	var coverage := float(opaque) / float(maxi(1, pixel_count))
	var avg := Color(r_sum / float(maxi(1, opaque)), g_sum / float(maxi(1, opaque)), b_sum / float(maxi(1, opaque)), 1.0)
	if opaque > 0:
		for i: int in range(bins.size()):
			bins[i] /= float(opaque)
	return {"coverage": coverage, "avg": avg, "bins": bins}


static func _thumb_diff(a: Dictionary, b: Dictionary) -> float:
	var cov_a: float = a.get("coverage", 0.0)
	var cov_b: float = b.get("coverage", 0.0)
	if cov_a <= EMPTY_COVERAGE and cov_b <= EMPTY_COVERAGE:
		return 0.0
	if cov_a <= EMPTY_COVERAGE or cov_b <= EMPTY_COVERAGE:
		return 1.0
	var avg_a: Color = a.get("avg", Color.BLACK)
	var avg_b: Color = b.get("avg", Color.BLACK)
	var color_diff := absf(avg_a.r - avg_b.r) + absf(avg_a.g - avg_b.g) + absf(avg_a.b - avg_b.b)
	var bins_a: PackedFloat32Array = a.get("bins", PackedFloat32Array())
	var bins_b: PackedFloat32Array = b.get("bins", PackedFloat32Array())
	var hist_diff := 0.0
	var n := mini(bins_a.size(), bins_b.size())
	for i: int in range(n):
		hist_diff += absf(bins_a[i] - bins_b[i])
	return clampf(color_diff * 0.35 + hist_diff * 0.65, 0.0, 1.0)


static func _reason_for_range(start_g: int, end_g: int, diffs: PackedFloat32Array, coverages: PackedFloat32Array) -> String:
	var motion_sum := 0.0
	var still_count := 0
	var samples := 0
	for g: int in range(start_g, end_g):
		if g < diffs.size():
			motion_sum += diffs[g]
			samples += 1
			if diffs[g] < STILL_DIFF:
				still_count += 1
	var avg_motion := motion_sum / float(maxi(1, samples))
	if coverages[start_g] <= EMPTY_COVERAGE or coverages[end_g] <= EMPTY_COVERAGE:
		return "low_content_edges"
	if still_count > samples / 2:
		return "still_hold_cluster"
	if avg_motion >= MOTION_DIFF:
		return "motion_cluster"
	return "mixed_motion_cluster"
