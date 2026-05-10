# PlayerVisualAnimator.gd
# Phase 0M-C2A — Visual-Only Player Animation Controller
#
# ATTACH TO: The AnimatedSprite2D node (PlayerVisual_ParmidaAnimated)
# DO NOT MODIFY: Player.gd, collision, input, camera, or movement
#
# Purpose: Play idle/walk animations based on parent velocity.
# Falls back to static visual if animation resources missing.

class_name PlayerVisualAnimator
extends AnimatedSprite2D

# Animation configuration
@export var idle_animation_name: String = "idle"
@export var walk_animation_name: String = "walk"
@export var walk_velocity_threshold: float = 10.0

@export var idle_fps: float = 6.0
@export var walk_fps: float = 10.0

# Internal state
var _parent_body: CharacterBody2D = null
var _has_animations: bool = false
var _current_animation: String = ""
var _last_facing: Vector2 = Vector2.DOWN

func _ready():
	# Try to find parent CharacterBody2D
	if get_parent() is CharacterBody2D:
		_parent_body = get_parent()
	else:
		# Search up the tree
		var parent = get_parent()
		while parent:
			if parent is CharacterBody2D:
				_parent_body = parent
				break
			parent = parent.get_parent()

	# Check if we have a valid SpriteFrames resource
	if sprite_frames == null:
		push_warning("PlayerVisualAnimator: No SpriteFrames assigned. Disabling animation.")
		_has_animations = false
		return

	# Check for required animations
	var has_idle = sprite_frames.has_animation(idle_animation_name)
	var has_walk = sprite_frames.has_animation(walk_animation_name)

	if not has_idle:
		push_warning("PlayerVisualAnimator: Missing idle animation '%s'" % idle_animation_name)

	_has_animations = has_idle

	if _has_animations:
		# Configure animation speeds
		if has_idle:
			sprite_frames.set_animation_speed(idle_animation_name, idle_fps)
		if has_walk:
			sprite_frames.set_animation_speed(walk_animation_name, walk_fps)

		# Start with idle
		play(idle_animation_name)
		_current_animation = idle_animation_name

func _process(_delta):
	if not _has_animations:
		return

	if _parent_body == null:
		return

	var velocity = _parent_body.velocity

	# Determine if moving
	var is_moving = velocity.length() > walk_velocity_threshold

	# Select animation
	var target_animation = ""
	if is_moving and sprite_frames.has_animation(walk_animation_name):
		target_animation = walk_animation_name
	elif sprite_frames.has_animation(idle_animation_name):
		target_animation = idle_animation_name

	# Play animation if changed
	if target_animation != "" and target_animation != _current_animation:
		play(target_animation)
		_current_animation = target_animation

	# Track facing direction for potential future directional animation support
	if velocity.length() > 0:
		_last_facing = velocity.normalized()

# Public API for external control (if needed)
func force_idle():
	if _has_animations and sprite_frames.has_animation(idle_animation_name):
		play(idle_animation_name)
		_current_animation = idle_animation_name

func force_walk():
	if _has_animations and sprite_frames.has_animation(walk_animation_name):
		play(walk_animation_name)
		_current_animation = walk_animation_name

# Returns true if animations are working
func is_animation_working() -> bool:
	return _has_animations
