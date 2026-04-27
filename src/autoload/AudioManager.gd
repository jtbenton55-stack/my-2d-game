# AudioManager.gd
# Placeholder audio manager - bus management, volume controls

extends Node

# Audio buses
enum Bus {
	MASTER = 0,
	MUSIC = 1,
	SFX = 2,
	UI = 3
}

func _ready() -> void:
	EventBus.debug("AudioManager loaded")
	
	# Load saved volume settings
	_update_volumes_from_settings()

# Set volume for a specific bus (0.0 to 1.0)
func set_bus_volume(bus: Bus, volume: float) -> void:
	var bus_index := AudioServer.get_bus_index(_bus_to_name(bus))
	if bus_index != -1:
		# Convert linear volume to dB
		var db_volume := linear_to_db(volume)
		AudioServer.set_bus_volume_db(bus_index, db_volume)
		
		# Update settings
		match bus:
			Bus.MASTER:
				GameState.settings.audio.master_volume = volume
			Bus.MUSIC:
				GameState.settings.audio.music_volume = volume
			Bus.SFX:
				GameState.settings.audio.sfx_volume = volume
		
		EventBus.debug("Set " + _bus_to_name(bus) + " volume to " + str(volume))

# Get current volume for a bus
func get_bus_volume(bus: Bus) -> float:
	var bus_index := AudioServer.get_bus_index(_bus_to_name(bus))
	if bus_index != -1:
		var db_volume := AudioServer.get_bus_volume_db(bus_index)
		return db_to_linear(db_volume)
	return 1.0

# Mute/unmute a bus
func set_bus_mute(bus: Bus, mute: bool) -> void:
	var bus_index := AudioServer.get_bus_index(_bus_to_name(bus))
	if bus_index != -1:
		AudioServer.set_bus_mute(bus_index, mute)
		EventBus.debug(( "Muted" if mute else "Unmuted") + " " + _bus_to_name(bus))

# Play a sound effect (placeholder - would integrate with actual audio files)
func play_sfx(sfx_name: String, position: Vector2 = Vector2.ZERO) -> void:
	EventBus.debug("Playing SFX: " + sfx_name + " at " + str(position))
	# In a real implementation, this would instantiate and play an AudioStreamPlayer

# Play music (placeholder)
func play_music(music_name: String, fade_time: float = 0.5) -> void:
	EventBus.debug("Playing music: " + music_name + " (fade: " + str(fade_time) + "s)")
	# In a real implementation, this would handle music crossfading

# Stop music
func stop_music(fade_time: float = 0.5) -> void:
	EventBus.debug("Stopping music (fade: " + str(fade_time) + "s)")

# Update volumes from GameState settings
func _update_volumes_from_settings() -> void:
	set_bus_volume(Bus.MASTER, GameState.settings.audio.master_volume)
	set_bus_volume(Bus.MUSIC, GameState.settings.audio.music_volume)
	set_bus_volume(Bus.SFX, GameState.settings.audio.sfx_volume)

# Convert Bus enum to bus name
func _bus_to_name(bus: Bus) -> String:
	match bus:
		Bus.MASTER: return "Master"
		Bus.MUSIC: return "Music"
		Bus.SFX: return "SFX"
		Bus.UI: return "UI"
		_: return "Master"