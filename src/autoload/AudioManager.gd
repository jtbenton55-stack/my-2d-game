extends Node

enum Bus { MASTER, MUSIC, SFX, UI }
var current_music := ""
var _music_cues: Dictionary = {}
var _music_player: AudioStreamPlayer = null

func _ready() -> void:
	_ensure_bus("Music")
	_ensure_bus("SFX")
	_ensure_bus("UI")
	var music_bus := AudioServer.get_bus_index("Music")
	AudioServer.set_bus_mute(music_bus, false)
	AudioServer.set_bus_volume_db(music_bus, 0.0)
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.bus = "Music"
	_music_player.volume_db = 0.0
	add_child(_music_player)
	EventBus.debug("AudioManager ready")


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	AudioServer.add_bus()
	AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)

func set_bus_volume(bus: int, volume: float) -> void:
	var bus_name := _bus_to_name(bus)
	var index := AudioServer.get_bus_index(bus_name)
	if index >= 0:
		AudioServer.set_bus_volume_db(index, linear_to_db(clamp(volume, 0.0001, 1.0)))

func get_bus_volume(bus: int) -> float:
	var index := AudioServer.get_bus_index(_bus_to_name(bus))
	if index >= 0:
		return db_to_linear(AudioServer.get_bus_volume_db(index))
	return 1.0

func set_bus_mute(bus: int, mute: bool) -> void:
	var index := AudioServer.get_bus_index(_bus_to_name(bus))
	if index >= 0:
		AudioServer.set_bus_mute(index, mute)

func register_music_cue(music_name: String, stream: AudioStream, loop: bool = true) -> bool:
	var key := music_name.strip_edges()
	if key == "" or stream == null:
		return false
	if loop and "loop" in stream:
		stream.set("loop", true)
	_music_cues[key] = stream
	return true

func play_music(music_name: String, _fade_time = 0.0) -> void:
	var key := music_name.strip_edges()
	if key == current_music and _music_player != null and _music_player.playing:
		return
	var stream := _music_cues.get(key) as AudioStream
	if stream == null:
		current_music = key
		EventBus.debug("Music cue unavailable: " + key)
		return
	current_music = music_name
	_music_player.stream = stream
	_music_player.play()
	EventBus.debug("Music cue: " + music_name)

func stop_music(_fade_time = 0.0) -> void:
	if _music_player != null:
		_music_player.stop()
	current_music = ""

func is_music_playing(music_name: String = "") -> bool:
	if _music_player == null or not _music_player.playing:
		return false
	return music_name.strip_edges() == "" or current_music == music_name.strip_edges()


func get_music_debug_state() -> Dictionary:
	var music_bus := AudioServer.get_bus_index("Music")
	var master_bus := AudioServer.get_bus_index("Master")
	return {
		"current_music": current_music,
		"playing": _music_player != null and _music_player.playing,
		"playback_position": _music_player.get_playback_position() if _music_player != null and _music_player.playing else 0.0,
		"stream": _music_player.stream.resource_path if _music_player != null and _music_player.stream != null else "",
		"player_volume_db": _music_player.volume_db if _music_player != null else -80.0,
		"music_bus_volume_db": AudioServer.get_bus_volume_db(music_bus) if music_bus >= 0 else -80.0,
		"music_bus_muted": AudioServer.is_bus_mute(music_bus) if music_bus >= 0 else true,
		"master_bus_volume_db": AudioServer.get_bus_volume_db(master_bus) if master_bus >= 0 else -80.0,
		"master_bus_muted": AudioServer.is_bus_mute(master_bus) if master_bus >= 0 else true,
	}

func play_sfx(sfx_name: String, _position = Vector2.ZERO) -> void:
	EventBus.debug("SFX cue: " + sfx_name)

func _bus_to_name(bus: int) -> String:
	match bus:
		Bus.MASTER:
			return "Master"
		Bus.MUSIC:
			return "Music"
		Bus.SFX:
			return "SFX"
		Bus.UI:
			return "UI"
		_:
			return "Master"
