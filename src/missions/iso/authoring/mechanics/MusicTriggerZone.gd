@tool
class_name MusicTriggerZone
extends TriggerZone

@export_group("Music")
@export var music_key: StringName = &""
@export var fade_time: float = 0.0
@export var on_exit_restore: bool = false
@export var restore_music_key: StringName = &""
@export var audio_player_path: NodePath
@export var audio_stream: AudioStream

var previous_music_key: String = ""
var last_music_result: Dictionary = {}


func _init() -> void:
	super._init()
	prompt_text = "Change music"
	trigger_on_enter = true
	interaction_mode = InteractionMode.AUTOMATIC_ON_ENTER
	one_shot = false


func _ready() -> void:
	super._ready()
	if audio_stream != null and get_node_or_null(audio_player_path) == null:
		var player := AudioStreamPlayer.new()
		player.name = "MusicPreviewPlayer"
		player.stream = audio_stream
		add_child(player)
		audio_player_path = NodePath("MusicPreviewPlayer")


func activate(actor: Node = null, reason: String = "interact") -> Dictionary:
	var result: Dictionary = super.activate(actor, reason)
	if bool(result.get("ok", false)) and String(result.get("code", "")) == "activation_succeeded":
		last_music_result = _request_music_change()
		var details: Dictionary = result.get("details", {})
		details["music_result"] = last_music_result
		result["details"] = details
		last_activation_result = result
	return result


func _on_body_exited(body: Node) -> void:
	super._on_body_exited(body)
	if on_exit_restore and can_actor_use(body):
		_restore_music()


func _request_music_change() -> Dictionary:
	var key := String(music_key).strip_edges()
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null and audio_manager.has_method("play_music") and key != "":
		previous_music_key = String(audio_manager.get("current_music")) if "current_music" in audio_manager else ""
		audio_manager.call("play_music", key, fade_time)
		return _result(true, "music_requested", "Requested music key.", String(mechanic_id), {"music_key": key})
	var player := get_node_or_null(audio_player_path) as AudioStreamPlayer
	if player != null:
		if audio_stream != null:
			player.stream = audio_stream
		player.play()
		return _result(true, "audio_player_started", "Started local AudioStreamPlayer.", String(mechanic_id), {"player_path": str(player.get_path())})
	return _result(false, "missing_audio_seam", "No AudioManager music key or AudioStreamPlayer available.", String(mechanic_id))


func _restore_music() -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	var restore_key := String(restore_music_key).strip_edges()
	if restore_key == "":
		restore_key = previous_music_key
	if audio_manager != null and audio_manager.has_method("play_music") and restore_key != "":
		audio_manager.call("play_music", restore_key, fade_time)
		return
	var player := get_node_or_null(audio_player_path) as AudioStreamPlayer
	if player != null:
		player.stop()
