extends RefCounted


static func sorted_frames_array(frames: PackedInt32Array) -> PackedInt32Array:
	var keys: Array = []
	for g: int in frames:
		keys.append(g)
	keys.sort()
	var out := PackedInt32Array()
	for k in keys:
		out.append(int(k))
	return out


static func build_row_column_ranges_from_frames(frames: PackedInt32Array, columns: int) -> Array:
	if frames.is_empty() or columns <= 0:
		return []
	var sorted := sorted_frames_array(frames)
	var ranges: Array = []
	var run_start: int = sorted[0]
	var run_end: int = sorted[0]
	for i: int in range(1, sorted.size()):
		if sorted[i] == run_end + 1:
			run_end = sorted[i]
		else:
			ranges.append(_range_dict_from_globals(run_start, run_end, columns))
			run_start = sorted[i]
			run_end = sorted[i]
	ranges.append(_range_dict_from_globals(run_start, run_end, columns))
	return ranges


static func _range_dict_from_globals(start_g: int, end_g: int, columns: int) -> Dictionary:
	var sr := start_g / columns
	var sc := start_g % columns
	var er := end_g / columns
	var ec := end_g % columns
	return {
		"start_row": sr,
		"start_column": sc,
		"end_row": er,
		"end_column": ec,
	}


static func build_animation_entry(
	animation_name: String,
	frames: PackedInt32Array,
	fps: float,
	loop: bool,
	review_status: String,
	notes: String,
	columns: int
) -> Dictionary:
	var sorted := sorted_frames_array(frames)
	if sorted.is_empty():
		return {}
	var frame_array: Array = []
	for g: int in sorted:
		frame_array.append(g)
	return {
		"animation_name": animation_name,
		"start_frame": sorted[0],
		"end_frame": sorted[sorted.size() - 1],
		"frames": frame_array,
		"fps": fps,
		"loop": loop,
		"review_status": review_status,
		"notes": notes,
		"row_column_ranges": build_row_column_ranges_from_frames(sorted, columns),
	}


static func selection_summary(frames: PackedInt32Array) -> String:
	if frames.is_empty():
		return "No frames selected."
	var sorted := sorted_frames_array(frames)
	return "frames %d..%d, count %d" % [sorted[0], sorted[sorted.size() - 1], sorted.size()]


static func expand_contiguous_range(start_g: int, end_g: int) -> PackedInt32Array:
	var out := PackedInt32Array()
	if end_g < start_g:
		return out
	for i: int in range(start_g, end_g + 1):
		out.append(i)
	return out


static func clamp_contiguous_frame_range(
	start_g: int,
	end_g: int,
	total_frames: int,
	edited_start: bool
) -> Vector2i:
	var max_g := maxi(0, total_frames - 1)
	var start_v := clampi(start_g, 0, max_g)
	var end_v := clampi(end_g, 0, max_g)
	if start_v > end_v:
		if edited_start:
			end_v = start_v
		else:
			start_v = end_v
	return Vector2i(start_v, end_v)


static func update_candidate_contiguous_range(
	entry: Dictionary,
	start_g: int,
	end_g: int,
	columns: int,
	total_frames: int,
	edited_start: bool
) -> Dictionary:
	if entry.is_empty() or columns <= 0 or total_frames <= 0:
		return {}
	var clamped := clamp_contiguous_frame_range(start_g, end_g, total_frames, edited_start)
	var start_v := clamped.x
	var end_v := clamped.y
	var frames := expand_contiguous_range(start_v, end_v)
	if frames.is_empty():
		return {}
	var status := String(entry.get("review_status", "needs_review"))
	if status.is_empty():
		status = "needs_review"
	var notes := String(entry.get("notes", ""))
	if not notes.contains("manual_range_edit="):
		if notes.is_empty():
			notes = "manual_range_edit=true"
		else:
			notes = "%s; manual_range_edit=true" % notes
	return build_animation_entry(
		String(entry.get("animation_name", "candidate_001")),
		frames,
		float(entry.get("fps", 10.0)),
		bool(entry.get("loop", true)),
		status,
		notes,
		columns
	)


static func frames_from_entry(entry: Dictionary) -> PackedInt32Array:
	var raw: Array = entry.get("frames", [])
	if not raw.is_empty():
		var out := PackedInt32Array()
		for v in raw:
			out.append(int(v))
		return out
	var start_f := int(entry.get("start_frame", 0))
	var end_f := int(entry.get("end_frame", start_f))
	var expanded := PackedInt32Array()
	for i: int in range(start_f, end_f + 1):
		expanded.append(i)
	return expanded


static func candidate_map_path_for_sheet(sheet_path: String) -> String:
	var base := sheet_path.get_file().get_basename()
	if base.is_empty():
		base = "sheet"
	return "res://resources/character_animation_maps/%s_candidate_ranges_v1.json" % base


static func build_candidate_map_dict(
	source_sheet: String,
	frame_width: int,
	frame_height: int,
	columns: int,
	rows: int,
	candidates: Array
) -> Dictionary:
	var anims: Array = []
	for c in candidates:
		if c is Dictionary:
			var copy: Dictionary = c.duplicate(true)
			copy["review_status"] = String(copy.get("review_status", "needs_review"))
			if copy["review_status"] == "reviewed":
				copy["review_status"] = "needs_review"
			anims.append(copy)
	return {
		"schema_version": 1,
		"tool": "CharacterAnimationMapperDock",
		"map_kind": "review_candidates",
		"source_sheet": source_sheet,
		"frame_width": frame_width,
		"frame_height": frame_height,
		"columns": columns,
		"rows": rows,
		"animations": anims,
	}


static func finalize_candidate_entries(candidates: Array, columns: int) -> Array:
	var out: Array = []
	for raw in candidates:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var c: Dictionary = raw.duplicate(true)
		var frames := frames_from_entry(c)
		if frames.is_empty():
			continue
		var fps := float(c.get("fps", 10.0))
		var loop := bool(c.get("loop", true))
		var status := String(c.get("review_status", "needs_review"))
		if status == "reviewed":
			status = "needs_review"
		var entry := build_animation_entry(
			String(c.get("animation_name", "candidate_001")),
			frames,
			fps,
			loop,
			status,
			String(c.get("notes", "")),
			columns
		)
		if not entry.is_empty():
			out.append(entry)
	return out


const DIRECTIONS: Array[String] = [
	"toward", "toward_right", "right", "away_right", "away", "away_left", "left", "toward_left",
]

const ACTIONS: Array[String] = [
	"idle", "walk", "run", "sneak", "attack", "interact", "use", "pickup", "hurt", "death", "sleep", "sit", "custom",
]

const COMMON_ANIMATION_NAME_STEMS: Array[String] = [
	"idle", "walk", "run", "sprint", "jump", "fall", "land", "crouch", "crouch_walk", "sneak",
	"turn", "strafe_left", "strafe_right", "backpedal", "dodge", "roll", "dash", "climb", "ladder_climb", "swim",
	"attack_light", "attack_heavy", "combo_attack", "block", "parry", "hit_react", "stagger", "knockback", "death", "revive",
	"interact", "use_item", "pickup", "throw", "aim", "shoot", "reload", "cast_spell", "equip_weapon", "unequip_weapon",
	"draw_weapon", "holster_weapon", "sit", "sleep", "talk", "gesture", "emote", "open_door", "open_chest", "push_pull",
	"carry_object", "victory", "injured_idle", "injured_walk", "injured_run", "exhausted_idle", "look_around", "alert_idle", "combat_idle", "ready_stance",
	"aim_idle", "aim_walk", "aim_strafe_left", "aim_strafe_right", "aim_recoil", "melee_windup", "melee_recovery", "charge_attack", "ground_slam", "kick",
	"punch", "grapple", "grab", "escape_grab", "push_button", "pull_lever", "open_container", "close_container", "loot", "eat",
	"drink", "heal", "craft", "build", "repair", "mine", "chop", "dig", "fish", "row_paddle",
	"mount", "dismount", "ride_idle", "ride_walk", "ride_run", "slide", "wall_slide", "wall_jump", "ledge_grab", "ledge_climb",
]

const PVGAMES_8DIR_ORDER := (
	"PVGames 8-dir order candidate: toward, toward_right, right, away_right, away, away_left, left, toward_left"
)


static func filter_common_animation_names(query: String, max_results: int = 100) -> Array[String]:
	var q := query.strip_edges().to_lower()
	var out: Array[String] = []
	for name: String in COMMON_ANIMATION_NAME_STEMS:
		if q.is_empty() or name.to_lower().contains(q):
			out.append(name)
			if out.size() >= max_results:
				break
	return out


static func action_defaults(action: String) -> Dictionary:
	match action:
		"idle":
			return {"fps": 6.0, "loop": true}
		"walk":
			return {"fps": 10.0, "loop": true}
		"run":
			return {"fps": 12.0, "loop": true}
		"sneak":
			return {"fps": 8.0, "loop": true}
		"attack":
			return {"fps": 12.0, "loop": false}
		"interact", "use", "pickup":
			return {"fps": 10.0, "loop": false}
		"hurt", "death":
			return {"fps": 8.0, "loop": false}
		"sleep", "sit":
			return {"fps": 6.0, "loop": true}
		_:
			return {"fps": 10.0, "loop": true}


static func build_structured_name(action: String, direction: String, variant: int, custom_stem: String = "") -> String:
	var stem := action
	if action == "custom":
		stem = custom_stem.strip_edges()
	if stem.is_empty() or direction.is_empty():
		return ""
	var variant_text := "%02d" % clampi(variant, 1, 99)
	return "%s_%s_%s" % [stem, direction, variant_text]


static func format_animation_list_label(entry: Dictionary) -> String:
	var name: String = String(entry.get("animation_name", "?"))
	var status: String = String(entry.get("review_status", "?"))
	return "%s [%d..%d] %s fps=%.1f loop=%s" % [
		name,
		int(entry.get("start_frame", 0)),
		int(entry.get("end_frame", 0)),
		status,
		float(entry.get("fps", 10.0)),
		str(entry.get("loop", true)),
	]


static func parse_structured_animation_name(animation_name: String) -> Dictionary:
	var name := animation_name.strip_edges()
	if name.is_empty():
		return {}
	var last_us := name.rfind("_")
	if last_us < 0:
		return {}
	var variant_text := name.substr(last_us + 1)
	if variant_text.is_empty() or not variant_text.is_valid_int():
		return {}
	var variant := int(variant_text)
	var remainder := name.substr(0, last_us)
	if remainder.is_empty():
		return {}
	var directions_sorted: Array[String] = []
	directions_sorted.assign(DIRECTIONS)
	directions_sorted.sort_custom(func(a: String, b: String) -> bool: return a.length() > b.length())
	for dir: String in directions_sorted:
		var suffix := "_" + dir
		if not remainder.ends_with(suffix):
			continue
		var action_stem := remainder.substr(0, remainder.length() - suffix.length())
		if action_stem.is_empty():
			continue
		var action := "custom"
		var custom_stem := ""
		if action_stem in ACTIONS:
			action = action_stem
		else:
			custom_stem = action_stem
		return {
			"action": action,
			"direction": dir,
			"variant": variant,
			"action_stem": action_stem,
			"custom_stem": custom_stem,
		}
	return {}


static func highest_variant_for_action_stem(animations: Array, action_stem: String) -> int:
	var stem_l := action_stem.strip_edges()
	if stem_l.is_empty():
		return 0
	var highest := 0
	for raw in animations:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var e: Dictionary = raw
		var parsed := parse_structured_animation_name(String(e.get("animation_name", "")))
		if parsed.is_empty():
			continue
		if String(parsed.get("action_stem", "")) == stem_l:
			highest = maxi(highest, int(parsed.get("variant", 0)))
	return highest


static func highest_variant_for_action_direction(
	animations: Array, action_stem: String, direction: String
) -> int:
	var stem_l := action_stem.strip_edges()
	var dir_l := direction.strip_edges()
	if stem_l.is_empty() or dir_l.is_empty():
		return 0
	var highest := 0
	for raw in animations:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var e: Dictionary = raw
		var parsed := parse_structured_animation_name(String(e.get("animation_name", "")))
		if parsed.is_empty():
			continue
		if String(parsed.get("action_stem", "")) == stem_l and String(parsed.get("direction", "")) == dir_l:
			highest = maxi(highest, int(parsed.get("variant", 0)))
	return highest


static func next_variant_for_action_stem(animations: Array, action_stem: String) -> int:
	var highest := highest_variant_for_action_stem(animations, action_stem)
	return highest + 1 if highest > 0 else 1


static func next_variant_for_action_direction(
	animations: Array, action_stem: String, direction: String
) -> int:
	var highest := highest_variant_for_action_direction(animations, action_stem, direction)
	return highest + 1 if highest > 0 else 1


static func candidate_detail_text(entry: Dictionary, columns: int) -> String:
	if entry.is_empty():
		return "No candidate loaded."
	var frames := frames_from_entry(entry)
	if frames.is_empty():
		return "Candidate has no frames."
	var sorted := sorted_frames_array(frames)
	var ranges: Array = entry.get("row_column_ranges", [])
	var rc_text := ""
	if not ranges.is_empty():
		var r: Dictionary = ranges[0]
		rc_text = " row/col %d,%d -> %d,%d" % [
			int(r.get("start_row", 0)), int(r.get("start_column", 0)),
			int(r.get("end_row", 0)), int(r.get("end_column", 0)),
		]
	return "frames %d..%d (%d)%s | status %s | %s" % [
		sorted[0],
		sorted[sorted.size() - 1],
		sorted.size(),
		rc_text,
		String(entry.get("review_status", "?")),
		String(entry.get("notes", "")),
	]


static func validate_candidate_map_schema(data: Dictionary, expected_sheet: String = "") -> Array[String]:
	var failures: Array[String] = []
	if int(data.get("frame_width", 0)) != 200:
		failures.append("frame_width must be 200")
	if int(data.get("frame_height", 0)) != 200:
		failures.append("frame_height must be 200")
	if int(data.get("columns", 0)) != 50:
		failures.append("columns must be 50")
	if int(data.get("rows", 0)) != 50:
		failures.append("rows must be 50")
	if not expected_sheet.is_empty() and String(data.get("source_sheet", "")) != expected_sheet:
		failures.append("source_sheet mismatch")
	var sheet_path := String(data.get("source_sheet", ""))
	if not sheet_path.is_empty() and not ResourceLoader.exists(sheet_path):
		failures.append("source_sheet missing: %s" % sheet_path)
	var max_frame := int(data.get("columns", 50)) * int(data.get("rows", 50)) - 1
	for raw in data.get("animations", []):
		if typeof(raw) != TYPE_DICTIONARY:
			failures.append("animation entry not a dictionary")
			continue
		var e: Dictionary = raw
		if String(e.get("review_status", "")) == "reviewed":
			failures.append("candidate must not be reviewed: %s" % e.get("animation_name", "?"))
		var start_f := int(e.get("start_frame", -1))
		var end_f := int(e.get("end_frame", -1))
		if start_f > end_f:
			failures.append("start_frame > end_frame for %s" % e.get("animation_name", "?"))
		for g in e.get("frames", []):
			var gi := int(g)
			if gi < 0 or gi > max_frame:
				failures.append("frame %d out of range for %s" % [gi, e.get("animation_name", "?")])
	return failures


static func build_occupied_frame_set(animations: Array) -> Dictionary:
	var occupied := {}
	for raw in animations:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		for g: int in frames_from_entry(raw):
			occupied[g] = true
	return occupied


static func build_unassigned_frame_ranges(animations: Array, columns: int, total_frames: int) -> Array:
	if columns <= 0 or total_frames <= 0:
		return []
	var occupied := build_occupied_frame_set(animations)
	var ranges: Array = []
	var start_g := -1
	for i: int in range(total_frames):
		if not occupied.has(i):
			if start_g < 0:
				start_g = i
		elif start_g >= 0:
			ranges.append(_unassigned_range_dict(start_g, i - 1, columns))
			start_g = -1
	if start_g >= 0:
		ranges.append(_unassigned_range_dict(start_g, total_frames - 1, columns))
	return ranges


static func _unassigned_range_dict(start_g: int, end_g: int, columns: int) -> Dictionary:
	var sr := start_g / columns
	var sc := start_g % columns
	var er := end_g / columns
	var ec := end_g % columns
	return {
		"start_frame": start_g,
		"end_frame": end_g,
		"frame_count": end_g - start_g + 1,
		"start_row": sr,
		"start_column": sc,
		"end_row": er,
		"end_column": ec,
	}


static func build_duplicate_frame_warnings(animations: Array) -> Array:
	var frame_to_names := {}
	for raw in animations:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var e: Dictionary = raw
		var anim_name := String(e.get("animation_name", "?"))
		for g: int in frames_from_entry(e):
			if not frame_to_names.has(g):
				frame_to_names[g] = []
			var names: Array = frame_to_names[g]
			if anim_name not in names:
				names.append(anim_name)
	var warnings: Array = []
	var dup_frames: Array = []
	for g in frame_to_names.keys():
		var names: Array = frame_to_names[g]
		if names.size() > 1:
			dup_frames.append(int(g))
	dup_frames.sort()
	if dup_frames.is_empty():
		return warnings
	var run_start: int = dup_frames[0]
	var run_end: int = dup_frames[0]
	var run_names: Dictionary = {}
	for n: String in frame_to_names[run_start]:
		run_names[n] = true
	for i: int in range(1, dup_frames.size()):
		var g: int = dup_frames[i]
		if g == run_end + 1:
			run_end = g
			for n: String in frame_to_names[g]:
				run_names[n] = true
		else:
			warnings.append(_duplicate_warning_dict(run_start, run_end, run_names.keys()))
			run_start = g
			run_end = g
			run_names.clear()
			for n: String in frame_to_names[g]:
				run_names[n] = true
	warnings.append(_duplicate_warning_dict(run_start, run_end, run_names.keys()))
	return warnings


static func _duplicate_warning_dict(start_g: int, end_g: int, animation_names: Array) -> Dictionary:
	var names_sorted: Array = animation_names.duplicate()
	names_sorted.sort()
	return {
		"issue_type": "duplicate_frame",
		"title": "Duplicate frame use: %d..%d" % [start_g, end_g],
		"start_frame": start_g,
		"end_frame": end_g,
		"frames": _frame_array_from_range(start_g, end_g),
		"animations": names_sorted,
		"note": "Same frame(s) assigned to multiple animations.",
	}


static func _frame_array_from_range(start_g: int, end_g: int) -> Array:
	var out: Array = []
	for i: int in range(start_g, end_g + 1):
		out.append(i)
	return out


static func build_known_needs_visual_review_items() -> Array:
	return [
		{
			"issue_type": "incomplete_direction_group",
			"title": "crouch_04 incomplete directions",
			"group": "crouch_04",
			"present_directions": ["toward", "right", "away_left", "left"],
			"missing_directions": ["toward_right", "away_right", "away", "toward_left"],
			"start_frame": 968,
			"end_frame": 979,
			"frames": _frame_array_from_range(968, 979),
			"note": "Structurally incomplete; visually inspect nearby unused frames 986..991.",
		},
		{
			"issue_type": "incomplete_direction_group",
			"title": "crouch_05 incomplete directions",
			"group": "crouch_05",
			"present_directions": ["toward", "away_left"],
			"missing_directions": ["toward_right", "right", "away_right", "away", "left", "toward_left"],
			"start_frame": 980,
			"end_frame": 985,
			"frames": _frame_array_from_range(980, 985),
			"note": "Only two directions mapped; visually inspect whether this is intentionally partial.",
		},
		{
			"issue_type": "naming_variant_mismatch",
			"title": "idle_11 / idle_12 variant suspicion",
			"group": "idle_11_idle_12",
			"start_frame": 896,
			"end_frame": 1167,
			"frames": _frame_array_from_range(896, 897) + _frame_array_from_range(1128, 1167),
			"note": "idle_toward_12 at 1128..1132 may belong with idle_*_11 at 1133..1167; idle_toward_11 at 896..897 overlaps dodge_toward_01.",
		},
	]


static func frames_from_qa_item(item: Dictionary) -> PackedInt32Array:
	if item.is_empty():
		return PackedInt32Array()
	var raw_frames: Array = item.get("frames", [])
	if not raw_frames.is_empty():
		var out := PackedInt32Array()
		for v in raw_frames:
			out.append(int(v))
		return sorted_frames_array(out)
	var start_f := int(item.get("start_frame", -1))
	var end_f := int(item.get("end_frame", start_f))
	if start_f >= 0 and end_f >= start_f:
		return expand_contiguous_range(start_f, end_f)
	return PackedInt32Array()


static func format_qa_item_list_label(item: Dictionary) -> String:
	var issue := String(item.get("issue_type", "review"))
	var title := String(item.get("title", issue))
	var start_f := int(item.get("start_frame", -1))
	var end_f := int(item.get("end_frame", start_f))
	if start_f >= 0:
		return "[%s] %s (%d..%d)" % [issue, title, start_f, end_f]
	return "[%s] %s" % [issue, title]


static func format_qa_item_detail(item: Dictionary) -> String:
	if item.is_empty():
		return "No review item selected."
	var lines: PackedStringArray = PackedStringArray()
	lines.append("Title: %s" % String(item.get("title", "?")))
	lines.append("Issue type: %s" % String(item.get("issue_type", "?")))
	var start_f := int(item.get("start_frame", -1))
	var end_f := int(item.get("end_frame", start_f))
	if start_f >= 0:
		lines.append("Frame range: %d..%d" % [start_f, end_f])
	var present: Array = item.get("present_directions", [])
	if not present.is_empty():
		lines.append("Present directions: %s" % ", ".join(present))
	var missing: Array = item.get("missing_directions", [])
	if not missing.is_empty():
		lines.append("Missing directions: %s" % ", ".join(missing))
	var anims: Array = item.get("animations", [])
	if not anims.is_empty():
		lines.append("Animations: %s" % ", ".join(anims))
	var note := String(item.get("note", ""))
	if not note.is_empty():
		lines.append("Note: %s" % note)
	return "\n".join(lines)


static func build_mapping_qa_review_items(animations: Array, columns: int, total_frames: int) -> Array:
	var items: Array = []
	for raw in build_known_needs_visual_review_items():
		items.append(raw.duplicate(true))
	for raw in build_duplicate_frame_warnings(animations):
		items.append(raw.duplicate(true))
	for raw in build_unassigned_frame_ranges(animations, columns, total_frames):
		var copy: Dictionary = raw.duplicate(true)
		copy["issue_type"] = "unassigned_frames"
		copy["title"] = "Unassigned: %d..%d (%d frames)" % [
			int(copy.get("start_frame", 0)),
			int(copy.get("end_frame", 0)),
			int(copy.get("frame_count", 0)),
		]
		copy["note"] = "Frames not assigned to any animation."
		copy["frames"] = _frame_array_from_range(
			int(copy.get("start_frame", 0)),
			int(copy.get("end_frame", 0))
		)
		items.append(copy)
	return items


static func format_unassigned_range_list_label(range: Dictionary) -> String:
	return "%d..%d | count=%d | row/col %d,%d -> %d,%d" % [
		int(range.get("start_frame", 0)),
		int(range.get("end_frame", 0)),
		int(range.get("frame_count", 0)),
		int(range.get("start_row", 0)),
		int(range.get("start_column", 0)),
		int(range.get("end_row", 0)),
		int(range.get("end_column", 0)),
	]
