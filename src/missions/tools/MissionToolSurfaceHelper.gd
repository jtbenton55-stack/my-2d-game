class_name MissionToolSurfaceHelper
extends RefCounted
## Resolves mission tool actions without Taco-specific duck typing in Player.

const TOOL_POOP_BAG := "poop_bag"


static func get_tool_surface_id(scene: Node) -> String:
	if scene == null:
		return ""
	if scene.has_method("get_tool_surface_id"):
		return String(scene.call("get_tool_surface_id"))
	var sc := scene.get_script() as Script
	if sc != null and sc.resource_path != "":
		return sc.resource_path.get_file()
	return String(scene.name)


static func supports_tool(scene: Node, tool_id: String) -> bool:
	if scene == null or tool_id.strip_edges() == "":
		return false
	if scene.has_method("supports_tool"):
		return scene.call("supports_tool", tool_id) == true
	return tool_id == TOOL_POOP_BAG and scene.has_method("deploy_poop_bag_decoy_at")


static func handle_tool_use(scene: Node, tool_id: String, payload: Dictionary = {}) -> Dictionary:
	if scene == null:
		return _result(false, false, "no_scene", tool_id, payload)
	if scene.has_method("handle_tool_use"):
		var r: Variant = scene.call("handle_tool_use", tool_id, payload)
		if r is Dictionary:
			return r
		return _result(false, false, "bad_return", tool_id, payload)
	if tool_id == TOOL_POOP_BAG and scene.has_method("deploy_poop_bag_decoy_at"):
		var pos: Vector2 = payload.get("world_pos", Vector2.ZERO) as Vector2
		var ok: bool = scene.call("deploy_poop_bag_decoy_at", pos) == true
		return _result(ok, true, "" if ok else "deploy_rejected", tool_id, payload, "legacy_deploy")
	return _result(false, false, "unsupported_tool", tool_id, payload)


static func _result(ok: bool, handled: bool, reason: String, tool_id: String, payload: Dictionary, effect: String = "") -> Dictionary:
	return {
		"ok": ok,
		"handled": handled,
		"reason": reason,
		"tool_id": tool_id,
		"effect": effect,
		"payload": payload,
	}
