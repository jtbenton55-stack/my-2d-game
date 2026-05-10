@tool
extends EditorScript
## File → Run. Prints whether key scripts exist (editor smoke check).

func _run() -> void:
	var paths := [
		"res://src/missions/dialogue/MissionDialogueProvider.gd",
		"res://src/missions/taco_bell/TacoBellDialogueProvider.gd",
		"res://src/missions/tools/MissionToolSurfaceHelper.gd",
		"res://src/missions/objectives/MissionObjectiveBridge.gd",
		"res://src/player/PlayerStaminaController.gd",
	]
	for p in paths:
		print("0MD1B: %s -> %s" % [p, "ok" if ResourceLoader.exists(p) else "MISSING"])
