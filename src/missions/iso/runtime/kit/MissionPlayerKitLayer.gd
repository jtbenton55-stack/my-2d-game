class_name MissionPlayerKitLayer
extends Node

## Replan Packet 2 composer: heist kit HUD, footstep noise tiers, and the
## decoy throw verb. IsoMissionBase auto-mounts one per mission.

const HeistKitHudScript := preload("res://src/missions/iso/runtime/kit/HeistKitHud.gd")
const PlayerFootstepNoiseEmitterScript := preload("res://src/missions/iso/runtime/kit/PlayerFootstepNoiseEmitter.gd")
const KitDecoyThrowerScript := preload("res://src/missions/iso/runtime/kit/KitDecoyThrower.gd")

@export var enable_kit_hud: bool = true
@export var enable_footstep_noise: bool = true
@export var enable_decoy_thrower: bool = true

var kit_hud: CanvasLayer = null
var footstep_emitter: Node = null
var decoy_thrower: Node = null


func _ready() -> void:
	add_to_group("mission_player_kit_layer")
	if enable_kit_hud and kit_hud == null:
		kit_hud = HeistKitHudScript.new() as CanvasLayer
		kit_hud.name = "HeistKitHud"
		add_child(kit_hud)
	if enable_footstep_noise and footstep_emitter == null:
		footstep_emitter = PlayerFootstepNoiseEmitterScript.new()
		footstep_emitter.name = "PlayerFootstepNoiseEmitter"
		add_child(footstep_emitter)
	if enable_decoy_thrower and decoy_thrower == null:
		decoy_thrower = KitDecoyThrowerScript.new()
		decoy_thrower.name = "KitDecoyThrower"
		add_child(decoy_thrower)


func get_kit_layer_summary() -> Dictionary:
	return {
		"kit_hud": kit_hud != null,
		"footstep_emitter": footstep_emitter != null,
		"decoy_thrower": decoy_thrower != null,
		"movement_tier": String(footstep_emitter.get("last_tier")) if footstep_emitter != null else "unknown",
	}
