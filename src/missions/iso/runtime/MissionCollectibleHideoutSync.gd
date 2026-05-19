extends RefCounted
## Maps committed mission collectibles to HideoutHub display flags and GameState markers.

const DEFAULT_HIDEOUT_KEYS := {
	"poop_bag": "poop_bag_fire_sauce_roll",
	"polaroid": "polaroid_taco_bell",
	"tiny_icon": "tiny_icon_sauce_packet",
	"glow_guy": "glow_guy_taco_bell",
	"evidence_clue": "clue_sauce_packet",
	"money": "case_cash",
	"case_cash": "case_cash",
}

const CASE_CASH_BANK_FLAG := "d6_06_case_cash_bank"


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
	var flag_key := "hideout_display:%s" % want
	if GameState.dialogue_flags.get(flag_key, false) == true:
		return
	GameState.dialogue_flags[flag_key] = true
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


static func commit_money_proof(entry: Dictionary) -> void:
	commit_case_cash(maxi(int(entry.get("amount", 1)), 1), entry)


static func commit_case_cash(amount: int, entry: Dictionary = {}) -> int:
	var add_amount := maxi(amount, 0)
	if add_amount <= 0:
		return 0
	var reason := "mission_authored:%s" % String(entry.get("collectible_id", "pickup"))
	var state := _find_hideout_state_controller()
	if state != null and state.has_method("add_case_cash"):
		state.call("add_case_cash", add_amount, reason)
		return add_amount
	var bank := int(GameState.dialogue_flags.get(CASE_CASH_BANK_FLAG, 0))
	GameState.dialogue_flags[CASE_CASH_BANK_FLAG] = bank + add_amount
	return add_amount


static func apply_banked_case_cash_to_hideout(state: Node) -> int:
	if state == null or not state.has_method("add_case_cash"):
		return 0
	var bank := int(GameState.dialogue_flags.get(CASE_CASH_BANK_FLAG, 0))
	if bank <= 0:
		return 0
	GameState.dialogue_flags.erase(CASE_CASH_BANK_FLAG)
	state.call("add_case_cash", bank, "d6_06_authored_mission_bank")
	return bank


static func _find_hideout_state_controller() -> Node:
	var tree := Engine.get_main_loop()
	if not (tree is SceneTree):
		return null
	for node in (tree as SceneTree).get_nodes_in_group("hideout_state_controller"):
		if node != null and is_instance_valid(node):
			return node
	return null
