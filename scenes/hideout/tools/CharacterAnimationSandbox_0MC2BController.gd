extends Node2D
## 0M-C2B sandbox: discovery preview only. Loads C2B SpriteFrames at runtime (no .tres ExtResource on scene).

const SPRITEFRAMES_C2B := "res://assets/characters/generated_player_visuals/c2b_full_animation/parmida_player_spriteframes_0mc2b.tres"
const META_C2B := "res://assets/characters/generated_player_visuals/c2b_full_animation/parmida_player_animation_metadata_0mc2b.json"
const SPRITEFRAMES_FIX3 := "res://assets/characters/generated_player_visuals/c2a_animation/fix3_stable/parmida_player_spriteframes_0mc2a_fix3.tres"

@onready var _fix3_sprite: AnimatedSprite2D = $Fix3IdleColumn/AnimatedFix3
@onready var _c2b_sprite: AnimatedSprite2D = $C2BAnimatedColumn/AnimatedC2B
@onready var _debug: Label = $DebugPanel/DebugLabel
@onready var _btn_idle: Button = $ControlPanel/Buttons/IdleButton
@onready var _btn_walk: Button = $ControlPanel/Buttons/WalkButton
@onready var _btn_run: Button = $ControlPanel/Buttons/RunButton
@onready var _btn_attack: Button = $ControlPanel/Buttons/AttackButton
@onready var _lbl_run: Label = $ControlPanel/MissingLabels/RunMissingLabel
@onready var _lbl_attack: Label = $ControlPanel/MissingLabels/AttackMissingLabel
@onready var _lbl_walk: Label = $ControlPanel/MissingLabels/WalkMissingLabel
@onready var _prev_btn: Button = $FrameByFrameViewer/VBox/Row/PrevButton
@onready var _next_btn: Button = $FrameByFrameViewer/VBox/Row/NextButton
@onready var _frame_tex: TextureRect = $FrameByFrameViewer/VBox/Row/FrameViewport/FrameTexture
@onready var _frame_info: Label = $FrameByFrameViewer/VBox/FrameInfo

var _sf_c2b: SpriteFrames
var _sf_fix3: SpriteFrames
var _c2b_load_error: String = ""
var _fix3_load_error: String = ""
var _meta: Dictionary = {}

var _inspect_anim: String = "idle"
var _inspect_index: int = 0

var _walk_available: bool = false
var _run_available: bool = false
var _attack_available: bool = false


func _ready() -> void:
	_btn_idle.pressed.connect(_on_idle)
	_btn_walk.pressed.connect(_on_walk)
	_btn_run.pressed.connect(_on_run)
	_btn_attack.pressed.connect(_on_attack)
	_prev_btn.pressed.connect(_on_prev_frame)
	_next_btn.pressed.connect(_on_next_frame)
	call_deferred("_bootstrap")


func _bootstrap() -> void:
	_load_meta()
	_load_fix3()
	_load_c2b()
	_apply_missing_labels()
	_sync_buttons()
	_pick_default_c2b_animation()
	_refresh_c2b_playback()
	_refresh_fix3_idle()
	_update_frame_viewer()
	_write_debug()


func _load_meta() -> void:
	_meta.clear()
	if not FileAccess.file_exists(META_C2B):
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(META_C2B))
	if typeof(parsed) == TYPE_DICTIONARY:
		_meta = parsed


func _load_fix3() -> void:
	_sf_fix3 = null
	_fix3_load_error = ""
	if not ResourceLoader.exists(SPRITEFRAMES_FIX3):
		_fix3_load_error = "FIX3 SpriteFrames path missing: %s" % SPRITEFRAMES_FIX3
		_fix3_sprite.sprite_frames = null
		_fix3_sprite.visible = false
		return
	var r = load(SPRITEFRAMES_FIX3)
	if r is SpriteFrames:
		_sf_fix3 = r
		_fix3_sprite.sprite_frames = _sf_fix3
		_fix3_sprite.visible = true
		_fix3_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_fix3_sprite.scale = Vector2(1.35, 1.35)
		_fix3_sprite.position = Vector2(0, -37)
	else:
		_fix3_load_error = "FIX3 load returned: %s" % str(r)


func _load_c2b() -> void:
	_sf_c2b = null
	_c2b_load_error = ""
	if not ResourceLoader.exists(SPRITEFRAMES_C2B):
		_c2b_load_error = "C2B SpriteFrames missing: %s" % SPRITEFRAMES_C2B
		_c2b_sprite.sprite_frames = null
		_c2b_sprite.visible = false
		return
	var r = load(SPRITEFRAMES_C2B)
	if r is SpriteFrames:
		_sf_c2b = r
		_c2b_sprite.sprite_frames = _sf_c2b
		_c2b_sprite.visible = true
		_c2b_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_c2b_sprite.scale = Vector2(1.35, 1.35)
		_c2b_sprite.position = Vector2(0, -37)
	else:
		_c2b_load_error = "C2B load returned: %s" % str(r)


func _selection_from_meta() -> Dictionary:
	var sel: Dictionary = {}
	if _meta.has("selection") and typeof(_meta["selection"]) == TYPE_DICTIONARY:
		sel = _meta["selection"]
	return sel


func _apply_missing_labels() -> void:
	_walk_available = _sf_c2b != null and _sf_c2b.has_animation("walk")
	_run_available = _sf_c2b != null and _sf_c2b.has_animation("run")
	_attack_available = _sf_c2b != null and (_sf_c2b.has_animation("attack") or _sf_c2b.has_animation("fight"))

	_lbl_walk.visible = not _walk_available
	_lbl_walk.text = "WALK NOT FOUND SAFE" if not _walk_available else ""

	_lbl_run.visible = not _run_available
	_lbl_run.text = "RUN NOT FOUND SAFE" if not _run_available else ""

	_lbl_attack.visible = not _attack_available
	_lbl_attack.text = "ATTACK NOT FOUND SAFE" if not _attack_available else ""


func _sync_buttons() -> void:
	_btn_idle.disabled = _sf_c2b == null or not _sf_c2b.has_animation("idle")
	_btn_walk.disabled = _sf_c2b == null or not _sf_c2b.has_animation("walk")
	_btn_run.disabled = _sf_c2b == null or not _sf_c2b.has_animation("run")
	var atk := false
	if _sf_c2b:
		atk = _sf_c2b.has_animation("attack") or _sf_c2b.has_animation("fight")
	_btn_attack.disabled = not atk


func _pick_default_c2b_animation() -> void:
	if _sf_c2b == null:
		_inspect_anim = ""
		return
	if _sf_c2b.has_animation("idle"):
		_inspect_anim = "idle"
	elif _sf_c2b.get_animation_names().size() > 0:
		_inspect_anim = str(_sf_c2b.get_animation_names()[0])
	else:
		_inspect_anim = ""


func _refresh_c2b_playback() -> void:
	if _sf_c2b == null or _inspect_anim == "" or not _sf_c2b.has_animation(_inspect_anim):
		return
	_c2b_sprite.play(_inspect_anim)


func _refresh_fix3_idle() -> void:
	if _sf_fix3 == null:
		return
	if _sf_fix3.has_animation("idle"):
		_fix3_sprite.play("idle")
	elif _sf_fix3.get_animation_names().size() > 0:
		_fix3_sprite.play(_sf_fix3.get_animation_names()[0])


func _on_idle() -> void:
	_set_c2b_anim("idle")


func _on_walk() -> void:
	_set_c2b_anim("walk")


func _on_run() -> void:
	_set_c2b_anim("run")


func _on_attack() -> void:
	if _sf_c2b == null:
		return
	if _sf_c2b.has_animation("attack"):
		_set_c2b_anim("attack")
	elif _sf_c2b.has_animation("fight"):
		_set_c2b_anim("fight")


func _set_c2b_anim(name: String) -> void:
	if _sf_c2b == null or not _sf_c2b.has_animation(name):
		return
	_inspect_anim = name
	_inspect_index = 0
	_refresh_c2b_playback()
	_update_frame_viewer()
	_write_debug()


func _frame_count_for(anim: String) -> int:
	if _sf_c2b == null or anim == "" or not _sf_c2b.has_animation(anim):
		return 0
	return _sf_c2b.get_frame_count(anim)


func _update_frame_viewer() -> void:
	if _sf_c2b == null or _inspect_anim == "" or not _sf_c2b.has_animation(_inspect_anim):
		_frame_tex.texture = null
		_frame_info.text = "C2B SpriteFrames not loaded or animation missing.\n%s" % _c2b_load_error
		return
	var n := _frame_count_for(_inspect_anim)
	if n <= 0:
		_frame_tex.texture = null
		_frame_info.text = "Animation %s has zero frames." % _inspect_anim
		return
	_inspect_index = clampi(_inspect_index, 0, n - 1)
	var tex := _sf_c2b.get_frame_texture(_inspect_anim, _inspect_index)
	_frame_tex.texture = tex
	var loop := _sf_c2b.get_animation_loop(_inspect_anim)
	var spd := _sf_c2b.get_animation_speed(_inspect_anim)
	var sel := _selection_from_meta()
	var row_idle := int(sel.get("idle_row", -1))
	var row_walk := sel.get("walk_row", null)
	var row_run := sel.get("run_row", null)
	var row_atk := sel.get("attack_row", null)
	_frame_info.text = "C2B frame viewer\nAnimation: %s\nFrame: %d / %d\nLoop: %s  FPS (speed): %.2f\nFrame size: 200x200 (fixed atlas cell)\nSource rows — idle:%s walk:%s run:%s attack:%s" % [
		_inspect_anim,
		_inspect_index + 1,
		n,
		str(loop).to_upper(),
		spd,
		str(row_idle),
		str(row_walk),
		str(row_run),
		str(row_atk),
	]


func _on_prev_frame() -> void:
	var n := _frame_count_for(_inspect_anim)
	if n <= 0:
		return
	_inspect_index = (_inspect_index - 1 + n) % n
	if _sf_c2b and _sf_c2b.has_animation(_inspect_anim):
		_c2b_sprite.pause()
		_c2b_sprite.frame = _inspect_index
	_update_frame_viewer()
	_write_debug()


func _on_next_frame() -> void:
	var n := _frame_count_for(_inspect_anim)
	if n <= 0:
		return
	_inspect_index = (_inspect_index + 1) % n
	if _sf_c2b and _sf_c2b.has_animation(_inspect_anim):
		_c2b_sprite.pause()
		_c2b_sprite.frame = _inspect_index
	_update_frame_viewer()
	_write_debug()


func _write_debug() -> void:
	var lines: Array[String] = []
	var names := PackedStringArray()
	if _sf_c2b:
		names = _sf_c2b.get_animation_names()
	var sel := _selection_from_meta()
	lines.append("=== 0M-C2B SANDBOX DEBUG ===")
	lines.append("C2B SpriteFrames path: %s" % SPRITEFRAMES_C2B)
	lines.append("C2B load error: %s" % (_c2b_load_error if _c2b_load_error != "" else "(none)"))
	lines.append("C2B loaded: %s" % str(_sf_c2b != null).to_upper())
	lines.append("Available C2B animations: %s" % (", ".join(names) if names.size() else "(none)"))
	lines.append("Selected C2B animation: %s" % (_inspect_anim if _inspect_anim != "" else "(none)"))
	lines.append("Frame count (current): %d" % _frame_count_for(_inspect_anim))
	if _sf_c2b and _inspect_anim != "" and _sf_c2b.has_animation(_inspect_anim):
		lines.append("Loop: %s" % str(_sf_c2b.get_animation_loop(_inspect_anim)).to_upper())
		lines.append("Speed: %.2f" % _sf_c2b.get_animation_speed(_inspect_anim))
	lines.append("Confirmed frame size: 200x200 (atlas + exported frames)")
	lines.append("FIX3 reference path: %s" % SPRITEFRAMES_FIX3)
	lines.append("FIX3 load error: %s" % (_fix3_load_error if _fix3_load_error != "" else "(none)"))
	lines.append("")
	lines.append("Metadata selection:")
	lines.append("  idle_row: %s" % str(sel.get("idle_row", "")))
	lines.append("  walk_row / status: %s / %s" % [str(sel.get("walk_row", "")), str(sel.get("walk_status", ""))])
	lines.append("  run_row / status: %s / %s" % [str(sel.get("run_row", "")), str(sel.get("run_status", ""))])
	lines.append("  attack_row / status: %s / %s" % [str(sel.get("attack_row", "")), str(sel.get("attack_status", ""))])
	lines.append("")
	lines.append("Missing / rejected (explicit):")
	lines.append("  walk missing UI: %s" % str(not _walk_available).to_upper())
	lines.append("  run missing UI: %s" % str(not _run_available).to_upper())
	lines.append("  attack missing UI: %s" % str(not _attack_available).to_upper())
	lines.append("")
	lines.append("Production promotion allowed: NO (manual validation required)")
	_debug.text = "\n".join(lines)
