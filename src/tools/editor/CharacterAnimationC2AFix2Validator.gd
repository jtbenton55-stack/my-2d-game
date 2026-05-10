@tool
extends EditorScript
## Editor helper: quick Godot-side checks for 0M-C2A-FIX2 (sandbox + fix2 SpriteFrames).
## Run from Godot: File > Run (while this script is focused).

const SANDBOX := "res://scenes/hideout/tools/CharacterAnimationSandbox_0MC2A.tscn"
const SANDBOX_CTRL := "res://scenes/hideout/tools/CharacterAnimationSandbox_0MC2AController.gd"
const FIX2_SF := "res://assets/characters/generated_player_visuals/c2a_animation/fix2_rebuilt/parmida_player_spriteframes_0mc2a_fix2.tres"
const FIX1_SF := "res://assets/characters/generated_player_visuals/c2a_animation/parmida_player_spriteframes_0mc2a_fix1.tres"
const BAD_SHEET := "res://docs/reports/character_animation_c2a/phase0mc2a_fix2_current_bad_frames_contact_sheet.png"
const REBUILT_SHEET := "res://docs/reports/character_animation_c2a/phase0mc2a_fix2_rebuilt_frames_contact_sheet.png"


func _run() -> void:
	print("=== CharacterAnimationC2AFix2Validator ===")
	print("Project root: ", ProjectSettings.globalize_path("res://"))
	print("Git branch (best effort): ", _read_git_branch())

	for p in [SANDBOX, SANDBOX_CTRL, FIX2_SF, FIX1_SF, BAD_SHEET, REBUILT_SHEET]:
		print("%s exists=%s" % [p, ResourceLoader.exists(p) or FileAccess.file_exists(p)])

	var sandbox_text := FileAccess.get_file_as_string(SANDBOX) if FileAccess.file_exists(SANDBOX) else ""
	var ctrl_text := FileAccess.get_file_as_string(SANDBOX_CTRL) if FileAccess.file_exists(SANDBOX_CTRL) else ""
	print("controller references FIX2 tres: ", ctrl_text.find("parmida_player_spriteframes_0mc2a_fix2.tres") != -1)
	print("scene does NOT hard-embed SpriteFrames ext_resource: ", not sandbox_text.contains("[ext_resource type=\"SpriteFrames\""))
	print("scene does NOT assign fix1 as ExtResource to sprite_frames: ", not sandbox_text.contains("sprite_frames = ExtResource(\"3_sf_fix1\")"))

	var sf: Resource = load(FIX2_SF)
	if sf is SpriteFrames:
		var names := (sf as SpriteFrames).get_animation_names()
		print("FIX2 SpriteFrames animations: ", names)
		if (sf as SpriteFrames).has_animation("idle"):
			print("FIX2 idle frame count: ", (sf as SpriteFrames).get_frame_count("idle"))
	else:
		print("FIX2 SpriteFrames load failed or wrong type: ", sf)

	print("NOTE: Run res://src/tools/editor/character_animation_c2a_fix2_static_validator.py for full static checks.")
	print("=== end ===")


func _read_git_branch() -> String:
	var proj := ProjectSettings.globalize_path("res://").replace("\\", "/")
	var head_path := proj + "/.git/HEAD"
	if not FileAccess.file_exists(head_path):
		return "(unknown)"
	var f := FileAccess.open(head_path, FileAccess.READ)
	if f == null:
		return "(unknown)"
	var line := f.get_as_text().strip_edges()
	if line.begins_with("ref: "):
		return line.substr(5).get_file()
	return line
