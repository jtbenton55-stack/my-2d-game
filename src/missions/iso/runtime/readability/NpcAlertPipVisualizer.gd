class_name NpcAlertPipVisualizer
extends Node2D

## Draws ?/! pips over guards and NPCs so alert and investigation states are
## readable in the world instead of only in the F10 debug panel (Replan Packet 1).

const REFRESH_INTERVAL := 0.2
const PIP_OFFSET := Vector2(0.0, -64.0)

var _refresh_timer := 0.0
var _pips: Array[Dictionary] = []


func _ready() -> void:
	z_as_relative = false
	z_index = 210


func _process(delta: float) -> void:
	_refresh_timer -= delta
	if _refresh_timer > 0.0:
		return
	_refresh_timer = REFRESH_INTERVAL
	_refresh_pips()
	queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	for pip in _pips:
		var pos := to_local(pip.get("position", Vector2.ZERO)) + PIP_OFFSET
		var text := String(pip.get("text", "?"))
		var color: Color = pip.get("color", Color.YELLOW)
		draw_circle(pos, 11.0, Color(0.08, 0.08, 0.1, 0.8))
		draw_string(font, pos + Vector2(-5.0, 6.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, color)


func _refresh_pips() -> void:
	_pips.clear()
	var tree := get_tree()
	if tree == null:
		return
	var alert_state := "normal"
	var controller := tree.get_first_node_in_group("iso_alert_controller")
	if controller != null:
		alert_state = String(controller.get("alert_state"))
	for node in tree.get_nodes_in_group("enemy"):
		if not (node is Node2D) or not is_instance_valid(node):
			continue
		var node2d := node as Node2D
		if not node2d.is_visible_in_tree():
			continue
		var entry := _pip_for_npc(node2d, alert_state)
		if not entry.is_empty():
			_pips.append(entry)


func _pip_for_npc(npc: Node2D, alert_state: String) -> Dictionary:
	var reaction := String(npc.get("reaction_state")) if npc.get("reaction_state") != null else ""
	if reaction == "investigating_noise":
		return {"position": npc.global_position, "text": "?", "color": Color(1.0, 0.85, 0.3)}
	match alert_state:
		"alerted":
			return {"position": npc.global_position, "text": "!", "color": Color(1.0, 0.35, 0.3)}
		"suspicious":
			return {"position": npc.global_position, "text": "?", "color": Color(1.0, 0.85, 0.3)}
	return {}


func get_pip_count() -> int:
	return _pips.size()
