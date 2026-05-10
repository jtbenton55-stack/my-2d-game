extends Node
## Run F6: prints resolver path + report for taco_bell_drop.


func _ready() -> void:
	var path := MissionSceneResolver.resolve_playable_scene_path("taco_bell_drop")
	var rep := MissionSceneResolver.get_resolution_report("taco_bell_drop")
	print("[0MD2 MissionSceneResolver] path=", path)
	print("[0MD2 MissionSceneResolver] report=", JSON.stringify(rep))
	print("[0MD2 MissionSceneResolver] legacy?", MissionSceneResolver.is_legacy_scene_path(MissionSceneResolver.LEGACY_BAKE_TACO_ISO))
