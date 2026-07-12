@tool
class_name TileDataPromotionHelper
extends RefCounted

const TILE_SET_LINE := 'tile_set = ExtResource("3")'
const CANONICAL_TILE_SET_PATH := "res://assets/tilesets/iso_blockout_clean/IsoBlockoutTileset_Clean.tres"
const TILE_DATA_PREFIX := "tile_map_data = "
const KNOWN_UNRELATED_DEFAULTS: Array[String] = [
	'locked_prompt_text = "Task would look suspicious"',
	'shape_size = Vector2(112, 112)',
	'locked_prompt_text = "Disruption unavailable"',
]
const LAYERS: Array[Dictionary] = [
	{"name": "FloorLayer", "id": 2053303541},
	{"name": "WallLayer", "id": 1291381707},
	{"name": "CoverLayer", "id": 680121401},
	{"name": "CollisionBarrierLayer", "id": 898422279},
]
const MARKER_HEADER := '[node name="MarkerTileLayer" type="TileMapLayer" parent="GameplayRoot/LayoutRoot" unique_id=773819837]'


static func stage_files(baseline_path: String, candidate_path: String, staged_path: String) -> Dictionary:
	var result: Dictionary = stage_bytes(FileAccess.get_file_as_bytes(baseline_path), FileAccess.get_file_as_bytes(candidate_path))
	result.baseline_path = baseline_path
	result.candidate_path = candidate_path
	result.staged_path = staged_path
	if not bool(result.get("ok", false)):
		return result
	var file: FileAccess = FileAccess.open(staged_path, FileAccess.WRITE)
	if file == null:
		result.ok = false
		result.errors.append("Could not open staged path for writing.")
		return result
	file.store_buffer(result.staged_bytes)
	file.close()
	result.staged_sha256 = FileAccess.get_sha256(staged_path)
	return result


static func stage_bytes(baseline_bytes: PackedByteArray, candidate_bytes: PackedByteArray) -> Dictionary:
	var result: Dictionary = {"ok": false, "errors": [], "inserted_spans": [], "payloads": {}, "staged_bytes": PackedByteArray()}
	if baseline_bytes.is_empty() or candidate_bytes.is_empty():
		result.errors.append("Baseline and candidate bytes must be nonempty.")
		return result
	var baseline: String = baseline_bytes.get_string_from_utf8()
	var candidate: String = candidate_bytes.get_string_from_utf8()
	if baseline.to_utf8_buffer() != baseline_bytes or candidate.to_utf8_buffer() != candidate_bytes:
		result.errors.append("TSCN inputs must be valid byte-stable UTF-8.")
		return result
	var newline: String = _newline_for(baseline)
	if newline == "" or not _has_consistent_newlines(baseline, newline):
		result.errors.append("Baseline must use LF or CRLF newlines consistently.")
		return result
	var insertions: Array[Dictionary] = []
	for spec: Dictionary in LAYERS:
		var header: String = _header(String(spec.name), int(spec.id))
		var baseline_block: Dictionary = _exact_block(baseline, header)
		var candidate_block: Dictionary = _exact_block(candidate, header)
		if not bool(baseline_block.ok) or not bool(candidate_block.ok):
			result.errors.append_array(baseline_block.errors)
			result.errors.append_array(candidate_block.errors)
			continue
		var baseline_text: String = baseline_block.text
		var candidate_text: String = candidate_block.text
		if baseline_text.contains(TILE_DATA_PREFIX):
			result.errors.append("Baseline %s already contains tile_map_data." % spec.name)
			continue
		if _line_count(baseline_text, TILE_SET_LINE) != 1:
			result.errors.append("Baseline %s must contain exactly one approved tile_set line." % spec.name)
			continue
		if not _candidate_tile_set_is_canonical(candidate, candidate_text):
			result.errors.append("Candidate %s must reference the canonical TileSet exactly once." % spec.name)
			continue
		var payload_result: Dictionary = _extract_payload(candidate_text, String(spec.name))
		if not bool(payload_result.ok):
			result.errors.append_array(payload_result.errors)
			continue
		var tile_set_offset: int = baseline.find(TILE_SET_LINE, int(baseline_block.start))
		if tile_set_offset < int(baseline_block.start) or tile_set_offset >= int(baseline_block.end):
			result.errors.append("Could not locate insertion point for %s." % spec.name)
			continue
		var payload: String = payload_result.payload
		insertions.append({"offset": tile_set_offset, "text": payload + newline, "layer": String(spec.name)})
		result.payloads[String(spec.name)] = payload
	var marker_baseline: Dictionary = _exact_block(baseline, MARKER_HEADER)
	var marker_candidate: Dictionary = _exact_block(candidate, MARKER_HEADER)
	if not bool(marker_baseline.ok) or not bool(marker_candidate.ok):
		result.errors.append_array(marker_baseline.errors)
		result.errors.append_array(marker_candidate.errors)
	elif String(marker_baseline.text).contains(TILE_DATA_PREFIX) or String(marker_candidate.text).contains(TILE_DATA_PREFIX):
		result.errors.append("MarkerTileLayer must not contain tile_map_data.")
	if not result.errors.is_empty() or insertions.size() != 4:
		return result
	insertions.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.offset) < int(b.offset))
	var staged: String = ""
	var baseline_cursor: int = 0
	var staged_cursor: int = 0
	for insertion: Dictionary in insertions:
		var offset: int = int(insertion.offset)
		var unchanged: String = baseline.substr(baseline_cursor, offset - baseline_cursor)
		staged += unchanged
		staged_cursor += unchanged.length()
		var inserted: String = String(insertion.text)
		result.inserted_spans.append({"offset": staged_cursor, "length": inserted.length(), "layer": insertion.layer})
		staged += inserted
		staged_cursor += inserted.length()
		baseline_cursor = offset
	staged += baseline.substr(baseline_cursor)
	var staged_bytes: PackedByteArray = staged.to_utf8_buffer()
	var inserted_size: int = 0
	for span: Dictionary in result.inserted_spans:
		inserted_size += int(span.length)
	if staged_bytes.size() != baseline_bytes.size() + inserted_size:
		result.errors.append("Staged size formula failed.")
	if remove_spans(staged_bytes, result.inserted_spans) != baseline_bytes:
		result.errors.append("Removing inserted spans did not reconstruct baseline bytes.")
	if _count_occurrences(staged, TILE_DATA_PREFIX) - _count_occurrences(baseline, TILE_DATA_PREFIX) != 4:
		result.errors.append("Staged text did not add exactly four tile_map_data properties.")
	for forbidden: String in KNOWN_UNRELATED_DEFAULTS:
		if staged.contains(forbidden):
			result.errors.append("Staged text contains unrelated default: %s" % forbidden)
	result.staged_bytes = staged_bytes
	result.baseline_size = baseline_bytes.size()
	result.inserted_size = inserted_size
	result.staged_size = staged_bytes.size()
	result.reconstruction_sha256 = _sha256_bytes(remove_spans(staged_bytes, result.inserted_spans))
	result.ok = result.errors.is_empty()
	return result


static func remove_spans(staged_bytes: PackedByteArray, spans: Array) -> PackedByteArray:
	var text: String = staged_bytes.get_string_from_utf8()
	var ordered: Array = spans.duplicate(true)
	ordered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.offset) > int(b.offset))
	for span: Dictionary in ordered:
		var offset: int = int(span.offset)
		var length: int = int(span.length)
		if offset < 0 or length <= 0 or offset + length > text.length():
			return PackedByteArray()
		text = text.erase(offset, length)
	return text.to_utf8_buffer()


static func _extract_payload(block: String, layer_name: String) -> Dictionary:
	var matches: Array[String] = []
	for raw_line: String in block.replace("\r\n", "\n").split("\n"):
		if raw_line.begins_with(TILE_DATA_PREFIX):
			matches.append(raw_line)
	if matches.size() != 1:
		return {"ok": false, "errors": ["Candidate %s must contain exactly one tile_map_data assignment." % layer_name]}
	var payload: String = matches[0]
	var regex: RegEx = RegEx.new()
	regex.compile('^tile_map_data = PackedByteArray\\("[A-Za-z0-9+/=]+"\\)$')
	if regex.search(payload) == null:
		return {"ok": false, "errors": ["Candidate %s tile_map_data is empty, malformed, or multiline." % layer_name]}
	return {"ok": true, "errors": [], "payload": payload}


static func _candidate_tile_set_is_canonical(candidate: String, block: String) -> bool:
	var regex: RegEx = RegEx.new()
	regex.compile('(?m)^tile_set = ExtResource\\("([^"]+)"\\)$')
	var matches: Array[RegExMatch] = regex.search_all(block.replace("\r\n", "\n"))
	if matches.size() != 1:
		return false
	var resource_id: String = matches[0].get_string(1)
	var declaration: String = '[ext_resource type="TileSet" path="%s" id="%s"]' % [CANONICAL_TILE_SET_PATH, resource_id]
	return _line_count(candidate, declaration) == 1


static func _exact_block(text: String, header: String) -> Dictionary:
	var positions: Array[int] = []
	var search_from: int = 0
	while true:
		var position: int = text.find(header, search_from)
		if position < 0:
			break
		var line_start: bool = position == 0 or text.unicode_at(position - 1) == 10
		var after: int = position + header.length()
		var line_end: bool = after == text.length() or text.unicode_at(after) == 10 or text.unicode_at(after) == 13
		if line_start and line_end:
			positions.append(position)
		search_from = position + header.length()
	if positions.size() != 1:
		return {"ok": false, "errors": ["Expected exactly one exact node block: %s" % header], "text": "", "start": -1, "end": -1}
	var start: int = positions[0]
	var next_node: int = text.find("\n[node ", start + header.length())
	var end: int = text.length() if next_node < 0 else next_node + 1
	return {"ok": true, "errors": [], "text": text.substr(start, end - start), "start": start, "end": end}


static func _header(name: String, unique_id: int) -> String:
	return '[node name="%s" type="TileMapLayer" parent="GameplayRoot/LayoutRoot" unique_id=%d]' % [name, unique_id]


static func _newline_for(text: String) -> String:
	var index: int = text.find("\n")
	if index < 0:
		return ""
	return "\r\n" if index > 0 and text.unicode_at(index - 1) == 13 else "\n"


static func _has_consistent_newlines(text: String, newline: String) -> bool:
	var normalized: String = text.replace("\r\n", "") if newline == "\r\n" else text
	return not normalized.contains("\n") if newline == "\r\n" else not text.contains("\r")


static func _line_count(block: String, wanted: String) -> int:
	var count: int = 0
	for line: String in block.replace("\r\n", "\n").split("\n"):
		if line == wanted:
			count += 1
	return count


static func _count_occurrences(text: String, needle: String) -> int:
	var count: int = 0
	var offset: int = 0
	while true:
		offset = text.find(needle, offset)
		if offset < 0:
			return count
		count += 1
		offset += needle.length()
	return count


static func _sha256_bytes(bytes: PackedByteArray) -> String:
	var context: HashingContext = HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()
