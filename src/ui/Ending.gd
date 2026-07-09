extends Control

@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var story_label: Label = $Panel/VBox/StoryLabel
@onready var continue_button: Button = $Panel/VBox/ButtonRow/ContinueButton
@onready var title_button: Button = $Panel/VBox/ButtonRow/TitleButton

func _ready() -> void:
	AudioManager.play_music("ending")
	_render_ending()
	continue_button.pressed.connect(_on_continue_pressed)
	title_button.pressed.connect(_on_title_pressed)
	continue_button.grab_focus()

## Friend lines render only for friends actually helped; unhelped friends are conspicuously absent.
const FRIEND_ASSIST_LINES: Dictionary = {
	"louis": "Louis opened the delivery elevator.",
	"mere": "Mere found the trap hidden in the contract.",
	"yordano": "Yordano dropped the bass and the lights went dark.",
	"jinx": "Jinx wiped the floors behind them - no prints, no proof, no problem.",
	"bryce": "Bryce counted fifteen seconds, then fifteen diamonds, in perfect Swiss time.",
	"dom": "Dom had the getaway idling before anyone asked.",
	"jc": "JC's tea kept every hand steady on the way up.",
	"violet": "Violet held the service door open with one arm. She didn't need the other.",
	"jin": "Jin forged the exit passes; Kiro killed the cameras on floor forty.",
	"jake": "Jake patched the bruises and pretended not to be proud.",
	"bentley": "Bentley retrieved the master key, then judged the carpet.",
}

const FRIEND_ABSENCE_LINES: Dictionary = {
	"louis": "She took the stairs. Louis would have known a better way in.",
	"mere": "She signed nothing on the way up. Mere would have read it twice anyway.",
	"yordano": "The lights stayed on. She missed the bass.",
	"jinx": "She left fingerprints. Somewhere, Jinx winced.",
	"bryce": "The vault took longer without a watch like Bryce's.",
	"dom": "The getaway was a bus. Dom would never let her live that down.",
	"jc": "No tea before the job. Her hands shook once, on the top floor.",
	"violet": "Nobody held the door. She shouldered it open alone.",
	"jin": "No forged passes tonight. She walked out the front, daring them to look.",
}

const FRIEND_LINE_ORDER: Array[String] = [
	"louis", "mere", "yordano", "jinx", "bryce", "dom", "jc", "violet", "jin", "jake", "bentley"
]

const NIGHT_JOB_BONUS_LINES: Dictionary = {
	"corner_store_cashout": "The corner store keeps a photo of her by the register. \"Our best shoplifter,\" the clerk says. \"Never took a thing.\"",
	"laundromat_heist": "Rosa's laundromat runs clean now - the only thing getting washed is clothes.",
	"arm_wrestling_underground": "At Violet's club, her name is still chalked on the champion board.",
	"bentleys_walk": "Half the neighborhood knows Bentley by name. The other half knows him by reputation.",
}

func _render_ending() -> void:
	title_label.text = "Friends Helping Friends"
	var lines: Array[String] = [
		"Victor Sterling thought she came alone.",
		"",
	]
	for friend_id in FRIEND_LINE_ORDER:
		if _friend_was_helped(friend_id):
			lines.append(String(FRIEND_ASSIST_LINES[friend_id]))
	var absences: Array[String] = []
	for friend_id in FRIEND_LINE_ORDER:
		if not _friend_was_helped(friend_id) and FRIEND_ABSENCE_LINES.has(friend_id):
			absences.append(String(FRIEND_ABSENCE_LINES[friend_id]))
	if not absences.is_empty():
		lines.append("")
		lines.append_array(absences)
	var night_job_lines := _collect_night_job_lines()
	if not night_job_lines.is_empty():
		lines.append("")
		lines.append_array(night_job_lines)
	lines.append_array([
		"",
		"Some empires are built on fear.",
		"Hers was built on favors.",
		"",
		"The city calls Parmida a crime lord now. She lets them.",
		"The title finally means what she always wanted it to mean.",
		"",
		"Final Polaroid unlocked: the crew, the city, and one very important Shiba."
	])
	story_label.text = "\n".join(lines)
	GameState.dialogue_flags["ending_seen"] = true
	GameState.collect_polaroid("final_crew_polaroid")
	SaveManager.auto_save()

func _friend_was_helped(friend_id: String) -> bool:
	# Jake and Bentley are family; they are always there.
	if friend_id == "jake" or friend_id == "bentley":
		return true
	var data: Dictionary = GameState.friend_favors.get(friend_id, {})
	return bool(data.get("helped", false))

func _collect_night_job_lines() -> Array[String]:
	var out: Array[String] = []
	for mission_id in NIGHT_JOB_BONUS_LINES.keys():
		if GameState.has_completed(mission_id):
			out.append(String(NIGHT_JOB_BONUS_LINES[mission_id]))
	return out

func _on_continue_pressed() -> void:
	SceneManager.return_to_hideout()

func _on_title_pressed() -> void:
	SceneManager.return_to_title()
