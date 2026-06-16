class_name MissionSchemeCardFormatter
extends RefCounted
## Player-facing scheme pause text + raw debug block for F10 (0M-D5-02A-FIX2).


static func _catalog_display_name(card_id: String) -> String:
	var cid := card_id.strip_edges()
	if cid == "":
		return ""
	const Catalog = preload("res://src/hideout/HideoutStationCatalog.gd")
	for c in Catalog.scheme_cards():
		if String(c.get("card_id", "")) == cid:
			return String(c.get("display_name", cid))
	return ""


static func display_name_for_id(card_id: String, snapshot_display: String = "") -> String:
	var cid := card_id.strip_edges()
	if cid == "":
		return "Unknown card"
	var snap := String(snapshot_display).strip_edges()
	if snap != "" and snap != cid:
		return snap
	var cat := _catalog_display_name(cid)
	if cat != "":
		return cat
	if MissionAutoloadResolver.has_card_manager():
		var res = CardManager.get_card(cid)
		if res != null:
			var display_name := String(res.get("display_name")).strip_edges()
			if display_name != "":
				return display_name
			var resource_id := String(res.get("id")).strip_edges()
			return resource_id if resource_id != "" else cid
	return _snake_case_to_title(cid)


static func _snake_case_to_title(raw: String) -> String:
	var s := raw.strip_edges()
	if s == "":
		return raw
	var parts := s.split("_", false)
	var out: Array[String] = []
	for p in parts:
		if p.is_empty():
			continue
		out.append(p.capitalize())
	return " ".join(out) if not out.is_empty() else raw


static func player_slot_label(slot_key: String) -> String:
	match String(slot_key):
		"plan":
			return "Plan"
		"trick":
			return "Trick"
		"comfort_chaos":
			return "Comfort / Chaos"
		_:
			return _snake_case_to_title(String(slot_key))


static func _lookup_equipped_display(equipped: Array, card_id: String) -> String:
	for r in equipped:
		if r is Dictionary and String(r.get("id", "")) == card_id:
			return String(r.get("display_name", ""))
	return ""


static func format_player_pause_scheme_text(snapshot: Dictionary) -> String:
	if snapshot.get("ok", false) != true:
		return "Scheme card data is not available right now."
	if not MissionAutoloadResolver.has_game_state():
		return "Scheme card data is not available right now."
	var lines: Array[String] = []
	lines.append("Scheme Cards for This Run")
	lines.append("")
	var loadout: Array = snapshot.get("loadout_slots", [])
	var equipped: Array = snapshot.get("equipped", [])
	var any_equipped := false
	for row in loadout:
		if not row is Dictionary:
			continue
		var cid := String(row.get("card_id", "")).strip_edges()
		if cid == "":
			continue
		any_equipped = true
		var slot_key := String(row.get("slot", ""))
		var dname := display_name_for_id(cid, _lookup_equipped_display(equipped, cid))
		lines.append(dname)
		lines.append("Slot: %s" % player_slot_label(slot_key))
		lines.append("Status: Equipped")
		if GameState.has_selected_card(cid):
			lines.append(
				"Bonus: This card is also on your mission card list. Some stat bonuses may apply in missions that use that list."
			)
		else:
			lines.append(
				"Bonus: Not active yet for this Taco Bell run. Your planning picks are saved, but extra effects are not wired into this mission."
			)
		lines.append("")
	if not any_equipped:
		lines.append("No scheme cards equipped for this run.")
		lines.append("")
		lines.append("Visit the Planning Table in the hideout before starting a mission to pick Plan, Trick, and Comfort / Chaos cards.")
	if any_equipped:
		var loadout_ids: Dictionary = {}
		for row2 in loadout:
			if row2 is Dictionary:
				var c2 := String(row2.get("card_id", "")).strip_edges()
				if c2 != "":
					loadout_ids[c2] = true
		var legacy: Array = snapshot.get("legacy_selected_card_ids", [])
		var extra: Array[String] = []
		for lid in legacy:
			var sid := String(lid).strip_edges()
			if sid != "" and not loadout_ids.has(sid):
				extra.append(sid)
		if extra.size() > 0:
			lines.append("Mission card list (separate picks)")
			for eid in extra:
				lines.append(
					"  - %s" % display_name_for_id(eid, _lookup_equipped_display(equipped, eid))
				)
			lines.append("Some stat bonuses may apply from this list where the mission supports it.")
			lines.append("")
	for w in snapshot.get("warnings", []):
		var ws := String(w).strip_edges()
		if ws == "":
			continue
		lines.append("")
		lines.append("Note: " + ws)
	return "\n".join(lines).strip_edges()


static func format_scheme_snapshot_debug_block(snapshot: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("--- scheme / loadout (raw debug) ---")
	lines.append("mission_id=%s ok=%s" % [str(snapshot.get("mission_id", "")), str(snapshot.get("ok", false))])
	lines.append("loadout_slots=%s" % str(snapshot.get("loadout_slots", [])))
	lines.append("legacy_selected_card_ids=%s" % str(snapshot.get("legacy_selected_card_ids", [])))
	lines.append("unlocked_ids=%s" % str(snapshot.get("unlocked_ids", [])))
	lines.append("equipped=%s" % str(snapshot.get("equipped", [])))
	var note := String(snapshot.get("scheme_debug_note", "")).strip_edges()
	if note != "":
		lines.append("")
		lines.append(note)
	for w in snapshot.get("warnings", []):
		lines.append("warning=%s" % String(w))
	lines.append("")
	lines.append(
		"Implementation: mission stat hooks read the separate mission card list; Taco route checks use unlock flags; planning slots persist on the autoload loadout dict until effects are bridged."
	)
	return "\n".join(lines)
