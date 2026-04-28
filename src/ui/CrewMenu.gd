extends Control

@onready var crew_list: VBoxContainer = $Panel/CrewList
@onready var back_button: Button = $BackButton
@onready var details_panel: Panel = $DetailsPanel
@onready var name_label: Label = $DetailsPanel/NameLabel
@onready var status_label: Label = $DetailsPanel/StatusLabel
@onready var favor_label: Label = $DetailsPanel/FavorLabel
@onready var card_label: Label = $DetailsPanel/CardLabel

var friend_data: Dictionary = {
	"jake": {"name": "Jake", "role": "The Medic", "description": "Keeps the crew patched up. Has history with Sterling.", "color": Color(0.4, 0.6, 0.8)},
	"bentley": {"name": "Bentley", "role": "The Dog", "description": "Jake's dental school dropout. Barks at guards, recharges on fish treats.", "color": Color(0.8, 0.5, 0.3)},
	"louis": {"name": "Louis", "role": "The Courier", "description": "Knows every back alley. His delivery routes reveal shortcuts.", "color": Color(0.6, 0.7, 0.4)},
	"mere": {"name": "Mere", "role": "The Legal Eye", "description": "Entertainment lawyer with a conscience. Protects the crew legally.", "color": Color(0.7, 0.4, 0.7)},
	"dom": {"name": "Dom", "role": "The Driver", "description": "Fast family. His keys unlock more than cars.", "color": Color(0.5, 0.5, 0.6)},
	"yordano": {"name": "Yordano", "role": "The Musician", "description": "Bass player with perfect timing. His rhythm boosts the whole crew.", "color": Color(0.3, 0.5, 0.7)},
	"bryce": {"name": "Bryce", "role": "The Swiss Watch", "description": "Precision timing. Bentley's bark travels further with his help.", "color": Color(0.6, 0.6, 0.5)},
	"jc": {"name": "JC", "role": "The London Contact", "description": "Fixer with global reach. Reduces cooldowns through efficiency.", "color": Color(0.7, 0.5, 0.4)},
	"violet": {"name": "Violet", "role": "The Counterpunch", "description": "Self-defense instructor. Adds sting to your attacks.", "color": Color(0.8, 0.3, 0.5)},
	"jinx": {"name": "Jinx", "role": "The Dealer", "description": "Cards and connections. Unlocks rare opportunities.", "color": Color(0.5, 0.3, 0.8)},
	"eren": {"name": "Eren", "role": "The Archivist", "description": "Collects secrets. Every polaroid tells a story.", "color": Color(0.4, 0.6, 0.5)},
	"kiro": {"name": "Kiro", "role": "The Tech", "description": "Security systems are just puzzles. Makes stealth easier.", "color": Color(0.3, 0.7, 0.6)},
	"jin": {"name": "Jin", "role": "The Forger", "description": "Documents, passes, alibis. Opens doors that should stay locked.", "color": Color(0.7, 0.6, 0.3)},
	"crew": {"name": "The Full Deck", "role": "Everyone", "description": "All friends united. The final heist requires everyone.", "color": Color(0.9, 0.8, 0.5)}
}

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	_populate_crew_list()
	_clear_details()

func _populate_crew_list() -> void:
	for child in crew_list.get_children():
		child.queue_free()
	
	for friend_id in GameState.crew_members:
		var data: Dictionary = friend_data.get(friend_id, {"name": friend_id, "role": "Unknown", "description": "No data available.", "color": Color(0.5, 0.5, 0.5)})
		var favor_data: Dictionary = GameState.friend_favors.get(friend_id, {"helped": false, "favors_owed": 0, "card_unlocked": ""})
		
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(300, 60)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		var status: String = "[Active]" if favor_data.get("helped", false) else "[Available]"
		var favors: int = favor_data.get("favors_owed", 0)
		btn.text = "%s %s (Favors: %d)" % [data.name, status, favors]
		btn.pressed.connect(_on_friend_selected.bind(friend_id, data, favor_data))
		crew_list.add_child(btn)

func _on_friend_selected(_friend_id: String, data: Dictionary, favor_data: Dictionary) -> void:
	var friend_name: String = data.get("name", "Unknown")
	var friend_role: String = data.get("role", "Unknown")
	name_label.text = friend_name + " — " + friend_role
	
	var status_text := "Active ally" if favor_data.get("helped", false) else "Not yet helped"
	status_label.text = "Status: " + status_text
	
	var favors: int = favor_data.get("favors_owed", 0)
	favor_label.text = "Favors Owed: " + str(favors)
	
	var card_unlocked: String = favor_data.get("card_unlocked", "")
	if card_unlocked != "":
		var card_data = CardManager.get_card(card_unlocked)
		if card_data and card_data.has_method("get_summary"):
			card_label.text = "Reward Card: " + card_data.display_name
		else:
			card_label.text = "Reward Card: Available"
	else:
		card_label.text = "Reward Card: Locked"
	
	AudioManager.play_sfx("ui_select")

func _clear_details() -> void:
	name_label.text = "Select a crew member"
	status_label.text = ""
	favor_label.text = ""
	card_label.text = ""

func _on_back_pressed() -> void:
	SceneManager.return_to_hideout()
