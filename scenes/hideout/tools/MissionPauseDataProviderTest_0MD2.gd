extends Node
## Run F6: prints pause payload shape (mission-agnostic).


func _ready() -> void:
	var payload := MissionPauseDataProvider.get_pause_payload("taco_bell_drop", null)
	print("[0MD2 MissionPauseDataProvider] ", JSON.stringify(payload))
	print("[0MD2 provider_id] ", MissionPauseDataProvider.get_provider_id())
