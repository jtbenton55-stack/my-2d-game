extends RefCounted
class_name DialoguePortraitRegistry

## Portrait registry for the hideout dialogue UI.
##
## Loads `res://data/dialogue/dialogue_portraits.json` once and exposes a small
## API for looking up a Texture2D by speaker_id. Both `parmida` and `mere`
## map to the same portrait by design - the project treats them as the same
## character.
##
## Missing portraits never crash. Unknown speakers fall back to the silhouette
## portrait, and even the silhouette is allowed to be missing on disk - in
## that case the API returns null and prints one warning per missing id.

const DATA_PATH := "res://data/dialogue/dialogue_portraits.json"
const FALLBACK_KEY := "fallback"

static var _entries: Dictionary = {}
static var _texture_cache: Dictionary = {}
static var _warned: Dictionary = {}
static var _loaded := false

static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	var f := FileAccess.open(DATA_PATH, FileAccess.READ)
	if f == null:
		push_warning("DialoguePortraitRegistry: missing %s - registry will be empty." % DATA_PATH)
		return
	var raw := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(raw)
	if not (parsed is Dictionary):
		push_warning("DialoguePortraitRegistry: %s did not parse to a Dictionary." % DATA_PATH)
		return
	var portraits: Variant = (parsed as Dictionary).get("portraits", {})
	if portraits is Dictionary:
		for key in (portraits as Dictionary).keys():
			var entry_variant: Variant = (portraits as Dictionary)[key]
			if entry_variant is Dictionary:
				var entry := entry_variant as Dictionary
				_entries[String(key).to_lower()] = entry
				var portrait_id := String(entry.get("portrait_id", "")).strip_edges().to_lower()
				if portrait_id != "":
					_entries[portrait_id] = entry

static func _normalize(speaker_id: String) -> String:
	return speaker_id.strip_edges().to_lower()

static func has_portrait(speaker_id: String) -> bool:
	_ensure_loaded()
	return _entries.has(_normalize(speaker_id))

static func get_portrait_entry(speaker_id: String) -> Dictionary:
	_ensure_loaded()
	var key := _normalize(speaker_id)
	if _entries.has(key):
		return (_entries[key] as Dictionary).duplicate(true)
	if _entries.has(FALLBACK_KEY):
		return (_entries[FALLBACK_KEY] as Dictionary).duplicate(true)
	return {}

static func get_portrait_texture(speaker_id: String) -> Texture2D:
	_ensure_loaded()
	var key := _normalize(speaker_id)
	var texture := _try_load_for_key(key)
	if texture != null:
		return texture
	# Fallback - try the explicit fallback key.
	if key != FALLBACK_KEY:
		var fallback_texture := _try_load_for_key(FALLBACK_KEY)
		if fallback_texture != null:
			return fallback_texture
	return null

static func get_speaker_name(speaker_id: String, default: String = "") -> String:
	_ensure_loaded()
	var entry := get_portrait_entry(speaker_id)
	var name_value := String(entry.get("speaker_name", ""))
	if name_value != "":
		return name_value
	if default != "":
		return default
	return speaker_id.capitalize()

static func list_speaker_ids() -> Array:
	_ensure_loaded()
	return _entries.keys()

static func _try_load_for_key(key: String) -> Texture2D:
	if not _entries.has(key):
		return null
	if _texture_cache.has(key):
		return _texture_cache[key]
	var entry := _entries[key] as Dictionary
	var png_path := String(entry.get("png_path", ""))
	if png_path != "" and ResourceLoader.exists(png_path):
		var tex := load(png_path)
		if tex is Texture2D:
			_texture_cache[key] = tex
			return tex
	var atlas_path := String(entry.get("atlas_path", ""))
	if atlas_path != "" and ResourceLoader.exists(atlas_path):
		var atex := load(atlas_path)
		if atex is Texture2D:
			_texture_cache[key] = atex
			return atex
	if not _warned.has(key):
		_warned[key] = true
		push_warning("DialoguePortraitRegistry: portrait texture missing for '%s' (png=%s atlas=%s)" %
			[key, png_path, atlas_path])
	return null
