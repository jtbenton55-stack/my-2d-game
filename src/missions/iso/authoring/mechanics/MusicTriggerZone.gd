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
var last_restore_result: Dictionary = {}
var _fade_tween: Tween = null


func _init() -> void:
	super._init()
	prompt_text = "Change music"
	trigger_on_enter = true
	interaction_mode = InteractionMode.AUTOMATIC_ON_ENTER
	one_shot = false


func _ready() -> void:
	super._ready()
	add_to_group("music_trigger_zone")
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
		_fade_player_in(player)
		return _result(true, "audio_player_started", "Started local AudioStreamPlayer.", String(mechanic_id), {"player_path": str(player.get_path())})
	return _result(false, "missing_audio_seam", "No AudioManager music key or AudioStreamPlayer available.", String(mechanic_id))


func _restore_music() -> Dictionary:
	var audio_manager := get_node_or_null("/root/AudioManager")
	var restore_key := String(restore_music_key).strip_edges()
	if restore_key == "":
		restore_key = previous_music_key
	if audio_manager != null and audio_manager.has_method("play_music") and restore_key != "":
		audio_manager.call("play_music", restore_key, fade_time)
		last_restore_result = _result(true, "music_restored", "Requested restore music key.", String(mechanic_id), {"music_key": restore_key})
		return last_restore_result
	var player := get_node_or_null(audio_player_path) as AudioStreamPlayer
	if player != null:
		_fade_player_out(player)
		last_restore_result = _result(true, "audio_player_stopping", "Stopping local AudioStreamPlayer.", String(mechanic_id), {"player_path": str(player.get_path())})
		return last_restore_result
	last_restore_result = _result(false, "missing_restore_target", "No AudioManager restore key or AudioStreamPlayer available.", String(mechanic_id))
	return last_restore_result


func _fade_player_in(player: AudioStreamPlayer) -> void:
	_kill_fade_tween()
	if fade_time <= 0.0:
		player.volume_db = 0.0
		player.play()
		return
	player.volume_db = -40.0
	player.play()
	_fade_tween = create_tween()
	_fade_tween.tween_property(player, "volume_db", 0.0, fade_time)


func _fade_player_out(player: AudioStreamPlayer) -> void:
	_kill_fade_tween()
	if fade_time <= 0.0:
		player.stop()
		return
	_fade_tween = create_tween()
	_fade_tween.tween_property(player, "volume_db", -40.0, fade_time)
	_fade_tween.tween_callback(Callable(player, "stop"))


func _kill_fade_tween() -> void:
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = null


func get_runtime_debug_summary() -> Dictionary:
	var player := get_node_or_null(audio_player_path) as AudioStreamPlayer
	return {
		"mechanic_id": String(mechanic_id),
		"music_key": String(music_key),
		"restore_music_key": String(restore_music_key),
		"previous_music_key": previous_music_key,
		"fade_time": fade_time,
		"on_exit_restore": on_exit_restore,
		"audio_player_path": str(audio_player_path),
		"audio_player_playing": player.playing if player != null else false,
		"last_music_result": last_music_result.duplicate(true),
		"last_restore_result": last_restore_result.duplicate(true),
	}
