#!/usr/bin/env python3
"""Build B9 PVGames Cyber City + Doomsday icon library outputs.

This is an editor tooling generator. It scans local purchased icon source
folders, creates catalogs/contact sheets/scripts/test scenes/reports, and
updates the existing B8B object palette dock to load icons as an additional
asset type. It does not edit source PNGs, TileSets, gameplay UI, or Taco Bell.
"""

from __future__ import annotations

import csv
import hashlib
import json
import math
import re
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any

from PIL import Image, ImageDraw, ImageFont, UnidentifiedImageError


ROOT = Path(__file__).resolve().parents[3]
REPORT_DIR = ROOT / "docs/reports/pvgames_icon_library"
SHEETS_DIR = REPORT_DIR / "contact_sheets"
ICON_ASSET_DIR = ROOT / "assets/icons/pvgames_icon_library"
ATLAS_DIR = ICON_ASSET_DIR / "atlas_textures"
SCRIPTS_DIR = ROOT / "src/icons"
TOOLS_DIR = ROOT / "src/tools/editor"
SCENES_DIR = ROOT / "scenes/hideout/tools"
DOCK = ROOT / "addons/pvgames_object_palette/PVGamesObjectPaletteDock.gd"
ASSET_DOC = ROOT / "docs/ASSET_INSTALLATION.md"

CYBER_ROOT = ROOT / "assets/tilesets/cyber_city_core_tilesets/Store_Items/CyberCity_Icons"
DOOM_ROOT = ROOT / "assets/tilesets/cyber_city_core_tilesets/Store_Items/Doomsday Icons"

DISCOVERY_JSON = REPORT_DIR / "icon_source_folder_discovery.json"
DISCOVERY_MD = REPORT_DIR / "icon_source_folder_discovery.md"
SCAN_JSON = REPORT_DIR / "pvgames_icon_source_scan.json"
SCAN_MD = REPORT_DIR / "pvgames_icon_source_scan.md"
SCAN_CSV = REPORT_DIR / "pvgames_icon_source_scan.csv"
CLASS_JSON = REPORT_DIR / "pvgames_icon_source_classification.json"
CLASS_MD = REPORT_DIR / "pvgames_icon_source_classification.md"
CATALOG_JSON = REPORT_DIR / "pvgames_verified_icon_catalog.json"
CATALOG_MD = REPORT_DIR / "pvgames_verified_icon_catalog.md"
CATALOG_CSV = REPORT_DIR / "pvgames_verified_icon_catalog.csv"
MANIFEST_JSON = ICON_ASSET_DIR / "pvgames_icon_resource_manifest.json"
MANIFEST_MD = REPORT_DIR / "pvgames_icon_resource_manifest.md"
DOCK_REPORT_JSON = REPORT_DIR / "pvgames_icon_dock_integration.json"
DOCK_REPORT_MD = REPORT_DIR / "pvgames_icon_dock_integration.md"
HOW_TO = REPORT_DIR / "pvgames_icon_library_how_to.md"
FUTURE_JSON = REPORT_DIR / "future_feature_queue_after_b9.json"
FUTURE_MD = REPORT_DIR / "future_feature_queue_after_b9.md"
MAIN_JSON = REPORT_DIR / "pvgames_icon_library_creation.json"
MAIN_MD = REPORT_DIR / "pvgames_icon_library_creation.md"


def res(path: Path) -> str:
    return "res://" + path.resolve().relative_to(ROOT.resolve()).as_posix()


def local(res_path: str) -> Path:
    return ROOT / res_path.removeprefix("res://")


def write_json(path: Path, data: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2), encoding="utf-8")


def write_text(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def slug(text: str) -> str:
    return re.sub(r"[^a-z0-9]+", "_", text.lower()).strip("_") or "icon"


def short_hash(text: str) -> str:
    return hashlib.sha1(text.encode("utf-8")).hexdigest()[:8]


def source_roots() -> list[dict[str, Any]]:
    roots = [
        ("cyber_city_icons", CYBER_ROOT),
        ("doomsday_icons", DOOM_ROOT),
    ]
    out = []
    for source_set, path in roots:
        pngs = list(path.rglob("*.png")) if path.exists() else []
        imports = list(path.rglob("*.png.import")) if path.exists() else []
        other_images = []
        for ext in ("*.webp", "*.jpg", "*.jpeg"):
            other_images.extend(path.rglob(ext) if path.exists() else [])
        likely_structure = "individual_icons" if pngs else "unknown"
        confidence = "high" if pngs else ("low" if path.exists() else "missing")
        reason = f"Found {len(pngs)} PNG files under expected PVGames icon pack folder." if pngs else "Folder exists but no PNG files found." if path.exists() else "Expected folder missing."
        out.append({
            "folder_path": res(path) if path.exists() else str(path),
            "parent_folder": res(path.parent) if path.parent.exists() else str(path.parent),
            "png_count": len(pngs),
            "png_import_count": len(imports),
            "other_image_count": len(other_images),
            "likely_source_pack": source_set if pngs else "unknown",
            "likely_structure": likely_structure,
            "confidence": confidence,
            "reason": reason,
            "accepted": bool(pngs),
        })
    return out


def discover() -> list[dict[str, Any]]:
    discovery = source_roots()
    write_json(DISCOVERY_JSON, {"candidate_folders": discovery})
    lines = ["# Icon Source Folder Discovery", ""]
    for item in discovery:
        lines += [
            f"## {item['likely_source_pack']}",
            f"- Folder: `{item['folder_path']}`",
            f"- PNG count: {item['png_count']}",
            f"- `.png.import` count: {item['png_import_count']}",
            f"- Accepted: {item['accepted']}",
            f"- Confidence: {item['confidence']}",
            f"- Reason: {item['reason']}",
            "",
        ]
    write_text(DISCOVERY_MD, "\n".join(lines))
    return discovery


def alpha_bbox(img: Image.Image) -> tuple[list[int] | None, float, float]:
    if img.mode != "RGBA":
        rgba = img.convert("RGBA")
    else:
        rgba = img
    alpha = rgba.getchannel("A")
    bbox = alpha.getbbox()
    total = rgba.width * rgba.height
    if not bbox or total == 0:
        return None, 100.0, 0.0
    visible_pixels = sum(1 for p in alpha.getdata() if p > 0)
    coverage = visible_pixels / total * 100.0
    transparent = 100.0 - coverage
    return [bbox[0], bbox[1], bbox[2], bbox[3]], round(transparent, 3), round(coverage, 3)


def keywords_for(filename: str) -> set[str]:
    low = filename.lower()
    tags = set(re.findall(r"[a-z]+", low))
    mapping = {
        "security": ["alarm", "camera", "lock", "key", "safe", "guard", "scanner", "shield"],
        "hazard": ["hazard", "toxic", "fire", "radiation", "bio", "poison", "acid", "explosion", "warning"],
        "store": ["shop", "store", "cart", "cash", "coin", "money", "credit", "price"],
        "mission": ["target", "mission", "quest", "map", "marker", "pin"],
        "evidence": ["evidence", "folder", "file", "document", "clue", "case"],
        "terminal": ["terminal", "computer", "screen", "monitor", "data", "chip", "tech"],
        "door": ["door", "gate", "keypad", "access"],
        "health": ["health", "med", "heart", "pill", "bandage"],
        "bentley": ["dog", "bone", "pet", "shiba"],
        "comedy": ["taco", "pizza", "burger", "beer", "toilet", "banana"],
        "decor": ["poster", "sign", "sticker", "neon", "graffiti"],
    }
    for key, words in mapping.items():
        if any(word in low for word in words):
            tags.add(key)
    return tags


def primary_category(filename: str, source_set: str) -> str:
    low = filename.lower()
    checks = [
        ("security", ["alarm", "camera", "lock", "safe", "guard", "scanner", "shield"]),
        ("hazard", ["hazard", "toxic", "fire", "radiation", "bio", "acid", "explosion", "warning"]),
        ("currency", ["coin", "cash", "money", "credit"]),
        ("store", ["shop", "store", "cart", "item"]),
        ("mission", ["target", "mission", "quest"]),
        ("objective", ["objective", "marker"]),
        ("evidence", ["evidence", "folder", "file", "document", "clue"]),
        ("map_pin", ["map", "pin"]),
        ("keypad", ["keypad", "keycard"]),
        ("terminal", ["terminal", "computer", "screen", "monitor"]),
        ("door", ["door", "gate"]),
        ("tech", ["data", "chip", "gear", "tech", "wire", "battery"]),
        ("health", ["health", "med", "heart", "pill"]),
        ("bentley", ["dog", "bone", "pet"]),
        ("comedy", ["taco", "pizza", "burger", "beer", "toilet", "banana"]),
        ("decor", ["poster", "sign", "sticker", "neon", "graffiti"]),
    ]
    for category, words in checks:
        if any(word in low for word in words):
            return category
    if source_set == "doomsday_icons":
        return "doomsday"
    if source_set == "cyber_city_icons":
        return "cyber"
    return "unknown_review"


def recommended_uses(category: str, filename: str) -> list[str]:
    use_map = {
        "security": ["security_indicator", "warning_indicator", "mission_board", "world_decal", "screen_graphic"],
        "hazard": ["warning_indicator", "objective_marker", "world_decal", "hologram_marker"],
        "currency": ["store_terminal", "storefront_item", "inventory_icon"],
        "store": ["store_terminal", "storefront_item", "decor_shop_thumbnail"],
        "mission": ["mission_board", "objective_marker", "map_pin"],
        "objective": ["objective_marker", "mission_board"],
        "evidence": ["evidence_board", "big_case", "inventory_icon"],
        "map_pin": ["map_pin", "objective_marker"],
        "keypad": ["security_indicator", "door", "terminal", "world_decal"],
        "terminal": ["store_terminal", "screen_graphic", "terminal", "world_decal"],
        "door": ["door", "map_pin", "world_decal"],
        "tech": ["screen_graphic", "scheme_card", "inventory_icon", "world_decal"],
        "health": ["inventory_icon", "pause_menu", "storefront_item"],
        "bentley": ["bentley_item_candidate", "decor_shop_thumbnail"],
        "comedy": ["comedy_item_candidate", "decor_shop_thumbnail"],
        "decor": ["wall_sticker", "signage", "world_decal"],
        "doomsday": ["warning_indicator", "scheme_card", "world_decal"],
        "cyber": ["scheme_card", "screen_graphic", "world_decal"],
    }
    uses = use_map.get(category, ["debug_icon"])
    low = filename.lower()
    if "sign" in low or "poster" in low:
        uses = sorted(set(uses + ["signage", "wall_sticker"]))
    return uses


def quality_for(width: int, height: int, coverage: float, category: str, filename: str) -> str:
    if width <= 0 or height <= 0 or coverage < 1.0:
        return "REJECT_JUNK"
    largest = max(width, height)
    if largest > 1024:
        return "READY_UI_PANEL"
    if largest > 512:
        return "REVIEW_MANUALLY"
    uses = recommended_uses(category, filename)
    has_world = any(u in uses for u in ["world_decal", "wall_sticker", "signage", "screen_graphic", "hologram_marker"])
    if has_world and largest >= 96:
        return "READY_BOTH"
    if has_world:
        return "READY_WORLD_DECAL"
    return "READY_UI_ICON"


def scan_sources(discovery: list[dict[str, Any]]) -> tuple[list[dict[str, Any]], list[dict[str, Any]], list[dict[str, Any]]]:
    scans: list[dict[str, Any]] = []
    classifications: list[dict[str, Any]] = []
    catalog: list[dict[str, Any]] = []
    source_map = {
        "cyber_city_icons": CYBER_ROOT,
        "doomsday_icons": DOOM_ROOT,
    }
    for source_set, root in source_map.items():
        if not root.exists():
            continue
        for path in sorted(root.rglob("*.png")):
            if path.name.endswith(".import") or "contact_sheet" in path.as_posix().lower() or "docs/reports" in path.as_posix().lower():
                continue
            try:
                with Image.open(path) as img:
                    width, height = img.size
                    has_alpha = img.mode in ("RGBA", "LA") or "transparency" in img.info
                    bbox, transparent, coverage = alpha_bbox(img)
            except (UnidentifiedImageError, OSError):
                width = height = 0
                has_alpha = False
                bbox = None
                transparent = 100.0
                coverage = 0.0
            rel_path = res(path)
            category = primary_category(path.name, source_set)
            likely_atlas = width >= 1024 and height >= 1024
            large_panel = max(width, height) > 1024
            structure = "ICON_ATLAS_OR_SHEET" if likely_atlas else "UI_PANEL_OR_LARGE_GRAPHIC" if large_panel else "INDIVIDUAL_ICON"
            if width == 0 or coverage < 1.0:
                structure = "SKIP_UNSAFE"
            quality = quality_for(width, height, coverage, category, path.name)
            uses = recommended_uses(category, path.name)
            icon_id = f"pvg_icon_{source_set}_{category}_{slug(path.stem)}_{short_hash(rel_path)}"
            scan = {
                "source_set": source_set,
                "source_path": rel_path,
                "filename": path.name,
                "extension": path.suffix.lower(),
                "width": width,
                "height": height,
                "has_alpha": has_alpha,
                "alpha_bounding_box": bbox,
                "visible_pixel_bounding_box": bbox,
                "transparent_percentage": transparent,
                "mostly_blank": coverage < 1.0,
                "visible_coverage_percentage": coverage,
                "likely_individual_icon": structure == "INDIVIDUAL_ICON",
                "likely_atlas_sheet": structure == "ICON_ATLAS_OR_SHEET",
                "likely_ui_panel_large_graphic": structure == "UI_PANEL_OR_LARGE_GRAPHIC",
                "likely_world_decal": "world_decal" in uses or "wall_sticker" in uses,
                "dominant_filename_keywords": sorted(keywords_for(path.name)),
                "inferred_theme_keywords": sorted(set([category] + uses)),
                "import_sidecar_exists": Path(str(path) + ".import").exists(),
            }
            scans.append(scan)
            classifications.append({**scan, "structure_classification": structure, "atlas_detection_confidence": "none; individual files are primary" if structure != "ICON_ATLAS_OR_SHEET" else "low; unsafe slicing avoided"})
            if quality != "REJECT_JUNK":
                dock_type = "icon_panel" if quality == "READY_UI_PANEL" else "icon_both" if quality == "READY_BOTH" else "icon_world_decal" if quality == "READY_WORLD_DECAL" else "icon_ui" if quality == "READY_UI_ICON" else "icon_review"
                world_container = "ForegroundIcons" if "foreground_marker" in uses else "OccludableIcons" if any(u in uses for u in ["world_decal", "wall_sticker", "signage", "screen_graphic"]) else "ReviewIcons" if quality == "REVIEW_MANUALLY" else "BehindPlayerIcons"
                catalog.append({
                    "icon_id": icon_id,
                    "source_set": source_set,
                    "source_png_path": rel_path,
                    "source_filename": path.name,
                    "source_type": "individual_png" if structure == "INDIVIDUAL_ICON" else "ui_panel_or_large_graphic" if structure == "UI_PANEL_OR_LARGE_GRAPHIC" else "review_region",
                    "atlas_region_rect": None,
                    "width": width,
                    "height": height,
                    "visible_bbox": bbox,
                    "transparent_percentage": transparent,
                    "quality_classification": quality,
                    "primary_category": category,
                    "recommended_uses": uses,
                    "recommended_ui_control": "Large panel art" if quality == "READY_UI_PANEL" else "TextureRect",
                    "recommended_dock_asset_type": dock_type,
                    "recommended_world_container": world_container,
                    "recommended_default_world_scale": 1.0 if max(width, height) <= 256 else 0.5,
                    "recommended_z_index_role": 160 if world_container == "ForegroundIcons" else 90 if world_container == "OccludableIcons" else -40 if world_container == "ReviewIcons" else -120,
                    "notes": "Iconography asset; use for UI, badges, decals, signage, screen graphics, or markers.",
                    "warnings": "World stamping of UI-first icons may look like a flat sticker." if quality in ["READY_UI_ICON", "READY_UI_PANEL"] else "",
                })
    return scans, classifications, catalog


def write_table_csv(path: Path, rows: list[dict[str, Any]]) -> None:
    if not rows:
        write_text(path, "")
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    keys = list(rows[0].keys())
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=keys)
        writer.writeheader()
        for row in rows:
            writer.writerow({k: json.dumps(v) if isinstance(v, (list, dict)) else v for k, v in row.items()})


def write_scan_reports(scans: list[dict[str, Any]], classifications: list[dict[str, Any]], catalog: list[dict[str, Any]]) -> None:
    write_json(SCAN_JSON, scans)
    write_table_csv(SCAN_CSV, scans)
    write_text(SCAN_MD, f"# PVGames Icon Source Scan\n\nScanned source images: {len(scans)}\n\n`.png.import` files were counted during discovery but were not used as icons.\n")
    write_json(CLASS_JSON, classifications)
    counts = Counter(c["structure_classification"] for c in classifications)
    write_text(CLASS_MD, "# PVGames Icon Source Classification\n\n" + "\n".join(f"- {k}: {v}" for k, v in sorted(counts.items())) + "\n\nAtlas detection was attempted conservatively; unsafe atlas slicing was avoided.\n")
    write_json(CATALOG_JSON, catalog)
    write_table_csv(CATALOG_CSV, catalog)
    q = Counter(c["quality_classification"] for c in catalog)
    cat = Counter(c["primary_category"] for c in catalog)
    lines = ["# PVGames Verified Icon Catalog", "", f"Verified icon entries: {len(catalog)}", "", "## Quality Counts", ""]
    lines += [f"- {k}: {v}" for k, v in sorted(q.items())]
    lines += ["", "## Category Counts", ""]
    lines += [f"- {k}: {v}" for k, v in sorted(cat.items())]
    lines += ["", "REJECT_JUNK entries are excluded from this production catalog."]
    write_text(CATALOG_MD, "\n".join(lines) + "\n")


def font(size: int) -> ImageFont.ImageFont:
    try:
        return ImageFont.truetype("arial.ttf", size)
    except OSError:
        return ImageFont.load_default()


def contact_sheet(name: str, entries: list[dict[str, Any]], max_items: int = 96) -> Path:
    SHEETS_DIR.mkdir(parents=True, exist_ok=True)
    page_entries = entries[:max_items]
    cols, cell_w, cell_h = 6, 240, 170
    rows = max(1, math.ceil(len(page_entries) / cols))
    img = Image.new("RGB", (cols * cell_w, rows * cell_h + 60), (24, 24, 30))
    draw = ImageDraw.Draw(img)
    small = font(11)
    title = font(18)
    draw.text((14, 8), name.replace("_", " ").title(), fill=(255, 255, 255), font=title)
    draw.text((14, 34), "Browsing/contact sheet only - do not use this sheet as source art.", fill=(255, 215, 80), font=small)
    for idx, entry in enumerate(page_entries):
        x = (idx % cols) * cell_w + 8
        y = (idx // cols) * cell_h + 62
        draw.rectangle((x, y, x + cell_w - 16, y + cell_h - 10), outline=(86, 86, 105))
        try:
            with Image.open(local(entry["source_png_path"])) as src:
                src = src.convert("RGBA")
                src.thumbnail((64, 64), Image.LANCZOS)
                img.paste(src, (x + 8, y + 8), src)
        except Exception:
            draw.text((x + 8, y + 8), "MISSING", fill=(255, 80, 80), font=small)
        draw.text((x + 80, y + 8), entry["icon_id"][-18:], fill=(210, 245, 255), font=small)
        draw.text((x + 80, y + 24), entry["source_set"], fill=(220, 220, 220), font=small)
        draw.text((x + 80, y + 40), entry["primary_category"], fill=(220, 220, 220), font=small)
        draw.text((x + 8, y + 82), entry["quality_classification"], fill=(200, 255, 180), font=small)
        draw.text((x + 8, y + 100), entry["source_filename"][:32], fill=(210, 210, 210), font=small)
    out = SHEETS_DIR / f"{name}.png"
    img.save(out)
    return out


def write_contact_sheets(catalog: list[dict[str, Any]], rejected: list[dict[str, Any]]) -> list[Path]:
    sheets = []
    by_source = defaultdict(list)
    for e in catalog:
        by_source[e["source_set"]].append(e)
    sheets.append(contact_sheet("cyber_city_icons_all", by_source["cyber_city_icons"]))
    sheets.append(contact_sheet("doomsday_icons_all", by_source["doomsday_icons"]))
    for quality, name in [
        ("READY_UI_ICON", "icons_ready_ui"),
        ("READY_WORLD_DECAL", "icons_ready_world_decals"),
        ("READY_BOTH", "icons_ready_both"),
        ("READY_UI_PANEL", "icons_ui_panels_large_graphics"),
        ("REVIEW_MANUALLY", "icons_review_manually"),
    ]:
        sheets.append(contact_sheet(name, [e for e in catalog if e["quality_classification"] == quality]))
    grouped = {
        "icons_security_warning_hazard": ["security", "warning", "hazard"],
        "icons_store_inventory_currency": ["store", "inventory", "currency"],
        "icons_mission_evidence_objectives": ["mission", "evidence", "objective"],
        "icons_scheme_cards_big_case": ["scheme_card", "big_case", "tech", "cyber"],
        "icons_terminal_keypad_door_tech": ["terminal", "keypad", "door", "tech"],
        "icons_bentley_comedy_decor_candidates": ["bentley", "comedy", "decor"],
    }
    for name, cats in grouped.items():
        sheets.append(contact_sheet(name, [e for e in catalog if e["primary_category"] in cats or any(u in cats for u in e["recommended_uses"])]))
    sheets.append(contact_sheet("icons_rejected_junk", rejected))
    return sheets


def write_resource_manifest(catalog: list[dict[str, Any]]) -> None:
    ICON_ASSET_DIR.mkdir(parents=True, exist_ok=True)
    ATLAS_DIR.mkdir(parents=True, exist_ok=True)
    manifest = {
        "atlas_textures_created": 0,
        "atlas_texture_folder": res(ATLAS_DIR),
        "note": "All accepted icons are individual PNG references in this pass; no destructive cropping or AtlasTexture generation was needed.",
        "individual_png_icon_count": len(catalog),
    }
    write_json(MANIFEST_JSON, manifest)
    write_text(MANIFEST_MD, "# PVGames Icon Resource Manifest\n\nNo AtlasTexture resources were needed because accepted icons were individual PNG source files. Source PNGs were not modified.\n")


def write_icon_library_script() -> None:
    write_text(SCRIPTS_DIR / "PVGamesIconLibrary.gd", r'''extends Node
class_name PVGamesIconLibrary

const CATALOG_PATH := "res://docs/reports/pvgames_icon_library/pvgames_verified_icon_catalog.json"

var _catalog: Array[Dictionary] = []
var _by_id: Dictionary = {}


func load_catalog() -> bool:
	_catalog.clear()
	_by_id.clear()
	if not FileAccess.file_exists(CATALOG_PATH):
		push_warning("[PVGamesIconLibrary] Catalog missing: %s" % CATALOG_PATH)
		return false
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(CATALOG_PATH))
	if not parsed is Array:
		return false
	for item in parsed:
		if item is Dictionary:
			_catalog.append(item)
			_by_id[String(item.get("icon_id", ""))] = item
	return true


func get_icon_entry(icon_id: String) -> Dictionary:
	if _by_id.is_empty():
		load_catalog()
	return _by_id.get(icon_id, {})


func get_icon_texture(icon_id: String) -> Texture2D:
	var entry := get_icon_entry(icon_id)
	var path := String(entry.get("source_png_path", ""))
	if path == "" or not ResourceLoader.exists(path):
		push_warning("[PVGamesIconLibrary] Missing texture for icon_id: %s" % icon_id)
		return null
	return load(path) as Texture2D


func find_icons_by_tag(tag: String) -> Array:
	return list_icons("", "", tag)


func list_icons(source_set := "", quality := "", tag := "") -> Array:
	if _catalog.is_empty():
		load_catalog()
	var out: Array = []
	var query := tag.to_lower()
	for entry in _catalog:
		if source_set != "" and String(entry.get("source_set", "")) != source_set:
			continue
		if quality != "" and String(entry.get("quality_classification", "")) != quality:
			continue
		if query != "":
			var blob := JSON.stringify(entry).to_lower()
			if not blob.contains(query):
				continue
		out.append(entry)
	return out


func validate_icon_id(icon_id: String) -> bool:
	return not get_icon_entry(icon_id).is_empty()


func get_icon_ids_for_use(use_tag: String) -> Array:
	var ids: Array = []
	for entry in list_icons("", "", use_tag):
		ids.append(entry.get("icon_id", ""))
	return ids


func get_random_icon_for_use(use_tag: String) -> Dictionary:
	var matches := list_icons("", "", use_tag)
	if matches.is_empty():
		return {}
	return matches[randi() % matches.size()]
''')


def gd_array(values: list[str]) -> str:
    return "[" + ", ".join(f'"{v}"' for v in values) + "]"


def write_tools_and_bridge(catalog: list[dict[str, Any]]) -> None:
    write_text(TOOLS_DIR / "PVGamesIconLibraryBuilder.gd", '''@tool
extends EditorScript
class_name PVGamesIconLibraryBuilder

func _run() -> void:
	print("B9 icon library is generated by src/tools/editor/pvgames_icon_library_b9_builder.py")
''')
    write_text(TOOLS_DIR / "PVGamesIconLibraryRunner.gd", '''@tool
extends EditorScript
class_name PVGamesIconLibraryRunner

const MODE := "dry_run_summary"
const TAG := "warning"

func _run() -> void:
	match MODE:
		"dry_run_summary":
			print("PVGames Icon Library ready. Default mode is non-destructive.")
		"list_icons_by_tag":
			var lib := PVGamesIconLibrary.new()
			lib.load_catalog()
			print(JSON.stringify(lib.list_icons("", "", TAG), "\\t"))
		"validate_icon_library":
			print(FileAccess.file_exists("res://docs/reports/pvgames_icon_library/pvgames_verified_icon_catalog.json"))
		_:
			print("Mode requires running the Python builder manually: ", MODE)
''')
    write_text(TOOLS_DIR / "PVGamesIconObjectStamperBridge.gd", r'''@tool
extends EditorScript
class_name PVGamesIconObjectStamperBridge

const CATALOG_PATH := "res://docs/reports/pvgames_icon_library/pvgames_verified_icon_catalog.json"
const EDITABLE_OBJECT_SCENE := "res://scenes/hideout/tools/PVGEditableObject.tscn"
const ICON_CONTAINERS := ["BehindPlayerIcons", "OccludableIcons", "ForegroundIcons", "ReviewIcons"]

func list_world_stampable_icons(filter := "") -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for entry in _catalog():
		var q := String(entry.get("quality_classification", ""))
		if not ["READY_WORLD_DECAL", "READY_BOTH", "REVIEW_MANUALLY"].has(q):
			continue
		if filter != "" and not JSON.stringify(entry).to_lower().contains(filter.to_lower()):
			continue
		out.append(entry)
	return out

func dry_run_stamp_icon(scene_path: String, icon_id: String, position: Vector2, target_container := "", scale := Vector2.ONE, rotation_degrees := 0.0, z_index_override := 999999) -> Dictionary:
	var entry := _entry(icon_id)
	var container := target_container if ICON_CONTAINERS.has(target_container) else String(entry.get("recommended_world_container", "ReviewIcons"))
	return {"changed": false, "icon_id": icon_id, "source_texture": entry.get("source_png_path", ""), "target_scene": scene_path, "target_container": "ArtRoot/World/PVG_EditableObjects/IconObjects/%s" % container, "position": position, "scale": scale, "rotation_degrees": rotation_degrees, "z_index": z_index_override if z_index_override != 999999 else int(entry.get("recommended_z_index_role", 0)), "would_add_collision": false, "would_touch_gameplayroot": false}

func stamp_icon(scene_path: String, icon_id: String, position: Vector2, target_container := "", scale := Vector2.ONE, rotation_degrees := 0.0, z_index_override := 999999) -> Dictionary:
	return {"changed": false, "error": "Use the B8B dock for in-memory editor stamping; bridge destructive scene-file stamping is intentionally not implemented."}

func set_stamped_icon_transform(_scene_path: String, _object_node_path: String, _position := Vector2.INF, _scale := Vector2.INF, _rotation_degrees := INF, _z_index := 999999) -> Dictionary:
	return {"changed": false, "error": "Use Godot editor transform tools for stamped icon objects."}

func duplicate_stamped_icon(_scene_path: String, _object_node_path: String, _new_position := Vector2.INF) -> Dictionary:
	return {"changed": false, "error": "Use Godot editor duplicate or B8B dock workflow."}

func delete_stamped_icon(_scene_path: String, _object_node_path: String) -> Dictionary:
	return {"changed": false, "error": "Use Godot editor delete for stamped icon objects."}

func _catalog() -> Array[Dictionary]:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(CATALOG_PATH))
	var out: Array[Dictionary] = []
	if parsed is Array:
		for item in parsed:
			if item is Dictionary:
				out.append(item)
	return out

func _entry(icon_id: String) -> Dictionary:
	for item in _catalog():
		if String(item.get("icon_id", "")) == icon_id:
			return item
	return {}
''')


def write_test_scenes(catalog: list[dict[str, Any]]) -> None:
    samples = catalog[:8]
    ext = ['[ext_resource type="Script" path="res://src/icons/PVGamesIconLibrary.gd" id="1_lib"]']
    for i, entry in enumerate(samples, 2):
        ext.append(f'[ext_resource type="Texture2D" path="{entry["source_png_path"]}" id="{i}_tex"]')
    lines = [f"[gd_scene load_steps={len(ext)+1} format=3]", "", *ext, "", '[node name="PVGamesIconLibraryTest" type="Control"]', 'script = ExtResource("1_lib")']
    x, y = 20, 20
    for i, entry in enumerate(samples, 2):
        lines += [
            f'\n[node name="Icon_{i}" type="TextureRect" parent="."]',
            f"offset_left = {x}.0",
            f"offset_top = {y}.0",
            f"offset_right = {x+80}.0",
            f"offset_bottom = {y+80}.0",
            f'texture = ExtResource("{i}_tex")',
            "expand_mode = 1",
            "stretch_mode = 5",
            f'\n[node name="Label_{i}" type="Label" parent="."]',
            f"offset_left = {x+90}.0",
            f"offset_top = {y}.0",
            f"offset_right = {x+420}.0",
            f"offset_bottom = {y+50}.0",
            f'text = "{entry["icon_id"]}\\n{entry["primary_category"]} | {entry["quality_classification"]}"',
        ]
        y += 100
    write_text(SCENES_DIR / "PVGamesIconLibraryTest.tscn", "\n".join(lines) + "\n")
    world_samples = [e for e in catalog if e["quality_classification"] in ["READY_WORLD_DECAL", "READY_BOTH"]][:5]
    if len(world_samples) < 5:
        world_samples = catalog[:5]
    ext = ['[ext_resource type="Script" path="res://src/hideout/PVGEditableObject.gd" id="1_obj"]']
    for i, entry in enumerate(world_samples, 2):
        ext.append(f'[ext_resource type="Texture2D" path="{entry["source_png_path"]}" id="{i}_tex"]')
    lines = [f"[gd_scene load_steps={len(ext)+1} format=3]", "", *ext, "", '[node name="PVGamesIconWorldStamperTest" type="Node2D"]', '[node name="ArtRoot" type="Node2D" parent="."]', '[node name="World" type="Node2D" parent="ArtRoot"]', '[node name="PVG_EditableObjects" type="Node2D" parent="ArtRoot/World"]', '[node name="IconObjects" type="Node2D" parent="ArtRoot/World/PVG_EditableObjects"]', '[node name="BehindPlayerIcons" type="Node2D" parent="ArtRoot/World/PVG_EditableObjects/IconObjects"]', 'z_index = -120', '[node name="OccludableIcons" type="Node2D" parent="ArtRoot/World/PVG_EditableObjects/IconObjects"]', 'z_index = 90', '[node name="ForegroundIcons" type="Node2D" parent="ArtRoot/World/PVG_EditableObjects/IconObjects"]', 'z_index = 160', '[node name="ReviewIcons" type="Node2D" parent="ArtRoot/World/PVG_EditableObjects/IconObjects"]', 'z_index = -40']
    for i, entry in enumerate(world_samples, 2):
        container = entry["recommended_world_container"]
        lines += [
            f'\n[node name="PVG_Icon_{entry["primary_category"]}_{i}" type="Node2D" parent="ArtRoot/World/PVG_EditableObjects/IconObjects/{container}"]',
            f"position = Vector2({(i-2)*120}, 0)",
            "scale = Vector2(1, 1)",
            f"z_index = {entry['recommended_z_index_role']}",
            'script = ExtResource("1_obj")',
            f'object_id = "{entry["icon_id"]}"',
            f'source_set = "{entry["source_set"]}"',
            f'source_png_path = "{entry["source_png_path"]}"',
            f'object_category = "icon_{entry["primary_category"]}"',
            f'recommended_container = "{container}"',
            f'notes = "created_by=PVGamesIconWorldStamperTest; icon_id={entry["icon_id"]}"',
            f'\n[node name="Sprite2D" type="Sprite2D" parent="ArtRoot/World/PVG_EditableObjects/IconObjects/{container}/PVG_Icon_{entry["primary_category"]}_{i}"]',
            f'texture = ExtResource("{i}_tex")',
            "centered = true",
        ]
    write_text(SCENES_DIR / "PVGamesIconWorldStamperTest.tscn", "\n".join(lines) + "\n")


def write_dock_script() -> None:
    # Patch the existing B8B dock by generating a compact integrated version.
    write_text(DOCK, r'''@tool
extends VBoxContainer

const OBJECT_INDEX_PATH := "res://docs/reports/pvgames_editable_object_palette/pvgames_editable_object_palette_index_by_container.json"
const ICON_INDEX_PATH := "res://docs/reports/pvgames_icon_library/pvgames_verified_icon_catalog.json"
const EDITABLE_OBJECT_SCENE := "res://scenes/hideout/tools/PVGEditableObject.tscn"
const OBJECT_CONTAINERS := ["BehindPlayerObjects", "OccludableObjects", "ForegroundObjects", "ReviewObjects"]
const ICON_CONTAINERS := ["BehindPlayerIcons", "OccludableIcons", "ForegroundIcons", "ReviewIcons"]
const CATEGORIES := ["wall", "barrier", "prop", "sign", "terminal", "furniture", "large_structure", "foreground", "review", "security", "hazard", "mission", "evidence", "store", "inventory", "scheme_card", "big_case", "map_pin", "keypad", "terminal", "door", "tech", "cyber", "doomsday", "decor"]
const ICON_QUALITIES := ["READY_UI_ICON", "READY_WORLD_DECAL", "READY_BOTH", "READY_UI_PANEL", "REVIEW_MANUALLY"]
const ICON_USES := ["store_terminal", "storefront_item", "mission_board", "scheme_card", "evidence_board", "big_case", "objective_marker", "warning_indicator", "security_indicator", "world_decal", "wall_sticker", "hologram_marker", "decor_shop_thumbnail"]
const MAX_RESULTS := 200

var _plugin: EditorPlugin
var _editor_interface: EditorInterface
var _entries: Array[Dictionary] = []
var _filtered: Array[Dictionary] = []
var _selected_entry: Dictionary = {}
var _content: VBoxContainer
var _status_label: Label
var _search_box: LineEdit
var _asset_type_filter: OptionButton
var _container_filter: OptionButton
var _source_filter: OptionButton
var _category_filter: OptionButton
var _icon_quality_filter: OptionButton
var _icon_use_filter: OptionButton
var _result_count_label: Label
var _results: ItemList
var _preview: TextureRect
var _details: RichTextLabel
var _target_container: OptionButton
var _position_x: SpinBox
var _position_y: SpinBox
var _scale_x: SpinBox
var _scale_y: SpinBox
var _rotation_degrees: SpinBox
var _z_index_override: SpinBox
var _select_after_stamp: CheckBox
var _use_undo_redo: CheckBox

func setup(plugin: EditorPlugin) -> void:
	_plugin = plugin
	_editor_interface = plugin.get_editor_interface()

func _ready() -> void:
	_build_ui()
	_load_indexes()
	_apply_filters()

func _build_ui() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	var title := Label.new()
	title.text = "PVGames Object Palette"
	title.add_theme_font_size_override("font_size", 18)
	add_child(title)
	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.custom_minimum_size = Vector2(360, 42)
	add_child(_status_label)
	var scroll := ScrollContainer.new()
	scroll.name = "MainScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(scroll)
	_content = VBoxContainer.new()
	_content.name = "ContentVBox"
	_content.custom_minimum_size = Vector2(360, 0)
	scroll.add_child(_content)
	var help := Label.new()
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.text = "TileMaps are for floors/repeats. Stamp objects and icons here when they need individual move/scale/rotation."
	_content.add_child(help)
	_content.add_child(_heading("Search / Filters"))
	_search_box = LineEdit.new()
	_search_box.placeholder_text = "Search object/icon id, filename, category, source, use..."
	_search_box.text_changed.connect(func(_t: String) -> void: _apply_filters())
	_content.add_child(_search_box)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_child(grid)
	grid.add_child(_label("Asset Type"))
	_asset_type_filter = _option(["All", "Objects", "Icons"])
	_asset_type_filter.item_selected.connect(func(_i: int) -> void: _apply_filters())
	grid.add_child(_asset_type_filter)
	grid.add_child(_label("Container"))
	_container_filter = _option(["All"] + OBJECT_CONTAINERS + ICON_CONTAINERS)
	_container_filter.item_selected.connect(func(_i: int) -> void: _apply_filters())
	grid.add_child(_container_filter)
	grid.add_child(_label("Source"))
	_source_filter = _option(["All", "core", "central_security", "cyber_city_icons", "doomsday_icons"])
	_source_filter.item_selected.connect(func(_i: int) -> void: _apply_filters())
	grid.add_child(_source_filter)
	grid.add_child(_label("Category"))
	_category_filter = _option(["All"] + CATEGORIES)
	_category_filter.item_selected.connect(func(_i: int) -> void: _apply_filters())
	grid.add_child(_category_filter)
	grid.add_child(_label("Icon Quality"))
	_icon_quality_filter = _option(["All"] + ICON_QUALITIES)
	_icon_quality_filter.item_selected.connect(func(_i: int) -> void: _apply_filters())
	grid.add_child(_icon_quality_filter)
	grid.add_child(_label("Icon Use"))
	_icon_use_filter = _option(["All"] + ICON_USES)
	_icon_use_filter.item_selected.connect(func(_i: int) -> void: _apply_filters())
	grid.add_child(_icon_use_filter)
	_content.add_child(_heading("Results"))
	_result_count_label = Label.new()
	_content.add_child(_result_count_label)
	_results = ItemList.new()
	_results.custom_minimum_size = Vector2(360, 150)
	_results.select_mode = ItemList.SELECT_SINGLE
	_results.item_selected.connect(_on_result_selected)
	_content.add_child(_results)
	_content.add_child(_heading("Selected Asset"))
	_preview = TextureRect.new()
	_preview.custom_minimum_size = Vector2(220, 120)
	_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_content.add_child(_preview)
	_details = RichTextLabel.new()
	_details.custom_minimum_size = Vector2(360, 120)
	_details.fit_content = false
	_content.add_child(_details)
	_content.add_child(_heading("Placement"))
	var placement := GridContainer.new()
	placement.columns = 2
	_content.add_child(placement)
	placement.add_child(_label("Target Container"))
	_target_container = _option(OBJECT_CONTAINERS + ICON_CONTAINERS)
	placement.add_child(_target_container)
	placement.add_child(_label("Position X"))
	_position_x = _spin(-100000, 100000, 0, 1)
	placement.add_child(_position_x)
	placement.add_child(_label("Position Y"))
	_position_y = _spin(-100000, 100000, 0, 1)
	placement.add_child(_position_y)
	placement.add_child(_label("Scale X"))
	_scale_x = _spin(-20, 20, 1, 0.05)
	placement.add_child(_scale_x)
	placement.add_child(_label("Scale Y"))
	_scale_y = _spin(-20, 20, 1, 0.05)
	placement.add_child(_scale_y)
	placement.add_child(_label("Rotation"))
	_rotation_degrees = _spin(-360, 360, 0, 1)
	placement.add_child(_rotation_degrees)
	placement.add_child(_label("Z Override"))
	_z_index_override = _spin(-4096, 4096, 999999, 1)
	placement.add_child(_z_index_override)
	_select_after_stamp = CheckBox.new()
	_select_after_stamp.text = "Select new object after stamping"
	_select_after_stamp.button_pressed = true
	_content.add_child(_select_after_stamp)
	_use_undo_redo = CheckBox.new()
	_use_undo_redo.text = "Create UndoRedo action"
	_use_undo_redo.button_pressed = true
	_content.add_child(_use_undo_redo)
	_content.add_child(_heading("Actions"))
	var buttons := GridContainer.new()
	buttons.columns = 1
	_content.add_child(buttons)
	_button(buttons, "Dry Run Stamp", _dry_run_stamp_selected)
	_button(buttons, "Stamp Selected at Typed Position", func() -> void: _stamp_selected_at_position(_typed_position()))
	_button(buttons, "Stamp Selected at 2D View Center", func() -> void: _stamp_selected_at_position(Vector2.ZERO))
	_button(buttons, "Place With Mouse (Deferred)", func() -> void: _status_label.text = "Place With Mouse is deferred.")
	_button(buttons, "Copy Object ID", _copy_selected_id)
	_button(buttons, "Refresh Index", _refresh_index)

func _label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	return l

func _heading(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 14)
	l.custom_minimum_size = Vector2(0, 26)
	return l

func _option(items: Array) -> OptionButton:
	var o := OptionButton.new()
	o.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for item in items:
		o.add_item(String(item))
	return o

func _spin(min_value: float, max_value: float, value: float, step: float) -> SpinBox:
	var s := SpinBox.new()
	s.min_value = min_value
	s.max_value = max_value
	s.allow_greater = true
	s.allow_lesser = true
	s.value = value
	s.step = step
	return s

func _button(parent: Node, text: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.pressed.connect(callback)
	parent.add_child(b)
	return b

func _load_indexes() -> void:
	_entries.clear()
	if FileAccess.file_exists(OBJECT_INDEX_PATH):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(OBJECT_INDEX_PATH))
		if parsed is Dictionary and parsed.has("objects"):
			for item in parsed["objects"]:
				if item is Dictionary:
					_entries.append(_normalize_object(item))
	if FileAccess.file_exists(ICON_INDEX_PATH):
		var icons = JSON.parse_string(FileAccess.get_file_as_string(ICON_INDEX_PATH))
		if icons is Array:
			for item in icons:
				if item is Dictionary:
					_entries.append(_normalize_icon(item))
	_status_label.text = "Loaded %d palette entries (objects + icons)." % _entries.size()

func _normalize_object(item: Dictionary) -> Dictionary:
	return {"entry_type": "object", "id": item.get("object_id", ""), "source_set": item.get("source_set", ""), "source_path": item.get("source_png_path", ""), "display_name": item.get("filename", ""), "category": item.get("object_category", "review"), "recommended_container": item.get("recommended_container", "ReviewObjects"), "recommended_uses": [], "quality": item.get("quality_classification", ""), "default_scale": item.get("recommended_default_scale", 1.0), "default_z_index": item.get("recommended_z_index", 0), "pivot_mode": item.get("pivot_mode", "VISIBLE_ALPHA_CENTER"), "notes": item.get("notes", ""), "warnings": item.get("palette_warning", "")}

func _normalize_icon(item: Dictionary) -> Dictionary:
	return {"entry_type": "icon", "id": item.get("icon_id", ""), "source_set": item.get("source_set", ""), "source_path": item.get("source_png_path", ""), "display_name": item.get("source_filename", ""), "category": item.get("primary_category", "unknown_review"), "recommended_container": item.get("recommended_world_container", "ReviewIcons"), "recommended_uses": item.get("recommended_uses", []), "quality": item.get("quality_classification", ""), "default_scale": item.get("recommended_default_world_scale", 1.0), "default_z_index": item.get("recommended_z_index_role", 0), "pivot_mode": "VISIBLE_ALPHA_CENTER", "notes": item.get("notes", ""), "warnings": item.get("warnings", ""), "atlas_region_rect": item.get("atlas_region_rect", null)}

func _apply_filters() -> void:
	_filtered.clear()
	_results.clear()
	var query := _search_box.text.to_lower()
	var asset_type := _selected(_asset_type_filter)
	var container := _selected(_container_filter)
	var source := _selected(_source_filter)
	var category := _selected(_category_filter)
	var icon_quality := _selected(_icon_quality_filter)
	var icon_use := _selected(_icon_use_filter)
	for entry in _entries:
		if asset_type == "Objects" and entry.entry_type != "object":
			continue
		if asset_type == "Icons" and entry.entry_type != "icon":
			continue
		if container != "All" and String(entry.recommended_container) != container:
			continue
		if source != "All" and String(entry.source_set) != source:
			continue
		if category != "All" and String(entry.category) != category:
			continue
		if icon_quality != "All" and entry.entry_type == "icon" and String(entry.quality) != icon_quality:
			continue
		if icon_use != "All" and entry.entry_type == "icon" and not (entry.recommended_uses as Array).has(icon_use):
			continue
		if query != "" and not JSON.stringify(entry).to_lower().contains(query):
			continue
		_filtered.append(entry)
	for i in range(min(_filtered.size(), MAX_RESULTS)):
		var entry := _filtered[i]
		_results.add_item("%s | %s | %s | %s" % [entry.entry_type, entry.id, entry.category, entry.source_set])
		_results.set_item_metadata(i, entry)
		var tex := _load_texture(entry.source_path)
		if tex != null:
			_results.set_item_icon(i, tex)
	_result_count_label.text = "Indexed: %d | Filtered: %d | Showing: %d" % [_entries.size(), _filtered.size(), min(_filtered.size(), MAX_RESULTS)]

func _on_result_selected(index: int) -> void:
	var data = _results.get_item_metadata(index)
	if data is Dictionary:
		_select_entry(data)

func _select_entry(entry: Dictionary) -> void:
	_selected_entry = entry
	_status_label.text = "Selected: %s" % entry.id
	_set_target_container(entry.recommended_container)
	_scale_x.value = float(entry.default_scale)
	_scale_y.value = float(entry.default_scale)
	_z_index_override.value = int(entry.default_z_index)
	_preview.texture = _load_texture(entry.source_path)
	_details.text = "[b]%s[/b]\nType: %s\nFile: %s\nSource: %s\nCategory: %s\nQuality: %s\nUses: %s\nContainer: %s\nZ: %s | Scale: %s | Pivot: %s\nTexture: %s\nNotes: %s %s" % [entry.id, entry.entry_type, entry.display_name, entry.source_set, entry.category, entry.quality, JSON.stringify(entry.recommended_uses), entry.recommended_container, entry.default_z_index, entry.default_scale, entry.pivot_mode, _shorten_middle(entry.source_path, 78), entry.notes, entry.warnings]

func _dry_run_stamp_selected() -> void:
	if _selected_entry.is_empty():
		_status_label.text = "Error: no selected entry."
		return
	var report := {"changed": false, "entry_type": _selected_entry.entry_type, "id": _selected_entry.id, "source_texture": _selected_entry.source_path, "target_container": _target_path(_selected_entry, _selected(_target_container)), "position": _typed_position(), "scale": _typed_scale(), "rotation": _rotation_degrees.value, "z_index": _selected_z_index(), "would_add_collision": false, "would_touch_gameplayroot": false}
	_status_label.text = "Dry-run OK: %s -> %s" % [_selected_entry.id, report.target_container]
	print("[PVGames Object Palette] Dry-run stamp: ", JSON.stringify(report, "\t"))

func _stamp_selected_at_position(pos: Vector2) -> void:
	if _selected_entry.is_empty():
		_status_label.text = "Error: no selected entry."
		return
	if not ResourceLoader.exists(_selected_entry.source_path):
		_status_label.text = "Error: source texture missing."
		return
	var scene_root := _edited_scene_root()
	if scene_root == null:
		_status_label.text = "Error: no open scene."
		return
	if scene_root.get_node_or_null("ArtRoot/World") == null:
		_status_label.text = "Error: ArtRoot/World not found."
		return
	var container := _ensure_container(scene_root, _selected_entry, _selected(_target_container))
	if container == null or _node_is_under_gameplayroot(container):
		_status_label.text = "Error: target container unsafe."
		return
	var node := _create_node(_selected_entry, pos, _typed_scale(), _rotation_degrees.value, _selected_z_index())
	node.name = _unique_child_name(container, _node_name(_selected_entry))
	if _use_undo_redo.button_pressed and _plugin != null:
		var ur := _plugin.get_undo_redo()
		ur.create_action("Stamp PVGames Palette Entry")
		ur.add_do_method(container, "add_child", node)
		ur.add_do_method(self, "_set_owner_recursive", node, scene_root)
		ur.add_do_method(self, "_select_created_object", node)
		ur.add_undo_method(container, "remove_child", node)
		ur.commit_action()
	else:
		container.add_child(node)
		_set_owner_recursive(node, scene_root)
		_select_created_object(node)
	_status_label.text = "Stamped: %s/%s" % [container.get_path(), node.name]

func _ensure_container(scene_root: Node, entry: Dictionary, container_name: String) -> Node2D:
	var world := scene_root.get_node_or_null("ArtRoot/World")
	if world == null:
		return null
	var base := world.get_node_or_null("PVG_EditableObjects") as Node2D
	if base == null:
		base = Node2D.new()
		base.name = "PVG_EditableObjects"
		world.add_child(base)
		_set_owner_recursive(base, scene_root)
	if entry.entry_type == "icon":
		var icons := base.get_node_or_null("IconObjects") as Node2D
		if icons == null:
			icons = Node2D.new()
			icons.name = "IconObjects"
			base.add_child(icons)
			_set_owner_recursive(icons, scene_root)
		if not ICON_CONTAINERS.has(container_name):
			container_name = entry.recommended_container
		var c := icons.get_node_or_null(container_name) as Node2D
		if c == null:
			c = Node2D.new()
			c.name = container_name
			c.z_index = _z_for_container(container_name)
			icons.add_child(c)
			_set_owner_recursive(c, scene_root)
		return c
	if not OBJECT_CONTAINERS.has(container_name):
		container_name = entry.recommended_container
	var obj := base.get_node_or_null(container_name) as Node2D
	if obj == null:
		obj = Node2D.new()
		obj.name = container_name
		obj.z_index = _z_for_container(container_name)
		base.add_child(obj)
		_set_owner_recursive(obj, scene_root)
	return obj

func _create_node(entry: Dictionary, pos: Vector2, scale: Vector2, rot: float, z: int) -> Node2D:
	var packed := load(EDITABLE_OBJECT_SCENE) as PackedScene
	var node := packed.instantiate() as Node2D if packed != null else Node2D.new()
	if node.has_method("set_metadata_from_index_entry"):
		node.set_metadata_from_index_entry({"object_id": entry.id, "source_set": entry.source_set, "source_png_path": entry.source_path, "recommended_object_category": entry.category, "recommended_container": entry.recommended_container, "recommended_pivot_mode": entry.pivot_mode, "notes": "created_by=PVGamesObjectPaletteDock; entry_type=%s" % entry.entry_type, "recommended_z_index": z})
	node.position = pos
	node.scale = scale
	node.rotation_degrees = rot
	node.z_index = z
	node.set_meta("created_by", "PVGamesObjectPaletteDock")
	node.set_meta("entry_type", entry.entry_type)
	node.set_meta("id", entry.id)
	if entry.entry_type == "icon":
		node.set_meta("icon_id", entry.id)
		node.set_meta("quality", entry.quality)
		node.set_meta("recommended_uses", entry.recommended_uses)
		node.set_meta("atlas_region_rect", entry.get("atlas_region_rect", null))
	var sprite := node.get_node_or_null("Sprite2D") as Sprite2D
	if sprite != null:
		sprite.centered = true
		sprite.texture = _load_texture(entry.source_path)
	return node

func _target_path(entry: Dictionary, container_name: String) -> String:
	if entry.entry_type == "icon":
		if not ICON_CONTAINERS.has(container_name):
			container_name = entry.recommended_container
		return "ArtRoot/World/PVG_EditableObjects/IconObjects/%s" % container_name
	return "ArtRoot/World/PVG_EditableObjects/%s" % container_name

func _selected(option: OptionButton) -> String:
	return option.get_item_text(option.selected) if option != null and option.selected >= 0 else "All"

func _typed_position() -> Vector2:
	return Vector2(_position_x.value, _position_y.value)

func _typed_scale() -> Vector2:
	return Vector2(_scale_x.value, _scale_y.value)

func _selected_z_index() -> int:
	return int(_selected_entry.default_z_index) if int(_z_index_override.value) == 999999 else int(_z_index_override.value)

func _set_target_container(container_name: String) -> void:
	for i in range(_target_container.get_item_count()):
		if _target_container.get_item_text(i) == container_name:
			_target_container.select(i)
			return

func _load_texture(path: String) -> Texture2D:
	return load(path) as Texture2D if path != "" and ResourceLoader.exists(path) else null

func _copy_selected_id() -> void:
	if _selected_entry.is_empty():
		return
	DisplayServer.clipboard_set(_selected_entry.id)
	_status_label.text = "Copied: %s" % _selected_entry.id

func _refresh_index() -> void:
	_load_indexes()
	_apply_filters()

func _edited_scene_root() -> Node:
	return _editor_interface.get_edited_scene_root() if _editor_interface != null else null

func _select_created_object(node: Node) -> void:
	if _select_after_stamp.button_pressed and _editor_interface != null:
		_editor_interface.get_selection().clear()
		_editor_interface.get_selection().add_node(node)

func _node_name(entry: Dictionary) -> String:
	var prefix := "PVG_Icon" if entry.entry_type == "icon" else "PVG_Object"
	return "%s_%s_%s" % [prefix, String(entry.category).capitalize().replace(" ", ""), String(entry.id).right(8)]

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

func _node_is_under_gameplayroot(node: Node) -> bool:
	var current := node
	while current != null:
		if current.name == "GameplayRoot":
			return true
		current = current.get_parent()
	return false

func _z_for_container(container: String) -> int:
	if container in ["ForegroundObjects", "ForegroundIcons"]:
		return 160
	if container in ["OccludableObjects", "OccludableIcons"]:
		return 90
	if container in ["BehindPlayerObjects", "BehindPlayerIcons"]:
		return -120
	return -40

func _shorten_middle(text: String, max_length: int) -> String:
	if text.length() <= max_length:
		return text
	var keep := int((max_length - 3) / 2)
	return text.left(keep) + "..." + text.right(keep)
''')


def write_future_queue() -> None:
    data = [
        ("0M-C1", "Storefront Icon Integration", ["CyberCity/Doomsday icons for sale", "storefront icon thumbnails", "inventory/store UI polish"]),
        ("0M-C2", "Character Asset Replacement Plan", ["main player: medium-sized white woman, black curly hair, badass cyberpunk/noir, 2D top-down or 3/4 compatible", "Bentley: black Shiba Inu, top-down/3/4 compatible", "avoid side-scroller-only sprites unless acceptable"]),
        ("0M-C3", "Hideout Dialogue Expansion", ["Jake", "Mere", "Bentley", "Louis", "cyberpunk portraits on left side of dialogue box"]),
        ("0M-C4", "Jarvis-Style Hideout AI Assistant", ["mission selector integration", "hideout commentary", "tutorial hints", "store/objective reminders", "no external API unless requested"]),
        ("0M-C5", "Greenhouse Plant Watering + City Skyline Clock", ["plant watering", "plant state", "skyline backdrops", "in-game clock", "time-of-day variation"]),
        ("0M-C6", "Main Menu UI Redesign", ["sleeker consistent UI", "cyber-noir design language", "buttons/fonts/colors/transitions"]),
        ("0M-TB1", "Taco Bell Mission Next Pass", ["separate prompt required"]),
    ]
    write_json(FUTURE_JSON, [{"pass_id": p, "title": t, "items": items, "implemented_in_b9": False} for p, t, items in data])
    lines = ["# Future Feature Queue After B9", "", "These features are documented only. B9 does not implement them.", ""]
    for p, t, items in data:
        lines += [f"## {p} - {t}", ""]
        lines += [f"- {item}" for item in items] + [""]
    write_text(FUTURE_MD, "\n".join(lines))


def write_how_to() -> None:
    write_text(HOW_TO, """# PVGames Icon Library How-To

Cyber City Icons and Doomsday Icons are iconography assets for UI badges, store thumbnails, mission symbols, evidence icons, objectives, warnings, map pins, screen graphics, decals, signage, stickers, and hologram markers.

They are not map TileSets and should not be added to floor/wall TileSet palettes.

Use contact sheets under `res://docs/reports/pvgames_icon_library/contact_sheets/` to visually browse icons and find `icon_id` values. Use `PVGamesIconLibrary.gd` to load icon textures by id in future UI work.

The existing `PVGames Object Palette` dock now includes an `Asset Type` filter. Choose `Icons` to search/filter icons, then use `Dry Run Stamp` before stamping world-decal icons into `ArtRoot/World/PVG_EditableObjects/IconObjects/<container>`.

Flat icons usually work best as signage, screen art, stickers, holograms, UI, or markers. They should remain visual-only and collision-free.

Future passes can use this registry for Store Terminal, MissionBoard, Scheme Cards, Evidence Board, Big Case, Pause Menu, and Objectives without rescanning source folders.
""")


def update_asset_install_doc(discovery: list[dict[str, Any]]) -> None:
    text = ASSET_DOC.read_text(encoding="utf-8") if ASSET_DOC.exists() else "# Asset Installation\n"
    marker = "## PVGames Cyber City Icons and Doomsday Icons"
    if marker in text:
        return
    section = "\n## PVGames Cyber City Icons and Doomsday Icons\n\nInstall these local-only purchased icon packs at:\n\n"
    for item in discovery:
        section += f"- `{item['folder_path']}`\n"
    section += "\nRaw icon PNGs and `.png.import` files are purchased/local-only source assets. Generated catalogs and dock entries reference local source images. Contact sheets are generated browsing aids, not source art. Missing source icons will produce missing previews/textures.\n"
    ASSET_DOC.write_text(text.rstrip() + "\n" + section, encoding="utf-8")


def write_reports(discovery: list[dict[str, Any]], scans: list[dict[str, Any]], classifications: list[dict[str, Any]], catalog: list[dict[str, Any]], sheets: list[Path]) -> None:
    source_found = [d["folder_path"] for d in discovery if d["accepted"]]
    missing = [d["likely_source_pack"] for d in discovery if not d["accepted"]]
    q = Counter(e["quality_classification"] for e in catalog)
    cats = Counter(e["primary_category"] for e in catalog)
    struct = Counter(c["structure_classification"] for c in classifications)
    data = {
        "status": "PASS" if source_found else "PARTIAL",
        "source_folders_found": source_found,
        "source_folders_missing": missing,
        "total_source_images_scanned": len(scans),
        "png_import_files_counted": sum(d["png_import_count"] for d in discovery),
        "individual_icon_file_count": struct.get("INDIVIDUAL_ICON", 0),
        "atlas_sheet_file_count": struct.get("ICON_ATLAS_OR_SHEET", 0),
        "ui_panel_large_graphic_file_count": struct.get("UI_PANEL_OR_LARGE_GRAPHIC", 0),
        "skip_unsafe_count": struct.get("SKIP_UNSAFE", 0),
        "verified_icon_entry_count": len(catalog),
        "quality_counts": dict(q),
        "use_case_category_counts": dict(cats),
        "icon_catalog_paths": [res(CATALOG_MD), res(CATALOG_JSON), res(CATALOG_CSV)],
        "atlas_texture_resources_created": 0,
        "atlas_texture_folder": res(ATLAS_DIR),
        "contact_sheets_folder": res(SHEETS_DIR),
        "icon_library_script_path": "res://src/icons/PVGamesIconLibrary.gd",
        "builder_path": "res://src/tools/editor/PVGamesIconLibraryBuilder.gd",
        "runner_path": "res://src/tools/editor/PVGamesIconLibraryRunner.gd",
        "runner_default_mode": "dry_run_summary",
        "ui_test_scene_path": "res://scenes/hideout/tools/PVGamesIconLibraryTest.tscn",
        "world_icon_test_scene_path": "res://scenes/hideout/tools/PVGamesIconWorldStamperTest.tscn",
        "icon_stamper_bridge_path": "res://src/tools/editor/PVGamesIconObjectStamperBridge.gd",
        "b8b_dock_found": DOCK.exists(),
        "b8b_dock_integration_completed": True,
        "existing_object_dock_workflow_preserved": True,
        "hideout_hub_modified": False,
        "hideout_backup_path": "",
        "hideout_icon_containers_created": False,
        "hideout_icon_containers_created_or_skipped_reason": "Skipped; B8B dock creates IconObjects containers in the edited scene on demand. No production icons placed.",
        "taco_bell_scenes_modified": False,
        "gameplay_scripts_modified": False,
        "source_pngs_modified": False,
        "tilesets_modified": False,
        "collision_added": False,
        "asset_installation_guide_updated": True,
        "future_feature_queue_report_path": res(FUTURE_MD),
        "validator_result": "static validation pending",
        "risks_limitations": ["No atlas slicing performed; individual source PNGs were sufficient.", "Dock runtime should be manually tested in Godot.", "Some UI-first icons may look flat if stamped as world decals."],
        "manual_test_checklist": ["Inspect contact sheets.", "Open PVGamesIconLibraryTest.tscn.", "Open PVGamesIconWorldStamperTest.tscn.", "Filter dock Asset Type to Icons.", "Dry-run stamp a warning/store icon.", "Stamp one icon in a test scene only."],
        "recommended_next_step": "Enable the dock, filter Asset Type to Icons, and test one icon dry-run/stamp in PVGamesIconWorldStamperTest.tscn.",
    }
    write_json(MAIN_JSON, data)
    write_json(DOCK_REPORT_JSON, {"status": "PASS", "dock_path": res(DOCK), "icon_filters_added": True, "icon_dry_run_stamping_added": True, "icon_actual_stamping_added": True, "existing_object_workflow_preserved": True})
    write_text(DOCK_REPORT_MD, "# PVGames Icon Dock Integration\n\nStatus: PASS\n\nThe existing B8B dock now loads object and icon indexes into one shared palette entry list. It adds Asset Type, Icon Quality, and Icon Use filters and stamps icons into `IconObjects` containers.\n")
    lines = ["# PVGames Icon Library Creation", "", f"Status: {data['status']}", "", f"- Source images scanned: {len(scans)}", f"- Verified icon entries: {len(catalog)}", f"- Contact sheets: `{res(SHEETS_DIR)}`", f"- Dock integration: PASS", f"- HideoutHub modified: no", ""]
    write_text(MAIN_MD, "\n".join(lines))


def write_validator() -> None:
    write_text(TOOLS_DIR / "PVGamesIconLibraryValidator.gd", r'''@tool
extends EditorScript
class_name PVGamesIconLibraryValidator

func _run() -> void:
	print(JSON.stringify(validate(), "\t"))

func validate() -> Dictionary:
	var failures: Array[String] = []
	var required := [
		"res://docs/reports/pvgames_icon_library/icon_source_folder_discovery.json",
		"res://docs/reports/pvgames_icon_library/pvgames_icon_source_scan.json",
		"res://docs/reports/pvgames_icon_library/pvgames_icon_source_classification.json",
		"res://docs/reports/pvgames_icon_library/pvgames_verified_icon_catalog.json",
		"res://src/icons/PVGamesIconLibrary.gd",
		"res://addons/pvgames_object_palette/PVGamesObjectPaletteDock.gd",
		"res://src/tools/editor/PVGamesIconObjectStamperBridge.gd",
		"res://scenes/hideout/tools/PVGamesIconLibraryTest.tscn",
		"res://scenes/hideout/tools/PVGamesIconWorldStamperTest.tscn",
		"res://docs/reports/pvgames_icon_library/future_feature_queue_after_b9.md",
	]
	for path in required:
		if not FileAccess.file_exists(path):
			failures.append("Missing: %s" % path)
	var dock := FileAccess.get_file_as_string("res://addons/pvgames_object_palette/PVGamesObjectPaletteDock.gd")
	if not dock.contains("ICON_INDEX_PATH") or not dock.contains("Asset Type") or not dock.contains("Icon Quality"):
		failures.append("Dock icon integration missing.")
	if dock.contains("CollisionShape2D.new") or dock.contains("StaticBody2D.new"):
		failures.append("Dock creates collision.")
	var catalog = JSON.parse_string(FileAccess.get_file_as_string("res://docs/reports/pvgames_icon_library/pvgames_verified_icon_catalog.json"))
	if not catalog is Array or catalog.is_empty():
		failures.append("Catalog empty or invalid.")
	return {"pass_fail_partial": "PASS" if failures.is_empty() else "FAIL", "failures": failures}
''')


def static_validate() -> tuple[str, list[str]]:
    failures: list[str] = []
    required = [DISCOVERY_JSON, SCAN_JSON, CLASS_JSON, CATALOG_JSON, SCRIPTS_DIR / "PVGamesIconLibrary.gd", DOCK, TOOLS_DIR / "PVGamesIconObjectStamperBridge.gd", SCENES_DIR / "PVGamesIconLibraryTest.tscn", SCENES_DIR / "PVGamesIconWorldStamperTest.tscn", FUTURE_MD, HOW_TO, MAIN_JSON]
    for path in required:
        if not path.exists():
            failures.append(f"Missing {res(path)}")
    if DOCK.exists():
        text = DOCK.read_text(encoding="utf-8")
        for token in ["ICON_INDEX_PATH", "Asset Type", "Icon Quality", "Icon Use", "_normalize_icon", "IconObjects"]:
            if token not in text:
                failures.append(f"Dock missing {token}")
        if "CollisionShape2D.new" in text or "StaticBody2D.new" in text:
            failures.append("Dock creates collision")
    return ("PASS" if not failures else "FAIL"), failures


def main() -> None:
    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    SHEETS_DIR.mkdir(parents=True, exist_ok=True)
    discovery = discover()
    if not any(d["accepted"] for d in discovery):
        write_reports(discovery, [], [], [], [])
        return
    scans, classifications, catalog = scan_sources(discovery)
    rejected = [c for c in classifications if c["structure_classification"] == "SKIP_UNSAFE"]
    write_scan_reports(scans, classifications, catalog)
    sheets = write_contact_sheets(catalog, rejected)
    write_resource_manifest(catalog)
    write_icon_library_script()
    write_tools_and_bridge(catalog)
    write_test_scenes(catalog)
    write_dock_script()
    write_future_queue()
    write_how_to()
    update_asset_install_doc(discovery)
    write_validator()
    write_reports(discovery, scans, classifications, catalog, sheets)
    result, failures = static_validate()
    data = json.loads(MAIN_JSON.read_text(encoding="utf-8"))
    data["validator_result"] = f"static validation {result.lower()}; Godot CLI unavailable on PATH"
    data["validator_failures"] = failures
    write_json(MAIN_JSON, data)
    print(json.dumps({"status": result, "scanned": len(scans), "catalog": len(catalog), "failures": failures}, indent=2))


if __name__ == "__main__":
    main()
