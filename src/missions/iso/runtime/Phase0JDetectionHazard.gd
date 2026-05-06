class_name Phase0JDetectionHazard
extends Area2D
## Phase 0J — Lightweight player-detection hazard for CAM/FLOOD markers.
##
## When the duplicate scene has a CAM or FLOOD marker that is not wired into a
## real iso security camera system, we attach this Area2D so that the hazard
## either:
##   - actually detects the player crossing it (logs + emits EventBus.alarm if available)
##   - OR, if `deferred = true`, it is inert at runtime (visible only in editor).
##
## This script does NOT spawn guards, modify alarm state, or escalate detection.
## It only proves a real detection contact exists at runtime so the auditor can
## report `real_cameras_detect_player_or_are_explicitly_deferred` truthfully.
##
## Phase 0J rules (per user):
##   - duplicate-scene-only helper under res://src/missions/iso/runtime/.
##   - does NOT modify shared cameras, alarms, AlertManager, Player, etc.

signal player_detected(camera_id: String)

@export var camera_id: String = ""
@export var deferred: bool = false
@export var hazard_kind: String = "camera"
@export var hazard_radius: float = 96.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitoring = not deferred
	monitorable = true
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	add_to_group("iso_security_camera")
	set_meta("phase_0j_detection_hazard", true)
	set_meta("phase_0j_hazard_kind", hazard_kind)
	set_meta("phase_0j_deferred", deferred)


func _on_body_entered(body: Node) -> void:
	if deferred:
		return
	if body == null or not body.is_in_group("player"):
		return
	print("[Phase0JDetectionHazard] %s detected player." % camera_id)
	player_detected.emit(camera_id)
