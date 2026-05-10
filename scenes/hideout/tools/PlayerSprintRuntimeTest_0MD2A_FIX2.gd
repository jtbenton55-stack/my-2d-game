extends Node
## 0M-D2A-FIX2: Throttled print of sprint signal chain when a player exists (`get_sprint_runtime_debug`).


var _accum: float = 0.0


func _physics_process(delta: float) -> void:
	_accum += delta
	if _accum < 0.45:
		return
	_accum = 0.0
	var p := get_tree().get_first_node_in_group("player")
	if p == null or not p.has_method("get_sprint_runtime_debug"):
		print("[FIX2 sprint] no player in group 'player' — open a mission or add this node under a scene that spawns Player.")
		return
	var d: Dictionary = p.get_sprint_runtime_debug()
	var ctrl_p: bool = bool(d.get("ctrl_physical_pressed", false))
	var ctrl_k: bool = bool(d.get("ctrl_key_pressed", false))
	var act: bool = bool(d.get("sprint_action_pressed", false))
	var req: bool = bool(d.get("is_sprint_requested", false))
	var actv: bool = bool(d.get("is_sprint_active", false))
	var mult: float = float(d.get("speed_multiplier", 1.0))
	var vlen: float = float(d.get("velocity_length_post_slide", 0.0))
	var st: float = float(d.get("current_stamina", 0.0))
	var dash: bool = bool(d.get("dash_active", false))
	var dodge_b: bool = bool(d.get("legacy_dodge_burst", false))
	var sup: String = str(d.get("sprint_suppressed_reason", ""))
	var c1 := "1" if (ctrl_p or ctrl_k) else "0"
	var c2 := "1" if act else "0"
	var c3 := "1" if req else "0"
	var c4 := "1" if actv else "0"
	var c5 := "1" if mult > 1.001 else "0"
	var c6 := "1" if vlen > 0.5 else "0"
	print(
		"[FIX2 sprint] CTRL→ACT→REQ→ACTV→MULT→VEL = %s→%s→%s→%s→%s→%s | sup=%s dash=%s dodgeBurst=%s stamina=%.1f | "
		% [c1, c2, c3, c4, c5, c6, sup, dash, dodge_b, st]
	)
	print("[FIX2 sprint json] ", JSON.stringify(d))
