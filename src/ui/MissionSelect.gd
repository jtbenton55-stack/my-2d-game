extends Control

const MISSION_BUTTON_SCENE_PATH := "res://scenes/ui/MissionButton.tscn"
## Story missions in Mission Bible v2 act order (Act 1 / Act 2 / Act 3 / finale).
const STORY_MISSION_ORDER: Array[String] = [
	"taco_bell_drop",
	"velvet_paw_jazz_club",
	"rewrite_room",
	"clean_job",
	"diamond_a_year_job",
	"fast_family_getaway",
	"persian_tea_poison_ink",
	"elephant_in_the_room",
	"shadow_solo_contract",
	"sterling_tower_heist"
]
## Optional Night Jobs side track (Mission Bible v2). "planned" catalog stubs are skipped at runtime.
const NIGHT_JOB_ORDER: Array[String] = [
	"corner_store_cashout",
	"arm_wrestling_underground",
	"laundromat_heist",
	"bentleys_walk"
]

@onready var missions_container: VBoxContainer = $Panel/ScrollContainer/MissionsContainer
@onready var back_button: Button = $BackButton
@onready var title_label: Label = $TitleLabel
@onready var dossier_panel: Panel = $DossierPanel
@onready var dossier_title: Label = $DossierPanel/DossierTitle
@onready var dossier_description: Label = $DossierPanel/DossierDescription
@onready var dossier_objectives: Label = $DossierPanel/DossierObjectives
@onready var dossier_cards: Label = $DossierPanel/DossierCards
@onready var dossier_rewards: Label = $DossierPanel/DossierRewards
@onready var start_button: Button = $DossierPanel/StartButton
@onready var close_dossier_button: Button = $DossierPanel/CloseDossierButton

var selected_mission_id: String = ""

var mission_dossiers: Dictionary = {
	"taco_bell_drop": {
		"background": "Louis's delivery bag contains more than receipts—it has the first clue to Sterling's network.",
		"required": "Infiltrate the Taco Bell after-hours, locate Louis's bag, and extract without alerting security.",
		"optional": ["Find the secret menu code", "Avoid all guard detection", "Complete in under 3 minutes"],
		"cards": ["bentley_dental_boy", "fish_treat_focus"],
		"rewards": ["Card: louis_delivery_route", "Polaroid: The Drop", "Crew favor: Louis"]
	},
	"velvet_paw_jazz_club": {
		"background": "Yordano's bass drops hide more than beats. His setlist contains blackmail names from Sterling's network - and one of those names knows where Dom hid his evidence.",
		"required": "Sneak backstage during the midnight set, recover the ledger from the bass case, and vanish before the final note.",
		"optional": ["Don't interrupt the performance", "Collect all three setlist variants", "Sign the guestbook as 'The Crew'"],
		"cards": ["yordano_bass_drop", "two_letters_away"],
		"rewards": ["Card: yordano_bass_drop", "Card: two_letters_away", "Polaroid: Midnight Jazz", "Crew favor: Yordano", "Unlock: The Arm-Wrestling Underground (Night Job)"]
	},
	"rewrite_room": {
		"background": "The showroom fingerprints matched Mere's legal files. Sterling's lawyers systematically stole creative works - and the documents proving it are in the archives.",
		"required": "Break into the legal archives, locate the fraudulent contracts, and replace them with restored rights documents.",
		"optional": ["Leave no fingerprints", "Photograph all evidence", "Escape through the window"],
		"cards": ["stationery_queen", "mere_legal_eyes"],
		"rewards": ["Card: stationery_queen", "Card: mere_legal_eyes", "Polaroid: The Rewrite", "Crew favor: Mere", "Unlock: Diamond a Year Job"]
	},
	"fast_family_getaway": {
		"background": "Dom's family chased the evidence. Now Sterling's men chase Dom. Hidden in Dom's stash: a watercolor from JC's conservatory, painted with poison ink that reveals Sterling's secrets.",
		"required": "Navigate the rainy city streets, evade pursuit vehicles, and reach the safe house with evidence intact.",
		"optional": ["No damage to the car", "Lose all tails within 2 minutes", "Collect the hidden checkpoint bonuses"],
		"cards": ["doms_getaway_keys"],
		"rewards": ["Card: doms_getaway_keys", "Polaroid: Rainy Getaway", "Crew favor: Dom", "Unlock: The Elephant in the Room"]
	},
	"sterling_tower_heist": {
		"background": "Every clue gathered. Every friend helped. The tower awaits - and Victor Sterling with it. The crew is complete. The favor chain ends here.",
		"required": "Infiltrate Sterling Tower, bypass the security systems, reach the penthouse vault, and secure the evidence to destroy Sterling's empire.",
		"optional": ["Ghost run—zero alerts", "Collect all crew intel files", "Complete before midnight"],
		"cards": ["polaroid_proof", "diamond_a_year"],
		"rewards": ["Polaroid: The Full Deck", "Crew favor: Everyone", "Unlock: Endgame content"]
	},
	"clean_job": {
		"background": "Louis's bag contained a cleaning invoice from Sterling's luxury showroom. The fingerprints there will reveal a code - and that code leads to the vault.",
		"required": "Use the Clorox Wipe Protocol to reveal hidden fingerprints, decode the vault combination, and extract the client list.",
		"optional": ["Leave the showroom spotless", "Find all three fingerprints", "Don't trigger the motion sensors"],
		"cards": ["clorox_wipe_protocol"],
		"rewards": ["Card: clorox_wipe_protocol", "Polaroid: The Clean Job", "Crew favor: Jinx", "Unlock: The Rewrite Room"]
	},
	"diamond_a_year_job": {
		"background": "The legal documents revealed Sterling's vault tribute - fifteen diamonds, one for each year of stolen work. But the vault also holds something else: correspondence linking Sterling to a shadow arena.",
		"required": "Synchronize with the vault's timing mechanism, crack the Swiss-precision locks, and extract the diamond tribute collection.",
		"optional": ["Perfect timing—no retries", "Document each diamond's origin", "Silent extraction"],
		"cards": ["diamond_a_year", "bryce_swiss_timing"],
		"rewards": ["Card: diamond_a_year", "Card: bryce_swiss_timing", "Polaroid: Diamond a Year", "Crew favor: Bryce", "Unlock: Persian Tea and Poison Ink"]
	},
	"corner_store_cashout": {
		"background": "A neon corner store, a misplaced cash envelope, and a petty insurance scam. Parmida's first favor - the kind of crime that leaves a place better than she found it.",
		"required": "Slip into the back office, recover the cash envelope and the scam evidence, and get out before the clerk finishes his rounds.",
		"optional": ["Never seen by the clerk", "Read the store's rumor board", "Leave the office tidier than you found it"],
		"cards": [],
		"rewards": ["Rumor lines around the neighborhood", "Intel points", "Parmida's legend grows"]
	},
	"arm_wrestling_underground": {
		"background": "Violet's underground club tests strength and loyalty. She knows about the shadow arena - win her challenge, and she'll share the arena's location.",
		"required": "Defeat three opponents in arm-wrestling matches, prove your strength to Violet, and earn the counterpunch technique.",
		"optional": ["Win all matches in under 30 seconds", "Don't use rest periods", "Perfect form bonus"],
		"cards": ["violet_counterpunch"],
		"rewards": ["Card: violet_counterpunch", "Polaroid: Arm-Wrestling Underground", "Crew favor: Violet", "Repeatable Night Job venue"]
	},
	"persian_tea_poison_ink": {
		"background": "JC's conservatory hides poison ink - the correspondence that links Sterling to the shadow arena. The letters mention something curious: a pink elephant in cold storage.",
		"required": "Prepare the proper tea blend, reveal the hidden watercolor clues, and expose the corporate poison plot.",
		"optional": ["Perfect tea preparation", "Collect all saffron strands", "Preserve every watercolor painting"],
		"cards": ["persian_tea_focus"],
		"rewards": ["Card: persian_tea_focus", "Polaroid: Persian Tea", "Crew favor: JC", "Unlock: The Elephant in the Room"]
	},
	"elephant_in_the_room": {
		"background": "Bentley lost Ellie years ago. The shadow arena contract mentions a pink elephant in storage - but rescuing her reveals something else: the arena's access codes.",
		"required": "Infiltrate the storage facility, locate Unit 42, rescue Ellie, and escape before the guard shift change.",
		"optional": ["Don't harm any guards", "Find Bentley's old collar", "Read the letter from Ellie's 'kidnapper'"],
		"cards": ["polaroid_proof"],
		"rewards": ["Card: polaroid_proof", "Polaroid: The Elephant in the Room", "Crew favor: Bentley's eternal gratitude", "Unlock: Shadow Solo Contract"]
	},
	"shadow_solo_contract": {
		"background": "Kiro and Jin's arena guards Sterling Tower's back entrance. Clear the contract, and the tower's service tunnels open. The final climb begins.",
		"required": "Navigate the neon-lit arena, disable the security systems using Kiro's tech, forge new exit passes with Jin, and clear the extraction zone.",
		"optional": ["Ghost through undetected", "Collect all data drives", "Leave calling cards for Sterling"],
		"cards": ["jc_london_contact"],
		"rewards": ["Card: jc_london_contact", "Polaroid: Shadow Solo", "Crew favor: Kiro & Jin", "Unlock: Sterling Tower Heist"]
	}
}

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	close_dossier_button.pressed.connect(_close_dossier)
	start_button.pressed.connect(_on_start_mission)
	_populate_missions()
	_hide_dossier()
	AudioManager.play_music("mission_select")

func _populate_missions() -> void:
	for child in missions_container.get_children():
		child.queue_free()
	
	var button_scene := load(MISSION_BUTTON_SCENE_PATH) as PackedScene
	var first_button := _add_mission_section("STORY", STORY_MISSION_ORDER, button_scene, null)
	first_button = _add_mission_section("NIGHT JOBS", NIGHT_JOB_ORDER, button_scene, first_button)
	if first_button:
		first_button.grab_focus()
	else:
		back_button.grab_focus()

func _add_mission_section(section_title: String, mission_ids: Array[String], button_scene: PackedScene, first_button: Button) -> Button:
	var section_buttons: Array[Button] = []
	for mission_id in mission_ids:
		var mission_data = GameState.mission_catalog.get(mission_id)
		if mission_data == null or button_scene == null:
			continue
		if bool(mission_data.get("planned", false)):
			continue
		var button = button_scene.instantiate()
		var is_unlocked := GameState.available_missions.has(mission_id)
		button.set_mission(mission_id, mission_data, is_unlocked)
		button.pressed.connect(_on_mission_selected.bind(mission_id))
		section_buttons.append(button)
	if section_buttons.is_empty():
		return first_button
	var header := Label.new()
	header.text = section_title
	header.add_theme_font_size_override("font_size", 13)
	header.modulate = Color(1.0, 1.0, 1.0, 0.6)
	missions_container.add_child(header)
	for button in section_buttons:
		missions_container.add_child(button)
		if first_button == null:
			first_button = button
	return first_button

func _on_mission_selected(mission_id: String) -> void:
	selected_mission_id = mission_id
	_show_dossier(mission_id)

func _show_dossier(mission_id: String) -> void:
	var catalog_data = GameState.mission_catalog.get(mission_id, {})
	var dossier = mission_dossiers.get(mission_id, {})
	var is_unlocked := GameState.available_missions.has(mission_id)
	
	dossier_title.text = catalog_data.get("name", "Unknown Mission")
	
	var status_text := "Status: AVAILABLE" if is_unlocked else "Status: LOCKED - " + _get_unlock_hint(mission_id)
	if GameState.has_completed(mission_id):
		status_text = "Status: COMPLETE"
	var desc_text: String = status_text + "\n\n[b]Background:[/b]\n" + dossier.get("background", catalog_data.get("description", "No intel available."))
	dossier_description.text = desc_text
	
	var objectives_text: String = "[b]Required Objective:[/b]\n" + dossier.get("required", "Complete the mission.")
	var optional = dossier.get("optional", [])
	if optional.size() > 0:
		objectives_text += "\n\n[b]Optional Objectives:[/b]"
		for obj in optional:
			objectives_text += "\n• " + obj
	dossier_objectives.text = objectives_text
	
	var cards = dossier.get("cards", [])
	if cards.size() > 0:
		var cards_text := "[b]Recommended Cards:[/b]"
		for card_id in cards:
			var card_name = _pretty_card_name(card_id)
			cards_text += "\n• " + card_name
		dossier_cards.text = cards_text
	else:
		dossier_cards.text = "[b]Recommended Cards:[/b]\nNo specific cards required."
	
	var rewards = dossier.get("rewards", [])
	if rewards.size() > 0:
		var rewards_text := "[b]Rewards:[/b]"
		for reward in rewards:
			rewards_text += "\n• " + reward
		dossier_rewards.text = rewards_text
	else:
		var catalog_rewards: Array[String] = []
		for card in catalog_data.get("reward_cards", []):
			catalog_rewards.append("Card: " + _pretty_card_name(card))
		for polaroid in catalog_data.get("reward_polaroids", []):
			catalog_rewards.append("Polaroid: " + _pretty_id(polaroid))
		if catalog_data.get("friend", "") != "":
			catalog_rewards.append("Crew favor: " + _pretty_id(catalog_data.get("friend", "")))
		if catalog_rewards.size() > 0:
			var rewards_text := "[b]Rewards:[/b]"
			for reward in catalog_rewards:
				rewards_text += "\n• " + reward
			dossier_rewards.text = rewards_text
		else:
			dossier_rewards.text = "[b]Rewards:[/b]\nIntel points"
	
	dossier_panel.visible = true
	start_button.disabled = not is_unlocked
	start_button.text = "Start Mission" if is_unlocked else "Locked"
	close_dossier_button.grab_focus()
	AudioManager.play_sfx("ui_select")

func _hide_dossier() -> void:
	dossier_panel.visible = false
	selected_mission_id = ""

func _close_dossier() -> void:
	_hide_dossier()

func _on_start_mission() -> void:
	if selected_mission_id != "" and GameState.available_missions.has(selected_mission_id):
		SceneManager.open_scheme_card_menu(selected_mission_id)

func _get_unlock_hint(mission_id: String) -> String:
	match mission_id:
		"clean_job":
			return "recover Louis's bag first."
		"velvet_paw_jazz_club":
			return "recover Louis's bag first."
		"rewrite_room":
			return "finish The Clean Job."
		"arm_wrestling_underground":
			return "follow Yordano's lead at the jazz club."
		"laundromat_heist":
			return "help Louis with the Taco Bell drop first."
		"bentleys_walk":
			return "Bentley will let you know when he's ready."
		"diamond_a_year_job":
			return "complete The Rewrite Room."
		"fast_family_getaway":
			return "complete The Rewrite Room."
		"persian_tea_poison_ink":
			return "crack the Diamond a Year vault."
		"elephant_in_the_room":
			return "survive Dom's getaway."
		"shadow_solo_contract":
			return "reveal the poison ink correspondence."
		"sterling_tower_heist":
			return "gather every major clue and help the full crew."
		_:
			return "keep following the evidence trail."

func _pretty_id(id: String) -> String:
	var parts := id.split("_")
	for i in range(parts.size()):
		parts[i] = parts[i].capitalize()
	return " ".join(parts)

func _pretty_card_name(card_id: String) -> String:
	var parts := card_id.split("_")
	for i in range(parts.size()):
		parts[i] = parts[i].capitalize()
	return " ".join(parts)

func _on_back_pressed() -> void:
	if dossier_panel.visible:
		_hide_dossier()
	else:
		SceneManager.return_to_hideout()
