extends Node

enum Bus { MASTER, MUSIC, SFX, UI }
var current_music := ""

func _ready() -> void:
	EventBus.debug("AudioManager ready")

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

func play_music(music_name: String, _fade_time = 0.0) -> void:
	current_music = music_name
	EventBus.debug("Music cue: " + music_name)

func stop_music(_fade_time = 0.0) -> void:
	current_music = ""

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
