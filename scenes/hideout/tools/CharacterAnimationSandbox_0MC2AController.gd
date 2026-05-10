extends Node2D
## Sandbox-only: diagnostics for C2A animation preview (FIX3 primary).
## Does not touch production player or gameplay scripts.

const SPRITEFRAMES_FIX3 := "res://assets/characters/generated_player_visuals/c2a_animation/fix3_stable/parmida_player_spriteframes_0mc2a_fix3.tres"
const SPRITEFRAMES_FIX2 := "res://assets/characters/generated_player_visuals/c2a_animation/fix2_rebuilt/parmida_player_spriteframes_0mc2a_fix2.tres"
const SPRITEFRAMES_FIX1 := "res://assets/characters/generated_player_visuals/c2a_animation/parmida_player_spriteframes_0mc2a_fix1.tres"
const SPRITEFRAMES_LEGACY := "res://assets/characters/generated_player_visuals/c2a_animation/parmida_player_spriteframes_0mc2a.tres"
const META_FIX3 := "res://assets/characters/generated_player_visuals/c2a_animation/fix3_stable/parmida_player_animation_metadata_0mc2a_fix3.json"
const COMPOSITE_FIX1 := "res://assets/characters/generated_player_visuals/c2a_animation/parmida_player_composite_sheet_0mc2a.png"
const BAD_IDLE_SHEET := "res://docs/reports/character_animation_c2a/phase0mc2a_fix3_current_bad_idle_frames.png"
const BAD_WALK_SHEET := "res://docs/reports/character_animation_c2a/phase0mc2a_fix3_current_bad_walk_frames.png"
const FORENSIC_COMPARE := "res://docs/reports/character_animation_c2a/phase0mc2a_fix3_frame_size_forensic_comparison.png"
const STABLE_SHEET := "res://docs/reports/character_animation_c2a/phase0mc2a_fix3_stable_frames_contact_sheet.png"
const FALLBACK_FRAME := "res://assets/characters/generated_player_visuals/c2a_animation/fix3_stable/frames/idle_000.png"

@onready var _animated: AnimatedSprite2D = $AnimatedParmidaColumn/AnimatedParmidaReference
@onready var _fallback: Sprite2D = $AnimatedParmidaColumn/AnimatedParmidaFallbackFrame
@onready var _warn_panel: CanvasItem = $AnimatedParmidaColumn/FallbackWarningPanel
@onready var _warn_label: Label = $AnimatedParmidaColumn/FallbackWarningLabel
@onready var _debug: Label = $DebugPanel/DebugLabel
@onready var _prev_btn: Button = $FrameByFrameViewer/VBox/Row/PrevButton
@onready var _next_btn: Button = $FrameByFrameViewer/VBox/Row/NextButton
@onready var _frame_tex: TextureRect = $FrameByFrameViewer/VBox/Row/FrameTexture
@onready var _frame_info: Label = $FrameByFrameViewer/VBox/FrameInfo

var _status: String = "FAIL"
var _fallback_mode: bool = false
var _root_cause: String = "UNKNOWN"
var _spriteframes_path_used: String = ""
var _selected_animation: String = ""
var _idle_paths: Array[String] = []
var _frame_index: int = 0
var _frame_fw: int = 200
var _frame_fh: int = 200
var _walk_included: bool = false


func _ready() -> void:
	_prev_btn.pressed.connect(_on_prev_frame)
	_next_btn.pressed.connect(_on_next_frame)
	call_deferred("_run_diagnostics")


func _run_diagnostics() -> void:
	var lines: PackedStringArray = []
	var sf: SpriteFrames = null
	var load_path := ""

	if ResourceLoader.exists(SPRITEFRAMES_FIX3):
		load_path = SPRITEFRAMES_FIX3
		sf = load(SPRITEFRAMES_FIX3) as SpriteFrames
	if sf == null and ResourceLoader.exists(SPRITEFRAMES_FIX2):
		load_path = SPRITEFRAMES_FIX2
		sf = load(SPRITEFRAMES_FIX2) as SpriteFrames
	if sf == null and ResourceLoader.exists(SPRITEFRAMES_FIX1):
		load_path = SPRITEFRAMES_FIX1
		sf = load(SPRITEFRAMES_FIX1) as SpriteFrames
	if sf == null and ResourceLoader.exists(SPRITEFRAMES_LEGACY):
		load_path = SPRITEFRAMES_LEGACY
		sf = load(SPRITEFRAMES_LEGACY) as SpriteFrames

	_spriteframes_path_used = load_path
	_load_fix3_meta()

	var sf_ok := sf != null
	var anim_names: PackedStringArray = PackedStringArray()
	if sf_ok:
		anim_names = sf.get_animation_names()

	var path_exists := load_path != "" and ResourceLoader.exists(load_path)

	var chosen := _pick_animation(sf)
	_selected_animation = chosen

	var anim_exists := chosen != "" and sf_ok and sf.has_animation(chosen)
	var frames_ok := false
	var tex_ok := false
	if anim_exists:
		var n := sf.get_frame_count(chosen)
		frames_ok = n > 0
		if frames_ok:
			var t0 := sf.get_frame_texture(chosen, 0)
			tex_ok = t0 != null

	if not ResourceLoader.exists(COMPOSITE_FIX1):
		_root_cause = "C — RESOURCE_PATH_BROKEN (legacy composite missing)"
	elif not sf_ok:
		_root_cause = "C/D — SpriteFrames did not load"
	elif anim_names.is_empty():
		_root_cause = "D — SPRITEFRAMES_EMPTY"
	elif not anim_exists:
		_root_cause = "E — ANIMATION_NAME_MISMATCH"
	elif not frames_ok:
		_root_cause = "D — zero frames"
	elif not tex_ok:
		_root_cause = "F — TEXTURES_MISSING"
	else:
		_root_cause = "NONE (loaded)"

	_warn_panel.visible = false
	_warn_label.visible = false
	_fallback.visible = false
	_fallback_mode = false

	if sf_ok and anim_exists and frames_ok and tex_ok:
		_animated.sprite_frames = sf
		_animated.visible = true
		_animated.z_index = 4
		_animated.modulate = Color(1, 1, 1, 1)
		_animated.play(chosen)
		_status = "PARTIAL_PENDING_MANUAL_VISUAL"
	else:
		_animated.sprite_frames = null
		_animated.visible = false
		_fallback_mode = true
		_status = "PARTIAL" if ResourceLoader.exists(FALLBACK_FRAME) else "FAIL"
		_warn_panel.visible = true
		_warn_label.visible = true
		if ResourceLoader.exists(FALLBACK_FRAME):
			var ftex: Texture2D = load(FALLBACK_FRAME) as Texture2D
			_fallback.texture = ftex
			_fallback.visible = true
			_fallback.z_index = 6
			_fallback.scale = Vector2(1.35, 1.35)
			_fallback.position = Vector2(0, -37)
			_fallback.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	_update_frame_viewer()

	var parent_vis := _visibility_chain_ok(_animated)
	lines.append("=== 0M-C2A-FIX3 SANDBOX DEBUG ===")
	lines.append("Using FIX3 as primary: %s" % str(load_path == SPRITEFRAMES_FIX3 and sf_ok).to_upper())
	lines.append("FIX3 resource: %s" % SPRITEFRAMES_FIX3)
	lines.append("Chosen frame size (from FIX3 metadata): %dx%d" % [_frame_fw, _frame_fh])
	lines.append("Walk included (metadata): %s" % str(_walk_included).to_upper())
	lines.append("Sandbox status: %s" % _status)
	lines.append("Fallback mode: %s" % str(_fallback_mode).to_upper())
	lines.append("Root cause (load): %s" % _root_cause)
	lines.append("")
	lines.append("Forensic comparison sheet:")
	lines.append(FORENSIC_COMPARE)
	lines.append("Bad idle sheet (prior FIX2 frames):")
	lines.append(BAD_IDLE_SHEET)
	lines.append("Bad walk sheet (if generated):")
	lines.append(BAD_WALK_SHEET)
	lines.append("Stable FIX3 contact sheet:")
	lines.append(STABLE_SHEET)
	lines.append("")
	lines.append("FIX1 (glitchy, NOT primary): %s" % SPRITEFRAMES_FIX1)
	lines.append("FIX2 (obsolete primary, NOT primary): %s" % SPRITEFRAMES_FIX2)
	lines.append("SpriteFrames path used: %s" % (_spriteframes_path_used if _spriteframes_path_used != "" else "(none)"))
	lines.append("SpriteFrames exists: %s" % str(path_exists).to_upper())
	lines.append("SpriteFrames loaded: %s" % str(sf_ok).to_upper())
	if sf_ok:
		lines.append("Available animations: %s" % ", ".join(anim_names))
	else:
		lines.append("Available animations: (none)")
	lines.append("Selected animation: %s" % (chosen if chosen != "" else "(none)"))
	if anim_exists and sf_ok:
		lines.append("Frame count: %d" % sf.get_frame_count(chosen))
	else:
		lines.append("Frame count: 0")
	lines.append("Idle stable (automated tags): see phase0mc2a_fix3_frame_quality.json")
	lines.append("Full-body automated PASS: NO (conservative bbox heuristics — eyeball contact sheet)")
	lines.append("Anchor stability (idle foot std): see JSON frame_quality")
	lines.append("")
	lines.append("Animated node visible: %s" % str(_animated.visible).to_upper())
	lines.append("Parent visibility chain OK: %s" % str(parent_vis).to_upper())
	lines.append("Animated scale: %s" % str(_animated.scale))
	lines.append("")
	lines.append("Production promotion allowed: NO (manual sandbox validation required first)")

	_debug.text = "\n".join(lines)


func _load_fix3_meta() -> void:
	_idle_paths.clear()
	if not FileAccess.file_exists(META_FIX3):
		return
	var txt := FileAccess.get_file_as_string(META_FIX3)
	var data = JSON.parse_string(txt)
	if typeof(data) != TYPE_DICTIONARY:
		return
	var idle_any: Variant = data.get("idle", {})
	if typeof(idle_any) != TYPE_DICTIONARY:
		return
	var idle: Dictionary = idle_any
	_frame_fw = int(data.get("frame_width", 200))
	_frame_fh = int(data.get("frame_height", 200))
	var walk_any: Variant = data.get("walk", {})
	if typeof(walk_any) == TYPE_DICTIONARY:
		_walk_included = bool(walk_any.get("included", false))
	var files: Variant = idle.get("frame_files", [])
	if files is Array:
		for rel in files:
			var s := str(rel).replace("\\", "/")
			if s.begins_with("res://"):
				_idle_paths.append(s)
			else:
				_idle_paths.append("res://" + s.lstrip("/"))


func _update_frame_viewer() -> void:
	if _idle_paths.is_empty():
		_frame_info.text = "No FIX3 idle paths in metadata (viewer idle)."
		return
	_frame_index = clampi(_frame_index, 0, _idle_paths.size() - 1)
	var p := _idle_paths[_frame_index]
	if ResourceLoader.exists(p):
		_frame_tex.texture = load(p) as Texture2D
	_frame_info.text = "FIX3 idle frame %d / %d\n%s" % [_frame_index + 1, _idle_paths.size(), p]


func _on_prev_frame() -> void:
	if _idle_paths.is_empty():
		return
	_frame_index = (_frame_index - 1 + _idle_paths.size()) % _idle_paths.size()
	_update_frame_viewer()


func _on_next_frame() -> void:
	if _idle_paths.is_empty():
		return
	_frame_index = (_frame_index + 1) % _idle_paths.size()
	_update_frame_viewer()


func _pick_animation(sf: SpriteFrames) -> String:
	if sf == null:
		return ""
	var names := sf.get_animation_names()
	var order := ["idle", "idle_down", "walk", "walk_down"]
	for cand in order:
		for a in names:
			if String(a) == cand:
				return cand
	if names.size() > 0:
		return names[0]
	return ""


func _visibility_chain_ok(n: CanvasItem) -> bool:
	var p: Node = n
	while p:
		if p is CanvasItem and not (p as CanvasItem).visible:
			return false
		p = p.get_parent()
	return true
