extends RefCounted
## Maps committed mission collectibles to HideoutHub display flags and GameState markers.

const DEFAULT_HIDEOUT_KEYS := {
	"poop_bag": "poop_bag_fire_sauce_roll",
	"polaroid": "polaroid_taco_bell",
	"tiny_icon": "tiny_icon_sauce_packet",
	"glow_guy": "glow_guy_taco_bell",
	"evidence_clue": "clue_sauce_packet",
	"money": "case_cash",
}


static func resolve_hideout_key(category: String, collectible_id: String, override_key: String) -> String:
	var key := override_key.strip_edges()
	if key != "":
		return key
	var cat := category.strip_edges().to_lower()
	if DEFAULT_HIDEOUT_KEYS.has(cat):
		return String(DEFAULT_HIDEOUT_KEYS[cat])
	return collectible_id


static func mark_hideout_display_found(display_key: String) -> void:
	var want := display_key.strip_edges()
	if want == "":
		return
	GameState.dialogue_flags["hideout_display:%s" % want] = true
	var state := _find_hideout_state_controller()
	if state != null and state.has_method("mark_collectible_display_found"):
		state.call("mark_collectible_display_found", want)


static func apply_persisted_flags_to_hideout_state(state: Node) -> void:
	if state == null or not state.has_method("mark_collectible_display_found"):
		return
	for flag_key in GameState.dialogue_flags.keys():
		var key_s := String(flag_key)
		if not key_s.begins_with("hideout_display:"):
			continue
		if GameState.dialogue_flags.get(flag_key, false) != true:
			continue
		var display_id := key_s.substr("hideout_display:".length())
		state.call("mark_collectible_display_found", display_id)


static func commit_money_proof(_entry: Dictionary) -> void:
	# Money proof persistence is handled in IsoMissionBase._commit_authored_money (dialogue flags).
	pass


static func _find_hideout_state_controller() -> Node:
	var tree := Engine.get_main_loop()
	if not (tree is SceneTree):
		return null
	for node in (tree as SceneTree).get_nodes_in_group("hideout_state_controller"):
		if node != null and is_instance_valid(node):
			return node
	return null
