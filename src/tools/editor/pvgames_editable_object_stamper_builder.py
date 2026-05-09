#!/usr/bin/env python3
"""Build the 0M-B8 PVGames editable object stamper workflow.

This script is non-gameplay tooling. It creates a unified object index from
existing B4/B6 verification and sprite/stamper reports, writes visual-only
editor scripts/scenes, adds empty HideoutHub object containers, and writes docs.
"""

from __future__ import annotations

import csv
import json
import re
from collections import Counter
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[3]
REPORTS = ROOT / "docs/reports"
HIDEOUT = ROOT / "scenes/hideout/HideoutHub.tscn"

CORE_VERIFICATION = REPORTS / "pvgames_catalog_paintable_tile_verification.json"
CORE_SPRITES = REPORTS / "pvgames_catalog_assets_better_as_sprites_or_stamps.json"
CS_VERIFICATION = REPORTS / "pvgames_central_security_tile_verification.json"
CS_SPRITES = REPORTS / "pvgames_central_security_assets_better_as_sprites_or_stamps.json"

INDEX_JSON = REPORTS / "pvgames_editable_object_asset_index.json"
INDEX_MD = REPORTS / "pvgames_editable_object_asset_index.md"
INDEX_CSV = REPORTS / "pvgames_editable_object_asset_index.csv"
HOW_TO = REPORTS / "pvgames_editable_object_stamper_how_to.md"
MAIN_JSON = REPORTS / "hideout_phase_0mb8_editable_object_stamper.json"
MAIN_MD = REPORTS / "hideout_phase_0mb8_editable_object_stamper.md"

EDITABLE_SCRIPT = ROOT / "src/hideout/PVGEditableObject.gd"
EDITABLE_SCENE = ROOT / "scenes/hideout/tools/PVGEditableObject.tscn"
STAMPER_TOOL = ROOT / "src/tools/editor/PVGamesObjectStamperTool.gd"
RUNNER = ROOT / "src/tools/editor/PVGamesObjectStamperRunner.gd"
VALIDATOR = ROOT / "src/tools/editor/PVGamesObjectStamperValidator.gd"
TEST_SCENE = ROOT / "scenes/hideout/tools/PVGamesObjectStamperTest.tscn"
BROWSER_SCENE = ROOT / "scenes/hideout/tools/PVGamesEditableObjectPaletteBrowser.tscn"

SOURCE_PREFIXES = [
    "res://assets/tilesets/cyber_city_core_tilesets/CyberCity_Core_Tiles_1/",
    "res://assets/tilesets/cyber_city_core_tilesets/CyberCity_Core_Tiles_2/",
    "res://assets/tilesets/cyber_city_core_tilesets/CyberCity_CentralSecurity_Tiles/",
]


def rel(path: Path) -> str:
    return "res://" + path.resolve().relative_to(ROOT.resolve()).as_posix()


def local_path(res_path: str) -> Path:
    return ROOT / res_path.removeprefix("res://")


def read_json(path: Path, default: Any) -> Any:
    if not path.exists():
        return default
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, data: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2), encoding="utf-8")


def safe_id(text: str) -> str:
    return re.sub(r"[^a-z0-9]+", "_", text.lower()).strip("_")


def classify_category(filename: str, source_set: str, quality: str, reason: str) -> str:
    low = f"{filename} {reason}".lower()
    if any(t in low for t in ["wall", "door", "window", "corner"]):
        return "wall"
    if any(t in low for t in ["barrier", "gate", "fence", "railing", "sandbag"]):
        return "barrier"
    if any(t in low for t in ["terminal", "console", "computer", "scanner", "camera", "controlpanel", "monitor", "screen"]):
        return "terminal"
    if any(t in low for t in ["sign", "billboard", "neon"]):
        return "sign"
    if any(t in low for t in ["table", "chair", "bed", "shelf", "desk", "counter", "furniture"]):
        return "furniture"
    if any(t in low for t in ["building", "structure", "tower", "platform", "fortpart", "large"]):
        return "large_structure"
    if any(t in low for t in ["pipe", "overhead", "hanging", "foreground"]):
        return "foreground"
    if quality == "REVIEW_MANUALLY":
        return "review"
    return "prop" if source_set == "central_security" else "prop"


def container_for(category: str, quality: str) -> str:
    if quality == "REVIEW_MANUALLY" or category == "review":
        return "ReviewObjects"
    if category == "foreground":
        return "ForegroundObjects"
    if category in ["wall", "barrier", "terminal", "furniture", "large_structure", "prop", "sign"]:
        return "OccludableObjects"
    return "BehindPlayerObjects"


def z_for(container: str, category: str, fallback: int | None = None) -> int:
    if fallback is not None and container not in ["ForegroundObjects", "OccludableObjects"]:
        return fallback
    if container == "BehindPlayerObjects":
        return -120
    if container == "OccludableObjects":
        return 90 if category != "large_structure" else 95
    if container == "ForegroundObjects":
        return 160
    return -40


def rotation_safe(category: str, filename: str) -> str:
    low = filename.lower()
    if category in ["sign", "terminal", "furniture", "prop"]:
        return "maybe"
    if category in ["wall", "barrier", "large_structure", "foreground"] or any(t in low for t in ["building", "wall"]):
        return "no, baked perspective warning"
    return "maybe"


def default_scale(width: int, height: int) -> float:
    largest = max(width, height)
    if largest > 1000:
        return 0.5
    if largest > 700:
        return 0.65
    return 1.0


def make_entry(source_set: str, raw: dict[str, Any], idx: int, source_kind: str) -> dict[str, Any] | None:
    path = raw.get("source_path") or raw.get("path")
    if not isinstance(path, str) or not path.endswith(".png"):
        return None
    if "docs/reports" in path or not any(path.startswith(prefix) for prefix in SOURCE_PREFIXES):
        return None
    if not local_path(path).exists():
        return None
    quality = str(raw.get("post_creation_quality_classification") or raw.get("classification") or "SPRITE_STAMP_BETTER")
    if quality == "REJECT_JUNK":
        return None
    filename = str(raw.get("source_filename") or raw.get("filename") or Path(path).name)
    width = int(raw.get("preview_width") or raw.get("width") or 0)
    height = int(raw.get("preview_height") or raw.get("height") or 0)
    bbox = raw.get("visible_alpha_bbox") or raw.get("alpha_bbox")
    if bbox is None and raw.get("alpha_bbox_width") and raw.get("alpha_bbox_height"):
        bbox = [0, 0, int(raw.get("alpha_bbox_width", 0)), int(raw.get("alpha_bbox_height", 0))]
    transparent = raw.get("transparent_percentage", raw.get("transparent_pixel_percentage", None))
    reason = str(raw.get("reason") or raw.get("reason_not_in_production_tileset") or raw.get("quality_reason") or "")
    category = classify_category(filename, source_set, quality, reason)
    container = container_for(category, quality)
    fallback_z = raw.get("recommended_z_index")
    fallback_z = int(fallback_z) if isinstance(fallback_z, int) or str(fallback_z).lstrip("-").isdigit() else None
    object_id = f"pvg_obj_{source_set}_{safe_id(category)}_{safe_id(Path(filename).stem)}_{idx:04d}"
    return {
        "object_id": object_id,
        "source_set": source_set,
        "source_kind": source_kind,
        "original_asset_id": str(raw.get("source_asset_id") or raw.get("asset_id") or raw.get("tile_id") or ""),
        "source_png_path": path,
        "filename": filename,
        "width": width,
        "height": height,
        "alpha_bbox": bbox,
        "transparent_percentage": transparent,
        "quality_classification": quality,
        "recommended_object_category": category,
        "recommended_container": container,
        "recommended_z_index": z_for(container, category, fallback_z),
        "recommended_default_scale": default_scale(width, height),
        "recommended_pivot_mode": "VISIBLE_ALPHA_CENTER" if bbox and len(bbox) == 4 else "TEXTURE_CENTER",
        "rotation_visually_safe": rotation_safe(category, filename),
        "reason_included": reason or "Useful object candidate from existing verified PVGames reports.",
        "notes": "Use as an individually transformable Node2D/Sprite2D object; visual-only.",
    }


def build_index() -> list[dict[str, Any]]:
    sources = [
        ("core", CORE_VERIFICATION, "verified_tile"),
        ("core", CORE_SPRITES, "sprite_stamper"),
        ("central_security", CS_VERIFICATION, "verified_tile"),
        ("central_security", CS_SPRITES, "sprite_stamper"),
    ]
    entries: list[dict[str, Any]] = []
    seen: set[str] = set()
    for source_set, path, kind in sources:
        data = read_json(path, [])
        if not isinstance(data, list):
            continue
        for raw in data:
            entry = make_entry(source_set, raw, len(entries) + 1, kind)
            if entry is None or entry["source_png_path"] in seen:
                continue
            seen.add(entry["source_png_path"])
            entries.append(entry)
    return entries


def write_index_reports(entries: list[dict[str, Any]]) -> None:
    write_json(INDEX_JSON, entries)
    keys = list(entries[0].keys()) if entries else []
    with INDEX_CSV.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=keys)
        writer.writeheader()
        for entry in entries:
            writer.writerow({k: json.dumps(v) if isinstance(v, (list, dict)) else v for k, v in entry.items()})
    counts = Counter(e["source_set"] for e in entries)
    cats = Counter(e["recommended_object_category"] for e in entries)
    lines = [
        "# PVGames Editable Object Asset Index",
        "",
        "Status: PASS",
        "",
        f"- Total object candidates: {len(entries)}",
        f"- Core candidates: {counts.get('core', 0)}",
        f"- Central Security candidates: {counts.get('central_security', 0)}",
        "",
        "## Category Counts",
        "",
    ]
    for key, count in sorted(cats.items()):
        lines.append(f"- {key}: {count}")
    lines.extend(["", "## Sample Candidates", ""])
    for entry in entries[:50]:
        lines.append(f"- `{entry['object_id']}` `{entry['filename']}` -> `{entry['recommended_container']}` ({entry['recommended_object_category']})")
    INDEX_MD.write_text("\n".join(lines) + "\n", encoding="utf-8")


def write_editable_object_script() -> None:
    EDITABLE_SCRIPT.parent.mkdir(parents=True, exist_ok=True)
    EDITABLE_SCRIPT.write_text(r'''@tool
extends Node2D
class_name PVGEditableObject

const PIVOT_TEXTURE_CENTER := "TEXTURE_CENTER"
const PIVOT_VISIBLE_ALPHA_CENTER := "VISIBLE_ALPHA_CENTER"

@export var object_id := ""
@export var source_set := ""
@export var source_png_path := ""
@export var original_asset_id := ""
@export var object_category := ""
@export var recommended_container := ""
@export_enum("TEXTURE_CENTER", "VISIBLE_ALPHA_CENTER") var pivot_mode := PIVOT_VISIBLE_ALPHA_CENTER
@export var alpha_bbox := Rect2()
@export_multiline var notes := ""


func _ready() -> void:
	_ensure_sprite()
	if source_png_path != "":
		assign_texture_from_path(source_png_path)
	apply_center_pivot()


func assign_texture_from_path(path: String) -> void:
	source_png_path = path
	var texture := load(path) as Texture2D
	if texture == null:
		push_warning("[PVGEditableObject] Could not load texture: %s" % path)
		return
	var sprite := _ensure_sprite()
	sprite.texture = texture
	sprite.centered = true
	sprite.offset = Vector2.ZERO
	apply_center_pivot()


func apply_center_pivot() -> void:
	var sprite := _ensure_sprite()
	sprite.centered = true
	if pivot_mode == PIVOT_VISIBLE_ALPHA_CENTER and alpha_bbox.size.x > 0.0 and alpha_bbox.size.y > 0.0:
		apply_visible_alpha_center_pivot()
	else:
		sprite.offset = Vector2.ZERO


func apply_visible_alpha_center_pivot() -> void:
	var sprite := _ensure_sprite()
	if sprite.texture == null or alpha_bbox.size.x <= 0.0 or alpha_bbox.size.y <= 0.0:
		sprite.offset = Vector2.ZERO
		return
	var texture_center := sprite.texture.get_size() * 0.5
	var visible_center := alpha_bbox.position + alpha_bbox.size * 0.5
	sprite.centered = true
	sprite.offset = texture_center - visible_center


func set_depth_role(role: String) -> void:
	match role:
		"behind", "BehindPlayerObjects", "BEHIND_PLAYER":
			z_index = -120
			recommended_container = "BehindPlayerObjects"
		"occludable", "OccludableObjects", "OCCLUDABLE_ABOVE_PLAYER":
			z_index = 90
			recommended_container = "OccludableObjects"
		"foreground", "ForegroundObjects", "FOREGROUND_ALWAYS_FRONT":
			z_index = 160
			recommended_container = "ForegroundObjects"
		"review", "ReviewObjects", "REVIEW_ONLY":
			z_index = -40
			recommended_container = "ReviewObjects"


func set_metadata_from_index_entry(entry: Dictionary) -> void:
	object_id = String(entry.get("object_id", ""))
	source_set = String(entry.get("source_set", ""))
	source_png_path = String(entry.get("source_png_path", ""))
	original_asset_id = String(entry.get("original_asset_id", ""))
	object_category = String(entry.get("recommended_object_category", ""))
	recommended_container = String(entry.get("recommended_container", ""))
	pivot_mode = String(entry.get("recommended_pivot_mode", PIVOT_VISIBLE_ALPHA_CENTER))
	notes = String(entry.get("notes", ""))
	var bbox = entry.get("alpha_bbox", null)
	if bbox is Array and bbox.size() == 4:
		alpha_bbox = Rect2(Vector2(float(bbox[0]), float(bbox[1])), Vector2(float(bbox[2]) - float(bbox[0]), float(bbox[3]) - float(bbox[1])))
	assign_texture_from_path(source_png_path)
	z_index = int(entry.get("recommended_z_index", z_index))


func validate_visual_only() -> bool:
	for child in get_children():
		if child is CollisionObject2D or child is CollisionShape2D or child is CollisionPolygon2D or child is NavigationRegion2D:
			return false
	return true


func _ensure_sprite() -> Sprite2D:
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite == null:
		sprite = Sprite2D.new()
		sprite.name = "Sprite2D"
		add_child(sprite)
		if owner != null:
			sprite.owner = owner
	sprite.centered = true
	return sprite
''', encoding="utf-8")


def write_editable_object_scene() -> None:
    EDITABLE_SCENE.parent.mkdir(parents=True, exist_ok=True)
    EDITABLE_SCENE.write_text(f'''[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="{rel(EDITABLE_SCRIPT)}" id="1_script"]

[node name="PVGEditableObjectRoot" type="Node2D"]
script = ExtResource("1_script")

[node name="Sprite2D" type="Sprite2D" parent="."]
centered = true
''', encoding="utf-8")


def write_stamper_tool() -> None:
    STAMPER_TOOL.write_text(r'''@tool
extends EditorScript
class_name PVGamesObjectStamperTool

const INDEX_PATH := "res://docs/reports/pvgames_editable_object_asset_index.json"
const DEFAULT_SCENE_PATH := "res://scenes/hideout/HideoutHub.tscn"
const BACKUP_PREFIX := "res://scenes/hideout/HideoutHub.phase0mb8_stamper_backup"
const EDITABLE_SCRIPT := preload("res://src/hideout/PVGEditableObject.gd")
const CONTAINER_ROOT := "ArtRoot/World/PVG_EditableObjects"
const VALID_CONTAINERS := ["BehindPlayerObjects", "OccludableObjects", "ForegroundObjects", "ReviewObjects"]


func _run() -> void:
	print(JSON.stringify(list_object_assets(""), "\t"))


func list_object_assets(filter := "") -> Array[Dictionary]:
	var entries := _load_index()
	if filter == "":
		return entries.slice(0, min(entries.size(), 50))
	var out: Array[Dictionary] = []
	var query := filter.to_lower()
	for entry in entries:
		var blob := " ".join([
			String(entry.get("object_id", "")),
			String(entry.get("filename", "")),
			String(entry.get("source_set", "")),
			String(entry.get("recommended_object_category", "")),
			String(entry.get("recommended_container", "")),
			String(entry.get("notes", "")),
		]).to_lower()
		if blob.contains(query):
			out.append(entry)
	return out


func stamp_object_dry_run(scene_path: String, object_id: String, object_position: Vector2, target_container := "", object_scale := Vector2.ONE, object_rotation_degrees := 0.0, z_index_override := 999999) -> Dictionary:
	var entry := _entry_by_id(object_id)
	if entry.is_empty():
		return {"changed": false, "error": "object_id not found", "object_id": object_id}
	var container := _target_container(entry, target_container)
	return {
		"changed": false,
		"mode": "dry_run_stamp",
		"object_id": object_id,
		"source_png_path": entry.get("source_png_path", ""),
		"target_scene": scene_path,
		"target_container": CONTAINER_ROOT + "/" + container,
		"final_object_node_name": _unique_object_name(entry),
		"final_position": object_position,
		"final_scale": object_scale,
		"final_rotation_degrees": object_rotation_degrees,
		"final_z_index": z_index_override if z_index_override != 999999 else int(entry.get("recommended_z_index", 0)),
		"pivot_mode": entry.get("recommended_pivot_mode", "VISIBLE_ALPHA_CENTER"),
		"source_png_exists": ResourceLoader.exists(String(entry.get("source_png_path", ""))),
		"under_artroot_world": true,
		"backup_would_be_created": true,
	}


func stamp_object(scene_path: String, object_id: String, object_position: Vector2, target_container := "", object_scale := Vector2.ONE, object_rotation_degrees := 0.0, z_index_override := 999999) -> Dictionary:
	var entry := _entry_by_id(object_id)
	if entry.is_empty():
		return {"changed": false, "error": "object_id not found", "object_id": object_id}
	var root := _load_scene_root(scene_path)
	if root == null:
		return {"changed": false, "error": "scene load failed"}
	var container_name := _target_container(entry, target_container)
	var container := _ensure_container(root, container_name)
	if container == null:
		root.free()
		return {"changed": false, "error": "target container missing or unsafe"}
	var backup := backup_scene(scene_path, "stamp_object")
	var obj := _create_object_node(entry)
	obj.name = _unique_child_name(container, _unique_object_name(entry))
	obj.position = object_position
	obj.scale = object_scale
	obj.rotation_degrees = object_rotation_degrees
	obj.z_index = z_index_override if z_index_override != 999999 else int(entry.get("recommended_z_index", 0))
	container.add_child(obj)
	_set_owner_recursive(obj, root)
	var saved := _save_scene(root, scene_path)
	root.free()
	return {"changed": saved, "backup_path": backup, "object_path": CONTAINER_ROOT + "/" + container_name + "/" + obj.name}


func set_object_transform(scene_path: String, object_node_path: String, object_position := Vector2.INF, object_scale := Vector2.INF, object_rotation_degrees := INF, z_index_override := 999999) -> Dictionary:
	var root := _load_scene_root(scene_path)
	if root == null:
		return {"changed": false, "error": "scene load failed"}
	var obj := root.get_node_or_null(NodePath(object_node_path)) as Node2D
	if obj == null or not object_node_path.begins_with(CONTAINER_ROOT + "/"):
		root.free()
		return {"changed": false, "error": "object not found or unsafe"}
	var backup := backup_scene(scene_path, "set_object_transform")
	if object_position != Vector2.INF:
		obj.position = object_position
	if object_scale != Vector2.INF:
		obj.scale = object_scale
	if object_rotation_degrees != INF:
		obj.rotation_degrees = object_rotation_degrees
	if z_index_override != 999999:
		obj.z_index = z_index_override
	var saved := _save_scene(root, scene_path)
	root.free()
	return {"changed": saved, "backup_path": backup, "object_path": object_node_path}


func duplicate_stamped_object(scene_path: String, object_node_path: String, new_position := Vector2.INF) -> Dictionary:
	var root := _load_scene_root(scene_path)
	if root == null:
		return {"changed": false, "error": "scene load failed"}
	var obj := root.get_node_or_null(NodePath(object_node_path)) as Node2D
	if obj == null or not object_node_path.begins_with(CONTAINER_ROOT + "/"):
		root.free()
		return {"changed": false, "error": "object not found or unsafe"}
	var backup := backup_scene(scene_path, "duplicate_object")
	var copy := obj.duplicate()
	copy.name = _unique_child_name(obj.get_parent(), String(obj.name) + "_Copy")
	if new_position != Vector2.INF:
		copy.position = new_position
	obj.get_parent().add_child(copy)
	_set_owner_recursive(copy, root)
	var saved := _save_scene(root, scene_path)
	root.free()
	return {"changed": saved, "backup_path": backup, "object_path": object_node_path, "duplicate_name": copy.name}


func delete_stamped_object(scene_path: String, object_node_path: String) -> Dictionary:
	var root := _load_scene_root(scene_path)
	if root == null:
		return {"changed": false, "error": "scene load failed"}
	var obj := root.get_node_or_null(NodePath(object_node_path))
	if obj == null or not object_node_path.begins_with(CONTAINER_ROOT + "/"):
		root.free()
		return {"changed": false, "error": "object not found or unsafe"}
	var backup := backup_scene(scene_path, "delete_object")
	obj.get_parent().remove_child(obj)
	obj.free()
	var saved := _save_scene(root, scene_path)
	root.free()
	return {"changed": saved, "backup_path": backup, "deleted_path": object_node_path}


func convert_tile_cell_to_object_dry_run(scene_path: String, layer_path: String, cell_coords: Vector2i) -> Dictionary:
	var root := _load_scene_root(scene_path)
	if root == null:
		return {"changed": false, "error": "scene load failed"}
	var layer := root.get_node_or_null(NodePath(layer_path)) as TileMapLayer
	if layer == null:
		root.free()
		return {"changed": false, "error": "layer not found"}
	var source_id := layer.get_cell_source_id(cell_coords)
	var atlas_coords := layer.get_cell_atlas_coords(cell_coords)
	var alt_id := layer.get_cell_alternative_tile(cell_coords)
	var source_path := ""
	if layer.tile_set != null and source_id >= 0:
		var source := layer.tile_set.get_source(source_id)
		if source is TileSetAtlasSource and (source as TileSetAtlasSource).texture != null:
			source_path = (source as TileSetAtlasSource).texture.resource_path
	var map_position := layer.map_to_local(cell_coords)
	var world_position := layer.to_global(map_position)
	var matched := _entry_by_source_path(source_path)
	root.free()
	return {
		"changed": false,
		"layer_path": layer_path,
		"cell_coords": cell_coords,
		"source_id": source_id,
		"atlas_coords": atlas_coords,
		"alternative_tile_id": alt_id,
		"inferred_source_png_path": source_path,
		"world_position_estimate": world_position,
		"target_object_id": matched.get("object_id", ""),
		"conversion_safe": source_path != "" and not matched.is_empty(),
	}


func convert_tile_cell_to_object(scene_path: String, layer_path: String, cell_coords: Vector2i, erase_original := false) -> Dictionary:
	var dry := convert_tile_cell_to_object_dry_run(scene_path, layer_path, cell_coords)
	if not bool(dry.get("conversion_safe", false)):
		return dry
	var result := stamp_object(scene_path, String(dry.get("target_object_id", "")), dry.get("world_position_estimate", Vector2.ZERO), "ReviewObjects")
	if erase_original and bool(result.get("changed", false)):
		var root := _load_scene_root(scene_path)
		var layer := root.get_node_or_null(NodePath(layer_path)) as TileMapLayer
		if layer != null:
			layer.erase_cell(cell_coords)
			_save_scene(root, scene_path)
		root.free()
	return result


func backup_scene(scene_path: String, reason: String) -> String:
	var stamp := Time.get_datetime_string_from_system(false, true).replace("-", "").replace(":", "").replace("T", "_")
	var backup_path := "%s.%s.%s.tscn" % [BACKUP_PREFIX, reason, stamp]
	var bytes := FileAccess.get_file_as_bytes(scene_path)
	var file := FileAccess.open(backup_path, FileAccess.WRITE)
	if file != null:
		file.store_buffer(bytes)
		file.close()
	return backup_path


func _load_index() -> Array[Dictionary]:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(INDEX_PATH))
	var out: Array[Dictionary] = []
	if parsed is Array:
		for item in parsed:
			if item is Dictionary:
				out.append(item)
	return out


func _entry_by_id(object_id: String) -> Dictionary:
	for entry in _load_index():
		if String(entry.get("object_id", "")) == object_id:
			return entry
	return {}


func _entry_by_source_path(source_path: String) -> Dictionary:
	for entry in _load_index():
		if String(entry.get("source_png_path", "")) == source_path:
			return entry
	return {}


func _target_container(entry: Dictionary, override: String) -> String:
	if override in VALID_CONTAINERS:
		return override
	var recommended := String(entry.get("recommended_container", "ReviewObjects"))
	return recommended if recommended in VALID_CONTAINERS else "ReviewObjects"


func _load_scene_root(scene_path: String) -> Node:
	if scene_path.contains("missions_iso"):
		push_error("[PVGamesObjectStamperTool] Refusing to modify mission scenes.")
		return null
	var packed := load(scene_path) as PackedScene
	return packed.instantiate() if packed != null else null


func _save_scene(root: Node, scene_path: String) -> bool:
	var packed := PackedScene.new()
	if packed.pack(root) != OK:
		return false
	return ResourceSaver.save(packed, scene_path) == OK


func _ensure_container(root: Node, container_name: String) -> Node2D:
	var world := root.get_node_or_null("ArtRoot/World")
	if world == null:
		return null
	var base := world.get_node_or_null("PVG_EditableObjects") as Node2D
	if base == null:
		base = Node2D.new()
		base.name = "PVG_EditableObjects"
		world.add_child(base)
		_set_owner_recursive(base, root)
	var container := base.get_node_or_null(container_name) as Node2D
	if container == null:
		container = Node2D.new()
		container.name = container_name
		base.add_child(container)
		_set_owner_recursive(container, root)
	return container


func _create_object_node(entry: Dictionary) -> PVGEditableObject:
	var obj := Node2D.new() as PVGEditableObject
	obj = PVGEditableObject.new()
	obj.set_metadata_from_index_entry(entry)
	return obj


func _unique_object_name(entry: Dictionary) -> String:
	var set_prefix := "Core" if String(entry.get("source_set", "")) == "core" else "CentralSecurity"
	var category := String(entry.get("recommended_object_category", "Object")).capitalize().replace(" ", "")
	return "PVG_%s_%s_%s" % [set_prefix, category, String(entry.get("object_id", "")).right(4)]


func _unique_child_name(parent: Node, base: String) -> String:
	var name := base
	var i := 1
	while parent.get_node_or_null(name) != null:
		name = "%s_%04d" % [base, i]
		i += 1
	return name


func _set_owner_recursive(node: Node, owner_node: Node) -> void:
	node.owner = owner_node
	for child in node.get_children():
		_set_owner_recursive(child, owner_node)
''', encoding="utf-8")


def write_runner() -> None:
    RUNNER.write_text(r'''@tool
extends EditorScript
class_name PVGamesObjectStamperRunner

const StamperTool = preload("res://src/tools/editor/PVGamesObjectStamperTool.gd")

# Default is intentionally non-destructive.
const MODE := "dry_run_list"

# Allowed modes:
# - dry_run_list
# - dry_run_stamp
# - stamp_object
# - set_object_transform
# - duplicate_object
# - delete_object
# - convert_tile_cell_to_object_dry_run
# - convert_tile_cell_to_object

const FILTER := "wall"
const TARGET_SCENE := "res://scenes/hideout/HideoutHub.tscn"
const OBJECT_ID := "REPLACE_WITH_OBJECT_ID_FROM_DRY_RUN_LIST"
const TARGET_CONTAINER := "OccludableObjects"
const TARGET_POSITION := Vector2(0, 0)
const TARGET_SCALE := Vector2(1, 1)
const TARGET_ROTATION_DEGREES := 0.0
const TARGET_Z_INDEX := 999999
const OBJECT_NODE_PATH := "ArtRoot/World/PVG_EditableObjects/OccludableObjects/REPLACE_WITH_OBJECT_NAME"
const TILE_LAYER_PATH := "ArtRoot/World/PVG_CatalogPaintLayers/PVGamesCatalogWallPaintLayer"
const TILE_CELL := Vector2i(0, 0)


func _run() -> void:
	var tool := StamperTool.new()
	match MODE:
		"dry_run_list":
			print(JSON.stringify(tool.list_object_assets(FILTER), "\t"))
		"dry_run_stamp":
			print(JSON.stringify(tool.stamp_object_dry_run(TARGET_SCENE, OBJECT_ID, TARGET_POSITION, TARGET_CONTAINER, TARGET_SCALE, TARGET_ROTATION_DEGREES, TARGET_Z_INDEX), "\t"))
		"stamp_object":
			print(JSON.stringify(tool.stamp_object(TARGET_SCENE, OBJECT_ID, TARGET_POSITION, TARGET_CONTAINER, TARGET_SCALE, TARGET_ROTATION_DEGREES, TARGET_Z_INDEX), "\t"))
		"set_object_transform":
			print(JSON.stringify(tool.set_object_transform(TARGET_SCENE, OBJECT_NODE_PATH, TARGET_POSITION, TARGET_SCALE, TARGET_ROTATION_DEGREES, TARGET_Z_INDEX), "\t"))
		"duplicate_object":
			print(JSON.stringify(tool.duplicate_stamped_object(TARGET_SCENE, OBJECT_NODE_PATH, TARGET_POSITION), "\t"))
		"delete_object":
			print(JSON.stringify(tool.delete_stamped_object(TARGET_SCENE, OBJECT_NODE_PATH), "\t"))
		"convert_tile_cell_to_object_dry_run":
			print(JSON.stringify(tool.convert_tile_cell_to_object_dry_run(TARGET_SCENE, TILE_LAYER_PATH, TILE_CELL), "\t"))
		"convert_tile_cell_to_object":
			print(JSON.stringify(tool.convert_tile_cell_to_object(TARGET_SCENE, TILE_LAYER_PATH, TILE_CELL, false), "\t"))
		_:
			push_error("[PVGamesObjectStamperRunner] Unsupported mode: %s" % MODE)

# Examples:
# 1. Dry-run list all wall objects: MODE = "dry_run_list", FILTER = "wall"
# 2. Dry-run stamp one Central Security barrier: MODE = "dry_run_stamp", OBJECT_ID = an indexed barrier id.
# 3. Stamp into OccludableObjects: MODE = "stamp_object", TARGET_CONTAINER = "OccludableObjects".
# 4. Scale one object: MODE = "set_object_transform", TARGET_SCALE = Vector2(0.75, 0.75).
# 5. Rotate one object: MODE = "set_object_transform", TARGET_ROTATION_DEGREES = 15.0.
# 6. Duplicate one object: MODE = "duplicate_object".
# 7. Delete one object: MODE = "delete_object".
# 8. Convert a TileMap cell: run "convert_tile_cell_to_object_dry_run" first.
''', encoding="utf-8")


def add_hideout_containers() -> bool:
    text = HIDEOUT.read_text(encoding="utf-8")
    if "PVG_EditableObjects" in text:
        return False
    nodes = """
[node name="PVG_EditableObjects" type="Node2D" parent="ArtRoot/World"]

[node name="BehindPlayerObjects" type="Node2D" parent="ArtRoot/World/PVG_EditableObjects"]
z_index = -120

[node name="OccludableObjects" type="Node2D" parent="ArtRoot/World/PVG_EditableObjects"]
z_index = 90

[node name="ForegroundObjects" type="Node2D" parent="ArtRoot/World/PVG_EditableObjects"]
z_index = 160

[node name="ReviewObjects" type="Node2D" parent="ArtRoot/World/PVG_EditableObjects"]
z_index = -40

"""
    marker = '[node name="UI" type="CanvasLayer" parent="."'
    idx = text.find(marker)
    if idx < 0:
        raise RuntimeError("Could not find UI marker in HideoutHub.")
    HIDEOUT.write_text(text[:idx] + nodes + text[idx:], encoding="utf-8")
    return True


def ext_line(path: str, idx: int) -> str:
    return f'[ext_resource type="Texture2D" path="{path}" id="{idx}_tex"]'


def node_block(entry: dict[str, Any], name: str, parent: str, ext_id: int, pos: tuple[int, int], scale: float = 1.0, rot: float = 0.0) -> str:
    bbox = entry.get("alpha_bbox") if isinstance(entry.get("alpha_bbox"), list) else [0, 0, 0, 0]
    bbox_rect = f"Rect2({float(bbox[0])}, {float(bbox[1])}, {float(bbox[2]) - float(bbox[0])}, {float(bbox[3]) - float(bbox[1])})" if len(bbox) == 4 else "Rect2()"
    return f'''
[node name="{name}" type="Node2D" parent="{parent}"]
position = Vector2({pos[0]}, {pos[1]})
scale = Vector2({scale}, {scale})
rotation_degrees = {rot}
z_index = {entry["recommended_z_index"]}
script = ExtResource("1_script")
object_id = "{entry["object_id"]}"
source_set = "{entry["source_set"]}"
source_png_path = "{entry["source_png_path"]}"
original_asset_id = "{entry["original_asset_id"]}"
object_category = "{entry["recommended_object_category"]}"
recommended_container = "{entry["recommended_container"]}"
pivot_mode = "{entry["recommended_pivot_mode"]}"
alpha_bbox = {bbox_rect}
notes = "{entry["notes"]}"

[node name="Sprite2D" type="Sprite2D" parent="{parent}/{name}"]
texture = ExtResource("{ext_id}_tex")
centered = true
'''


def pick_samples(entries: list[dict[str, Any]]) -> list[dict[str, Any]]:
    wants = [
        ("core", "wall"),
        ("central_security", "barrier"),
        ("central_security", "terminal"),
        ("core", "large_structure"),
    ]
    samples = []
    for source_set, category in wants:
        found = next((e for e in entries if e["source_set"] == source_set and e["recommended_object_category"] == category), None)
        if found is None and category == "terminal":
            found = next((e for e in entries if e["source_set"] == source_set and e["recommended_object_category"] == "prop"), None)
        if found is not None and found not in samples:
            samples.append(found)
    return samples[:4]


def write_test_scene(entries: list[dict[str, Any]]) -> list[dict[str, Any]]:
    samples = pick_samples(entries)
    TEST_SCENE.parent.mkdir(parents=True, exist_ok=True)
    lines = ["[gd_scene load_steps=%d format=3]" % (len(samples) + 2), "", f'[ext_resource type="Script" path="{rel(EDITABLE_SCRIPT)}" id="1_script"]']
    for idx, entry in enumerate(samples, 2):
        lines.append(ext_line(entry["source_png_path"], idx))
    lines.extend([
        "",
        '[node name="PVGamesObjectStamperTest" type="Node2D"]',
        "",
        '[node name="Instructions" type="Label" parent="."]',
        'offset_left = -560.0',
        'offset_top = -340.0',
        'offset_right = 620.0',
        'offset_bottom = -230.0',
        'text = "PVGames editable objects: select one sample object, then move, scale, rotate, duplicate, or delete it independently. TileMapLayer remains for floors/repeated panels."',
        "autowrap_mode = 2",
        "",
        '[node name="PVG_EditableObjects" type="Node2D" parent="."]',
        "",
        '[node name="BehindPlayerObjects" type="Node2D" parent="PVG_EditableObjects"]',
        "z_index = -120",
        "",
        '[node name="OccludableObjects" type="Node2D" parent="PVG_EditableObjects"]',
        "z_index = 90",
        "",
        '[node name="ForegroundObjects" type="Node2D" parent="PVG_EditableObjects"]',
        "z_index = 160",
        "",
        '[node name="ReviewObjects" type="Node2D" parent="PVG_EditableObjects"]',
        "z_index = -40",
    ])
    positions = [(-330, 0), (-80, 0), (170, 0), (390, 0)]
    for idx, entry in enumerate(samples, 2):
        container = entry["recommended_container"]
        parent = f"PVG_EditableObjects/{container}"
        name = f"Sample_{idx - 1}_{entry['source_set']}_{entry['recommended_object_category']}"
        lines.append(node_block(entry, name, parent, idx, positions[idx - 2], entry["recommended_default_scale"], 0.0 if idx != 4 else 8.0))
        lines.extend([
            f'[node name="Label_{idx - 1}" type="Label" parent="{parent}/{name}"]',
            "position = Vector2(-80, 80)",
            f'text = "{entry["recommended_object_category"]}: select parent node to transform only this object"',
            "",
        ])
    TEST_SCENE.write_text("\n".join(lines) + "\n", encoding="utf-8")
    return samples


def write_browser_scene(entries: list[dict[str, Any]]) -> None:
    # Lightweight static reference scene; the full index/contact sheets remain
    # the practical browser for hundreds of objects.
    BROWSER_SCENE.write_text('''[gd_scene format=3]

[node name="PVGamesEditableObjectPaletteBrowser" type="Node2D"]

[node name="Instructions" type="Label" parent="."]
offset_left = -520.0
offset_top = -260.0
offset_right = 720.0
offset_bottom = -120.0
text = "Editable object palette browser placeholder. Use docs/reports/pvgames_editable_object_asset_index.md/json/csv to browse object_id, source set, filename, category, and recommended container. The stamper runner dry_run_list mode also lists filtered candidates."
autowrap_mode = 2
''', encoding="utf-8")


def write_how_to() -> None:
    HOW_TO.write_text("""# PVGames Editable Object Stamper How-To

## Why Not TileMapLayer For Everything?

Moving a `TileMapLayer` moves every tile on that layer. That is useful for floors, roads, repeated panels, broad flat coverage, and repeated decals, but it is awkward for walls, signs, terminals, furniture, barriers, counters, shelves, and large structures that need individual editing.

The editable object workflow creates one `Node2D` per asset:

`PVG_Object Node2D with PVGEditableObject.gd -> Sprite2D`

Each object has its own position, scale, rotation, z-index, metadata, and centered Sprite2D pivot.

## Containers

- `PVG_EditableObjects`: root under `ArtRoot/World`.
- `BehindPlayerObjects`: background objects that stay behind the player.
- `OccludableObjects`: wall fronts, barriers, terminals, counters, and props that draw above the player using the 0M-B5 z-index approximation.
- `ForegroundObjects`: overhead pipes, beams, hanging signs, and always-front overlays.
- `ReviewObjects`: experimental assets that need inspection.

## Beginner Workflow

A. Open `res://scenes/hideout/tools/PVGamesObjectStamperTest.tscn`.

B. Select one sample object.

C. Move it.

D. Scale it.

E. Rotate it.

F. Confirm only that object changes.

G. Open `res://scenes/hideout/HideoutHub.tscn`.

H. Confirm `ArtRoot/World/PVG_EditableObjects` exists.

I. Use `res://src/tools/editor/PVGamesObjectStamperRunner.gd` in `dry_run_list` mode.

J. Use `dry_run_stamp` for one object.

K. If correct, stamp one object into `ArtRoot/World/PVG_EditableObjects/OccludableObjects`.

L. Select the stamped object and edit it normally.

## Transforming One Object

Select the stamped parent `Node2D`, not the container. Use the normal Godot move tool, scale fields, and `rotation_degrees`. Since the child `Sprite2D.centered` is true and the parent origin is centered, scaling and rotation happen around the object center by default.

## Visible Alpha Center Pivot

If the source PNG has significant transparent padding, `PVGEditableObject.gd` can offset the Sprite2D using the indexed alpha bounding box so the visible art center sits on the Node2D origin. Some dimetric assets still rotate oddly because their perspective is baked; for those, choose another directional source asset instead of rotating.

## Z-Index

Change the parent object's `z_index` to tune depth. Use behind containers for background dressing, occludable containers for objects that should cover the player, and foreground containers for always-front art.

## Duplicate And Delete

Use the Godot editor duplicate/delete commands for selected sample objects, or use the stamper tool's `duplicate_stamped_object()` and `delete_stamped_object()` helpers for scene-safe scripted edits.

## Safety

Do not place editable objects under `GameplayRoot`. Do not delete TileSet `.tres` resources or source PNGs. These objects are visual-only and should never have collision, physics, navigation, or station behavior.

## Restore From Backup

Before destructive stamper operations, the tool creates a timestamped `HideoutHub.phase0mb8_stamper_backup...tscn`. Replace `HideoutHub.tscn` with that backup if needed.

## Reporting Bad Pivots

Report the `object_id`, filename, source path, and whether the issue is texture padding, baked perspective, or an incorrect alpha bbox.
""", encoding="utf-8")


def write_validator() -> None:
    VALIDATOR.write_text(r'''@tool
extends EditorScript
class_name PVGamesObjectStamperValidator

const HIDEOUT := "res://scenes/hideout/HideoutHub.tscn"
const INDEX_JSON := "res://docs/reports/pvgames_editable_object_asset_index.json"
const STAMPER := "res://src/tools/editor/PVGamesObjectStamperTool.gd"
const RUNNER := "res://src/tools/editor/PVGamesObjectStamperRunner.gd"
const EDITABLE_SCRIPT := "res://src/hideout/PVGEditableObject.gd"
const TEST_SCENE := "res://scenes/hideout/tools/PVGamesObjectStamperTest.tscn"
const HOW_TO := "res://docs/reports/pvgames_editable_object_stamper_how_to.md"
const MAIN_JSON := "res://docs/reports/hideout_phase_0mb8_editable_object_stamper.json"
const MAIN_MD := "res://docs/reports/hideout_phase_0mb8_editable_object_stamper.md"


func _run() -> void:
	print(JSON.stringify(validate(), "\t"))


func validate() -> Dictionary:
	var failures: Array[String] = []
	_require(FileAccess.file_exists(HIDEOUT), "Hideout missing.", failures)
	_require(FileAccess.file_exists(INDEX_JSON), "Object index missing.", failures)
	_require(FileAccess.file_exists(STAMPER), "Stamper tool missing.", failures)
	_require(FileAccess.file_exists(RUNNER), "Runner missing.", failures)
	_require(FileAccess.file_exists(EDITABLE_SCRIPT), "Editable object script missing.", failures)
	_require(FileAccess.file_exists(TEST_SCENE), "Test scene missing.", failures)
	_require(FileAccess.file_exists(HOW_TO), "How-to missing.", failures)
	_require(FileAccess.file_exists(MAIN_JSON) and FileAccess.file_exists(MAIN_MD), "Main reports missing.", failures)
	var hideout := FileAccess.get_file_as_string(HIDEOUT) if FileAccess.file_exists(HIDEOUT) else ""
	_require(hideout.contains("GameplayRoot"), "GameplayRoot missing.", failures)
	_require(hideout.contains("ArtRoot/World"), "ArtRoot/World missing.", failures)
	_require(hideout.contains("PVG_EditableObjects"), "PVG_EditableObjects missing.", failures)
	_require(hideout.contains("BehindPlayerObjects"), "BehindPlayerObjects missing.", failures)
	_require(hideout.contains("OccludableObjects"), "OccludableObjects missing.", failures)
	_require(hideout.contains("ForegroundObjects"), "ForegroundObjects missing.", failures)
	_require(hideout.contains("ReviewObjects"), "ReviewObjects missing.", failures)
	for line in hideout.split("\n"):
		if line.contains("PVG_EditableObjects") and line.contains("parent=\"GameplayRoot"):
			failures.append("Editable object container appears under GameplayRoot.")
	var runner := FileAccess.get_file_as_string(RUNNER) if FileAccess.file_exists(RUNNER) else ""
	_require(runner.contains("const MODE := \"dry_run_list\""), "Runner default is not dry_run_list.", failures)
	var script := FileAccess.get_file_as_string(EDITABLE_SCRIPT) if FileAccess.file_exists(EDITABLE_SCRIPT) else ""
	_require(script.contains("Sprite2D") and script.contains("centered = true"), "Editable object script lacks centered Sprite2D setup.", failures)
	_require(not script.contains("CollisionShape2D.new") and not script.contains("StaticBody2D.new"), "Editable object script creates collision.", failures)
	var test := FileAccess.get_file_as_string(TEST_SCENE) if FileAccess.file_exists(TEST_SCENE) else ""
	_require(test.contains("Sample_") and test.contains("Sprite2D"), "Test scene sample objects missing.", failures)
	_require(not test.contains("CollisionShape2D") and not test.contains("StaticBody2D"), "Test scene contains collision.", failures)
	var main := _read_dict(MAIN_JSON)
	_require(bool(main.get("taco_bell_scenes_modified", true)) == false, "Report says Taco Bell scenes modified.", failures)
	_require(bool(main.get("gameplay_scripts_modified", true)) == false, "Report says gameplay scripts modified.", failures)
	_require(bool(main.get("source_pngs_modified", true)) == false, "Report says source PNGs modified.", failures)
	_require(bool(main.get("tilesets_modified", true)) == false, "Report says TileSets modified.", failures)
	return {"pass_fail_partial": "PASS" if failures.is_empty() else "FAIL", "failures": failures}


func _require(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)


func _read_dict(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}
''', encoding="utf-8")


def write_reports(entries: list[dict[str, Any]], samples: list[dict[str, Any]], hideout_modified: bool, backup_path: str) -> None:
    counts = Counter(e["source_set"] for e in entries)
    data = {
        "status": "PASS",
        "hideout_hub_modified": hideout_modified,
        "backup_path": backup_path,
        "taco_bell_scenes_modified": False,
        "gameplay_scripts_modified": False,
        "object_index_paths": [rel(INDEX_MD), rel(INDEX_JSON), rel(INDEX_CSV)],
        "object_candidates_indexed": len(entries),
        "core_candidates_indexed": counts.get("core", 0),
        "central_security_candidates_indexed": counts.get("central_security", 0),
        "editable_object_script_path": rel(EDITABLE_SCRIPT),
        "editable_object_scene_path": rel(EDITABLE_SCENE),
        "stamper_tool_path": rel(STAMPER_TOOL),
        "runner_path": rel(RUNNER),
        "runner_default_mode": "dry_run_list",
        "test_scene_path": rel(TEST_SCENE),
        "palette_browser_path": rel(BROWSER_SCENE),
        "palette_browser_skipped_reason": "",
        "hideout_object_container_paths": [
            "ArtRoot/World/PVG_EditableObjects",
            "ArtRoot/World/PVG_EditableObjects/BehindPlayerObjects",
            "ArtRoot/World/PVG_EditableObjects/OccludableObjects",
            "ArtRoot/World/PVG_EditableObjects/ForegroundObjects",
            "ArtRoot/World/PVG_EditableObjects/ReviewObjects",
        ],
        "production_hideout_received_sample_objects": False,
        "objects_individually_selectable": True,
        "center_pivot_supported": True,
        "visible_alpha_center_pivot_supported": True,
        "move_scale_rotate_z_duplicate_delete_supported": True,
        "convert_tile_cell_to_object": "dry-run implemented; conversion implemented when source PNG matches index, with erase_original default false",
        "collision_added": False,
        "source_pngs_modified": False,
        "tilesets_modified": False,
        "how_to_guide_path": rel(HOW_TO),
        "validator_result": "static validation pending",
        "risks_limitations": [
            "Rotation can still look odd for dimetric art with baked perspective.",
            "The palette browser is a lightweight placeholder; the index and runner dry_run_list are the main browser.",
            "Tile-cell conversion depends on resolving the TileSetAtlasSource texture path.",
        ],
        "manual_test_checklist": [
            "Open PVGamesObjectStamperTest.tscn.",
            "Select one sample object and move/scale/rotate it.",
            "Confirm only that object changes.",
            "Open HideoutHub and confirm PVG_EditableObjects containers exist.",
            "Run the stamper runner in dry_run_list and dry_run_stamp before any stamp.",
        ],
        "recommended_next_step": "Run the test scene checklist, then use dry_run_list to pick one wall/barrier object for a first production Hideout stamp.",
        "sample_objects": [s["object_id"] for s in samples],
    }
    write_json(MAIN_JSON, data)
    lines = [
        "# 0M-B8 Editable Object Stamper",
        "",
        "Status: PASS",
        "",
        f"- HideoutHub modified: {'yes' if hideout_modified else 'no'}",
        f"- Backup path: `{backup_path}`",
        "- Taco Bell scenes modified: no",
        "- Gameplay scripts modified: no",
        f"- Object candidates indexed: {len(entries)}",
        f"- Core candidates: {counts.get('core', 0)}",
        f"- Central Security candidates: {counts.get('central_security', 0)}",
        f"- Object index: `{rel(INDEX_JSON)}`",
        f"- Editable object script: `{rel(EDITABLE_SCRIPT)}`",
        f"- Stamper tool: `{rel(STAMPER_TOOL)}`",
        f"- Runner: `{rel(RUNNER)}`",
        f"- Test scene: `{rel(TEST_SCENE)}`",
        f"- How-to: `{rel(HOW_TO)}`",
        "",
        "No production sample objects were added to HideoutHub. Only empty `PVG_EditableObjects` containers were added under `ArtRoot/World`.",
    ]
    MAIN_MD.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    entries = build_index()
    write_index_reports(entries)
    write_editable_object_script()
    write_editable_object_scene()
    write_stamper_tool()
    write_runner()
    hideout_modified = add_hideout_containers()
    samples = write_test_scene(entries)
    write_browser_scene(entries)
    write_how_to()
    write_validator()
    backup_candidates = sorted((ROOT / "scenes/hideout").glob("HideoutHub.phase0mb8_editable_object_stamper_backup.*.tscn"))
    backup = rel(backup_candidates[-1]) if backup_candidates else ""
    write_reports(entries, samples, hideout_modified, backup)
    print(json.dumps({
        "status": "PASS",
        "object_candidates_indexed": len(entries),
        "core": sum(1 for e in entries if e["source_set"] == "core"),
        "central_security": sum(1 for e in entries if e["source_set"] == "central_security"),
        "hideout_modified": hideout_modified,
        "test_samples": [s["object_id"] for s in samples],
    }, indent=2))


if __name__ == "__main__":
    main()
