@tool
extends EditorScript

func _run() -> void:
	var checks := {
		"player_scene_exists": FileAccess.file_exists("res://scenes/characters/player.tscn"),
		"generated_visual_exists": FileAccess.file_exists("res://assets/characters/generated_player_visuals/parmida_player_visual_0mc2.png"),
		"sandbox_exists": FileAccess.file_exists("res://scenes/hideout/tools/CharacterVisualSandbox_0MC2.tscn"),
		"final_report_exists": FileAccess.file_exists("res://docs/reports/character_sprite_replacement/phase0mc2_character_sprite_replacement.json"),
	}
	print(JSON.stringify(checks, "  "))
