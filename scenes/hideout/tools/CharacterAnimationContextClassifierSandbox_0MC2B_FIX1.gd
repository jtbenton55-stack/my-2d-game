extends Node2D
## 0M-C2B-FIX1 — Context classifier diagnostic sandbox. Runtime-loads SpriteFrames; no production changes.

const SPRITEFRAMES_PATH := "res://assets/characters/generated_player_visuals/c2b_context_classifier/parmida_context_classifier_spriteframes.tres"
const CLIPS_META := "res://docs/reports/character_animation_c2b_fix1/recommended_animation_clips.json"
const FIX3_SF := "res://assets/characters/generated_player_visuals/c2a_animation/fix3_stable/parmida_player_spriteframes_0mc2a_fix3.tres"

const CLIP_ORDER: Array[String] = [
	"idle_best",
	"walk_best",
	"run_best",
	"fight_stance_best",
	"attack_candidate_best",
	"jump_best",
	"sneak_best",
	"crouch_best",
	"sit_best",
	"dance_best",
	"fall_best",
]

@onready var _fix3: AnimatedSprite2D = $Fix3Column/AnimatedFix3
@onready var _clip: AnimatedSprite2D = $ClipColumn/AnimatedClip
@onready var _debug: Label = $DebugPanel/DebugLabel
@onready var _missing: Label = $ClipColumn/MissingClipLabel
@onready var _clip_select: OptionButton = $ClipColumn/ClipOptionButton
@onready var _prev: Button = $FrameViewer/VBox/Row/PrevButton
@onready var _next: Button = $FrameViewer/VBox/Row/NextButton
@onready var _ftex: TextureRect = $FrameViewer/VBox/Row/FrameViewport/FrameTexture
@onready var _finfo: Label = $FrameViewer/VBox/FrameInfo

var _sf: SpriteFrames
var _meta: Dictionary = {}
var _current_anim: String = ""
var _frame_i: int = 0
var _load_err: String = ""


func _ready() -> void:
	_prev.pressed.connect(_on_prev)
	_next.pressed.connect(_on_next)
	_clip_select.item_selected.connect(_on_clip_selected)
	call_deferred("_bootstrap")


func _bootstrap() -> void:
	_clip_select.clear()
	for nm in CLIP_ORDER:
		_clip_select.add_item(nm)
	_load_meta()
	_load_fix3()
	_load_spriteframes()
	_sync_option_availability()
	_pick_first_available_anim()
	_refresh_play()
	_update_frame_view()
	_write_debug()


func _sync_option_availability() -> void:
	for i in range(_clip_select.item_count):
		var nm := String(_clip_select.get_item_text(i))
		var ok := _sf != null and _sf.has_animation(nm)
		_clip_select.set_item_disabled(i, not ok)


func _load_meta() -> void:
	_meta.clear()
	if not FileAccess.file_exists(CLIPS_META):
		return
	var p = JSON.parse_string(FileAccess.get_file_as_string(CLIPS_META))
	if typeof(p) == TYPE_DICTIONARY:
		_meta = p


func _load_fix3() -> void:
	if not ResourceLoader.exists(FIX3_SF):
		return
	var r = load(FIX3_SF)
	if r is SpriteFrames:
		var nsf: SpriteFrames = r
		_fix3.sprite_frames = nsf
		_fix3.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_fix3.scale = Vector2(1.35, 1.35)
		_fix3.position = Vector2(0, -37)
		if nsf.has_animation("idle"):
			_fix3.play("idle")
		elif nsf.get_animation_names().size() > 0:
			_fix3.play(nsf.get_animation_names()[0])


func _load_spriteframes() -> void:
	_sf = null
	_load_err = ""
	if not ResourceLoader.exists(SPRITEFRAMES_PATH):
		_load_err = "SpriteFrames not found: " + SPRITEFRAMES_PATH
		return
	var r = load(SPRITEFRAMES_PATH)
	if r is SpriteFrames:
		_sf = r
		_clip.sprite_frames = _sf
		_clip.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_clip.scale = Vector2(1.35, 1.35)
		_clip.position = Vector2(0, -37)
	else:
		_load_err = "Load failed for SpriteFrames"


func _pick_first_available_anim() -> void:
	_current_anim = ""
	if _sf == null:
		return
	for nm in CLIP_ORDER:
		if _sf.has_animation(nm):
			_current_anim = nm
			var idx := -1
			for j in range(CLIP_ORDER.size()):
				if CLIP_ORDER[j] == nm:
					idx = j
					break
			if idx >= 0:
				_clip_select.select(idx)
			return


func _on_clip_selected(idx: int) -> void:
	var nm := String(_clip_select.get_item_text(idx))
	if _sf != null and _sf.has_animation(nm):
		_current_anim = nm
		_frame_i = 0
		_refresh_play()
		_update_frame_view()
		_write_debug()
	else:
		_missing.text = "MISSING / NOT IN SPRITEFRAMES: " + nm.to_upper()
		_missing.visible = true


func _refresh_play() -> void:
	_missing.visible = false
	_missing.text = ""
	if _sf == null or _current_anim == "" or not _sf.has_animation(_current_anim):
		_clip.visible = false
		if _sf == null:
			_missing.text = "CLIP / SPRITEFRAMES MISSING\n" + _load_err
		else:
			_missing.text = "CLIP NOT IN SPRITEFRAMES: " + _current_anim
		_missing.visible = true
		return
	_clip.visible = true
	_clip.play(_current_anim)
	_frame_i = 0
	_clip.pause()
	_clip.frame = 0


func _on_prev() -> void:
	if _sf == null or _current_anim == "" or not _sf.has_animation(_current_anim):
		return
	var n := _sf.get_frame_count(_current_anim)
	if n <= 0:
		return
	_frame_i = (_frame_i - 1 + n) % n
	_clip.pause()
	_clip.frame = _frame_i
	_update_frame_view()
	_write_debug()


func _on_next() -> void:
	if _sf == null or _current_anim == "" or not _sf.has_animation(_current_anim):
		return
	var n := _sf.get_frame_count(_current_anim)
	if n <= 0:
		return
	_frame_i = (_frame_i + 1) % n
	_clip.pause()
	_clip.frame = _frame_i
	_update_frame_view()
	_write_debug()


func _clip_meta(anim: String) -> Dictionary:
	var clips: Variant = _meta.get("clips", {})
	if typeof(clips) != TYPE_DICTIONARY:
		return {}
	var c: Variant = clips.get(anim, {})
	return c if typeof(c) == TYPE_DICTIONARY else {}


func _update_frame_view() -> void:
	if _sf == null or _current_anim == "" or not _sf.has_animation(_current_anim):
		_ftex.texture = null
		_finfo.text = "No clip loaded."
		return
	var n := _sf.get_frame_count(_current_anim)
	_frame_i = clampi(_frame_i, 0, maxi(0, n - 1))
	var tex := _sf.get_frame_texture(_current_anim, _frame_i)
	_ftex.texture = tex
	var cm := _clip_meta(_current_anim)
	_finfo.text = "Anim: %s  frame %d / %d\nMeta: %s" % [_current_anim, _frame_i + 1, n, str(cm)]


func _write_debug() -> void:
	var lines: Array[String] = []
	lines.append("=== 0M-C2B-FIX1 CONTEXT CLASSIFIER SANDBOX ===")
	lines.append("SpriteFrames: " + SPRITEFRAMES_PATH)
	lines.append("Load error: " + (_load_err if _load_err != "" else "(none)"))
	if _sf:
		lines.append("Animations: " + ", ".join(_sf.get_animation_names()))
	else:
		lines.append("Animations: (none)")
	lines.append("Selected: " + (_current_anim if _current_anim != "" else "(none)"))
	var cm := _clip_meta(_current_anim)
	if cm.has("start_global"):
		lines.append("Start/end global: %s .. %s" % [str(cm.get("start_global")), str(cm.get("end_global"))])
	lines.append("Frame size: 200x200")
	lines.append("Production promotion allowed: NO")
	_debug.text = "\n".join(lines)
