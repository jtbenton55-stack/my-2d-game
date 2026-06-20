class_name NoiseEvent
extends RefCounted


static func make_event(
	noise_id: String,
	source_id: String,
	position: Vector2,
	radius: float,
	strength: float,
	kind: String = "generic",
	team: String = "neutral",
	details: Dictionary = {}
) -> Dictionary:
	return {
		"noise_id": noise_id,
		"source_id": source_id,
		"position": position,
		"radius": maxf(0.0, radius),
		"strength": maxf(0.0, strength),
		"kind": kind,
		"team": team,
		"timestamp": Time.get_ticks_msec(),
		"details": details.duplicate(true),
	}


static func is_point_in_range(event: Dictionary, point: Vector2) -> bool:
	var origin: Vector2 = event.get("position", Vector2.ZERO)
	var radius := float(event.get("radius", 0.0))
	return origin.distance_to(point) <= radius


static func debug_summary(event: Dictionary) -> String:
	return "%s:%s r=%.1f s=%.2f" % [
		String(event.get("kind", "generic")),
		String(event.get("source_id", "")),
		float(event.get("radius", 0.0)),
		float(event.get("strength", 0.0)),
	]
