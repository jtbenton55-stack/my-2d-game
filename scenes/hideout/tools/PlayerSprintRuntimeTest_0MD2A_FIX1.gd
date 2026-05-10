extends Node
## 0M-D2A-FIX1: Throttled print of `Player.get_sprint_runtime_debug()` when a player exists in the tree.


var _accum: float = 0.0


func _physics_process(delta: float) -> void:
	_accum += delta
	if _accum < 0.45:
		return
	_accum = 0.0
	var p := get_tree().get_first_node_in_group("player")
	if p != null and p.has_method("get_sprint_runtime_debug"):
		print("[FIX1 sprint runtime] ", JSON.stringify(p.get_sprint_runtime_debug()))
	else:
		print("[FIX1 sprint runtime] no player in group 'player' (run from a scene that spawns the player).")
