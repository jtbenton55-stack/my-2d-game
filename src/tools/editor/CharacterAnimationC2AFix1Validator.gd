@tool
extends EditorScript
## Editor helper: prints a short 0M-C2A-FIX1 structural validation summary.
## Run from Godot: File > Run (while this script is focused) or attach as EditorScript.

func _run() -> void:
	var root := ProjectSettings.globalize_path("res://")
	print("=== CharacterAnimationC2AFix1Validator ===")
	print("Project root: ", root)

	var branch := _read_git_branch()
	print("Git branch (best effort): ", branch)

	var paths := [
		"res://scenes/hideout/tools/CharacterAnimationSandbox_0MC2A.tscn",
		"res://scenes/hideout/tools/CharacterAnimationSandbox_0MC2AController.gd",
		"res://assets/characters/generated_player_visuals/c2a_animation/parmida_player_spriteframes_0mc2a_fix1.tres",
		"res://assets/characters/generated_player_visuals/c2a_animation/parmida_player_composite_sheet_0mc2a.png",
		"res://assets/characters/generated_player_visuals/c2a_animation/frames/idle_frame_00.png",
	]
	for p in paths:
		var ok := ResourceLoader.exists(p)
		print("%s exists=%s" % [p, ok])

	var sf: Resource = load("res://assets/characters/generated_player_visuals/c2a_animation/parmida_player_spriteframes_0mc2a_fix1.tres")
	if sf is SpriteFrames:
		var names := (sf as SpriteFrames).get_animation_names()
		print("SpriteFrames animations: ", names)
	else:
		print("SpriteFrames load failed or wrong type: ", sf)

	print("NOTE: Run res://src/tools/editor/character_animation_c2a_fix1_static_validator.py for full static checks.")
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
