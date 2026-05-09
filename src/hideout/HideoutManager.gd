extends Node
class_name HideoutManager

const Catalog = preload("res://src/hideout/HideoutStationCatalog.gd")
const StateControllerScript = preload("res://src/hideout/HideoutStateController.gd")
const InteractableScript = preload("res://src/hideout/HideoutInteractable.gd")
const PlacementZoneScript = preload("res://src/hideout/HideoutPlacementZone.gd")
const InteractionBridgeScript = preload("res://src/hideout/HideoutInteractionBridge.gd")
const DecorationControllerScript = preload("res://src/hideout/HideoutDecorationController.gd")
const DialogueBank = preload("res://src/hideout/HideoutDialogueBank.gd")
const HideoutCharacterDialogueBankScript = preload("res://src/dialogue/HideoutCharacterDialogueBank.gd")
const DialogueBoxScene = preload("res://scenes/ui/DialogueBox.tscn")
const StorefrontPanelScene = preload("res://scenes/ui/HideoutStorefrontPanel.tscn")

# Phase 0M-C3 - speaker IDs that should bypass the panel and fire the
# DialogueBox (with left-side portrait support) directly.
const _PORTRAIT_DIALOGUE_CHARACTER_IDS := ["jake", "mere", "parmida", "bentley", "louis"]

@export var stations_path: NodePath
@export var collision_path: NodePath
@export var walkable_area_path: NodePath
@export var interaction_areas_path: NodePath
@export var placement_zones_path: NodePath
@export var snap_markers_path: NodePath
@export var characters_path: NodePath
@export var art_world_path: NodePath
@export var panel_path: NodePath
@export var prompt_path: NodePath
@export var debug_buttons_path: NodePath
@export var show_runtime_graybox_debug := false
@export var show_station_proxy_debug_labels := false

var current_state := "fresh"
var current_station_id := ""
var _state: Node = null
var _decoration_controller: Node = null
var _decorating_mode_controller: Node = null
var _storefront_panel: Node = null

@onready var _stations: Node = get_node(stations_path)
@onready var _collision: Node = get_node(collision_path)
@onready var _walkable_area: Node = get_node(walkable_area_path)
@onready var _interaction_areas: Node = get_node(interaction_areas_path)
@onready var _placement_zones: Node = get_node(placement_zones_path)
@onready var _snap_markers: Node = get_node(snap_markers_path)
@onready var _characters: Node = get_node(characters_path)
@onready var _world: Node = get_node(art_world_path)
@onready var _panel: Node = get_node(panel_path)
@onready var _prompt: Label = get_node(prompt_path)
@onready var _mission_board: Node = get_node("../HideoutMissionBoardController")
@onready var _evidence_board: Node = get_node("../HideoutEvidenceBoardController")
@onready var _scheme_cards: Node = get_node("../HideoutSchemeCardController")
@onready var _collectibles: Node = get_node("../HideoutCollectibleController")
@onready var _care: Node = get_node("../HideoutCareController")
@onready var _store: Node = get_node("../HideoutStoreController")
@onready var _characters_controller: Node = get_node("../HideoutCharacterController")
@onready var _debug_controller: Node = get_node("../HideoutDebugController")

func _ready() -> void:
	add_to_group("hideout_manager")
	_ensure_state_controller()
	_position_player_spawn()
	_build_world_layers()
	_ensure_decoration_controller()
	_build_navigation_collision()
	_build_stations()
	_build_placement_zones()
	_build_snap_markers()
	_build_required_markers()
	_build_interaction_bridge()
	_ensure_dialogue_box()
	call_deferred("_ensure_dialogue_box")
	_setup_debug_panel()
	if _panel.has_signal("panel_action_pressed"):
		_panel.panel_action_pressed.connect(_on_panel_action_pressed)
	else:
		_panel.action_pressed.connect(_on_panel_action)
	_apply_world_z_order()
	apply_debug_state("fresh")

func _process(_delta: float) -> void:
	_update_prompt()

func open_station(station_id: String, interactable: Node = null, _player: Node = null) -> void:
	var normalized_id := Catalog.normalize_station_id(station_id)
	current_station_id = normalized_id
	# Phase 0M-C3: route the four anchor character interactions to the
	# portrait-aware DialogueBox instead of the station panel. Other
	# stations keep using the existing ScrollableStationPanel flow.
	if normalized_id in _PORTRAIT_DIALOGUE_CHARACTER_IDS:
		_open_character_portrait_dialogue(normalized_id)
		return
	if normalized_id == "store_terminal":
		_open_storefront()
		return
	var panel_data := _panel_data_for(normalized_id, interactable)
	if _panel.has_method("clear_history"):
		_panel.clear_history()
	_panel.open_panel(String(panel_data.get("title", "Hideout Station")), String(panel_data.get("body", "")), panel_data.get("buttons", []))

func _open_character_portrait_dialogue(speaker_id: String) -> void:
	_ensure_dialogue_box()
	# Build a short sequence (3 lines) so the player gets a small dialogue
	# experience but can advance through it quickly with E.
	var lines: Array = HideoutCharacterDialogueBankScript.build_short_sequence(speaker_id, 3)
	if lines.is_empty():
		return
	if DialogueManager.has_method("start_simple_dialogue"):
		DialogueManager.call_deferred("start_simple_dialogue", lines)

func _open_storefront() -> void:
	if _panel != null and _panel.has_method("close_panel") and _panel.has_method("is_open") and _panel.is_open():
		_panel.close_panel()
	if _storefront_panel == null or not is_instance_valid(_storefront_panel):
		var root := get_tree().current_scene
		var ui_root := root.get_node_or_null("UI") if root != null else null
		if ui_root == null:
			push_warning("[HideoutManager] Could not find UI root for storefront; falling back to text store panel.")
			var panel_data := _panel_data_for("store_terminal")
			_panel.open_panel(String(panel_data.get("title", "Store Terminal")), String(panel_data.get("body", "")), panel_data.get("buttons", []))
			return
		_storefront_panel = StorefrontPanelScene.instantiate()
		_storefront_panel.name = "HideoutStorefrontPanel"
		ui_root.add_child(_storefront_panel)
	if _storefront_panel.has_method("set_store_context"):
		_storefront_panel.set_store_context(_store, _state)
	if _storefront_panel.has_method("open_store"):
		_storefront_panel.open_store()

func apply_debug_state(state_id: String) -> void:
	_ensure_state_controller()
	if _state != null and _state.has_method("apply_debug_state"):
		_state.apply_debug_state(state_id)
	current_state = String(_state.get("current_debug_state")) if _state != null else state_id
	var louis_visible := _is_louis_visible_in_state(current_state)
	var louis := _stations.get_node_or_null("Louis")
	if louis:
		louis.visible = louis_visible
		if _has_property(louis, "disabled"):
			louis.set("disabled", not louis_visible)
	var louis_visual := _world.get_node_or_null("PropLayer/Visual_Louis")
	if louis_visual:
		louis_visual.visible = louis_visible
	_set_visual_tint("HeatScanner", Color(1, 0.12, 0.1, 1) if current_state == "high_heat" else Color(0.25, 0.8, 1, 1))
	for id in ["PolaroidWall", "GlowGuyShelf", "TinyIconShelf", "PoopBagCareDisplay", "EvidenceBoard_TheBigCase", "MissionBoard", "StoreTerminal", "BentleyCareStation", "LootCrateDropZone"]:
		_set_visual_tint(id, _state_color(current_state, id))
	if _panel.has_method("is_open") and _panel.is_open() and current_station_id != "":
		open_station(current_station_id)

func _panel_data_for(station_id: String, interactable: Node = null) -> Dictionary:
	var catalog_data := Catalog.get_panel_data(station_id)
	var specialized := _specialized_panel_data_for(station_id)
	if not specialized.is_empty():
		return specialized
	if catalog_data.get("title", "") != "Unknown Station":
		return catalog_data
	if interactable != null:
		var fallback_title := String(interactable.get("panel_title")) if _has_property(interactable, "panel_title") else ""
		var fallback_body := String(interactable.get("panel_body")) if _has_property(interactable, "panel_body") else ""
		if fallback_title != "" or fallback_body != "":
			catalog_data["title"] = fallback_title if fallback_title != "" else "Hideout Station"
			catalog_data["body"] = fallback_body if fallback_body != "" else "This station is wired, but its text has not been filled in yet."
			catalog_data["buttons"] = [{"id": "back", "label": "Back", "action": "close"}]
	return catalog_data

func _specialized_panel_data_for(station_id: String) -> Dictionary:
	_ensure_state_controller()
	match station_id:
		"mission_board":
			return _mission_board.get_panel_data(_state) if _mission_board.has_method("get_panel_data") else {}
		"greenhouse_alcove":
			return _greenhouse_panel_data()
		"evidence_board_big_case":
			return _evidence_board.get_panel_data(_state) if _evidence_board.has_method("get_panel_data") else {}
		"planning_table":
			return _scheme_cards.get_panel_data(_state) if _scheme_cards.has_method("get_panel_data") else {}
		"bentley_care_station":
			return _care.get_panel_data(_state) if _care.has_method("get_panel_data") else {}
		"store_terminal":
			return _store.get_panel_data(_state) if _store.has_method("get_panel_data") else {}
		"loot_crate_drop_zone":
			return _decoration_controller.get_loot_crate_panel_data() if _decoration_controller != null and _decoration_controller.has_method("get_loot_crate_panel_data") else {}
		"open_decor_zone":
			return _decoration_controller.get_open_decor_panel_data() if _decoration_controller != null and _decoration_controller.has_method("get_open_decor_panel_data") else {}
		"polaroid_wall", "glow_guy_shelf", "tiny_icon_shelf", "poop_bag_care_display":
			return _collectibles.get_panel_data(station_id, _state) if _collectibles.has_method("get_panel_data") else {}
		"bentley", "jake", "mere", "louis":
			return _characters_controller.get_panel_data(station_id, _state) if _characters_controller.has_method("get_panel_data") else {}
		_:
			return {}

func _specialized_body_for(station_id: String) -> String:
	match station_id:
		"mission_board":
			return _non_empty_controller_body(_mission_board, "get_panel_body", [current_state], station_id)
		"evidence_board_big_case":
			return _non_empty_controller_body(_evidence_board, "get_panel_body", [current_state], station_id)
		"planning_table":
			return _non_empty_controller_body(_scheme_cards, "get_panel_body", [current_state], station_id)
		"bentley_care_station":
			return _non_empty_controller_body(_care, "get_panel_body", [current_state], station_id)
		"store_terminal":
			return _non_empty_controller_body(_store, "get_panel_body", [current_state], station_id)
		"polaroid_wall", "glow_guy_shelf", "tiny_icon_shelf", "poop_bag_care_display":
			return _non_empty_controller_body(_collectibles, "get_panel_body", [station_id, current_state], station_id)
		"bentley", "jake", "mere", "louis":
			return _non_empty_controller_body(_characters_controller, "dialogue_for", [station_id, current_state], station_id)
		_:
			return ""

func _on_panel_action(action_id: String) -> void:
	if current_station_id == "mission_board" and (action_id == "start_the_taco_bell_drop" or action_id == "start_mission" or action_id == "replay_mission"):
		_mission_board.launch_taco_bell()

func _on_panel_action_pressed(action_id: String, payload: Dictionary) -> void:
	_ensure_state_controller()
	var parsed := _parse_action(action_id, payload)
	var base_action := String(parsed.get("base", action_id))
	var action_value := String(parsed.get("value", ""))
	payload = parsed
	match base_action:
		"back":
			if current_station_id in ["mission_board", "planning_table", "bentley_care_station", "store_terminal", "open_decor_zone", "loot_crate_drop_zone", "evidence_board_big_case", "polaroid_wall", "glow_guy_shelf", "tiny_icon_shelf", "poop_bag_care_display", "greenhouse_alcove"]:
				open_station(current_station_id)
			elif _panel.has_method("go_back"):
				_panel.go_back()
		"close":
			if _panel.has_method("close_panel"):
				_panel.close_panel()
		"launch_taco_bell":
			_open_subpanel(_mission_start_confirmation_data())
		"confirm_launch_taco_bell":
			_write_scheme_loadout_to_game_state()
			_mission_board.launch_taco_bell()
		"go_to_planning_table":
			current_station_id = "planning_table"
			_open_controller_panel(_scheme_cards.get_panel_data(_state))
		"show_known_info":
			_show_feedback("Known Info", "The Taco Bell Drop is ready for delivery. Recover the bag, watch the route, and do not overthink the sauce packets.")
		"replay_mission":
			_mission_board.launch_taco_bell()
		"search_missing_items":
			_show_feedback("Search Missing Items", "Replay placeholder: the next pass can route directly into missing clue/collectible hunts. For now, use Replay Mission or View Missing Items.")
		"view_missing_items":
			_show_feedback("Missing Items", _mission_board.get_panel_body(_state) if _mission_board.has_method("get_panel_body") else "Missing item summary unavailable.")
		"lower_heat_run":
			_show_feedback("Lower Heat Run", "Lower Heat Run is available for completed/replayable Taco Bell only. This is placeholder feedback; heat gameplay is deferred.")
		"clean_getaway_attempt":
			_show_feedback("Clean Getaway Attempt", "Clean Getaway Attempt is scaffolded as a replay goal. No real scoring changes are applied yet.")
		"view_results":
			_show_feedback("The Taco Bell Drop Results", "The Taco Bell Drop Results:\n- Base delivery payout: +50 Case Cash\n- Clean getaway bonus: pending\n- Clue bonus: pending\n- Collectible bonus: pending\n\nCurrent Case Cash: %d" % int(_state.get("case_cash")))
		"show_scheme_cards":
			_open_controller_panel(_scheme_cards.get_panel_data(_state))
		"show_active_slots":
			_show_feedback("Active Scheme Slots", _scheme_cards.get_panel_body(_state) if _scheme_cards.has_method("get_panel_body") else "Active slots unavailable.")
		"equip_scheme_card":
			var card_id := action_value if action_value != "" else String(payload.get("card_id", ""))
			var equip_message: String = _scheme_cards.equip_card(card_id, _state) if _scheme_cards.has_method("equip_card") else "Scheme card handled safely."
			_refresh_root_panel_with_feedback(_scheme_cards.get_panel_data(_state), equip_message)
		"clear_scheme_slot":
			var slot_type := action_value if action_value != "" else String(payload.get("slot_type", ""))
			var clear_slot_message: String = _scheme_cards.clear_slot(slot_type, _state) if _scheme_cards.has_method("clear_slot") else "Slot clear handled safely."
			_refresh_root_panel_with_feedback(_scheme_cards.get_panel_data(_state), clear_slot_message)
		"clear_scheme_loadout":
			var clear_all_message: String = _scheme_cards.clear_loadout(_state) if _scheme_cards.has_method("clear_loadout") else "Loadout clear handled safely."
			_refresh_root_panel_with_feedback(_scheme_cards.get_panel_data(_state), clear_all_message)
		"clear_loadout":
			var clear_message: String = _scheme_cards.clear_loadout(_state) if _scheme_cards.has_method("clear_loadout") else "Loadout clear handled safely."
			_refresh_root_panel_with_feedback(_scheme_cards.get_panel_data(_state), clear_message)
		"show_evidence":
			_open_controller_panel(_evidence_board.get_panel_data(_state, "details"))
		"mark_evidence_reviewed":
			if _evidence_board.has_method("mark_reviewed"):
				_evidence_board.mark_reviewed(_state)
			_open_controller_panel(_evidence_board.get_panel_data(_state, "details"))
		"show_missing_evidence":
			_open_controller_panel(_evidence_board.get_panel_data(_state, "missing"))
		"care_wipe_paws":
			_show_feedback("Bentley Care", "%s\n\n%s" % [_care.wipe_paws(_state), _care.get_panel_body(_state)])
		"care_give_treat":
			_show_feedback("Bentley Care", "%s\n\n%s" % [_care.give_treat(_state), _care.get_panel_body(_state)])
		"care_brush":
			_show_feedback("Bentley Care", "%s\n\n%s" % [_care.brush_bentley(_state), _care.get_panel_body(_state)])
		"care_restock_poop_bags":
			_show_feedback("Bentley Care", "%s\n\n%s" % [_care.restock_poop_bags(_state), _care.get_panel_body(_state)])
		"care_view_poop_bags":
			_open_subpanel({"title": "Poop Bag Collection", "body": _care.poop_bag_summary(_state) if _care.has_method("poop_bag_summary") else "Poop bag collection handled safely.", "buttons": [{"id": "back", "label": "Back", "action": "back"}, {"id": "close", "label": "Close", "action": "close"}]})
		"inspect":
			_show_feedback("Inspect", "This station is wired and ready for a later detailed system.")
		"show_collection":
			var view_id := String(payload.get("view", "summary"))
			if current_station_id in ["polaroid_wall", "glow_guy_shelf", "tiny_icon_shelf", "poop_bag_care_display"]:
				_open_subpanel(_collectibles.get_panel_data(current_station_id, _state, view_id))
			else:
				_show_feedback("Collection", "Decoration placement comes in a later pass.")
		"show_found_collection":
			var display_id := action_value if action_value != "" else current_station_id
			_open_subpanel(_collectibles.get_panel_data(display_id, _state, "found"))
		"show_missing_collection":
			var missing_display_id := action_value if action_value != "" else current_station_id
			_open_subpanel(_collectibles.get_panel_data(missing_display_id, _state, "missing"))
		"arrange_later":
			_show_feedback("Arrange Later", DialogueBank.get_random_line("arrange_later"))
		"show_store_category":
			_open_subpanel(_store.get_panel_data(_state, String(payload.get("category_id", ""))))
		"store_view_category":
			_open_subpanel(_store.get_panel_data(_state, action_value))
		"buy_store_placeholder":
			var purchase_message: String = _store.purchase_placeholder(String(payload.get("item_id", "")), _state) if _store.has_method("purchase_placeholder") else "Store purchase handled safely."
			_refresh_root_panel_with_feedback(_store.get_panel_data(_state, String(payload.get("category_id", ""))), purchase_message)
		"store_buy_item":
			var purchase_item_id := action_value if action_value != "" else String(payload.get("item_id", ""))
			var buy_message: String = _store.purchase_placeholder(purchase_item_id, _state) if _store.has_method("purchase_placeholder") else "Store purchase handled safely."
			var category_id := String(_store.item_by_id(purchase_item_id).get("category", "")) if _store.has_method("item_by_id") else ""
			_refresh_root_panel_with_feedback(_store.get_panel_data(_state, category_id), buy_message)
		"decor_select_item":
			_refresh_root_panel_with_feedback(_decoration_controller.get_open_decor_panel_data(), _decoration_controller.select_item(action_value))
		"decor_select_placed":
			_refresh_root_panel_with_feedback(_decoration_controller.get_open_decor_panel_data(), _decoration_controller.select_placed(action_value))
		"decor_enter_click_to_place_mode", "decor_enter_placement_mode", "enter_click_to_place_mode", "decor_enter_click_to_place", "decor_place_mode":
			var selected_item_id := String(_state.get("selected_placeable_item_id"))
			if selected_item_id == "":
				_refresh_root_panel_with_feedback(_decoration_controller.get_open_decor_panel_data(), "Select an owned decor item first.")
			else:
				_ensure_decorating_mode_controller()
				if _decorating_mode_controller != null:
					_decorating_mode_controller.enter_decorating_mode(selected_item_id)
		"decor_enter_decorating_mode":
			_ensure_decorating_mode_controller()
			if _decorating_mode_controller != null:
				_decorating_mode_controller.enter_decorating_mode("")
		"open_decor_inventory":
			current_station_id = "open_decor_zone"
			_open_controller_panel(_decoration_controller.get_open_decor_panel_data())
		"decor_place_selected":
			var place_message: String = _decoration_controller.place_selected()
			_sync_decorating_visuals()
			_refresh_root_panel_with_feedback(_decoration_controller.get_open_decor_panel_data(), place_message)
		"decor_move_selected":
			var move_message: String = _decoration_controller.move_selected()
			_sync_decorating_visuals()
			_refresh_root_panel_with_feedback(_decoration_controller.get_open_decor_panel_data(), move_message)
		"decor_remove_selected":
			if _decorating_mode_controller != null and _decorating_mode_controller.has_method("is_in_decorating_mode") and _decorating_mode_controller.is_in_decorating_mode():
				_decorating_mode_controller.remove_selected_placed_item()
				_refresh_root_panel_with_feedback(_decoration_controller.get_open_decor_panel_data(), "Removed selected decor. Owned inventory unchanged.")
			else:
				var remove_message: String = _decoration_controller.remove_selected()
				_sync_decorating_visuals()
				_refresh_root_panel_with_feedback(_decoration_controller.get_open_decor_panel_data(), remove_message)
		"decor_clear_all":
			if _decorating_mode_controller != null:
				_decorating_mode_controller.clear_all_placed_decor()
			_refresh_root_panel_with_feedback(_decoration_controller.get_open_decor_panel_data(), _decoration_controller.clear_all())
		"greenhouse_take_breath":
			_show_feedback("Greenhouse Alcove", DialogueBank.get_random_line("greenhouse_take_breath"))
		"greenhouse_water_plants":
			_show_feedback("Greenhouse Alcove", DialogueBank.get_random_line("greenhouse_water_plants"))
		"greenhouse_inspect_skyline":
			_show_feedback("Greenhouse Alcove", DialogueBank.get_random_line("greenhouse_inspect_skyline"))
		"show_placement_zones":
			_show_feedback("Placement Zones", "Placement zones are scaffolded, but drag/drop is not implemented yet.")
		"view_heat":
			_show_feedback("Heat Scanner", "Current heat state: %s.\nCompleted missions can expose lower-heat replay actions. Fresh missions do not show heat controls." % String(_state.get("heat_state")).capitalize())
		"talk":
			var character_id := String(payload.get("character_id", current_station_id))
			var line: String = _characters_controller.next_dialogue(character_id, _state) if _characters_controller.has_method("next_dialogue") else "Conversation handled safely."
			_show_feedback(character_id.capitalize(), line)
		_:
			print("[HideoutManager] Unknown panel action '%s' payload=%s" % [action_id, payload])
			_show_feedback("Under Construction", "Action '%s' is under construction, but it did not crash." % action_id)

func _build_world_layers() -> void:
	_clear_runtime_graybox_visuals()
	if not show_runtime_graybox_debug:
		return
	var floor_layer := _world.get_node("FloorLayer")
	var floor_poly := Polygon2D.new()
	floor_poly.name = "IrregularGarageGreenhouseFloor"
	floor_poly.polygon = _floor_polygon()
	floor_poly.color = Color(0.12, 0.12, 0.13, 1)
	floor_layer.add_child(floor_poly)
	var guide := Line2D.new()
	guide.name = "DashedCirculationPath"
	guide.width = 4.0
	guide.default_color = Color(0.85, 0.85, 0.78, 0.45)
	guide.points = PackedVector2Array([Vector2(-760, -160), Vector2(-360, -260), Vector2(0, -260), Vector2(350, -270), Vector2(690, -180), Vector2(650, 80), Vector2(520, 280), Vector2(220, 315), Vector2(-130, 260), Vector2(-520, 240), Vector2(-790, 120)])
	floor_layer.add_child(guide)
	var wall_layer := _world.get_node("WallLayer")
	_add_window_band(wall_layer, Vector2(0, -635), Vector2(860, 90), "GREENHOUSE ALCOVE\nGlass windows + city view")
	_add_world_label(wall_layer, "THE BIG CASE", Vector2(-90, -470), Color(0.95, 0.78, 0.45, 1))
	_add_world_label(wall_layer, "ANGLED / INSET WALLS - ART REPLACEABLE", Vector2(-770, -330), Color(0.6, 0.7, 0.8, 1))
	var decoration_layer := _world.get_node("DecorationLayer")
	_add_rect_visual(decoration_layer, "CozyLoungeRug", Vector2(-640, 360), Vector2(470, 260), Color(0.34, 0.20, 0.16, 0.9), "COZY LOUNGE")
	_add_rect_visual(decoration_layer, "BentleyBedPlaceholder", Vector2(-800, 390), Vector2(120, 90), Color(0.22, 0.15, 0.10, 1), "BENTLEY BED")
	_add_rect_visual(decoration_layer, "SchemeCardSlotsPlaceholder", Vector2(0, 115), Vector2(300, 52), Color(0.14, 0.22, 0.25, 0.85), "SCHEME CARD SLOTS")
	_add_rect_visual(decoration_layer, "OpenDecorDashedZone", Vector2(470, 120), Vector2(440, 350), Color(0.08, 0.13, 0.14, 0.35), "OPEN DECOR AREA")

func _build_navigation_collision() -> void:
	_clear_children(_collision)
	_clear_children(_walkable_area)
	_add_boundary_walls()
	var walk := Polygon2D.new()
	walk.name = "WalkableAreaPolygon"
	walk.polygon = _floor_polygon()
	walk.color = Color(0.2, 0.45, 0.25, 0.18)
	walk.visible = show_runtime_graybox_debug
	_walkable_area.add_child(walk)

func _build_stations() -> void:
	_clear_children(_stations)
	_clear_runtime_station_visuals()
	for entry in Catalog.stations():
		var station = InteractableScript.new()
		station.name = String(entry["node_name"])
		station.set("interactable_id", String(entry["station_id"]))
		station.set("station_id", String(entry["station_id"]))
		station.set("display_name", String(entry["display_name"]))
		station.set("station_type", String(entry["station_type"]))
		station.set("prompt_text", "Press E: " + String(entry["display_name"]))
		station.set("panel_title", String(entry["panel_title"]))
		station.set("panel_body", String(entry["panel_body"]))
		station.set("interaction_priority", 80 if String(entry["station_id"]) == "mission_board" else 120)
		station.set("panel_buttons", Array(entry["panel_buttons"]))
		station.position = entry["proxy_position"]
		station.set_meta("station_position", entry["position"])
		station.set_meta("proxy_position", entry["proxy_position"])
		station.set_meta("station_id", entry["station_id"])
		station.set_meta("classification", entry["classification"])
		station.add_to_group("hideout_character" if String(entry["station_type"]) == "character" else "hideout_station")
		if String(entry["station_id"]) in ["bentley", "jake", "mere"]:
			station.add_to_group("hideout_core_character")
		if String(entry["station_id"]) == "louis":
			station.add_to_group("hideout_unlockable_character")
		if String(entry["station_type"]).contains("collect"):
			station.add_to_group("hideout_collectible_display")
		if String(entry["station_id"]) == "bentley_care_station":
			station.add_to_group("hideout_care_station")
		if String(entry["station_id"]) == "greenhouse_alcove":
			station.add_to_group("hideout_greenhouse")
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(64, 64)
		shape.shape = rect
		station.add_child(shape)
		var proxy_label := Label.new()
		proxy_label.name = "InteractionProxy"
		proxy_label.position = Vector2(-46, 28)
		proxy_label.text = "E"
		proxy_label.add_theme_color_override("font_color", Color(0.8, 1, 0.8, 1))
		proxy_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		proxy_label.add_theme_constant_override("outline_size", 4)
		proxy_label.add_theme_font_size_override("font_size", 16)
		proxy_label.visible = show_station_proxy_debug_labels
		station.add_child(proxy_label)
		_stations.add_child(station)
		if show_runtime_graybox_debug:
			_make_station_visual(entry)

func _make_station_visual(entry: Dictionary) -> void:
	var prop_layer := _world.get_node("PropLayer")
	var holder := Node2D.new()
	holder.name = "Visual_" + String(entry["node_name"])
	holder.position = entry["position"]
	holder.add_to_group("hideout_progression_visual")
	prop_layer.add_child(holder)
	var box := Polygon2D.new()
	box.name = "ReplaceableGrayboxProp"
	box.polygon = _visual_polygon_for(String(entry["station_id"]))
	box.color = Color(0.24, 0.25, 0.28, 1)
	holder.add_child(box)
	_add_world_label(holder, String(entry["display_name"]), Vector2(-72, -58), Color(1, 0.95, 0.72, 1))

func _build_placement_zones() -> void:
	_clear_children(_placement_zones)
	var zones := {
		"WallZone_North": [Vector2(0, -455), Vector2(880, 120), ["wall_item", "mission_trophy"]],
		"WallZone_West": [Vector2(-865, 10), Vector2(230, 560), ["wall_item", "shelf_item"]],
		"PolaroidWallZone": [Vector2(-850, -230), Vector2(220, 130), ["wall_item"]],
		"ShelfZone_GlowGuys": [Vector2(-880, -40), Vector2(220, 110), ["shelf_item"]],
		"ShelfZone_TinyIcons": [Vector2(-880, 110), Vector2(220, 110), ["shelf_item"]],
		"ShelfZone_Trophies": [Vector2(-840, 250), Vector2(220, 110), ["mission_trophy"]],
		"TableZone_Planning": [Vector2(0, 20), Vector2(420, 230), ["tabletop_item"]],
		"FloorZone_OpenDecor": [Vector2(470, 120), Vector2(440, 350), ["floor_item", "rug", "large_furniture"]],
		"BentleyZone": [Vector2(-705, 360), Vector2(360, 240), ["bentley_item"]],
		"CareStationZone": [Vector2(555, 350), Vector2(260, 170), ["care_station_item", "bentley_item"]],
		"StoreDeliveryZone": [Vector2(785, 20), Vector2(260, 460), ["floor_item", "large_furniture", "mission_trophy"]],
	}
	for zone_id in zones.keys():
		var data: Array = zones[zone_id]
		var zone = PlacementZoneScript.new()
		zone.name = zone_id
		zone.set("zone_id", zone_id)
		zone.set("zone_display_name", zone_id.replace("_", " "))
		var allowed: Array[String] = []
		allowed.assign(data[2])
		zone.set("allowed_tags", allowed)
		zone.set("description", "0M-A snap/placement scaffold. No drag/drop behavior yet.")
		zone.position = data[0]
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = data[1]
		shape.shape = rect
		zone.add_child(shape)
		_placement_zones.add_child(zone)

func _build_snap_markers() -> void:
	_clear_children(_snap_markers)
	var containers := ["MissionCardSlots", "EvidenceClueSlots", "PolaroidSlots", "GlowGuySlots", "TinyIconSlots", "PoopBagSlots", "CareItemSlots", "SchemeCardSlots", "FurnitureAnchors", "StoreDeliveryAnchors"]
	for container_name in containers:
		var container := Node2D.new()
		container.name = container_name
		_snap_markers.add_child(container)
		var count := 11 if container_name == "MissionCardSlots" else 4
		for i in range(count):
			var marker := Marker2D.new()
			marker.name = "Marker_%s_%02d" % [container_name.trim_suffix("Slots").trim_suffix("Anchors"), i + 1]
			marker.position = _snap_marker_position(container_name, i)
			marker.add_to_group("hideout_snap_zone")
			container.add_child(marker)

func _build_required_markers() -> void:
	var marker_root := get_parent().get_node_or_null("GameplayRoot/SpawnMarkers")
	if marker_root == null:
		return
	for child in marker_root.get_children():
		if String(child.name).begins_with("Marker_") and child.name not in ["Marker_PlayerSpawn_Return", "Marker_PlayerSpawn_FromMenu"]:
			child.queue_free()
	var markers := {
		"Marker_PlayerSpawn_Return": Vector2(650, 360),
		"Marker_PlayerSpawn_FromMenu": Vector2(650, 360),
		"Marker_EntryExitDoor": Vector2(760, 430),
		"Marker_LootCrateSpawn": Vector2(210, 350),
		"Marker_BentleyCareStation": Vector2(520, 330),
		"Marker_BentleyWipeSpot": Vector2(490, 360),
		"Marker_BentleyTreatSpot": Vector2(540, 360),
		"Marker_BentleyBrushSpot": Vector2(580, 330),
		"Marker_BentleyBed": Vector2(-800, 390),
		"Marker_BentleyIdle_01": Vector2(-760, 350),
		"Marker_BentleyIdle_02": Vector2(-710, 390),
		"Marker_JakeIdle_01": Vector2(-560, 300),
		"Marker_JakeDialogueSpot": Vector2(-525, 265),
		"Marker_MereIdle_01": Vector2(-420, 300),
		"Marker_MereDialogueSpot": Vector2(-455, 265),
		"Marker_LouisIdle_Store": Vector2(820, 130),
		"Marker_LouisDialogueSpot": Vector2(780, 120),
		"Marker_StoreDeliverySpawn": Vector2(745, 205),
		"Marker_FurnitureAnchor_01": Vector2(340, 65),
		"Marker_FurnitureAnchor_02": Vector2(475, 120),
		"Marker_FurnitureAnchor_03": Vector2(610, 205),
		"Marker_RugAnchor_01": Vector2(470, 225),
		"Marker_WallDecorAnchor_01": Vector2(-120, -500),
		"Marker_WallDecorAnchor_02": Vector2(155, -500),
	}
	for i in range(11):
		markers["Marker_MissionCard_%02d" % [i + 1]] = Vector2(410 + (i % 4) * 75, -450 + int(i / 4) * 46)
	for i in range(3):
		markers["Marker_Evidence_TacoBell_%02d" % [i + 1]] = Vector2(-160 + i * 80, -455)
		markers["Marker_Evidence_BigCase_%02d" % [i + 1]] = Vector2(-160 + i * 80, -400)
	for item in {
		"Marker_Polaroid_TacoBell_01": Vector2(-850, -230),
		"Marker_GlowGuy_TacoBell_01": Vector2(-880, -40),
		"Marker_TinyIcon_TacoBell_01": Vector2(-880, 110),
		"Marker_TinyIcon_TacoBell_02": Vector2(-810, 110),
		"Marker_PoopBag_TacoBell_01": Vector2(-840, 250),
	}.keys():
		markers[item] = {
			"Marker_Polaroid_TacoBell_01": Vector2(-850, -230),
			"Marker_GlowGuy_TacoBell_01": Vector2(-880, -40),
			"Marker_TinyIcon_TacoBell_01": Vector2(-880, 110),
			"Marker_TinyIcon_TacoBell_02": Vector2(-810, 110),
			"Marker_PoopBag_TacoBell_01": Vector2(-840, 250),
		}[item]
	for i in range(4):
		markers["Marker_SchemeSlot_%02d" % [i + 1]] = Vector2(-90 + i * 60, 115)
	for marker_name in markers.keys():
		var marker := marker_root.get_node_or_null(marker_name) as Marker2D
		if marker == null:
			marker = Marker2D.new()
			marker.name = marker_name
			marker_root.add_child(marker)
		marker.position = markers[marker_name]

func _setup_debug_panel() -> void:
	_debug_controller.debug_state_requested.connect(apply_debug_state)
	_debug_controller.connect_buttons(get_node(debug_buttons_path))

func _ensure_state_controller() -> void:
	if _state != null and is_instance_valid(_state):
		return
	_state = get_node_or_null("../HideoutStateController")
	if _state == null:
		_state = StateControllerScript.new()
		_state.name = "HideoutStateController"
		get_parent().call_deferred("add_child", _state)

func _ensure_decoration_controller() -> void:
	if _decoration_controller != null and is_instance_valid(_decoration_controller):
		return
	_decoration_controller = get_node_or_null("../HideoutDecorationController")
	if _decoration_controller == null:
		_decoration_controller = DecorationControllerScript.new()
		_decoration_controller.name = "HideoutDecorationController"
		get_parent().add_child(_decoration_controller)
	var decor_layer := _world.get_node_or_null("DecorationLayer")
	var placed_container := decor_layer.get_node_or_null("PlacedDecor") if decor_layer != null else null
	if decor_layer != null and placed_container == null:
		placed_container = Node2D.new()
		placed_container.name = "PlacedDecor"
		decor_layer.add_child(placed_container)
	if _decoration_controller.has_method("configure"):
		_decoration_controller.configure(_state, placed_container)

func _ensure_decorating_mode_controller() -> void:
	if _decorating_mode_controller != null and is_instance_valid(_decorating_mode_controller):
		return
	_decorating_mode_controller = get_node_or_null("../HideoutDecoratingModeController")
	if _decorating_mode_controller == null:
		var controller_script: Script = load("res://src/hideout/HideoutDecoratingModeController.gd") as Script
		if controller_script == null:
			_show_feedback("Decorating Mode", "Decorating Mode script failed to load. Open Decor anchor buttons are still available.")
			return
		_decorating_mode_controller = controller_script.new()
		_decorating_mode_controller.name = "HideoutDecoratingModeController"
		get_parent().add_child(_decorating_mode_controller)
	var decor_layer := _world.get_node_or_null("DecorationLayer")
	var placed_container := decor_layer.get_node_or_null("PlacedDecor") if decor_layer != null else null
	var ui_root := get_node_or_null("../../../UI") as CanvasLayer
	if _decorating_mode_controller.has_method("configure"):
		_decorating_mode_controller.configure(_state, placed_container, _panel, ui_root)

func _sync_decorating_visuals() -> void:
	if _decorating_mode_controller == null:
		return
	if _decorating_mode_controller.has_method("rebuild_placed_visuals"):
		_decorating_mode_controller.rebuild_placed_visuals()

func _build_interaction_bridge() -> void:
	var existing := get_parent().get_node_or_null("HideoutInteractionBridge")
	if existing != null:
		return
	var bridge = InteractionBridgeScript.new()
	bridge.name = "HideoutInteractionBridge"
	bridge.set("player_path", NodePath("../../Characters/Player"))
	get_parent().add_child(bridge)

func _ensure_dialogue_box() -> void:
	var scene_root := _scene_root()
	if scene_root == null:
		return
	var existing := scene_root.get_node_or_null("DialogueBox")
	if existing != null and is_instance_valid(existing):
		return
	var dialogue_box := DialogueBoxScene.instantiate()
	dialogue_box.name = "DialogueBox"
	scene_root.add_child(dialogue_box)

func _scene_root() -> Node:
	if get_tree().current_scene != null:
		return get_tree().current_scene
	var node := self
	while node.get_parent() != null and node.get_parent() != get_tree().root:
		node = node.get_parent()
	return node

func _is_louis_visible_in_state(state_id: String) -> bool:
	return state_id in ["taco_bell_completed", "taco_bell_missing_items", "high_heat", "louis_unlocked"]

func _update_prompt() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null or _panel.visible:
		_prompt.hide()
		return
	var best: Node = null
	var best_dist := INF
	for node in get_tree().get_nodes_in_group("hideout_interactable"):
		if node is Node2D and node.has_method("is_interaction_available") and node.is_interaction_available(player):
			var dist := player.global_position.distance_to(node.global_position)
			if dist < best_dist:
				best = node
				best_dist = dist
	if best:
		_prompt.text = best.get_prompt_text()
		_prompt.show()
	else:
		_prompt.hide()

func _station_entry(station_id: String) -> Dictionary:
	for entry in Catalog.stations():
		if String(entry.get("station_id", "")) == station_id:
			return entry
	return {}

func _non_empty_controller_body(controller: Node, method_name: String, args: Array, station_id: String) -> String:
	if controller == null or not controller.has_method(method_name):
		return ""
	var result = controller.callv(method_name, args)
	var text := String(result)
	if text.strip_edges() == "":
		print("[HideoutManager] Specialized controller empty for %s; using catalog fallback." % station_id)
		return ""
	return text

func _show_feedback(title: String, message: String) -> void:
	_panel.open_subpanel(title, message, [{"id": "back", "label": "Back", "action": "back"}, {"id": "close", "label": "Close", "action": "close"}])

func _open_controller_panel(data: Dictionary) -> void:
	_panel.open_panel(String(data.get("title", "Hideout Station")), String(data.get("body", "")), data.get("buttons", [{"id": "close", "label": "Close", "action": "close"}]))

func _open_subpanel(data: Dictionary) -> void:
	_panel.open_subpanel(String(data.get("title", "Hideout Station")), String(data.get("body", "")), data.get("buttons", [{"id": "back", "label": "Back", "action": "back"}, {"id": "close", "label": "Close", "action": "close"}]))

func _refresh_root_panel_with_feedback(data: Dictionary, feedback: String) -> void:
	var body := String(data.get("body", ""))
	if feedback.strip_edges() != "":
		body = "%s\n\n%s" % [feedback, body]
	_panel.open_panel(String(data.get("title", "Hideout Station")), body, data.get("buttons", [{"id": "close", "label": "Close", "action": "close"}]))

func _parse_action(action_id: String, payload: Dictionary) -> Dictionary:
	var parsed := payload.duplicate(true)
	var parts := action_id.split(":", false, 1)
	parsed["base"] = parts[0]
	parsed["value"] = parts[1] if parts.size() > 1 else ""
	return parsed

func _mission_start_confirmation_data() -> Dictionary:
	var loadout: Dictionary = _state.get_current_scheme_loadout() if _state != null and _state.has_method("get_current_scheme_loadout") else {}
	var plan: String = _scheme_cards.card_name(String(loadout.get("plan", ""))) if _scheme_cards.has_method("card_name") else "Empty"
	var trick: String = _scheme_cards.card_name(String(loadout.get("trick", ""))) if _scheme_cards.has_method("card_name") else "Empty"
	var comfort: String = _scheme_cards.card_name(String(loadout.get("comfort_chaos", ""))) if _scheme_cards.has_method("card_name") else "Empty"
	var lines: Array[String] = [
		"Ready for The Taco Bell Drop?",
		"",
		DialogueBank.get_random_line("mission_start_warning"),
		"Double-check your scheme cards before starting.",
		"",
		"Current Plan Card: %s" % plan,
		"Current Trick Card: %s" % trick,
		"Current Comfort/Chaos Card: %s" % comfort,
	]
	if plan == "Empty" or trick == "Empty" or comfort == "Empty":
		lines.append("")
		lines.append("One or more scheme slots are empty.")
	lines.append("")
	lines.append("Routes and mission choices belong at the Planning Table, not the Mission Board.")
	return {
		"title": "Ready for The Taco Bell Drop?",
		"body": "\n".join(lines),
		"buttons": [
			{"id": "confirm_launch", "label": "Start Mission", "action": "confirm_launch_taco_bell"},
			{"id": "go_planning", "label": "Go to Planning Table", "action": "go_to_planning_table"},
			{"id": "back", "label": "Back", "action": "back"},
			{"id": "close", "label": "Close", "action": "close"},
		],
	}

func _write_scheme_loadout_to_game_state() -> void:
	if _state == null or not _state.has_method("get_current_scheme_loadout"):
		return
	var loadout: Dictionary = _state.get_current_scheme_loadout()
	if is_inside_tree() and get_tree().root.get_node_or_null("GameState") != null:
		if GameState.has_method("set_current_scheme_loadout"):
			GameState.set_current_scheme_loadout(loadout)
		else:
			GameState.set("current_scheme_loadout", loadout)

func _greenhouse_panel_data() -> Dictionary:
	return {
		"title": "Greenhouse Alcove",
		"body": "%s\n\nThe city looks beautiful from here, which is rude given the circumstances." % DialogueBank.get_random_line("greenhouse_interaction"),
		"buttons": [
			{"id": "take_breath", "label": "Take a Breath", "action": "greenhouse_take_breath"},
			{"id": "water_plants", "label": "Water Suspicious Plants", "action": "greenhouse_water_plants"},
			{"id": "inspect_skyline", "label": "Inspect the Skyline", "action": "greenhouse_inspect_skyline"},
			{"id": "close", "label": "Close", "action": "close"},
		],
	}

func _has_property(node: Object, property_name: String) -> bool:
	for property in node.get_property_list():
		if String(property.get("name", "")) == property_name:
			return true
	return false

func _state_color(state_id: String, visual_id: String) -> Color:
	if state_id == "high_heat":
		return Color(0.9, 0.12, 0.08, 1)
	if state_id == "fresh":
		return Color(0.24, 0.25, 0.28, 1)
	if visual_id in ["PolaroidWall", "GlowGuyShelf", "TinyIconShelf", "PoopBagCareDisplay", "EvidenceBoard_TheBigCase", "MissionBoard", "StoreTerminal", "BentleyCareStation"]:
		return Color(0.18, 0.46, 0.36, 1)
	return Color(0.24, 0.25, 0.28, 1)

func _set_visual_tint(node_name: String, color: Color) -> void:
	var visual := _world.get_node_or_null("PropLayer/Visual_" + node_name + "/ReplaceableGrayboxProp")
	if visual is Polygon2D:
		visual.color = color

func _add_boundary_walls() -> void:
	var body := StaticBody2D.new()
	body.name = "BoundaryWalls"
	_collision.add_child(body)
	var points := _floor_polygon()
	var thickness := 64.0
	var overlap_margin := 48.0
	for i in range(points.size()):
		var start := points[i]
		var end := points[(i + 1) % points.size()]
		var segment := end - start
		var shape := CollisionShape2D.new()
		shape.name = "BoundarySegment_%02d" % [i + 1]
		shape.position = start + segment * 0.5
		shape.rotation = segment.angle()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(segment.length() + overlap_margin, thickness)
		shape.shape = rect
		body.add_child(shape)

func _floor_polygon() -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(-960, -250),
		Vector2(-820, -430),
		Vector2(-500, -430),
		Vector2(-430, -690),
		Vector2(430, -690),
		Vector2(500, -430),
		Vector2(790, -430),
		Vector2(960, -260),
		Vector2(960, 340),
		Vector2(800, 500),
		Vector2(470, 500),
		Vector2(330, 420),
		Vector2(-360, 420),
		Vector2(-500, 520),
		Vector2(-900, 520),
		Vector2(-1040, 360),
		Vector2(-1040, -120),
	])

func _apply_world_z_order() -> void:
	var gameplay_root := get_parent().get_parent()
	if gameplay_root is Node2D:
		gameplay_root.z_index = 0
	_world.z_index = 0
	var layer_z := {
		"FloorLayer": -300,
		"WallLayer": -200,
		"PropLayer": -100,
		"DecorationLayer": -80,
		"CollectibleLayer": -60,
		"CharacterVisualLayer": 10,
		"PVG_CatalogPaintLayers": -300,
		"PVG_DepthPaintLayers": 0,
		"PVG_CentralSecurityPaintLayers": -300,
		"PVG_CentralSecurityDepthPaintLayers": 0,
		"QuarantinedOldPVGamesVisuals_0MB5": -500,
		"ForegroundLayer": 150,
		"LightingLayer": 200,
		"EditorGuideLayer": 260,
	}
	for layer_name in layer_z.keys():
		var layer := _world.get_node_or_null(layer_name)
		if layer is Node2D:
			layer.z_index = int(layer_z[layer_name])
			layer.y_sort_enabled = false
	_characters.z_index = 20
	_stations.z_index = 25
	_placement_zones.z_index = 5
	var player := _characters.get_node_or_null("Player")
	if player is Node2D:
		player.z_index = 30
		player.y_sort_enabled = false

func _position_player_spawn() -> void:
	var player := _characters.get_node_or_null("Player")
	if player is Node2D:
		player.position = Vector2(650, 360)

func _clear_runtime_graybox_visuals() -> void:
	for path in ["FloorLayer", "WallLayer", "DecorationLayer"]:
		var layer := _world.get_node_or_null(path)
		if layer != null:
			for child in layer.get_children():
				if not _is_runtime_graybox_visual(child):
					continue
				child.free()

func _clear_runtime_station_visuals() -> void:
	var prop_layer := _world.get_node_or_null("PropLayer")
	if prop_layer == null:
		return
	for child in prop_layer.get_children():
		if String(child.name).begins_with("Visual_"):
			child.free()

func _is_runtime_graybox_visual(node: Node) -> bool:
	var node_name := String(node.name)
	return node_name in [
		"IrregularGarageGreenhouseFloor",
		"DashedCirculationPath",
		"GreenhouseAlcoveGlass",
		"CozyLoungeRug",
		"BentleyBedPlaceholder",
		"SchemeCardSlotsPlaceholder",
		"OpenDecorDashedZone",
	] or node_name.begins_with("Label_")

func _clear_children(parent: Node) -> void:
	for child in parent.get_children():
		child.free()

func _visual_polygon_for(station_id: String) -> PackedVector2Array:
	match station_id:
		"planning_table":
			return PackedVector2Array([Vector2(-180, -90), Vector2(180, -90), Vector2(180, 90), Vector2(-180, 90)])
		"open_decor_zone":
			return PackedVector2Array([Vector2(-220, -175), Vector2(220, -175), Vector2(220, 175), Vector2(-220, 175)])
		"mission_board", "evidence_board_big_case", "polaroid_wall", "glow_guy_shelf", "tiny_icon_shelf", "poop_bag_care_display":
			return PackedVector2Array([Vector2(-95, -50), Vector2(95, -50), Vector2(95, 50), Vector2(-95, 50)])
		"loot_crate_drop_zone":
			return PackedVector2Array([Vector2(-70, -70), Vector2(70, -70), Vector2(70, 70), Vector2(-70, 70)])
		"entry_exit_door":
			return PackedVector2Array([Vector2(-70, -90), Vector2(70, -90), Vector2(70, 90), Vector2(-70, 90)])
		_:
			return PackedVector2Array([Vector2(-64, -36), Vector2(64, -36), Vector2(64, 36), Vector2(-64, 36)])

func _snap_marker_position(container_name: String, index: int) -> Vector2:
	match container_name:
		"MissionCardSlots":
			return Vector2(410 + (index % 4) * 75, -450 + int(index / 4) * 46)
		"EvidenceClueSlots":
			return Vector2(-160 + (index % 3) * 80, -455 + int(index / 3) * 55)
		"PolaroidSlots":
			return Vector2(-890, -260 + index * 34)
		"GlowGuySlots":
			return Vector2(-915, -70 + index * 34)
		"TinyIconSlots":
			return Vector2(-915, 80 + index * 34)
		"PoopBagSlots":
			return Vector2(-875, 220 + index * 34)
		"CareItemSlots":
			return Vector2(480 + index * 38, 385)
		"SchemeCardSlots":
			return Vector2(-90 + index * 60, 115)
		"FurnitureAnchors":
			return Vector2(340 + (index % 2) * 140, 65 + int(index / 2) * 125)
		"StoreDeliveryAnchors":
			return Vector2(710 + (index % 2) * 55, 180 + int(index / 2) * 55)
		_:
			return Vector2((index % 6) * 45, int(index / 6) * 45)

func _add_window_band(parent: Node, pos: Vector2, size: Vector2, text: String) -> void:
	_add_rect_visual(parent, "GreenhouseAlcoveGlass", pos, size, Color(0.08, 0.28, 0.30, 0.9), text)

func _add_rect_visual(parent: Node, node_name: String, pos: Vector2, size: Vector2, color: Color, text: String) -> void:
	var holder := Node2D.new()
	holder.name = node_name
	holder.position = pos
	parent.add_child(holder)
	var poly := Polygon2D.new()
	poly.name = "ReplaceableGraybox"
	var half := size * 0.5
	poly.polygon = PackedVector2Array([Vector2(-half.x, -half.y), Vector2(half.x, -half.y), Vector2(half.x, half.y), Vector2(-half.x, half.y)])
	poly.color = color
	holder.add_child(poly)
	_add_world_label(holder, text, Vector2(-half.x + 12, -half.y + 10), Color(0.85, 1, 0.9, 1))

func _add_world_label(parent: Node, text: String, pos: Vector2, color: Color) -> void:
	var label := Label.new()
	label.name = "Label_" + text.replace(" ", "_").replace("/", "_")
	label.position = pos
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	label.add_theme_constant_override("outline_size", 5)
	label.add_theme_font_size_override("font_size", 16)
	parent.add_child(label)
