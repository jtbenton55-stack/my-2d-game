@tool
extends EditorScript
## Editor helper: quick Godot-side checks for 0M-C2B.

const C2B_SF := "res://assets/characters/generated_player_visuals/c2b_full_animation/parmida_player_spriteframes_0mc2b.tres"
const SANDBOX := "res://scenes/hideout/tools/CharacterAnimationSandbox_0MC2B.tscn"
const CTRL := "res://scenes/hideout/tools/CharacterAnimationSandbox_0MC2BController.gd"


func _run() -> void:
	print("=== CharacterAnimationC2BValidator ===")
	print("C2B SpriteFrames exists: ", ResourceLoader.exists(C2B_SF))
	var sf: Resource = load(C2B_SF) if ResourceLoader.exists(C2B_SF) else null
	if sf is SpriteFrames:
		print("C2B animations: ", (sf as SpriteFrames).get_animation_names())
	else:
		print("C2B load: ", sf)
	var sb := FileAccess.get_file_as_string(SANDBOX) if FileAccess.file_exists(SANDBOX) else ""
	print("Sandbox has FrameByFrameViewer: ", sb.find("FrameByFrameViewer") != -1)
	print("Sandbox avoids hardwired C2B SpriteFrames ExtResource: ", sb.find("parmida_player_spriteframes_0mc2b.tres") == -1)
	var ct := FileAccess.get_file_as_string(CTRL) if FileAccess.file_exists(CTRL) else ""
	print("Controller runtime-loads C2B: ", ct.find("load(SPRITEFRAMES_C2B)") != -1)
	print("NOTE: run src/tools/editor/character_animation_c2b_static_validator.py for full static checks.")
	print("=== end ===")
