extends Node2D
## Validation-only SpriteFrames preview for Manual Animation Mapper reviewed maps.
## Not referenced by player, Taco, MainMenu, or autoloads.

const SAFE_MAX_BYTES := 100 * 1024 * 1024
const LEGACY_HUGE_PARMIDA := (
	"res://resources/character_animation_maps/generated_preview/parmida_manual_preview_spriteframes.tres"
)
const DEFAULT_SPRITEFRAMES := (
	"res://resources/character_animation_maps/generated_preview/character_02_neon_runner_preview_spriteframes.tres"
)

const PREVIEW_OPTIONS: Array[Dictionary] = [
	{
		"label": "Parmida (character 01)",
		"path": (
			"res://resources/character_animation_maps/generated_preview/"
			+ "character_01_parmida_reference_variant_preview_spriteframes.tres"
		),
	},
	{
		"label": "Neon runner (character 02)",
		"path": "res://resources/character_animation_maps/generated_preview/character_02_neon_runner_preview_spriteframes.tres",
	},
	{
		"label": "Cyber tech (character 03)",
		"path": "res://resources/character_animation_maps/generated_preview/character_03_cyber_tech_preview_spriteframes.tres",
	},
	{
		"label": "Street bruiser (character 04)",
		"path": "res://resources/character_animation_maps/generated_preview/character_04_street_bruiser_preview_spriteframes.tres",
	},
	{
		"label": "Nocturne guard (character 05)",
		"path": "res://resources/character_animation_maps/generated_preview/character_05_nocturne_guard_preview_spriteframes.tres",
	},
	{
		"label": "Parmida LEGACY (embedded, unsafe)",
		"path": LEGACY_HUGE_PARMIDA,
		"unsafe_legacy": true,
	},
]

@export var spriteframes_path: String = DEFAULT_SPRITEFRAMES
@export var auto_play: bool = false

@onready var _animated: AnimatedSprite2D = $PreviewColumn/AnimatedSprite2D
@onready var _path_label: Label = $UI/PathLabel
@onready var _preview_option: OptionButton = $UI/PreviewRow/PreviewOptionButton
@onready var _load_preview_btn: Button = $UI/PreviewRow/LoadPreviewButton
@onready var _status_label: Label = $UI/StatusLabel
@onready var _anim_option: OptionButton = $UI/AnimRow/AnimOptionButton
@onready var _info_label: Label = $UI/InfoLabel
@onready var _play_btn: Button = $UI/AnimRow/PlayButton
@onready var _stop_btn: Button = $UI/AnimRow/StopButton

var _spriteframes: SpriteFrames
var _load_error: String = ""
var _current_anim: String = ""
var _loaded_path: String = ""


func _ready() -> void:
	_play_btn.pressed.connect(_on_play)
	_stop_btn.pressed.connect(_on_stop)
	_anim_option.item_selected.connect(_on_anim_selected)
	if _load_preview_btn != null:
		_load_preview_btn.pressed.connect(_on_load_preview_pressed)
	if _preview_option != null:
		_preview_option.item_selected.connect(_on_preview_selected)
		_populate_preview_options()
	call_deferred("_bootstrap")


func _populate_preview_options() -> void:
	if _preview_option == null:
		return
	_preview_option.clear()
	var selected_index := 1
	for i: int in range(PREVIEW_OPTIONS.size()):
		var item: Dictionary = PREVIEW_OPTIONS[i]
		_preview_option.add_item(String(item.get("label", "Preview %d" % i)))
		if String(item.get("path", "")) == spriteframes_path:
			selected_index = i
	if _preview_option.item_count > 0:
		_preview_option.select(selected_index)
		_set_selected_preview_path(selected_index)


func _on_preview_selected(index: int) -> void:
	_set_selected_preview_path(index)


func _set_selected_preview_path(index: int) -> void:
	if index < 0 or index >= PREVIEW_OPTIONS.size():
		return
	spriteframes_path = String(PREVIEW_OPTIONS[index].get("path", DEFAULT_SPRITEFRAMES))
	_on_stop()
	_clear_loaded_preview()
	_refresh_pending_state()


func _bootstrap() -> void:
	_clear_loaded_preview()
	_refresh_pending_state()


func _clear_loaded_preview() -> void:
	_spriteframes = null
	_loaded_path = ""
	_load_error = ""
	_anim_option.clear()
	_animated.sprite_frames = null
	_animated.stop()
	_current_anim = ""


func _refresh_pending_state() -> void:
	var size_report := _spriteframes_file_size_report(spriteframes_path)
	var size_text := ""
	if size_report.get("ok", false):
		size_text = " | file size: %.2f MB" % float(size_report.get("size_mb", 0.0))
	_path_label.text = "Selected preview: %s%s (not loaded)" % [spriteframes_path, size_text]
	if _preview_option != null and _preview_option.selected >= 0 and _preview_option.selected < PREVIEW_OPTIONS.size():
		if bool(PREVIEW_OPTIONS[_preview_option.selected].get("unsafe_legacy", false)):
			_status_label.text = (
				"Legacy Parmida preview uses embedded textures (~1.1 GB). "
				+ "Use the small Parmida option or click Load Preview only if regenerated safely."
			)
		else:
			_status_label.text = "Validation sandbox — select a character, then click Load Preview."
	else:
		_status_label.text = "Validation sandbox — select a character, then click Load Preview."
	_info_label.text = "No SpriteFrames loaded. Click Load Preview to populate animations."


func _on_load_preview_pressed() -> void:
	_load_spriteframes()
	_populate_animations()
	_refresh_labels()
	if _spriteframes != null and auto_play and _anim_option.item_count > 0:
		_on_play()


func _spriteframes_file_size_bytes(path: String) -> int:
	if path.is_empty() or not path.begins_with("res://"):
		return -1
	var global_path := ProjectSettings.globalize_path(path)
	if not FileAccess.file_exists(global_path):
		return -1
	var file := FileAccess.open(global_path, FileAccess.READ)
	if file == null:
		return -1
	var size := file.get_length()
	file.close()
	return int(size)


func _spriteframes_file_size_report(path: String) -> Dictionary:
	var size_bytes := _spriteframes_file_size_bytes(path)
	if size_bytes < 0:
		return {"ok": false, "size_bytes": size_bytes, "size_mb": 0.0}
	return {
		"ok": true,
		"size_bytes": size_bytes,
		"size_mb": float(size_bytes) / (1024.0 * 1024.0),
	}


func _load_spriteframes() -> void:
	_spriteframes = null
	_load_error = ""
	_loaded_path = ""
	var size_report := _spriteframes_file_size_report(spriteframes_path)
	if spriteframes_path.is_empty() or not spriteframes_path.begins_with("res://"):
		_load_error = "Invalid path (must be res://)."
		_path_label.text = "SpriteFrames: %s" % spriteframes_path
		return
	if not ResourceLoader.exists(spriteframes_path):
		_load_error = "SpriteFrames not found. Generate validation preview first."
		_path_label.text = "SpriteFrames: %s" % spriteframes_path
		return
	if size_report.get("ok", false):
		var size_bytes: int = int(size_report.get("size_bytes", 0))
		if size_bytes > SAFE_MAX_BYTES:
			var size_mb := float(size_report.get("size_mb", 0.0))
			_load_error = (
				"Preview SpriteFrames is very large (%.0f MB). "
				% size_mb
				+ "Regenerate with external texture refs before loading."
			)
			_path_label.text = "SpriteFrames blocked: %s" % spriteframes_path
			return
	_path_label.text = "SpriteFrames: %s" % spriteframes_path
	var res: Resource = load(spriteframes_path)
	if res == null:
		_load_error = "Failed to load resource."
		return
	if not res is SpriteFrames:
		_load_error = "Resource is not SpriteFrames."
		return
	_spriteframes = res as SpriteFrames
	_loaded_path = spriteframes_path


func _populate_animations() -> void:
	_anim_option.clear()
	if _spriteframes == null:
		return
	var names: PackedStringArray = _spriteframes.get_animation_names()
	var usable: Array[String] = []
	for nm in names:
		if nm == "default":
			continue
		if _spriteframes.get_frame_count(nm) <= 0:
			continue
		usable.append(nm)
	usable.sort()
	for nm in usable:
		_anim_option.add_item(nm)
	if usable.is_empty():
		for nm in names:
			if _spriteframes.get_frame_count(nm) > 0:
				_anim_option.add_item(nm)


func _refresh_labels() -> void:
	if not _load_error.is_empty():
		_status_label.text = "WARNING: %s" % _load_error
		_info_label.text = "No preview available."
		_animated.sprite_frames = null
		_animated.stop()
		return
	if _spriteframes == null:
		_refresh_pending_state()
		return
	_status_label.text = "Validation sandbox — not for production."
	if _loaded_path != spriteframes_path:
		_info_label.text = "Loaded preview is stale. Click Load Preview again."
		return
	var anim := _current_anim
	if anim.is_empty() and _anim_option.item_count > 0:
		anim = _anim_option.get_item_text(0)
	if anim.is_empty():
		_info_label.text = "No animations with frames."
		return
	var fc := _spriteframes.get_frame_count(anim)
	var fps := _spriteframes.get_animation_speed(anim)
	var looping := _spriteframes.get_animation_loop(anim)
	_info_label.text = "Animation: %s | frames: %d | fps: %.1f | loop: %s | playing: %s" % [
		anim, fc, fps, str(looping), str(_animated.is_playing())
	]


func _on_anim_selected(_index: int) -> void:
	_current_anim = _anim_option.get_item_text(_anim_option.selected)
	_apply_animation(false)


func _on_play() -> void:
	_apply_animation(true)


func _on_stop() -> void:
	_animated.stop()
	_refresh_labels()


func _apply_animation(play: bool) -> void:
	if _spriteframes == null:
		_status_label.text = "Load a preview first."
		return
	if _anim_option.item_count == 0:
		return
	_current_anim = _anim_option.get_item_text(_anim_option.selected)
	if not _spriteframes.has_animation(_current_anim):
		_status_label.text = "Missing animation: %s" % _current_anim
		return
	if _spriteframes.get_frame_count(_current_anim) <= 0:
		_status_label.text = "Animation '%s' has zero frames." % _current_anim
		return
	_animated.sprite_frames = _spriteframes
	_animated.animation = _current_anim
	if play:
		_animated.play(_current_anim)
	else:
		_animated.stop()
		_animated.frame = 0
	_refresh_labels()
