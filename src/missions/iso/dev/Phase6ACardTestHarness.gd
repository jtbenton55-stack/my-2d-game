extends PanelContainer

const EMPTY_LOADOUT := {"plan": "", "trick": "", "comfort_chaos": ""}

var _card_option: OptionButton
var _readout: RichTextLabel
var _rows: Array[Dictionary] = []
var _has_applied_loadout := false


func _ready() -> void:
	_build_ui()
	_populate_cards()
	_select_none()


func _build_ui() -> void:
	custom_minimum_size = Vector2(500, 230)
	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(root)

	var title := Label.new()
	title.text = "Phase 6A Card Test Harness"
	title.add_theme_font_size_override("font_size", 14)
	root.add_child(title)

	var help := Label.new()
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.text = "Dev-only: choose a resource card to write GameState.current_scheme_loadout.plan for scheme_effect requirements."
	root.add_child(help)

	_card_option = OptionButton.new()
	_card_option.item_selected.connect(_on_card_selected)
	root.add_child(_card_option)

	_readout = RichTextLabel.new()
	_readout.bbcode_enabled = true
	_readout.fit_content = false
	_readout.scroll_active = true
	_readout.custom_minimum_size = Vector2(480, 130)
	root.add_child(_readout)


func _populate_cards() -> void:
	_rows.clear()
	_card_option.clear()
	_add_row({
		"card_id": "",
		"display_name": "None",
		"effect_key": "",
		"effect_value": 0.0,
	})

	if CardManager.cards.is_empty() and CardManager.has_method("load_cards"):
		CardManager.load_cards()

	var discovered: Array[Dictionary] = []
	for raw_id in CardManager.cards.keys():
		var card_id := String(raw_id)
		var card = CardManager.get_card(card_id)
		if card == null:
			continue
		var display_name := String(card.get("display_name")).strip_edges()
		if display_name == "":
			display_name = card_id
		discovered.append({
			"card_id": card_id,
			"display_name": display_name,
			"effect_key": String(card.get("effect_key")).strip_edges(),
			"effect_value": float(card.get("effect_value")),
		})
	discovered.sort_custom(_sort_card_rows)
	for row in discovered:
		_add_row(row)


func _sort_card_rows(a: Dictionary, b: Dictionary) -> bool:
	return String(a.get("display_name", "")) < String(b.get("display_name", ""))


func _add_row(row: Dictionary) -> void:
	var card_id := String(row.get("card_id", ""))
	var display_name := String(row.get("display_name", card_id))
	var effect_key := String(row.get("effect_key", ""))
	var label := display_name
	if card_id != "":
		label = "%s -> %s" % [display_name, effect_key if effect_key != "" else "no effect_key"]
	_rows.append(row)
	_card_option.add_item(label)


func _select_none() -> void:
	if _card_option.get_item_count() > 0:
		_card_option.select(0)
		_update_readout(_rows[0])
	else:
		_update_readout({})


func _on_card_selected(index: int) -> void:
	if index < 0 or index >= _rows.size():
		return
	_apply_row(_rows[index])


func _apply_row(row: Dictionary) -> void:
	var card_id := String(row.get("card_id", ""))
	var loadout := EMPTY_LOADOUT.duplicate(true)
	if card_id != "":
		loadout["plan"] = card_id
	_apply_loadout(loadout)
	_update_readout(row)
	_refresh_mechanic_debug_labels()


func _apply_loadout(loadout: Dictionary) -> void:
	if GameState.has_method("set_current_scheme_loadout"):
		GameState.set_current_scheme_loadout(loadout)
	else:
		GameState.set("current_scheme_loadout", loadout.duplicate(true))
	if GameState.has_method("set_selected_cards"):
		GameState.set_selected_cards([])
	else:
		GameState.set("selected_cards", [])
	_has_applied_loadout = true


func _refresh_mechanic_debug_labels() -> void:
	if not is_inside_tree():
		return
	for node in get_tree().get_nodes_in_group("mission_mechanic"):
		if node != null and node.has_method("refresh_debug_label"):
			node.call("refresh_debug_label")


func _update_readout(row: Dictionary) -> void:
	var card_id := String(row.get("card_id", ""))
	var display_name := String(row.get("display_name", "None"))
	var effect_key := String(row.get("effect_key", ""))
	var effect_value := float(row.get("effect_value", 0.0))
	var loadout := GameState.get_current_scheme_loadout() if GameState.has_method("get_current_scheme_loadout") else EMPTY_LOADOUT
	var lines: Array[String] = []
	lines.append("[b]Active Test Card[/b]: %s" % display_name)
	lines.append("[b]Card ID[/b]: %s" % (card_id if card_id != "" else "none"))
	lines.append("[b]Effect Key[/b]: %s" % (effect_key if effect_key != "" else "none"))
	lines.append("[b]Effect Value[/b]: %s" % str(effect_value))
	var loadout_label := "Loadout Written" if _has_applied_loadout else "Current Loadout"
	lines.append("[b]%s[/b]: plan=%s trick=%s comfort_chaos=%s" % [loadout_label, String(loadout.get("plan", "")), String(loadout.get("trick", "")), String(loadout.get("comfort_chaos", ""))])
	lines.append("[b]Legacy selected_cards[/b]: %s" % ("cleared for deterministic dev testing" if _has_applied_loadout else "unchanged until you choose a dropdown item"))
	lines.append("")
	if card_id == "":
		lines.append("Pick a card to apply a dev loadout, or choose None after a card to clear it.")
	elif effect_key == "":
		lines.append("This card has no effect_key, so scheme_effect requirements will not match it.")
	else:
		lines.append("[b]Use these MissionRequirement fields:[/b]")
		lines.append("fact_type = scheme_effect")
		lines.append("key = %s" % effect_key)
		lines.append("operator = EXISTS")
		lines.append("expected_value_type = exists")
	_readout.text = "\n".join(lines)
