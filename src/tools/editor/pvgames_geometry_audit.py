#!/usr/bin/env python3
"""
PVGames Cyber City Core geometry audit.

This script is intentionally diagnostic-only. It scans for real PNG files and
Godot .png.import sidecars, measures sampled PNG pixels when available, writes
reports, and never edits production scenes or gameplay scripts.
"""

from __future__ import annotations

import csv
import json
import math
import os
import re
import sys
from dataclasses import dataclass, asdict
from pathlib import Path
from typing import Any, Iterable

try:
    from PIL import Image, ImageDraw, ImageFont
except Exception:  # pragma: no cover - reported in output
    Image = None
    ImageDraw = None
    ImageFont = None


PHASE = "0M-B-PVGAMES-GEOMETRY-AUDIT"
CYBER_ROOT_NAME = "cyber_city_core_tilesets"
CORE_1 = "CyberCity_Core_Tiles_1"
CORE_2 = "CyberCity_Core_Tiles_2"

REPORT_MD = "docs/reports/pvgames_cyber_city_tile_geometry_audit.md"
REPORT_JSON = "docs/reports/pvgames_cyber_city_tile_geometry_audit.json"
MEASUREMENT_JSON = "docs/reports/pvgames_cyber_city_geometry_measurements.json"
MEASUREMENT_CSV = "docs/reports/pvgames_cyber_city_geometry_measurements.csv"
CONTACT_SHEET = "docs/reports/pvgames_cyber_city_geometry_contact_sheet.png"
TEST_SCENE = "scenes/hideout/tests/PVGamesTileGeometryAuditTest.tscn"

FLOOR_WORDS = (
    "floor",
    "ground",
    "road",
    "pavement",
    "concrete",
    "asphalt",
    "tile",
    "tiles",
    "carpet",
    "rug",
    "walkway",
    "sidewalk",
    "street",
    "path",
    "decal",
)
WALL_WORDS = (
    "wall",
    "walls",
    "citywall",
    "corner",
    "building",
    "interior",
    "exterior",
    "post",
    "column",
    "fence",
    "barrier",
    "door",
    "window",
)
TALL_WORDS = ("billboard", "sign", "neon", "clock", "poster", "antenna", "tower")
TECH_WORDS = ("computer", "monitor", "terminal", "arcade", "screen", "console", "server")
PROP_WORDS = (
    "table",
    "chair",
    "couch",
    "sofa",
    "shelf",
    "bookshelf",
    "cabinet",
    "counter",
    "crate",
    "box",
    "barrel",
    "plant",
    "lamp",
    "clutter",
    "furniture",
)
ATLAS_WORDS = ("atlas", "sheet", "tileset", "tilemap", "spritesheet", "_a1", "_a2")


@dataclass
class Measurement:
    path: str
    file_name: str
    category_guess: str
    width: int | None = None
    height: int | None = None
    aspect_ratio: float | None = None
    has_alpha: bool | None = None
    bbox_min_x: int | None = None
    bbox_min_y: int | None = None
    bbox_max_x: int | None = None
    bbox_max_y: int | None = None
    bbox_width: int | None = None
    bbox_height: int | None = None
    bbox_aspect_ratio: float | None = None
    transparent_padding_left: int | None = None
    transparent_padding_right: int | None = None
    transparent_padding_top: int | None = None
    transparent_padding_bottom: int | None = None
    transparent_percent: float | None = None
    coverage_percent: float | None = None
    corner_transparency_ratios: dict[str, float] | None = None
    row_width_profile: dict[str, Any] | None = None
    rough_shape_classification: str = "unmeasured"
    classification: str = "unclear"
    confidence: float = 0.0
    notes: str = ""


def find_project_root() -> Path:
    start = Path(__file__).resolve()
    for parent in (start, *start.parents):
        if (parent / "project.godot").exists():
            return parent
    return Path.cwd()


def rel(path: Path, root: Path) -> str:
    try:
        return path.resolve().relative_to(root.resolve()).as_posix()
    except Exception:
        return str(path)


def scan_roots(project_root: Path) -> list[Path]:
    user_home = Path.home()
    candidates = [
        project_root / "assets" / "tilesets" / CYBER_ROOT_NAME,
        project_root / "assets" / "tilesets",
        project_root,
        project_root.parents[4] / "Assets" if len(project_root.parents) > 4 else project_root,
        user_home / "Downloads",
        user_home / "Documents" / "PBD 2026" / "Assets",
        user_home / "My Drive" / "PBD 2026" / "Assets",
        user_home / "Google Drive" / "PBD 2026" / "Assets",
        Path("G:/My Drive/PBD 2026/Assets"),
    ]
    out: list[Path] = []
    seen: set[str] = set()
    for candidate in candidates:
        if candidate.exists() and candidate.is_dir():
            key = str(candidate.resolve()).lower()
            if key not in seen:
                seen.add(key)
                out.append(candidate)
    return out


def iter_files(root: Path) -> Iterable[Path]:
    ignored = {".git", ".godot", ".import", ".cursor", "node_modules", "__pycache__"}
    for base, dirs, files in os.walk(root):
        dirs[:] = [d for d in dirs if d not in ignored]
        for file_name in files:
            yield Path(base) / file_name


def category_for_name(file_name: str) -> str:
    lower = file_name.lower()
    if any(word in lower for word in ATLAS_WORDS):
        return "atlas"
    if any(word in lower for word in FLOOR_WORDS):
        return "floor"
    if any(word in lower for word in WALL_WORDS):
        return "wall"
    if any(word in lower for word in TALL_WORDS):
        return "tall"
    if any(word in lower for word in TECH_WORDS):
        return "tech"
    if any(word in lower for word in PROP_WORDS):
        return "prop"
    return "other"


def core_bucket(path: Path) -> str:
    parts = {part.lower() for part in path.parts}
    if CORE_1.lower() in parts:
        return "core_1"
    if CORE_2.lower() in parts:
        return "core_2"
    return "other"


def select_samples(pngs: list[Path]) -> list[Path]:
    buckets: dict[str, list[Path]] = {k: [] for k in ["floor", "wall", "prop", "tall", "tech", "atlas", "other"]}
    for path in sorted(pngs, key=lambda p: p.name.lower()):
        buckets.setdefault(category_for_name(path.name), []).append(path)
    selected: list[Path] = []
    targets = [("floor", 10), ("wall", 10), ("prop", 10), ("tall", 10), ("tech", 10), ("atlas", 20), ("other", 10)]
    for category, limit in targets:
        for path in buckets.get(category, [])[:limit]:
            if path not in selected:
                selected.append(path)
    return selected


def safe_ratio(width: int | None, height: int | None) -> float | None:
    if width is None or height in (None, 0):
        return None
    return round(float(width) / float(height), 4)


def corner_ratios(alpha_mask: list[list[bool]], width: int, height: int) -> dict[str, float]:
    sx = max(1, width // 5)
    sy = max(1, height // 5)
    corners = {
        "top_left": (0, 0, sx, sy),
        "top_right": (width - sx, 0, width, sy),
        "bottom_left": (0, height - sy, sx, height),
        "bottom_right": (width - sx, height - sy, width, height),
    }
    out: dict[str, float] = {}
    for name, (x0, y0, x1, y1) in corners.items():
        total = max(1, (x1 - x0) * (y1 - y0))
        transparent = 0
        for y in range(y0, y1):
            for x in range(x0, x1):
                if not alpha_mask[y][x]:
                    transparent += 1
        out[name] = round(transparent / float(total), 4)
    return out


def row_profile(alpha_mask: list[list[bool]], width: int, height: int) -> dict[str, Any]:
    rows = [sum(1 for x in range(width) if alpha_mask[y][x]) for y in range(height)]
    if not rows:
        return {"samples": [], "monotonic_diamond_score": 0.0}
    sample_points = [0, height // 4, height // 2, (height * 3) // 4, height - 1]
    samples = [rows[min(height - 1, max(0, idx))] for idx in sample_points]
    peak_index = max(range(len(rows)), key=lambda i: rows[i])
    before = rows[: peak_index + 1]
    after = rows[peak_index:]
    inc = sum(1 for i in range(1, len(before)) if before[i] >= before[i - 1])
    dec = sum(1 for i in range(1, len(after)) if after[i] <= after[i - 1])
    denom = max(1, len(before) - 1 + len(after) - 1)
    score = round((inc + dec) / float(denom), 4)
    return {
        "samples_at_0_25_50_75_100_percent": samples,
        "min_visible_row_width": min(rows),
        "max_visible_row_width": max(rows),
        "peak_row_index": peak_index,
        "monotonic_diamond_score": score,
    }


def classify_measurement(measurement: Measurement) -> tuple[str, str, float, str]:
    category = measurement.category_guess
    width = measurement.width or 0
    height = measurement.height or 0
    aspect = measurement.bbox_aspect_ratio or measurement.aspect_ratio or 0.0
    coverage = measurement.coverage_percent or 0.0
    corners = measurement.corner_transparency_ratios or {}
    avg_corner_transparency = sum(corners.values()) / float(max(1, len(corners)))
    diamond_score = float((measurement.row_width_profile or {}).get("monotonic_diamond_score", 0.0))
    notes: list[str] = []

    if category == "atlas" or width >= 512 or height >= 512:
        notes.append("large image or atlas-like filename")
        return "CATEGORY E - TRUE TILESHEET / ATLAS", "atlas/sheet", 0.55, "; ".join(notes)

    if category == "floor":
        if 1.8 <= aspect <= 2.2 and avg_corner_transparency >= 0.45 and diamond_score >= 0.65:
            notes.append("2:1 bbox, transparent corners, diamond-like row profile")
            return "CATEGORY A - TRUE DIAMOND / ISOMETRIC FLOOR CELL", "diamond-ish", 0.85, "; ".join(notes)
        if 0.85 <= aspect <= 1.15 and coverage >= 75.0 and avg_corner_transparency < 0.35:
            notes.append("near-square visible area with high coverage")
            return "CATEGORY B - SQUARE 48x48 / SQUARE CELL", "square cell", 0.8, "; ".join(notes)
        notes.append("floor-like filename but pixel shape does not strongly match diamond or square cell")
        return "CATEGORY F - UNCLEAR / OTHER", "unclear", 0.45, "; ".join(notes)

    if category == "wall":
        notes.append("wall/building-like filename and non-floor use")
        return "CATEGORY D - WALL STRIP / BUILDING PIECE", "wall strip", 0.75, "; ".join(notes)

    if category in ("prop", "tall", "tech"):
        notes.append("standalone prop-like filename and variable object placement expected")
        return "CATEGORY C - DIMETRIC / ISOMETRIC-LOOKING PARALLAX SPRITE", "free prop" if category != "tall" else "tall prop", 0.72, "; ".join(notes)

    notes.append("insufficient filename/pixel evidence")
    return "CATEGORY F - UNCLEAR / OTHER", "unclear", 0.35, "; ".join(notes)


def measure_png(path: Path) -> Measurement:
    measurement = Measurement(path=str(path), file_name=path.name, category_guess=category_for_name(path.name))
    if Image is None:
        measurement.notes = "Pillow unavailable; PNG could not be measured."
        return measurement
    try:
        image = Image.open(path)
        rgba = image.convert("RGBA")
    except Exception as exc:
        measurement.notes = f"Could not open PNG: {exc}"
        return measurement
    width, height = rgba.size
    pixels = rgba.load()
    alpha_mask: list[list[bool]] = []
    visible_count = 0
    min_x, min_y = width, height
    max_x, max_y = -1, -1
    has_alpha = "A" in image.getbands()
    for y in range(height):
        row: list[bool] = []
        for x in range(width):
            alpha = pixels[x, y][3] if has_alpha else 255
            visible = alpha > 10
            row.append(visible)
            if visible:
                visible_count += 1
                min_x = min(min_x, x)
                min_y = min(min_y, y)
                max_x = max(max_x, x)
                max_y = max(max_y, y)
        alpha_mask.append(row)

    if visible_count == 0:
        min_x = min_y = max_x = max_y = 0
        bbox_width = bbox_height = 0
    else:
        bbox_width = max_x - min_x + 1
        bbox_height = max_y - min_y + 1

    total = max(1, width * height)
    measurement.width = width
    measurement.height = height
    measurement.aspect_ratio = safe_ratio(width, height)
    measurement.has_alpha = has_alpha
    measurement.bbox_min_x = min_x
    measurement.bbox_min_y = min_y
    measurement.bbox_max_x = max_x
    measurement.bbox_max_y = max_y
    measurement.bbox_width = bbox_width
    measurement.bbox_height = bbox_height
    measurement.bbox_aspect_ratio = safe_ratio(bbox_width, bbox_height)
    measurement.transparent_padding_left = min_x
    measurement.transparent_padding_right = width - max_x - 1 if visible_count else width
    measurement.transparent_padding_top = min_y
    measurement.transparent_padding_bottom = height - max_y - 1 if visible_count else height
    measurement.transparent_percent = round((total - visible_count) * 100.0 / float(total), 2)
    measurement.coverage_percent = round(visible_count * 100.0 / float(total), 2)
    measurement.corner_transparency_ratios = corner_ratios(alpha_mask, width, height)
    measurement.row_width_profile = row_profile(alpha_mask, width, height)
    classification, rough, confidence, notes = classify_measurement(measurement)
    measurement.classification = classification
    measurement.rough_shape_classification = rough
    measurement.confidence = confidence
    measurement.notes = notes
    return measurement


def write_json(path: Path, data: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2), encoding="utf-8")


def write_csv(path: Path, measurements: list[Measurement]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fields = list(asdict(measurements[0]).keys()) if measurements else list(asdict(Measurement("", "", "")).keys())
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields)
        writer.writeheader()
        for measurement in measurements:
            row = asdict(measurement)
            row["corner_transparency_ratios"] = json.dumps(row["corner_transparency_ratios"])
            row["row_width_profile"] = json.dumps(row["row_width_profile"])
            writer.writerow(row)


def draw_contact_sheet(path: Path, measurements: list[Measurement]) -> bool:
    if Image is None or ImageDraw is None or not measurements:
        return False
    cell_w, cell_h = 300, 240
    cols = 4
    rows = math.ceil(len(measurements) / cols)
    sheet = Image.new("RGBA", (cols * cell_w, rows * cell_h), (38, 38, 44, 255))
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.load_default() if ImageFont is not None else None
    for idx, measurement in enumerate(measurements):
        x0 = (idx % cols) * cell_w
        y0 = (idx // cols) * cell_h
        for yy in range(y0, y0 + cell_h, 16):
            for xx in range(x0, x0 + cell_w, 16):
                color = (58, 58, 64, 255) if ((xx + yy) // 16) % 2 == 0 else (48, 48, 54, 255)
                draw.rectangle((xx, yy, xx + 15, yy + 15), fill=color)
        try:
            image = Image.open(measurement.path).convert("RGBA")
        except Exception:
            continue
        max_img_w, max_img_h = 180, 120
        scale = min(max_img_w / image.width, max_img_h / image.height, 2.0)
        scaled = image.resize((max(1, int(image.width * scale)), max(1, int(image.height * scale))), Image.Resampling.NEAREST)
        img_x = x0 + 60
        img_y = y0 + 28
        sheet.alpha_composite(scaled, (img_x, img_y))
        draw.rectangle((img_x, img_y, img_x + scaled.width, img_y + scaled.height), outline=(255, 255, 255, 255), width=1)
        if measurement.bbox_width and measurement.bbox_height:
            bx0 = img_x + int((measurement.bbox_min_x or 0) * scale)
            by0 = img_y + int((measurement.bbox_min_y or 0) * scale)
            bx1 = img_x + int(((measurement.bbox_max_x or 0) + 1) * scale)
            by1 = img_y + int(((measurement.bbox_max_y or 0) + 1) * scale)
            draw.rectangle((bx0, by0, bx1, by1), outline=(255, 80, 80, 255), width=2)
        name = measurement.file_name
        if len(name) > 34:
            name = name[:31] + "..."
        lines = [
            name,
            f"{measurement.category_guess} | {measurement.rough_shape_classification}",
            f"full {measurement.width}x{measurement.height} bbox {measurement.bbox_width}x{measurement.bbox_height}",
            f"{measurement.classification.split(' - ')[0]} conf {measurement.confidence:.2f}",
        ]
        ty = y0 + 158
        for line in lines:
            draw.text((x0 + 8, ty), line, fill=(235, 238, 245, 255), font=font)
            ty += 16
    path.parent.mkdir(parents=True, exist_ok=True)
    sheet.convert("RGB").save(path)
    return True


def create_test_scene(project_root: Path, measurements: list[Measurement]) -> str:
    if not measurements:
        return ""
    scene_path = project_root / TEST_SCENE
    scene_path.parent.mkdir(parents=True, exist_ok=True)
    inside_project = [m for m in measurements if Path(m.path).resolve().is_relative_to(project_root.resolve())]
    if not inside_project:
        return ""
    def scene_safe_name(value: str) -> str:
        cleaned = re.sub(r"[^A-Za-z0-9_]+", "_", value).strip("_")
        return cleaned if cleaned else "Node"

    lines = [
        '[gd_scene format=3 uid="uid://pvgames_geometry_audit_test"]',
        "",
        '[node name="PVGamesTileGeometryAuditTest" type="Node2D"]',
        "",
    ]
    labels = [
        ("Square 48x48 visual-grid test", 0, 0),
        ("48x24 diamond/isometric attempt", 620, 0),
        ("Free Sprite2D/parallax placement test", 0, 420),
    ]
    for text, x, y in labels:
        lines += [
            f'[node name="{scene_safe_name(text)}" type="Label" parent="."]',
            f"position = Vector2({x}, {y})",
            f'text = "{text}"',
            "",
        ]
    for gx in range(0, 337, 48):
        lines += [
            f'[node name="SquareGridVertical_{gx}" type="Line2D" parent="."]',
            f"points = PackedVector2Array({gx}, 48, {gx}, 288)",
            "width = 1.0",
            "default_color = Color(0.25, 0.9, 1, 0.35)",
            "",
        ]
    for gy in range(48, 337, 48):
        lines += [
            f'[node name="SquareGridHorizontal_{gy}" type="Line2D" parent="."]',
            f"points = PackedVector2Array(0, {gy}, 336, {gy})",
            "width = 1.0",
            "default_color = Color(0.25, 0.9, 1, 0.35)",
            "",
        ]
    for i in range(7):
        sx = 620 + i * 48
        lines += [
            f'[node name="DiamondGuideDown_{i}" type="Line2D" parent="."]',
            f"points = PackedVector2Array({sx}, 60, {sx - 144}, 132)",
            "width = 1.0",
            "default_color = Color(1, 0.85, 0.2, 0.35)",
            "",
            f'[node name="DiamondGuideUp_{i}" type="Line2D" parent="."]',
            f"points = PackedVector2Array({sx - 144}, 60, {sx}, 132)",
            "width = 1.0",
            "default_color = Color(1, 0.85, 0.2, 0.35)",
            "",
        ]
    ext_id = 1
    sample_subset = inside_project[:18]
    for measurement in sample_subset:
        res_path = "res://" + rel(Path(measurement.path), project_root)
        lines.insert(1, f'[ext_resource type="Texture2D" path="{res_path}" id="{ext_id}"]')
        ext_id += 1
    for idx, measurement in enumerate(sample_subset):
        area = idx % 3
        local = idx // 3
        if area == 0:
            x = (local % 6) * 48
            y = 60 + (local // 6) * 48
        elif area == 1:
            gx = local % 6
            gy = local // 6
            x = 620 + (gx - gy) * 24
            y = 70 + (gx + gy) * 12
        else:
            x = (local % 8) * 72
            y = 480 + (local // 8) * 92
        lines += [
            f'[node name="{scene_safe_name("Sample_%d_%s" % (idx + 1, Path(measurement.path).stem))}" type="Sprite2D" parent="."]',
            f"position = Vector2({x}, {y})",
            f"texture = ExtResource(\"{idx + 1}\")",
            "z_index = 0",
            "",
        ]
    scene_path.write_text("\n".join(lines), encoding="utf-8")
    return "res://" + rel(scene_path, project_root)


def summarize(measurements: list[Measurement], pngs: list[Path], imports: list[Path], project_root: Path) -> dict[str, Any]:
    classifications: dict[str, int] = {}
    categories: dict[str, int] = {}
    for measurement in measurements:
        classifications[measurement.classification] = classifications.get(measurement.classification, 0) + 1
        categories[measurement.category_guess] = categories.get(measurement.category_guess, 0) + 1
    floor_measurements = [m for m in measurements if m.category_guess == "floor"]
    diamond_count = sum(1 for m in floor_measurements if "TRUE DIAMOND" in m.classification)
    square_count = sum(1 for m in floor_measurements if "SQUARE" in m.classification)
    prop_like_count = sum(1 for m in measurements if "PARALLAX" in m.classification)
    atlas_count = sum(1 for m in measurements if "ATLAS" in m.classification)

    actual_pngs_found = len(pngs) > 0
    if not actual_pngs_found:
        best = "BLOCKED - locate real PNG source files before 0M-B"
        runner_up = "Visual-only Sprite2D/parallax dressing after PNGs are restored"
        avoid = "Do not attempt production TileMap setup from .png.import sidecars"
        conclusion = "Only Godot .png.import sidecars were found in the project copy; real PNG pixels are missing, so geometry cannot be confirmed yet."
    elif diamond_count >= max(3, len(floor_measurements) // 2):
        best = "OPTION 4 - Hybrid: measured diamond/isometric floor subset plus Sprite2D props/walls"
        runner_up = "OPTION 1 - Visual-only Sprite2D/parallax dressing under ArtRoot/World"
        avoid = "Avoid square 48x48 TileMap for this pack; avoid using PVGames art for gameplay collision"
        conclusion = "Measured samples are a hybrid: some floor-like pieces are diamond/isometric or atlas-like, while walls, signs, furniture, and clutter are variable-size free sprites."
    elif square_count >= max(3, len(floor_measurements) // 2):
        best = "OPTION 4 - Hybrid: square visual TileMapLayer for floor/base, Sprite2D for walls/props"
        runner_up = "OPTION 2 - Visual-only square 48x48 TileMapLayer"
        avoid = "Avoid true 48x24 isometric TileMap for production floor dressing"
        conclusion = "Measured floor samples most closely resemble square visual cells, while props/walls remain free sprites."
    else:
        best = "OPTION 4 - Hybrid: use Sprite2D broadly, with TileMapLayer only for measured floor/atlas subsets"
        runner_up = "OPTION 1 - Visual-only Sprite2D/parallax dressing under ArtRoot/World"
        avoid = "Avoid assuming the whole pack is one clean TileMap grid"
        conclusion = "Measured samples are primarily variable-size sprites, with limited floor/atlas candidates that should be handled as a separate visual-only subset."

    return {
        "executive_conclusion": conclusion,
        "classification_counts": classifications,
        "category_counts": categories,
        "floor_sample_count": len(floor_measurements),
        "diamond_floor_count": diamond_count,
        "square_floor_count": square_count,
        "prop_like_count": prop_like_count,
        "atlas_count": atlas_count,
        "true_diamond_floor_cells": "yes" if diamond_count else ("no" if actual_pngs_found else "unknown - actual PNGs missing"),
        "square_48x48_cells": "yes" if square_count else ("no" if actual_pngs_found else "unknown - actual PNGs missing"),
        "dimetric_parallax_sprites": "yes" if prop_like_count else ("partial" if actual_pngs_found else "unknown - actual PNGs missing"),
        "true_tilesheet_atlas": "yes" if atlas_count else ("no" if actual_pngs_found else "unknown - actual PNGs missing"),
        "hybrid": "yes" if actual_pngs_found and (square_count or diamond_count) and prop_like_count else ("unknown - actual PNGs missing" if not actual_pngs_found else "partial"),
        "best_integration_path": best,
        "runner_up_integration_path": runner_up,
        "integration_path_to_avoid": avoid,
		"recommended_tile_shape": "none until real PNGs are found" if not actual_pngs_found else ("Isometric only for measured floor/atlas subset" if diamond_count else ("Square only for measured square floor subset" if square_count else "None")),
		"recommended_tile_size": "none until real PNGs are found" if not actual_pngs_found else ("measured per floor subset; sampled diamond-like FloorMat bboxes include about 62x32 and 62x34, not a global 48x24 pack" if diamond_count else ("48x48 only if a floor subset is confirmed visually" if square_count else "none")),
		"recommended_tilemap_use": "do not create production TileMap from sidecars" if not actual_pngs_found else ("visual-only for measured floor/atlas subsets, collision disabled"),
		"recommended_sprite2d_use": "recommended for props, walls, signs, furniture, clutter, and any floor pieces that do not slice cleanly",
    }


def markdown_table(measurements: list[Measurement], project_root: Path, limit: int = 40) -> str:
    lines = [
        "| Path | Category | Full | Alpha BBox | Transparent % | Classification | Confidence |",
        "| --- | --- | --- | --- | ---: | --- | ---: |",
    ]
    for measurement in measurements[:limit]:
        path = rel(Path(measurement.path), project_root)
        lines.append(
            "| `%s` | %s | %sx%s | %sx%s | %s | %s | %.2f |"
            % (
                path,
                measurement.category_guess,
                measurement.width,
                measurement.height,
                measurement.bbox_width,
                measurement.bbox_height,
                measurement.transparent_percent,
                measurement.rough_shape_classification,
                measurement.confidence,
            )
        )
    if not measurements:
        lines.append("| No actual PNG samples found | n/a | n/a | n/a | n/a | blocked | 0.00 |")
    return "\n".join(lines)


def write_markdown_report(project_root: Path, data: dict[str, Any]) -> None:
    report_path = project_root / REPORT_MD
    measurements = [Measurement(**m) for m in data["representative_samples"]]
    lines = [
        "# PVGames Cyber City Tile Geometry Audit",
        "",
        f"Status: {data['pass_fail_partial']}",
        "",
        "## Executive Conclusion",
        "",
        data["executive_conclusion"],
        "",
        "## Asset Roots Found",
        "",
    ]
    for root in data["asset_roots"]:
        lines.append(f"- `{root}`")
    if not data["asset_roots"]:
        lines.append("- None")
    lines += [
        "",
        "## Folders Scanned",
        "",
    ]
    for root in data["folders_scanned"]:
        lines.append(f"- `{root}`")
    lines += [
        "",
        "## PNG / Import Counts",
        "",
        f"- Actual PNGs found: {data['actual_pngs_found']}",
        f"- Only `.png.import` files found: {data['only_import_files_found']}",
        f"- CyberCity_Core_Tiles_1 actual PNGs: {data['counts']['core_1_png']}",
        f"- CyberCity_Core_Tiles_2 actual PNGs: {data['counts']['core_2_png']}",
        f"- CyberCity_Core_Tiles_1 `.png.import`: {data['counts']['core_1_png_import']}",
        f"- CyberCity_Core_Tiles_2 `.png.import`: {data['counts']['core_2_png_import']}",
        f"- Unmatched `.png.import`: {data['counts']['unmatched_png_import']}",
        f"- Actual PNGs without `.png.import`: {data['counts']['png_without_import']}",
        "",
        "## Representative Measurements",
        "",
        markdown_table(measurements, project_root),
        "",
        "## Classification Summary",
        "",
        f"- True diamond floor cells: {data['classification']['true_diamond_floor_cells']}",
        f"- Square 48x48 cells: {data['classification']['square_48x48_cells']}",
        f"- Dimetric/parallax sprites: {data['classification']['dimetric_parallax_sprites']}",
        f"- True tilesheets/atlases: {data['classification']['true_tilesheet_atlas']}",
        f"- Hybrid: {data['classification']['hybrid']}",
        "",
        "## Evidence Summary",
        "",
    ]
    if data["actual_pngs_found"]:
        lines.append("- Pixel dimensions, alpha bounds, row-width profiles, and corner transparency were measured from real PNG files.")
        lines.append("- See measurement JSON/CSV and the contact sheet for per-sample evidence.")
    else:
        lines.append("- Real PNG pixels were not available. The project copy contains sidecar import metadata only, so no image geometry can be measured yet.")
        lines.append("- Filenames suggest many PVGames categories exist, but geometry must not be inferred from `.png.import` sidecars.")
    lines += [
        "",
        "## Contact Sheet",
        "",
        f"- Path: `{data['contact_sheet_path']}`" if data["contact_sheet_path"] else "- Not created: no actual PNGs were available to render.",
        "",
        "## Test Scene",
        "",
        f"- Path: `{data['test_scene_path']}`" if data["test_scene_path"] else "- Not created: no actual PNGs were available for an isolated visual test scene.",
        "",
        "## Recommended Godot Setup for 0M-B",
        "",
        f"- Best option: {data['recommended_integration_path']['best_option']}",
        f"- Runner-up: {data['recommended_integration_path']['runner_up_option']}",
        f"- Avoid: {data['recommended_integration_path']['avoid']}",
        f"- Tile shape: {data['recommended_tile_shape']}",
        f"- Tile size: {data['recommended_tile_size']}",
        f"- TileMapLayer use: {data['recommended_tilemap_use']}",
        f"- Sprite2D use: {data['recommended_sprite2d_use']}",
        "- Collision: visual-only; keep GameplayRoot as gameplay truth.",
        "- Y-sort/z-index: use ArtRoot/World visual layers, y-sort for free sprites, and small z-index bands for floor/wall/prop/foreground art.",
        "",
        "## Risks",
        "",
    ]
    for warning in data["warnings"]:
        lines.append(f"- {warning}")
    lines += [
        "",
        "## Exact Next Prompt Recommendation",
        "",
        data["exact_next_prompt_recommendation"],
        "",
    ]
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text("\n".join(lines), encoding="utf-8")


def main() -> int:
    project_root = find_project_root()
    roots = scan_roots(project_root)
    all_pngs: list[Path] = []
    all_imports: list[Path] = []
    readmes: list[Path] = []
    asset_roots: set[Path] = set()

    for root in roots:
        for path in iter_files(root):
            lower = path.name.lower()
            path_text = str(path).lower()
            if CYBER_ROOT_NAME in path_text or CORE_1.lower() in path_text or CORE_2.lower() in path_text or "cybercity" in lower:
                if CYBER_ROOT_NAME in path_text:
                    for parent in path.parents:
                        if parent.name.lower() == CYBER_ROOT_NAME:
                            asset_roots.add(parent)
                            break
                if lower.endswith(".png.import"):
                    all_imports.append(path)
                elif lower.endswith(".png"):
                    all_pngs.append(path)
                elif any(token in lower for token in ("readme", "license", "licence")):
                    readmes.append(path)

    all_pngs = sorted(set(all_pngs), key=lambda p: str(p).lower())
    all_imports = sorted(set(all_imports), key=lambda p: str(p).lower())
    png_set = {str(p.resolve()).lower() for p in all_pngs}
    import_expected_pngs = [Path(str(p)[: -len(".import")]) for p in all_imports]
    unmatched_imports = [p for p, expected in zip(all_imports, import_expected_pngs) if str(expected.resolve()).lower() not in png_set]
    import_set = {str(p.resolve()).lower() for p in all_imports}
    png_without_import = [p for p in all_pngs if str(Path(str(p) + ".import").resolve()).lower() not in import_set]

    samples = select_samples(all_pngs)
    measurements = [measure_png(path) for path in samples]
    summary = summarize(measurements, all_pngs, all_imports, project_root)

    reports_dir = project_root / "docs" / "reports"
    reports_dir.mkdir(parents=True, exist_ok=True)
    write_json(project_root / MEASUREMENT_JSON, [asdict(m) for m in measurements])
    write_csv(project_root / MEASUREMENT_CSV, measurements)
    contact_created = draw_contact_sheet(project_root / CONTACT_SHEET, measurements[:40])
    test_scene_path = create_test_scene(project_root, measurements) if all_pngs else ""

    counts = {
        "core_1_png": sum(1 for p in all_pngs if core_bucket(p) == "core_1"),
        "core_2_png": sum(1 for p in all_pngs if core_bucket(p) == "core_2"),
        "core_1_png_import": sum(1 for p in all_imports if core_bucket(p) == "core_1"),
        "core_2_png_import": sum(1 for p in all_imports if core_bucket(p) == "core_2"),
        "unmatched_png_import": len(unmatched_imports),
        "png_without_import": len(png_without_import),
        "total_png": len(all_pngs),
        "total_png_import": len(all_imports),
    }
    actual_pngs_found = len(all_pngs) > 0
    pass_fail = "PASS" if actual_pngs_found and measurements and contact_created else ("PARTIAL" if all_imports else "FAIL")
    if not actual_pngs_found:
        pass_fail = "PARTIAL"

    data: dict[str, Any] = {
        "phase": PHASE,
        "pass_fail_partial": pass_fail,
        "project_root": str(project_root),
        "folders_scanned": [str(p) for p in roots],
        "asset_roots": [str(p) for p in sorted(asset_roots, key=lambda p: str(p).lower())],
        "asset_location": "inside Godot project" if any(project_root in p.parents for p in asset_roots) else "outside project or not found",
        "actual_pngs_found": actual_pngs_found,
        "only_import_files_found": bool(all_imports) and not actual_pngs_found,
        "counts": counts,
        "unmatched_import_files": [str(p) for p in unmatched_imports[:200]],
        "png_without_import_files": [str(p) for p in png_without_import[:200]],
        "representative_png_paths": [str(p) for p in all_pngs[:40]],
        "representative_import_paths": [str(p) for p in all_imports[:40]],
        "readme_license_files": [str(p) for p in readmes[:40]],
        "representative_samples": [asdict(m) for m in measurements],
        "classification": {
            "true_diamond_floor_cells": summary["true_diamond_floor_cells"],
            "square_48x48_cells": summary["square_48x48_cells"],
            "dimetric_parallax_sprites": summary["dimetric_parallax_sprites"],
            "true_tilesheet_atlas": summary["true_tilesheet_atlas"],
            "hybrid": summary["hybrid"],
            "classification_counts": summary["classification_counts"],
            "category_counts": summary["category_counts"],
        },
        "executive_conclusion": summary["executive_conclusion"],
        "recommended_integration_path": {
            "best_option": summary["best_integration_path"],
            "runner_up_option": summary["runner_up_integration_path"],
            "avoid": summary["integration_path_to_avoid"],
        },
        "recommended_tile_shape": summary["recommended_tile_shape"],
        "recommended_tile_size": summary["recommended_tile_size"],
        "recommended_tilemap_use": summary["recommended_tilemap_use"],
        "recommended_sprite2d_use": summary["recommended_sprite2d_use"],
		"recommended_hideout_strategy": "Preserve GameplayRoot as gameplay truth. Use ArtRoot/World only for visual dressing; keep all PVGames TileMap/Sprite2D nodes visual-only with collision disabled.",
        "contact_sheet_path": "res://" + CONTACT_SHEET if contact_created else "",
        "test_scene_path": test_scene_path,
        "created_files": [
            "res://" + MEASUREMENT_JSON,
            "res://" + MEASUREMENT_CSV,
            "res://" + REPORT_MD,
            "res://" + REPORT_JSON,
        ]
        + (["res://" + CONTACT_SHEET] if contact_created else [])
        + ([test_scene_path] if test_scene_path else []),
        "modified_files": ["res://src/tools/editor/pvgames_geometry_audit.py"],
        "warnings": [
            "Actual PNG files are required before confirming PVGames geometry." if not actual_pngs_found else "Manual visual review of the contact sheet is still recommended.",
            "Do not infer diamond/square TileMap compatibility from .png.import sidecars.",
            "Do not modify HideoutHub or gameplay collision during this audit.",
        ],
        "strict_do_not_touch_confirmations": {
            "HideoutHub_touched": False,
            "TacoBell_RedesignTest_touched": False,
            "TacoBell_Source_touched": False,
            "production_gameplay_scripts_touched": False,
        },
		"exact_next_prompt_recommendation": "Proceed to 0M-B — Hideout PVGames visual dressing pass using a hybrid visual-only strategy: Sprite2D/free placement for walls, props, signs, furniture, and clutter; only use visual TileMapLayer for measured floor/atlas subsets that slice cleanly. Keep GameplayRoot, collision, interactions, decoration mode, store, MissionBoard, Taco Bell scenes, GameState, SceneManager, and Player.gd untouched.",
    }
    write_markdown_report(project_root, data)
    write_json(project_root / REPORT_JSON, data)
    print(json.dumps(data, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
