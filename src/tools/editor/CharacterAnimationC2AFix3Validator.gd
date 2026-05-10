@tool
extends EditorScript
## Editor helper: quick Godot-side checks for 0M-C2A-FIX3.

const FIX3_SF := "res://assets/characters/generated_player_visuals/c2a_animation/fix3_stable/parmida_player_spriteframes_0mc2a_fix3.tres"
const SANDBOX := "res://scenes/hideout/tools/CharacterAnimationSandbox_0MC2A.tscn"
const CTRL := "res://scenes/hideout/tools/CharacterAnimationSandbox_0MC2AController.gd"


func _run() -> void:
	print("=== CharacterAnimationC2AFix3Validator ===")
	print("FIX3 exists: ", ResourceLoader.exists(FIX3_SF))
	var sf: Resource = load(FIX3_SF)
	if sf is SpriteFrames:
		print("FIX3 animations: ", (sf as SpriteFrames).get_animation_names())
	else:
		print("FIX3 load: ", sf)
	var sb := FileAccess.get_file_as_string(SANDBOX) if FileAccess.file_exists(SANDBOX) else ""
	print("Sandbox has FrameByFrameViewer: ", sb.find("FrameByFrameViewer") != -1)
	var ct := FileAccess.get_file_as_string(CTRL) if FileAccess.file_exists(CTRL) else ""
	print("Controller lists FIX3 before FIX2: ", ct.find("SPRITEFRAMES_FIX3") != -1 and ct.find("SPRITEFRAMES_FIX3") < ct.find("SPRITEFRAMES_FIX2"))
	print("NOTE: run res://src/tools/editor/character_animation_c2a_fix3_static_validator.py for full static checks.")
	print("=== end ===")
