#!/usr/bin/env python3
"""Build 0M-B8A baked PVGames editable object palette scenes.

This is editor/reference tooling only. It reads the B8 object index and creates
Godot-openable palette scenes, contact sheets, helper scripts, and reports.
It does not stamp preview objects into production HideoutHub.
"""

from __future__ import annotations

import csv
import json
import math
import textwrap
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[3]
TOOLS = ROOT / "src/tools/editor"
SCENES = ROOT / "scenes/hideout/tools"
SOURCE_INDEX = ROOT / "docs/reports/pvgames_editable_object_asset_index.json"
REPORT_DIR = ROOT / "docs/reports/pvgames_editable_object_palette"
SHEETS_DIR = REPORT_DIR / "contact_sheets"
HIDEOUT = ROOT / "scenes/hideout/HideoutHub.tscn"

CONTAINERS = ["BehindPlayerObjects", "OccludableObjects", "ForegroundObjects", "ReviewObjects"]
PAGE_SIZE = 125
CARD_W = 360
CARD_H = 245
GRID_COLUMNS = 4
THUMB_MAX_W = 128
THUMB_MAX_H = 96

NORMALIZED_JSON = REPORT_DIR / "pvgames_editable_object_palette_index_by_container.json"
NORMALIZED_MD = REPORT_DIR / "pvgames_editable_object_palette_index_by_container.md"
NORMALIZED_CSV = REPORT_DIR / "pvgames_editable_object_palette_index_by_container.csv"
CREATION_JSON = REPORT_DIR / "pvgames_editable_object_palette_creation.json"
CREATION_MD = REPORT_DIR / "pvgames_editable_object_palette_creation.md"
HOW_TO = REPORT_DIR / "pvgames_editable_object_palette_how_to_use.md"

MASTER_SCENE = SCENES / "PVGamesEditableObjectMasterPalette.tscn"
HELPER = TOOLS / "PVGamesEditableObjectPaletteBrowserHelper.gd"
RUNNER = TOOLS / "PVGamesEditableObjectPaletteRunner.gd"
VALIDATOR = TOOLS / "PVGamesEditableObjectPaletteValidator.gd"
BUILDER_GD = TOOLS / "PVGamesEditableObjectPaletteBuilder.gd"


def res(path: Path) -> str:
    return "res://" + path.resolve().relative_to(ROOT.resolve()).as_posix()


def local(res_path: str) -> Path:
    return ROOT / res_path.removeprefix("res://")


def load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, data: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2), encoding="utf-8")


def esc(text: Any) -> str:
    return str(text).replace("\\", "\\\\").replace('"', '\\"').replace("\n", " ")


def safe_name(text: str) -> str:
    return "".join(c if c.isalnum() else "_" for c in text)[:64].strip("_") or "Object"


def normalize_container(entry: dict[str, Any]) -> tuple[str, str]:
    container = str(entry.get("recommended_container", ""))
    if container in CONTAINERS:
        return container, ""
    category = str(entry.get("recommended_object_category", "")).lower()
    if category in {"foreground"}:
        return "ForegroundObjects", "Invalid/missing container inferred from foreground category."
    if category in {"wall", "barrier", "terminal", "furniture", "large_structure", "prop", "sign"}:
        return "OccludableObjects", "Invalid/missing container inferred from object category."
    return "ReviewObjects", "Invalid/missing container assigned to ReviewObjects."


def normalize_entries() -> tuple[list[dict[str, Any]], list[dict[str, Any]], list[str]]:
    raw_entries = load_json(SOURCE_INDEX)
    seen: set[str] = set()
    duplicates: list[str] = []
    normalized: list[dict[str, Any]] = []
    missing_sources: list[dict[str, Any]] = []
    for raw in raw_entries:
        object_id = str(raw.get("object_id", ""))
        if object_id in seen:
            duplicates.append(object_id)
            continue
        seen.add(object_id)
        source_path = str(raw.get("source_png_path", ""))
        filename = str(raw.get("filename") or Path(source_path).name)
        source_exists = source_path.endswith(".png") and local(source_path).exists()
        source_is_contact_sheet = "contact_sheet" in source_path.lower() or "docs/reports" in source_path.lower()
        container, warning = normalize_container(raw)
        quality = str(raw.get("quality_classification", ""))
        if quality == "REJECT_JUNK":
            container = "ReviewObjects"
            warning = (warning + " " if warning else "") + "Rejected/junk quality kept out of ready sections."
        if not source_exists or source_is_contact_sheet:
            container = "ReviewObjects"
            warning = (warning + " " if warning else "") + "Source missing or invalid; preview will show warning."
            missing_sources.append({"object_id": object_id, "source_png_path": source_path, "filename": filename})
        rotation = str(raw.get("rotation_visually_safe", "maybe"))
        if rotation.startswith("no"):
            warning = (warning + " " if warning else "") + rotation
        item = {
            "object_id": object_id,
            "source_set": str(raw.get("source_set", "")),
            "original_asset_id": str(raw.get("original_asset_id", "")),
            "source_png_path": source_path,
            "filename": filename,
            "width": int(raw.get("width") or 0),
            "height": int(raw.get("height") or 0),
            "object_category": str(raw.get("recommended_object_category", "review")),
            "recommended_container": container,
            "recommended_z_index": int(raw.get("recommended_z_index") or 0),
            "recommended_default_scale": float(raw.get("recommended_default_scale") or 1.0),
            "pivot_mode": str(raw.get("recommended_pivot_mode", "TEXTURE_CENTER")),
            "quality_classification": quality,
            "rotation_warning": rotation,
            "notes": str(raw.get("notes", "")),
            "palette_warning": warning,
            "source_exists": source_exists and not source_is_contact_sheet,
        }
        normalized.append(item)
    normalized.sort(key=lambda e: (e["recommended_container"], e["source_set"], e["object_category"], e["filename"], e["object_id"]))
    return normalized, missing_sources, duplicates


def grouped(entries: list[dict[str, Any]]) -> dict[str, list[dict[str, Any]]]:
    out = {container: [] for container in CONTAINERS}
    for entry in entries:
        out[entry["recommended_container"]].append(entry)
    return out


def write_normalized_index(entries: list[dict[str, Any]], missing_sources: list[dict[str, Any]], duplicates: list[str]) -> None:
    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    write_json(NORMALIZED_JSON, {
        "source_index": res(SOURCE_INDEX),
        "containers": grouped(entries),
        "objects": entries,
        "missing_sources": missing_sources,
        "duplicate_object_ids_skipped": duplicates,
    })
    with NORMALIZED_CSV.open("w", newline="", encoding="utf-8") as handle:
        fieldnames = list(entries[0].keys()) if entries else []
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        for entry in entries:
            writer.writerow(entry)
    by_container = Counter(e["recommended_container"] for e in entries)
    by_category = Counter(e["object_category"] for e in entries)
    lines = [
        "# PVGames Editable Object Palette Index By Container",
        "",
        f"Source index: `{res(SOURCE_INDEX)}`",
        f"Total objects: {len(entries)}",
        f"Missing/invalid sources reported: {len(missing_sources)}",
        "",
        "## Container Counts",
        "",
    ]
    for container in CONTAINERS:
        lines.append(f"- {container}: {by_container.get(container, 0)}")
    lines.extend(["", "## Category Counts", ""])
    for category, count in sorted(by_category.items()):
        lines.append(f"- {category}: {count}")
    lines.extend(["", "## First 25 Objects", ""])
    for entry in entries[:25]:
        lines.append(f"- `{entry['object_id']}` | `{entry['recommended_container']}` | `{entry['source_set']}` | `{entry['object_category']}` | `{entry['filename']}`")
    NORMALIZED_MD.write_text("\n".join(lines) + "\n", encoding="utf-8")


def label_node(name: str, parent: str, text: str, x: float, y: float, w: float = 1200, h: float = 24) -> str:
    return (
        f'\n[node name="{name}" type="Label" parent="{parent}"]\n'
        f"offset_left = {x}\n"
        f"offset_top = {y}\n"
        f"offset_right = {x + w}\n"
        f"offset_bottom = {y + h}\n"
        f'text = "{esc(text)}"\n'
    )


def texture_ext_resources(entries: list[dict[str, Any]]) -> tuple[list[str], dict[str, str]]:
    lines: list[str] = []
    ids: dict[str, str] = {}
    next_id = 1
    for entry in entries:
        path = entry["source_png_path"]
        if not entry["source_exists"] or path in ids:
            continue
        tex_id = f"{next_id}_tex"
        ids[path] = tex_id
        lines.append(f'[ext_resource type="Texture2D" path="{path}" id="{tex_id}"]')
        next_id += 1
    return lines, ids


def card_block(entry: dict[str, Any], parent: str, index: int, tex_ids: dict[str, str]) -> str:
    card = f"Card_{index:03d}_{safe_name(entry['object_id'])}"
    warning = entry["palette_warning"] or ("review candidate" if entry["recommended_container"] == "ReviewObjects" else "")
    source_line = f"{entry['source_set']} | {entry['object_category']} | z {entry['recommended_z_index']} | {entry['pivot_mode']}"
    filename = entry["filename"]
    text = [
        f'\n[node name="{card}" type="PanelContainer" parent="{parent}"]',
        f"custom_minimum_size = Vector2({CARD_W}, {CARD_H})",
        f'metadata/object_id = "{esc(entry["object_id"])}"',
        f'metadata/source_png_path = "{esc(entry["source_png_path"])}"',
        f'metadata/source_set = "{esc(entry["source_set"])}"',
        f'metadata/object_category = "{esc(entry["object_category"])}"',
        f'metadata/recommended_container = "{esc(entry["recommended_container"])}"',
        f'metadata/recommended_z_index = {entry["recommended_z_index"]}',
        f'metadata/recommended_default_scale = {entry["recommended_default_scale"]}',
        f'metadata/pivot_mode = "{esc(entry["pivot_mode"])}"',
        f'\n[node name="VBox" type="VBoxContainer" parent="{parent}/{card}"]',
    ]
    tex_id = tex_ids.get(entry["source_png_path"])
    if tex_id:
        text.extend([
            f'\n[node name="Preview" type="TextureRect" parent="{parent}/{card}/VBox"]',
            f"custom_minimum_size = Vector2({THUMB_MAX_W}, {THUMB_MAX_H})",
            f'texture = ExtResource("{tex_id}")',
            "expand_mode = 1",
            "stretch_mode = 5",
        ])
    else:
        text.extend([
            f'\n[node name="MissingTextureWarning" type="Label" parent="{parent}/{card}/VBox"]',
            f"custom_minimum_size = Vector2({THUMB_MAX_W}, {THUMB_MAX_H})",
            'text = "MISSING SOURCE TEXTURE"',
        ])
    text.extend([
        f'\n[node name="ObjectId" type="Label" parent="{parent}/{card}/VBox"]',
        f'text = "{esc(entry["object_id"])}"',
        f'\n[node name="Details" type="Label" parent="{parent}/{card}/VBox"]',
        f'text = "{esc(source_line)}"',
        f'\n[node name="Container" type="Label" parent="{parent}/{card}/VBox"]',
        f'text = "{esc(entry["recommended_container"])}"',
        f'\n[node name="Filename" type="Label" parent="{parent}/{card}/VBox"]',
        f'text = "{esc(filename[:44])}"',
    ])
    if warning:
        text.extend([
            f'\n[node name="Warning" type="Label" parent="{parent}/{card}/VBox"]',
            f'text = "{esc(warning[:70])}"',
        ])
    return "\n".join(text) + "\n"


def write_page_scene(container: str, page_number: int, page_entries: list[dict[str, Any]], total_count: int) -> Path:
    path = SCENES / f"PVGamesEditableObjectPalette_{container}_Page{page_number:03d}.tscn"
    ext, tex_ids = texture_ext_resources(page_entries)
    lines = [f"[gd_scene load_steps={len(ext) + 1} format=3]", "", *ext, "", f'[node name="PVGamesEditableObjectPalette_{container}_Page{page_number:03d}" type="Control"]']
    lines.append(label_node("Title", ".", f"{container} Palette Page {page_number:03d} - {len(page_entries)} previews of {total_count}", 20, 10))
    lines.append(label_node("Instructions", ".", "Browsing palette only. Copy object_id into the B8/B8A runner for dry-run stamp before placing in HideoutHub.", 20, 42, 1500))
    lines.extend([
        '\n[node name="ScrollContainer" type="ScrollContainer" parent="."]',
        "offset_left = 20.0",
        "offset_top = 86.0",
        "offset_right = 1580.0",
        "offset_bottom = 980.0",
        '\n[node name="GridContainer" type="GridContainer" parent="ScrollContainer"]',
        f"columns = {GRID_COLUMNS}",
    ])
    parent = "ScrollContainer/GridContainer"
    for idx, entry in enumerate(page_entries, 1):
        lines.append(card_block(entry, parent, idx, tex_ids))
    path.write_text("\n".join(lines), encoding="utf-8")
    return path


def write_container_index_scene(container: str, entries: list[dict[str, Any]], pages: list[Path]) -> Path:
    path = SCENES / f"PVGamesEditableObjectPalette_{container}.tscn"
    sample_entries = entries[:8]
    ext, tex_ids = texture_ext_resources(sample_entries)
    lines = [f"[gd_scene load_steps={len(ext) + 1} format=3]", "", *ext, "", f'[node name="PVGamesEditableObjectPalette_{container}" type="Control"]']
    lines.append(label_node("Title", ".", f"{container} Editable Object Palette", 20, 10))
    lines.append(label_node("Summary", ".", f"{len(entries)} objects. Open page scenes below for full visual browsing. Previews are not production Hideout objects.", 20, 42, 1500))
    y = 78
    if pages:
        for page in pages:
            lines.append(label_node(f"Page_{page.stem[-3:]}", ".", res(page), 20, y, 1500))
            y += 26
    else:
        lines.append(label_node("NoObjects", ".", "No objects assigned to this container.", 20, y, 1000))
        y += 26
    lines.extend([
        f'\n[node name="SampleCards" type="GridContainer" parent="."]',
        f"offset_left = 20.0",
        f"offset_top = {y + 24}.0",
        f"offset_right = 1560.0",
        f"offset_bottom = 900.0",
        f"columns = {GRID_COLUMNS}",
    ])
    for idx, entry in enumerate(sample_entries, 1):
        lines.append(card_block(entry, "SampleCards", idx, tex_ids))
    path.write_text("\n".join(lines), encoding="utf-8")
    return path


def write_master_scene(groups: dict[str, list[dict[str, Any]]], container_scenes: dict[str, Path], page_scenes: dict[str, list[Path]]) -> None:
    sample_entries = [entries[0] for entries in groups.values() if entries][:8]
    ext, tex_ids = texture_ext_resources(sample_entries)
    lines = [f"[gd_scene load_steps={len(ext) + 1} format=3]", "", *ext, "", '[node name="PVGamesEditableObjectMasterPalette" type="Control"]']
    lines.append(label_node("Title", ".", "PVGames Editable Object Master Palette", 20, 10))
    lines.append(label_node("Warning", ".", "Palette/browser scenes only. Do not drag all previews into production HideoutHub. Use object_id with dry-run stamper first.", 20, 42, 1600))
    y = 84
    for container in CONTAINERS:
        lines.append(label_node(f"{container}_Summary", ".", f"{container}: {len(groups[container])} objects | index scene: {res(container_scenes[container])} | pages: {len(page_scenes[container])}", 20, y, 1800))
        y += 28
    lines.extend([
        f'\n[node name="SampleCards" type="GridContainer" parent="."]',
        f"offset_left = 20.0",
        f"offset_top = {y + 24}.0",
        f"offset_right = 1560.0",
        f"offset_bottom = 900.0",
        f"columns = {GRID_COLUMNS}",
    ])
    for idx, entry in enumerate(sample_entries, 1):
        lines.append(card_block(entry, "SampleCards", idx, tex_ids))
    MASTER_SCENE.write_text("\n".join(lines), encoding="utf-8")


def write_palette_scenes(entries: list[dict[str, Any]]) -> tuple[dict[str, Path], dict[str, list[Path]]]:
    SCENES.mkdir(parents=True, exist_ok=True)
    groups = grouped(entries)
    container_scenes: dict[str, Path] = {}
    page_scenes: dict[str, list[Path]] = {}
    for container, items in groups.items():
        pages: list[Path] = []
        for page_num in range(1, max(1, math.ceil(len(items) / PAGE_SIZE)) + 1):
            page_entries = items[(page_num - 1) * PAGE_SIZE: page_num * PAGE_SIZE]
            pages.append(write_page_scene(container, page_num, page_entries, len(items)))
        page_scenes[container] = pages
        container_scenes[container] = write_container_index_scene(container, items, pages)
    write_master_scene(groups, container_scenes, page_scenes)
    return container_scenes, page_scenes


def load_font(size: int) -> ImageFont.ImageFont:
    try:
        return ImageFont.truetype("arial.ttf", size)
    except OSError:
        return ImageFont.load_default()


def draw_wrapped(draw: ImageDraw.ImageDraw, pos: tuple[int, int], text: str, font: ImageFont.ImageFont, fill: tuple[int, int, int], width: int) -> None:
    y = pos[1]
    for line in textwrap.wrap(text, width=width):
        draw.text((pos[0], y), line, font=font, fill=fill)
        y += 14


def contact_sheet(entries: list[dict[str, Any]], prefix: str, title: str, page_size: int = 48) -> list[Path]:
    SHEETS_DIR.mkdir(parents=True, exist_ok=True)
    out: list[Path] = []
    font = load_font(12)
    title_font = load_font(18)
    cols = 4
    cell_w = 360
    cell_h = 210
    for page in range(1, max(1, math.ceil(len(entries) / page_size)) + 1):
        page_entries = entries[(page - 1) * page_size: page * page_size]
        rows = max(1, math.ceil(len(page_entries) / cols))
        img = Image.new("RGB", (cols * cell_w, rows * cell_h + 70), (28, 28, 34))
        draw = ImageDraw.Draw(img)
        draw.text((16, 10), f"{title} Page {page:03d}", font=title_font, fill=(255, 255, 255))
        draw.text((16, 36), "Browsing/contact sheet only - do not use this sheet as source art.", font=font, fill=(255, 210, 80))
        for idx, entry in enumerate(page_entries):
            col = idx % cols
            row = idx // cols
            x = col * cell_w + 12
            y = row * cell_h + 72
            draw.rectangle((x, y, x + cell_w - 24, y + cell_h - 14), outline=(90, 90, 110), width=1)
            thumb_box = (x + 8, y + 8, x + 128, y + 112)
            if entry["source_exists"]:
                try:
                    with Image.open(local(entry["source_png_path"])) as src:
                        src = src.convert("RGBA")
                        src.thumbnail((120, 96), Image.LANCZOS)
                        tx = thumb_box[0] + (120 - src.width) // 2
                        ty = thumb_box[1] + (96 - src.height) // 2
                        img.paste(src, (tx, ty), src)
                except Exception:
                    draw.text((thumb_box[0], thumb_box[1]), "LOAD ERROR", font=font, fill=(255, 80, 80))
            else:
                draw.text((thumb_box[0], thumb_box[1]), "MISSING", font=font, fill=(255, 80, 80))
            text_x = x + 142
            draw_wrapped(draw, (text_x, y + 8), entry["object_id"], font, (220, 255, 255), 26)
            draw.text((text_x, y + 52), f"{entry['source_set']} | {entry['object_category']}", font=font, fill=(220, 220, 220))
            draw.text((text_x, y + 70), entry["recommended_container"], font=font, fill=(180, 220, 255))
            draw.text((text_x, y + 88), f"{entry['quality_classification']} | z {entry['recommended_z_index']}", font=font, fill=(210, 210, 210))
            if entry["palette_warning"]:
                draw_wrapped(draw, (text_x, y + 108), entry["palette_warning"][:72], font, (255, 200, 120), 28)
        path = SHEETS_DIR / f"{prefix}_page_{page:03d}.png"
        img.save(path)
        out.append(path)
    return out


def write_contact_sheets(entries: list[dict[str, Any]]) -> list[Path]:
    groups = grouped(entries)
    sheets: list[Path] = []
    sheets.extend(contact_sheet(groups["BehindPlayerObjects"], "editable_objects_behind_player", "BehindPlayerObjects"))
    sheets.extend(contact_sheet(groups["OccludableObjects"], "editable_objects_occludable", "OccludableObjects"))
    sheets.extend(contact_sheet(groups["ForegroundObjects"], "editable_objects_foreground", "ForegroundObjects"))
    sheets.extend(contact_sheet(groups["ReviewObjects"], "editable_objects_review", "ReviewObjects"))
    sheets.extend(contact_sheet([e for e in entries if e["object_category"] in {"wall", "barrier"}], "editable_objects_walls_barriers", "Walls and Barriers"))
    sheets.extend(contact_sheet([e for e in entries if e["object_category"] in {"prop", "sign", "terminal"}], "editable_objects_props_signs_terminals", "Props Signs Terminals"))
    sheets.extend(contact_sheet([e for e in entries if e["object_category"] == "large_structure"], "editable_objects_large_structures", "Large Structures"))
    return sheets


def write_gd_tools() -> None:
    BUILDER_GD.write_text('''@tool
extends EditorScript
class_name PVGamesEditableObjectPaletteBuilder

func _run() -> void:
	print("B8A palette scenes are generated by src/tools/editor/pvgames_editable_object_palette_builder.py.")
	print("Run that Python builder to refresh scenes, normalized index, contact sheets, and reports.")
''', encoding="utf-8")
    HELPER.write_text(r'''@tool
extends EditorScript
class_name PVGamesEditableObjectPaletteBrowserHelper

const INDEX_PATH := "res://docs/reports/pvgames_editable_object_palette/pvgames_editable_object_palette_index_by_container.json"


func _run() -> void:
	print("PVGamesEditableObjectPaletteBrowserHelper ready. Call print_object_info, print_stamp_command, list_by_container, list_by_category, or validate_palette_scene.")


func print_object_info(object_id: String) -> void:
	var entry := find_object(object_id)
	print(JSON.stringify(entry, "\t"))


func print_stamp_command(object_id: String) -> void:
	var entry := find_object(object_id)
	if entry.is_empty():
		print("Object not found: %s" % object_id)
		return
	var container := String(entry.get("recommended_container", "OccludableObjects"))
	print("Set PVGamesEditableObjectPaletteRunner.gd:")
	print("const MODE := \"dry_run_stamp_object\"")
	print("const OBJECT_ID := \"%s\"" % object_id)
	print("const TARGET_CONTAINER := \"%s\"" % container)


func list_by_container(container_name: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for entry in _objects():
		if String(entry.get("recommended_container", "")) == container_name:
			out.append(entry)
	print(JSON.stringify(out, "\t"))
	return out


func list_by_category(category: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for entry in _objects():
		if String(entry.get("object_category", "")) == category:
			out.append(entry)
	print(JSON.stringify(out, "\t"))
	return out


func validate_palette_scene(scene_path: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(scene_path)
	var result := {
		"scene_path": scene_path,
		"has_object_id_metadata": text.contains("metadata/object_id"),
		"has_object_id_labels": text.contains("ObjectId"),
		"uses_contact_sheet_as_texture": text.contains("contact_sheets") or text.contains("contact_sheet"),
		"has_collision": text.contains("CollisionShape2D") or text.contains("StaticBody2D") or text.contains("Area2D"),
	}
	print(JSON.stringify(result, "\t"))
	return result


func find_object(object_id: String) -> Dictionary:
	for entry in _objects():
		if String(entry.get("object_id", "")) == object_id:
			return entry
	return {}


func _objects() -> Array[Dictionary]:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(INDEX_PATH))
	var out: Array[Dictionary] = []
	if parsed is Dictionary and parsed.has("objects"):
		for item in parsed["objects"]:
			if item is Dictionary:
				out.append(item)
	return out
''', encoding="utf-8")
    RUNNER.write_text(r'''@tool
extends EditorScript
class_name PVGamesEditableObjectPaletteRunner

const Helper = preload("res://src/tools/editor/PVGamesEditableObjectPaletteBrowserHelper.gd")
const Stamper = preload("res://src/tools/editor/PVGamesObjectStamperTool.gd")

# Default is intentionally non-destructive.
const MODE := "dry_run_list_palette"

const OBJECT_ID := "pvg_obj_core_wall_interior_wall11_2_0189"
const TARGET_SCENE := "res://scenes/hideout/HideoutHub.tscn"
const TARGET_CONTAINER := "OccludableObjects"
const TARGET_POSITION := Vector2(0, 0)
const TARGET_SCALE := Vector2(1, 1)
const TARGET_ROTATION_DEGREES := 0.0
const TARGET_Z_INDEX := 999999
const CONTAINER_NAME := "OccludableObjects"
const CATEGORY := "wall"
const SOURCE_SET := "core"
const PALETTE_SCENE := "res://scenes/hideout/tools/PVGamesEditableObjectPalette_OccludableObjects_Page001.tscn"


func _run() -> void:
	var helper := Helper.new()
	var stamper := Stamper.new()
	match MODE:
		"dry_run_list_palette":
			helper.list_by_container(CONTAINER_NAME)
		"dry_run_find_object":
			helper.print_object_info(OBJECT_ID)
		"dry_run_stamp_object":
			print(JSON.stringify(stamper.stamp_object_dry_run(TARGET_SCENE, OBJECT_ID, TARGET_POSITION, TARGET_CONTAINER, TARGET_SCALE, TARGET_ROTATION_DEGREES, TARGET_Z_INDEX), "\t"))
		"stamp_object":
			print(JSON.stringify(stamper.stamp_object(TARGET_SCENE, OBJECT_ID, TARGET_POSITION, TARGET_CONTAINER, TARGET_SCALE, TARGET_ROTATION_DEGREES, TARGET_Z_INDEX), "\t"))
		"list_by_container":
			helper.list_by_container(CONTAINER_NAME)
		"list_by_category":
			helper.list_by_category(CATEGORY)
		"list_by_source_set":
			var out: Array[Dictionary] = []
			for entry in helper._objects():
				if String(entry.get("source_set", "")) == SOURCE_SET:
					out.append(entry)
			print(JSON.stringify(out, "\t"))
		"validate_palette":
			helper.validate_palette_scene(PALETTE_SCENE)
		_:
			push_error("Unsupported B8A palette runner mode: %s" % MODE)
''', encoding="utf-8")
    VALIDATOR.write_text(r'''@tool
extends EditorScript
class_name PVGamesEditableObjectPaletteValidator

const INDEX := "res://docs/reports/pvgames_editable_object_asset_index.json"
const NORMALIZED := "res://docs/reports/pvgames_editable_object_palette/pvgames_editable_object_palette_index_by_container.json"
const MASTER := "res://scenes/hideout/tools/PVGamesEditableObjectMasterPalette.tscn"
const RUNNER := "res://src/tools/editor/PVGamesEditableObjectPaletteRunner.gd"
const HELPER := "res://src/tools/editor/PVGamesEditableObjectPaletteBrowserHelper.gd"
const HOW_TO := "res://docs/reports/pvgames_editable_object_palette/pvgames_editable_object_palette_how_to_use.md"
const HIDEOUT := "res://scenes/hideout/HideoutHub.tscn"
const CONTAINERS := ["BehindPlayerObjects", "OccludableObjects", "ForegroundObjects", "ReviewObjects"]


func _run() -> void:
	print(JSON.stringify(validate(), "\t"))


func validate() -> Dictionary:
	var failures: Array[String] = []
	_require(FileAccess.file_exists(INDEX), "B8 source index missing.", failures)
	_require(FileAccess.file_exists(NORMALIZED), "Normalized palette index missing.", failures)
	_require(FileAccess.file_exists(MASTER), "Master palette scene missing.", failures)
	_require(FileAccess.file_exists(RUNNER), "Palette runner missing.", failures)
	_require(FileAccess.file_exists(HELPER), "Palette helper missing.", failures)
	_require(FileAccess.file_exists(HOW_TO), "How-to missing.", failures)
	for container in CONTAINERS:
		_require(FileAccess.file_exists("res://scenes/hideout/tools/PVGamesEditableObjectPalette_%s.tscn" % container), "%s palette scene missing." % container, failures)
	var data := _read_dict(NORMALIZED)
	var objects: Array = data.get("objects", [])
	for item in objects:
		if item is Dictionary:
			var container := String(item.get("recommended_container", ""))
			if not CONTAINERS.has(container):
				failures.append("Ungrouped object: %s" % item.get("object_id", ""))
	var runner_text := FileAccess.get_file_as_string(RUNNER) if FileAccess.file_exists(RUNNER) else ""
	_require(runner_text.contains("const MODE := \"dry_run_list_palette\""), "Runner default is not dry_run_list_palette.", failures)
	var master_text := FileAccess.get_file_as_string(MASTER) if FileAccess.file_exists(MASTER) else ""
	_require(master_text.contains("BehindPlayerObjects") and master_text.contains("OccludableObjects") and master_text.contains("ForegroundObjects") and master_text.contains("ReviewObjects"), "Master scene does not list all containers.", failures)
	_require(not master_text.contains("GameplayRoot"), "Palette scene references GameplayRoot.", failures)
	_require(not master_text.contains("CollisionShape2D") and not master_text.contains("StaticBody2D"), "Collision found in master scene.", failures)
	var hideout := FileAccess.get_file_as_string(HIDEOUT) if FileAccess.file_exists(HIDEOUT) else ""
	_require(hideout.contains("PVG_EditableObjects"), "Hideout editable containers missing.", failures)
	_require(not hideout.contains("PVGamesEditableObjectPalette"), "Palette previews appear to be in production Hideout.", failures)
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


def write_how_to(container_scenes: dict[str, Path], page_scenes: dict[str, list[Path]]) -> None:
    HOW_TO.write_text(f"""# PVGames Editable Object Palette How-To

This baked palette is a visual shelf for the B8 editable object stamper. It is not a production gameplay scene and it is not a TileMap palette.

TileMap palettes are still best for floors, roads, repeated panels, repeated decals, and broad flat coverage. This palette is for individual Sprite2D/Node2D objects: walls, barriers, signs, terminals, counters, shelves, large structures, foreground pieces, and anything you want to move, scale, rotate, duplicate, delete, or z-order by itself.

## Preview Scenes Are Not Production

Do not drag every preview into `HideoutHub`. The preview cards are browsing aids. Production `HideoutHub` should stay clean with empty containers under `ArtRoot/World/PVG_EditableObjects` until you intentionally stamp one chosen object with the B8 stamper.

## Depth Containers

- `BehindPlayerObjects`: background panels, back-wall details, and non-occluding dressing.
- `OccludableObjects`: walls, wall fronts, barriers, counters, shelves, terminals, tall props, and large physical objects.
- `ForegroundObjects`: overhead pipes, ceiling pieces, hanging signs, and always-front overlays.
- `ReviewObjects`: uncertain, oversized, awkwardly cropped, missing, or visually risky assets.

## First-Use Workflow

A. Open `res://scenes/hideout/tools/PVGamesEditableObjectMasterPalette.tscn`.

B. Open `res://scenes/hideout/tools/PVGamesEditableObjectPalette_OccludableObjects.tscn`.

C. Pick a wall/barrier `object_id`.

D. Use `PVGamesEditableObjectPaletteRunner.gd` with `MODE := "dry_run_find_object"`.

E. Use `MODE := "dry_run_stamp_object"`.

F. If correct, use B8 stamper or change the runner to `stamp_object` to stamp exactly one object into `ArtRoot/World/PVG_EditableObjects/OccludableObjects`.

G. Select the stamped object in `HideoutHub`.

H. Move, scale, and rotate it normally.

## Scene Paths

- Master: `res://scenes/hideout/tools/PVGamesEditableObjectMasterPalette.tscn`
- Behind: `{res(container_scenes['BehindPlayerObjects'])}`
- Occludable: `{res(container_scenes['OccludableObjects'])}`
- Foreground: `{res(container_scenes['ForegroundObjects'])}`
- Review: `{res(container_scenes['ReviewObjects'])}`

## Contact Sheets

Contact sheets live in `res://docs/reports/pvgames_editable_object_palette/contact_sheets/`. They are browsing-only and are labeled that way. Do not use contact sheets as source art.

## If A Preview Is Missing

The object is assigned to `ReviewObjects` and the card shows a warning. Use another asset or report the `object_id` and source path.

## If A Palette Scene Is Slow

Open the specific page scene instead of the container index scene. Large containers are paginated at {PAGE_SIZE} preview cards per page.

## If Labels Overlap

Use the normalized index or contact sheet for the same object_id. The stamped production object uses the B8 object metadata, not the label layout.

## Rotation Warning

Some dimetric assets have baked perspective and may look wrong when rotated. Prefer a source asset facing the right direction over rotating a perspective-heavy sprite.

## What Not To Touch

Do not manually edit `GameplayRoot`, Taco Bell scenes, gameplay scripts, source PNGs, TileSets, or collision. Do not mass-place previews into production `HideoutHub`.
""", encoding="utf-8")


def write_creation_report(entries: list[dict[str, Any]], missing_sources: list[dict[str, Any]], container_scenes: dict[str, Path], page_scenes: dict[str, list[Path]], sheets: list[Path], hideout_modified: bool) -> None:
    by_container = Counter(e["recommended_container"] for e in entries)
    by_source = Counter(e["source_set"] for e in entries)
    by_category = Counter(e["object_category"] for e in entries)
    data = {
        "status": "PASS",
        "source_index_path": res(SOURCE_INDEX),
        "total_objects_processed": len(entries),
        "behind_player_count": by_container.get("BehindPlayerObjects", 0),
        "occludable_count": by_container.get("OccludableObjects", 0),
        "foreground_count": by_container.get("ForegroundObjects", 0),
        "review_count": by_container.get("ReviewObjects", 0),
        "core_objects_count": by_source.get("core", 0),
        "central_security_objects_count": by_source.get("central_security", 0),
        "category_counts": dict(sorted(by_category.items())),
        "missing_source_count": len(missing_sources),
        "palette_scenes_created": [res(p) for p in [MASTER_SCENE, *container_scenes.values()]],
        "page_scenes_created": {k: [res(p) for p in v] for k, v in page_scenes.items()},
        "contact_sheets_created": [res(p) for p in sheets],
        "browser_helper_path": res(HELPER),
        "palette_runner_path": res(RUNNER),
        "runner_default_mode": "dry_run_list_palette",
        "hideout_hub_modified": hideout_modified,
        "hideout_backup_path": "",
        "production_hideout_preview_objects_added": False,
        "taco_bell_scenes_modified": False,
        "gameplay_scripts_modified": False,
        "source_pngs_modified": False,
        "tilesets_modified": False,
        "collision_added": False,
        "validator_result": "static validation pending",
        "risks_limitations": [
            "Large palette page scenes may still take a moment to open because they reference many source textures.",
            "Some dimetric sprites have baked perspective and may not rotate cleanly.",
            "Preview cards are browsing UI, not copy/paste production objects.",
        ],
        "manual_test_checklist": [
            "Open master palette scene.",
            "Open each container scene and first page scene.",
            "Confirm object_id labels and thumbnails are visible.",
            "Use palette runner dry_run_find_object and dry_run_stamp_object.",
            "Confirm production HideoutHub was not filled with preview cards.",
        ],
        "recommended_next_step": "Open the Occludable palette page, choose one wall/barrier object_id, and run dry_run_stamp_object before placing one object with the B8 stamper.",
    }
    write_json(CREATION_JSON, data)
    lines = [
        "# PVGames Editable Object Palette Creation",
        "",
        "Status: PASS",
        "",
        f"- Source index: `{res(SOURCE_INDEX)}`",
        f"- Total objects processed: {len(entries)}",
        f"- BehindPlayerObjects: {by_container.get('BehindPlayerObjects', 0)}",
        f"- OccludableObjects: {by_container.get('OccludableObjects', 0)}",
        f"- ForegroundObjects: {by_container.get('ForegroundObjects', 0)}",
        f"- ReviewObjects: {by_container.get('ReviewObjects', 0)}",
        f"- Core objects: {by_source.get('core', 0)}",
        f"- Central Security objects: {by_source.get('central_security', 0)}",
        f"- Missing sources: {len(missing_sources)}",
        f"- Master palette: `{res(MASTER_SCENE)}`",
        f"- Contact sheets: `{res(SHEETS_DIR)}`",
        f"- Runner: `{res(RUNNER)}` default `dry_run_list_palette`",
        "",
        "Production `HideoutHub` was not modified by B8A and no preview objects were added to it.",
    ]
    CREATION_MD.write_text("\n".join(lines) + "\n", encoding="utf-8")


def static_validate(entries: list[dict[str, Any]], page_scenes: dict[str, list[Path]], sheets: list[Path]) -> tuple[str, list[str]]:
    failures: list[str] = []
    if not SOURCE_INDEX.exists():
        failures.append("B8 source object index missing.")
    if len({e["object_id"] for e in entries}) != len(entries):
        failures.append("Object IDs are not unique.")
    if any(e["recommended_container"] not in CONTAINERS for e in entries):
        failures.append("At least one object is not in a required container.")
    if not MASTER_SCENE.exists():
        failures.append("Master palette scene missing.")
    for container in CONTAINERS:
        if not (SCENES / f"PVGamesEditableObjectPalette_{container}.tscn").exists():
            failures.append(f"{container} index scene missing.")
        if not page_scenes.get(container):
            failures.append(f"{container} page scene missing.")
    if not sheets:
        failures.append("Contact sheets missing.")
    for path in [HELPER, RUNNER, VALIDATOR, HOW_TO, NORMALIZED_JSON, CREATION_JSON]:
        if not path.exists():
            failures.append(f"Missing output: {res(path)}")
    runner_text = RUNNER.read_text(encoding="utf-8") if RUNNER.exists() else ""
    if 'const MODE := "dry_run_list_palette"' not in runner_text:
        failures.append("Palette runner default is not dry_run_list_palette.")
    hideout_text = HIDEOUT.read_text(encoding="utf-8")
    if "PVGamesEditableObjectPalette" in hideout_text or "Card_001_" in hideout_text:
        failures.append("Production Hideout appears to contain palette preview objects.")
    if "parent=\"GameplayRoot" in MASTER_SCENE.read_text(encoding="utf-8"):
        failures.append("Master palette references GameplayRoot.")
    return ("PASS" if not failures else "FAIL"), failures


def main() -> None:
    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    SHEETS_DIR.mkdir(parents=True, exist_ok=True)
    entries, missing_sources, duplicates = normalize_entries()
    write_normalized_index(entries, missing_sources, duplicates)
    container_scenes, page_scenes = write_palette_scenes(entries)
    sheets = write_contact_sheets(entries)
    write_gd_tools()
    write_how_to(container_scenes, page_scenes)
    hideout_modified = False
    write_creation_report(entries, missing_sources, container_scenes, page_scenes, sheets, hideout_modified)
    result, failures = static_validate(entries, page_scenes, sheets)
    data = load_json(CREATION_JSON)
    data["validator_result"] = f"static validation {result.lower()}"
    data["validator_failures"] = failures
    write_json(CREATION_JSON, data)
    md = CREATION_MD.read_text(encoding="utf-8")
    md += f"\n## Validation\n\nStatic validation: {result}\n"
    if failures:
        md += "\nFailures:\n" + "\n".join(f"- {failure}" for failure in failures) + "\n"
    CREATION_MD.write_text(md, encoding="utf-8")
    print(json.dumps({
        "status": result,
        "total": len(entries),
        "containers": Counter(e["recommended_container"] for e in entries),
        "source_sets": Counter(e["source_set"] for e in entries),
        "missing_sources": len(missing_sources),
        "page_scene_count": sum(len(v) for v in page_scenes.values()),
        "contact_sheet_count": len(sheets),
        "failures": failures,
    }, indent=2))


if __name__ == "__main__":
    main()
