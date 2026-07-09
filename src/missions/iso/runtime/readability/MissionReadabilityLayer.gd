class_name MissionReadabilityLayer
extends Node2D

## Single drop-in node that gives a mission the Replan Packet 1 readability
## stack: noise pulse rings, NPC alert pips, and the Casing Mode overlay.
## IsoMissionBase auto-mounts one of these when missing, so authored scenes
## only need to place it manually when they want custom configuration.

const NoisePulseVisualizerScript := preload("res://src/missions/iso/runtime/readability/NoisePulseVisualizer.gd")
const NpcAlertPipVisualizerScript := preload("res://src/missions/iso/runtime/readability/NpcAlertPipVisualizer.gd")
const MissionCasingOverlayScript := preload("res://src/missions/iso/runtime/readability/MissionCasingOverlay.gd")

@export var enable_noise_pulses: bool = true
@export var enable_npc_pips: bool = true
@export var enable_casing_overlay: bool = true

var noise_pulses: Node2D = null
var npc_pips: Node2D = null
var casing_overlay: Node2D = null


func _ready() -> void:
	add_to_group("mission_readability_layer")
	if enable_noise_pulses and noise_pulses == null:
		noise_pulses = NoisePulseVisualizerScript.new()
		noise_pulses.name = "NoisePulseVisualizer"
		add_child(noise_pulses)
	if enable_npc_pips and npc_pips == null:
		npc_pips = NpcAlertPipVisualizerScript.new()
		npc_pips.name = "NpcAlertPipVisualizer"
		add_child(npc_pips)
	if enable_casing_overlay and casing_overlay == null:
		casing_overlay = MissionCasingOverlayScript.new()
		casing_overlay.name = "MissionCasingOverlay"
		add_child(casing_overlay)


func get_readability_summary() -> Dictionary:
	return {
		"noise_pulses": noise_pulses != null,
		"npc_pips": npc_pips != null,
		"casing_overlay": casing_overlay != null,
		"casing_active": casing_overlay != null and bool(casing_overlay.get("casing_active")),
	}
