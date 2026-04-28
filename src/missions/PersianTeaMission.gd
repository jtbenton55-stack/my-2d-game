extends "res://src/missions/InteractiveMission.gd"

# Persian Tea and Poison Ink - Mission 4
# Warm cultural/emotional mission with tea brewing mechanics

var ingredients_collected := {"sour_cherry": false, "cardamom": false, "saffron": false}
var tea_brewed := false
var drawer_revealed := false
var has_sour_buff := false
var jc_dialogue_started := false

func _ready() -> void:
	super._ready()
	_setup_dialogue_triggers()
	_setup_tea_station()
	_setup_drawer_logic()

func _setup_dialogue_triggers() -> void:
	var jc_dialogue := get_node_or_null("JC_Dialogue")
	if jc_dialogue:
		var interact_zone := jc_dialogue.get_node_or_null("InteractZone")
		if interact_zone:
			interact_zone.body_entered.connect(_on_jc_dialogue_triggered)
			interact_zone.add_to_group("interactable")

func _on_jc_dialogue_triggered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if jc_dialogue_started:
		return
	jc_dialogue_started = true
	
	var jc_node := get_node_or_null("JC_Dialogue")
	if jc_node and jc_node.has_method("start_dialogue"):
		jc_node.start_dialogue()
		QuestManager.set_objective("Collect the three tea ingredients from the garden.", get_mission_id())
	
	# Bentley comment
	EventBus.dialogue_ended.connect(_bentley_tea_comment, CONNECT_ONE_SHOT)

func _bentley_tea_comment() -> void:
	DialogueManager.show_dialogue("Bentley", "*wags tail hopefully* Woof.")

func _setup_tea_station() -> void:
	var tea_station := get_node_or_null("TeaStation")
	if tea_station:
		tea_station.body_entered.connect(_on_tea_station_approached)

func _on_tea_station_approached(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if tea_brewed:
		return
	
	var all_ingredients: bool = ingredients_collected["sour_cherry"] and ingredients_collected["cardamom"] and ingredients_collected["saffron"]
	if all_ingredients:
		_brew_tea()

func _brew_tea() -> void:
	tea_brewed = true
	AudioManager.play_sfx("item_craft")
	QuestManager.set_objective("The tea blend is perfect. The hidden drawer should now open.", get_mission_id())
	
	# Reveal the hidden drawer
	var drawer_zone := get_node_or_null("HiddenDrawerZone")
	if drawer_zone:
		drawer_zone.visible = true
	var drawer_label := get_node_or_null("HiddenDrawerZone/HiddenDrawerLabel")
	if drawer_label:
		drawer_label.visible = true
	
	# Make drawer interactable
	var drawer_interact := get_node_or_null("HiddenDrawerInteract")
	if drawer_interact:
		drawer_interact.visible = true
		var drawer_visual := drawer_interact.get_node_or_null("Visual")
		if drawer_visual:
			drawer_visual.visible = true
		var label := drawer_interact.get_node_or_null("Label")
		if label:
			label.visible = true
		drawer_revealed = true
	
	DialogueManager.show_dialogue("JC", "Perfect! The drawer opens when the tea is ready. You have a gift for this.")
	
	# Bentley comment on the tea
	EventBus.dialogue_ended.connect(_bentley_drawer_comment, CONNECT_ONE_SHOT)

func _bentley_drawer_comment() -> void:
	DialogueManager.show_dialogue("Bentley", "*sniffs the tea steam and sneezes* ...Woof.")

func _setup_drawer_logic() -> void:
	var drawer := get_node_or_null("HiddenDrawerInteract")
	if drawer:
		drawer.body_entered.connect(_on_drawer_opened)

func _on_drawer_opened(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if not drawer_revealed:
		return
	
	# Check for sour buff
	var sour_item := get_node_or_null("Optional_SourItem")
	if sour_item and not has_sour_buff:
		_check_sour_item()

func _check_sour_item() -> void:
	# Trigger Bentley judgment if player ate the sour item
	DialogueManager.show_dialogue("Bentley", "*judgmental stare* You ate that WHOLE jar of sour plums? Your dental bill is going to be... significant. I'm calling you 'Dental Boy' now.")
	has_sour_buff = true
	# Could apply a gameplay buff here if desired

func _on_required_entered(body: Node, zone: Area2D) -> void:
	if not body.is_in_group("player"):
		return
	
	var zone_name := zone.name
	if zone_name == "Objective_SourCherry":
		ingredients_collected["sour_cherry"] = true
		DialogueManager.show_dialogue("JC", "Ah, the albaloo! Sour cherries for remembrance.")
	elif zone_name == "Objective_Cardamom":
		ingredients_collected["cardamom"] = true
		DialogueManager.show_dialogue("JC", "Hel — cardamom for clarity of mind.")
	elif zone_name == "Objective_Saffron":
		ingredients_collected["saffron"] = true
		DialogueManager.show_dialogue("JC", "Zaferan! Saffron threads, more precious than gold.")
	
	super._on_required_entered(body, zone)
	
	# Update objective if all ingredients collected
	var all_collected: bool = ingredients_collected["sour_cherry"] and ingredients_collected["cardamom"] and ingredients_collected["saffron"]
	if all_collected and not tea_brewed:
		QuestManager.set_objective("Return to the tea station to brew the blend.", get_mission_id())

func _on_optional_entered(body: Node, zone: Area2D) -> void:
	if not body.is_in_group("player"):
		return
	
	var zone_name := zone.name
	if zone_name == "Optional_SourItem":
		_check_sour_item()
	
	super._on_optional_entered(body, zone)

func complete_level() -> void:
	if not tea_brewed:
		QuestManager.set_objective("The tea must be brewed before we can leave. JC is waiting.", get_mission_id())
		return
	if not drawer_revealed:
		QuestManager.set_objective("The hidden drawer holds the evidence we need.", get_mission_id())
		return
	
	# Collect polaroid if not already
	if not CollectibleManager.has_polaroid("conservatory_serenity"):
		CollectibleManager.collect_polaroid("conservatory_serenity")
	
	# Final warm dialogue
	DialogueManager.show_dialogue("JC", "Come back anytime, friend. The tea is always ready for you.")
	
	super.complete_level()
