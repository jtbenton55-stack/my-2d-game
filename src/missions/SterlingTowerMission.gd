extends "res://src/levels/LevelBase.gd"

var vault_cracked := false
var final_message_shown := false

func _ready() -> void:
	mission_id = "sterling_tower_heist"
	objective_text = "Crack the vault. Every favor comes due."
	guard_count = 6
	super._ready()
	
	var vault := get_node_or_null("VaultZone")
	if vault:
		vault.add_to_group("interactable")
		vault.body_entered.connect(_on_vault_body_entered)
	
	# Show opening dialogue
	DialogueManager.start_simple_dialogue([
		{ "speaker": "Jake", "text": "This is it. Sterling's vault. Every crew member we helped is here with us." },
		{ "speaker": "Bentley", "text": "*intense dental stare*" },
		{ "speaker": "Jake", "text": "Let's finish this." }
	])

func _on_vault_body_entered(body: Node) -> void:
	if body.is_in_group("player") and not vault_cracked:
		vault_cracked = true
		QuestManager.set_objective("Vault cracked! Exit through the lobby!", mission_id)
		var vault := get_node_or_null("VaultZone")
		if vault:
			vault.visible = false
		AudioManager.play_sfx("vault_open")
		
		# Show victory dialogue
		DialogueManager.start_simple_dialogue([
			{ "speaker": "Jake", "text": "We did it. All of us. Every favor, every risk." },
			{ "speaker": "Bentley", "text": "*approving woof*" }
		])

func complete_level() -> void:
	if not vault_cracked:
		QuestManager.set_objective("The vault holds everything. We need inside.", mission_id)
		return
	
	if not final_message_shown:
		final_message_shown = true
		DialogueManager.start_simple_dialogue([
			{ "speaker": "Jake", "text": "Sterling's finished. And we did it together." },
			{ "speaker": "Mere", "text": "Creative collaboration always wins. Even in a heist." },
			{ "speaker": "Dom", "text": "Fast family. Forever." },
			{ "speaker": "Louis", "text": "I knew my routes would pay off!" },
			{ "speaker": "Yordano", "text": "The rhythm of revenge is sweet." },
			{ "speaker": "Bentley", "text": "*happy bark*" }
		])
	
	CollectibleManager.collect_polaroid("final_crew_polaroid")
	super.complete_level()
