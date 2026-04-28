extends "res://src/levels/LevelBase.gd"

var bag_collected := false

func _ready() -> void:
	mission_id = "taco_bell_drop"
	objective_text = "Recover Louis's delivery bag, then reach the exit."
	super._ready()
	var bag := get_node_or_null("BagPickupZone")
	if bag:
		bag.add_to_group("interactable")
		bag.body_entered.connect(_on_bag_body_entered)
	var trail := get_node_or_null("SniffTrail")
	if trail:
		trail.visible = GameState.has_selected_card("fish_treat_focus") or GameState.has_selected_card("two_letters_away")

func _on_bag_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		bag_collected = true
		QuestManager.set_objective("Bag recovered. Reach the exit.", mission_id)
		var bag := get_node_or_null("BagPickupZone")
		if bag:
			bag.visible = false
		AudioManager.play_sfx("item_pickup")

func complete_level() -> void:
	if not bag_collected:
		QuestManager.set_objective("Bentley insists the bag comes with us.", mission_id)
		return
	# Collect polaroid on completion
	CollectibleManager.collect_polaroid("taco_bell_polaroid")
	super.complete_level()
