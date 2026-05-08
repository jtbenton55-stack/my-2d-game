extends RefCounted
class_name HideoutDecorPlacementValidator

const VALID_BOUNDS := Rect2(Vector2(-1000, -650), Vector2(1920, 1120))
const DIRECT_PROXY_MARGIN_PX := 6
const CRITICAL_ZONE_MARGIN_PX := 24
const BOUNDARY_ZONE_MARGIN_PX := 16
const MAX_NEAREST_OPEN_SEARCH_RADIUS_PX := 256

static func no_place_zones() -> Array[Dictionary]:
	return [
		_zone("entry_exit_door", Vector2(760, 430), Vector2(220, 190), "Entry/exit door protection", CRITICAL_ZONE_MARGIN_PX),
		_zone("player_spawn", Vector2(650, 360), Vector2(220, 180), "Player spawn protection", CRITICAL_ZONE_MARGIN_PX),
		_zone("bentley_care_station", Vector2(520, 330), Vector2(88, 64), "Bentley care station direct proxy", DIRECT_PROXY_MARGIN_PX),
		_zone("loot_crate_drop_zone", Vector2(210, 350), Vector2(82, 64), "Loot crate direct proxy", DIRECT_PROXY_MARGIN_PX),
		_zone("bentley", Vector2(-800, 390), Vector2(72, 58), "Bentley direct proxy", DIRECT_PROXY_MARGIN_PX),
		_zone("jake", Vector2(-525, 265), Vector2(58, 58), "Jake direct proxy", DIRECT_PROXY_MARGIN_PX),
		_zone("mere", Vector2(-455, 265), Vector2(58, 58), "Mere direct proxy", DIRECT_PROXY_MARGIN_PX),
		_zone("mission_board", Vector2(470, -450), Vector2(126, 58), "Mission Board direct proxy", DIRECT_PROXY_MARGIN_PX),
		_zone("evidence_board_big_case", Vector2(-90, -455), Vector2(126, 58), "The Big Case direct proxy", DIRECT_PROXY_MARGIN_PX),
		_zone("planning_table", Vector2(0, 20), Vector2(132, 90), "Planning Table direct proxy", DIRECT_PROXY_MARGIN_PX),
		_zone("polaroid_wall", Vector2(-850, -230), Vector2(88, 52), "Polaroid wall direct proxy", DIRECT_PROXY_MARGIN_PX),
		_zone("glow_guy_shelf", Vector2(-880, -40), Vector2(88, 52), "Glow Guy shelf direct proxy", DIRECT_PROXY_MARGIN_PX),
		_zone("tiny_icon_shelf", Vector2(-880, 110), Vector2(88, 52), "Tiny Icon shelf direct proxy", DIRECT_PROXY_MARGIN_PX),
		_zone("poop_bag_display", Vector2(-840, 250), Vector2(88, 52), "Poop Bag display direct proxy", DIRECT_PROXY_MARGIN_PX),
		_zone("store_terminal", Vector2(710, -80), Vector2(104, 76), "Store Terminal direct proxy", DIRECT_PROXY_MARGIN_PX),
		_zone("open_decor_zone_proxy", Vector2(445, 155), Vector2(82, 64), "Open Decor Area direct proxy", DIRECT_PROXY_MARGIN_PX),
		_zone("heat_scanner", Vector2(0, -310), Vector2(86, 58), "Heat Scanner direct proxy", DIRECT_PROXY_MARGIN_PX),
		_zone("louis_store_area", Vector2(780, 120), Vector2(70, 58), "Louis direct proxy", DIRECT_PROXY_MARGIN_PX),
		_zone("boundary_margin_north", Vector2(0, -650), Vector2(1900, 80), "Boundary margin", BOUNDARY_ZONE_MARGIN_PX),
		_zone("boundary_margin_south", Vector2(0, 500), Vector2(1900, 80), "Boundary margin", BOUNDARY_ZONE_MARGIN_PX),
		_zone("boundary_margin_west", Vector2(-1010, 50), Vector2(80, 980), "Boundary margin", BOUNDARY_ZONE_MARGIN_PX),
		_zone("boundary_margin_east", Vector2(930, 40), Vector2(80, 1000), "Boundary margin", BOUNDARY_ZONE_MARGIN_PX),
	]

static func wall_snap_zones() -> Array[Dictionary]:
	return [
		{"zone_id": "wall_snap_west", "rect": Rect2(Vector2(-930, -335), Vector2(130, 610)), "orientation": "vertical", "fixed_x": -865.0},
		{"zone_id": "wall_snap_east_store", "rect": Rect2(Vector2(720, -250), Vector2(160, 470)), "orientation": "vertical", "fixed_x": 800.0},
		{"zone_id": "wall_snap_north_big_case", "rect": Rect2(Vector2(-330, -530), Vector2(660, 110)), "orientation": "horizontal", "fixed_y": -475.0},
		{"zone_id": "wall_snap_greenhouse", "rect": Rect2(Vector2(-360, -670), Vector2(720, 80)), "orientation": "horizontal", "fixed_y": -630.0},
		{"zone_id": "wall_snap_cozy_lounge", "rect": Rect2(Vector2(-790, 210), Vector2(360, 90)), "orientation": "horizontal", "fixed_y": 250.0},
	]

static func snap_world_position(pos: Vector2, snap_grid_size: int = 16) -> Vector2:
	return Vector2(round(pos.x / float(snap_grid_size)) * snap_grid_size, round(pos.y / float(snap_grid_size)) * snap_grid_size)

static func snap_wall_position(pos: Vector2, item: Dictionary, snap_grid_size: int = 16) -> Dictionary:
	if not _is_wall_item(item):
		return {"position": snap_world_position(pos, snap_grid_size), "zone_id": ""}
	var best_pos := pos
	var best_zone := ""
	var best_dist := INF
	for zone in wall_snap_zones():
		var rect: Rect2 = zone.get("rect", Rect2())
		var candidate := pos
		if String(zone.get("orientation", "")) == "vertical":
			candidate.x = float(zone.get("fixed_x", rect.get_center().x))
			candidate.y = clampf(pos.y, rect.position.y, rect.position.y + rect.size.y)
		else:
			candidate.y = float(zone.get("fixed_y", rect.get_center().y))
			candidate.x = clampf(pos.x, rect.position.x, rect.position.x + rect.size.x)
		var dist := candidate.distance_to(pos)
		if dist < best_dist:
			best_dist = dist
			best_pos = candidate
			best_zone = String(zone.get("zone_id", ""))
	return {"position": snap_world_position(best_pos, snap_grid_size), "zone_id": best_zone}

static func validate_position(pos: Vector2, item: Dictionary, placed_items: Array, moving_placed_id: String = "") -> Dictionary:
	var footprint := footprint_rect(pos, item, float(item.get("rotation_degrees", 0.0)))
	if not VALID_BOUNDS.encloses(footprint):
		return {"valid": false, "reason": "outside hideout bounds"}
	for zone in no_place_zones():
		var zone_rect: Rect2 = zone.get("rect", Rect2())
		if footprint.intersects(zone_rect):
			return {"valid": false, "reason": String(zone.get("reason", "blocked zone")), "zone_id": String(zone.get("zone_id", ""))}
	for placed in placed_items:
		if String(placed.get("placed_id", "")) == moving_placed_id:
			continue
		var other_item: Dictionary = placed.get("item_data", {})
		var other_rect := footprint_rect(placed.get("position", Vector2.ZERO), other_item, float(placed.get("rotation", 0.0)))
		if footprint.intersects(other_rect):
			return {"valid": false, "reason": "overlaps placed decor", "placed_id": String(placed.get("placed_id", ""))}
	if _is_wall_item(item) and not _wall_rect_contains(pos):
		return {"valid": false, "reason": "wall decor must use wall snap rows"}
	return {"valid": true, "reason": "valid"}

static func find_nearest_valid_position(requested_pos: Vector2, item: Dictionary, placed_items: Array, moving_placed_id: String = "", snap_grid_size: int = 16) -> Dictionary:
	var requested := snap_world_position(requested_pos, snap_grid_size)
	var initial := validate_position(requested, item, placed_items, moving_placed_id)
	if bool(initial.get("valid", false)):
		return {"found": true, "position": requested, "reason": "valid"}
	var max_steps := int(float(MAX_NEAREST_OPEN_SEARCH_RADIUS_PX) / float(snap_grid_size))
	for radius in range(1, max_steps + 1):
		for dx in range(-radius, radius + 1):
			for dy in range(-radius, radius + 1):
				if abs(dx) != radius and abs(dy) != radius:
					continue
				var candidate := requested + Vector2(dx * snap_grid_size, dy * snap_grid_size)
				var result := validate_position(candidate, item, placed_items, moving_placed_id)
				if bool(result.get("valid", false)):
					return {"found": true, "position": candidate, "reason": "nearest_open"}
	return {"found": false, "position": requested, "reason": "No open spot nearby."}

static func footprint_rect(pos: Vector2, item: Dictionary, rotation_degrees: float = 0.0) -> Rect2:
	var size := Vector2(float(item.get("footprint_width_px", 48)), float(item.get("footprint_height_px", 48)))
	var normalized := int(abs(round(rotation_degrees))) % 180
	if normalized == 90 or normalized == 45 or normalized == 135:
		size = Vector2(maxf(size.x, size.y), maxf(size.x, size.y))
	return Rect2(pos - size * 0.5, size)

static func _zone(zone_id: String, center: Vector2, size: Vector2, reason: String, padding_px: int = DIRECT_PROXY_MARGIN_PX) -> Dictionary:
	var expanded := size + Vector2(padding_px * 2, padding_px * 2)
	return {
		"zone_id": zone_id,
		"rect": Rect2(center - expanded * 0.5, expanded),
		"reason": reason,
		"padding_px": padding_px,
		"blocks_floor_items": true,
		"blocks_wall_items": true,
		"blocks_rugs": true,
		"blocks_tabletop_items": true,
	}

static func _is_wall_item(item: Dictionary) -> bool:
	var tags: Array = item.get("placement_tags", [])
	return tags.has("wall_item") or tags.has("light") or bool(item.get("wall_only", false))

static func _wall_rect_contains(pos: Vector2) -> bool:
	for zone in wall_snap_zones():
		var rect: Rect2 = zone.get("rect", Rect2())
		if rect.has_point(pos):
			return true
	return false
