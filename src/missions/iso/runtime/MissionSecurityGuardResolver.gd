class_name MissionSecurityGuardResolver
extends RefCounted
## Central GOOD vs BAD guard identity for iso security responses (D6-01-FIX1).

const GOOD_GUARD_SCENE := "res://scenes/characters/guard.tscn"
## Procedural Phase0K placeholder — still exists for tooling, not for live security spawns.
const BAD_GUARD_SCRIPT_PATH := "res://src/missions/iso/runtime/Phase0KGuardPatrol.gd"


static func good_guard_scene_path() -> String:
	return GOOD_GUARD_SCENE


static func bad_guard_script_path() -> String:
	return BAD_GUARD_SCRIPT_PATH
