@tool
extends EditorScript
## Quick Godot-side checks for 0M-C2B-FIX1.

const SF := "res://assets/characters/generated_player_visuals/c2b_context_classifier/parmida_context_classifier_spriteframes.tres"
const SB := "res://scenes/hideout/tools/CharacterAnimationContextClassifierSandbox_0MC2B_FIX1.tscn"


func _run() -> void:
	print("=== CharacterAnimationC2BFix1ContextClassifierValidator ===")
	print("Diagnostic SpriteFrames exists: ", ResourceLoader.exists(SF))
	var s := FileAccess.get_file_as_string(SB) if FileAccess.file_exists(SB) else ""
	print("Sandbox avoids embedding .tres path: ", s.find("parmida_context_classifier_spriteframes.tres") == -1)
	print("NOTE: run src/tools/editor/character_animation_c2b_fix1_context_classifier_validator.py for full checks.")
	print("=== end ===")
