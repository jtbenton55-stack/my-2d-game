#!/usr/bin/env python3
"""Generate five PVGames character composite sheets for manual mapper review.

This script reads repo-local PVGames Character Creator Kit spritesheets and writes
generated composite sheets only under assets/characters/generated_player_visuals.
Raw kit files are never modified.
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from PIL import Image, ImageDraw, ImageFont

Image.MAX_IMAGE_PIXELS = 600_000_000

ROOT = Path(__file__).resolve().parents[3]
KIT = ROOT / "assets/characters/pvgames_cyber_city_character_creator_kit"
OUTPUT_DIR = ROOT / "assets/characters/generated_player_visuals/manual_5pack_20260521"
REPORTS_DIR = ROOT / "reports/ai"

FRAME_WIDTH = 200
FRAME_HEIGHT = 200
SHEET_COLUMNS = 50
SHEET_ROWS = 50
EXPECTED_SIZE = (FRAME_WIDTH * SHEET_COLUMNS, FRAME_HEIGHT * SHEET_ROWS)


def _sheet(rel: str) -> str:
    return rel.replace("\\", "/") + "/Spritesheet.png"


CHARACTERS: list[dict[str, Any]] = [
    {
        "id": "character_01_parmida_reference_variant",
        "display_name": "Parmida reference variant",
        "gender": "Female",
        "description": "Close to the existing Parmida diagnostic stack, kept as a continuity/reference character.",
        "layers": [
            ("base", _sheet("CyberCity_CharacterCreatorKit_1/CyberCity Character Creator Kit/Female/Base/CyberCity_3")),
            ("bottoms", _sheet("CyberCity_CharacterCreatorKit_1/CyberCity Character Creator Kit/Female/Bottoms/CyberCity_13")),
            ("tops", _sheet("CyberCity_CharacterCreatorKit_2/CyberCity Character Creator Kit/Female/Tops/CyberCity_24")),
            ("head", _sheet("CyberCity_CharacterCreatorKit_2/CyberCity Character Creator Kit/Female/Head/CyberCity_4")),
            ("hair", _sheet("CyberCity_CharacterCreatorKit_1/CyberCity Character Creator Kit/Female/Hair/CyberCity_7")),
            ("accessories", _sheet("CyberCity_CharacterCreatorKit_1/CyberCity Character Creator Kit/Female/Accessories/CyberCity_2")),
        ],
    },
    {
        "id": "character_02_neon_runner",
        "display_name": "Neon runner",
        "gender": "Female",
        "description": "High-contrast runner look with different base, outfit, hair, and accessory layers.",
        "layers": [
            ("base", _sheet("CyberCity_CharacterCreatorKit_1/CyberCity Character Creator Kit/Female/Base/CyberCity_1")),
            ("bottoms", _sheet("CyberCity_CharacterCreatorKit_1/CyberCity Character Creator Kit/Female/Bottoms/CyberCity_5")),
            ("tops", _sheet("CyberCity_CharacterCreatorKit_2/CyberCity Character Creator Kit/Female/Tops/CyberCity_9")),
            ("head", _sheet("CyberCity_CharacterCreatorKit_2/CyberCity Character Creator Kit/Female/Head/CyberCity_8")),
            ("hair", _sheet("CyberCity_CharacterCreatorKit_1/CyberCity Character Creator Kit/Female/Hair/CyberCity_14")),
            ("accessories", _sheet("CyberCity_CharacterCreatorKit_1/CyberCity Character Creator Kit/Female/Accessories/CyberCity_9")),
        ],
    },
    {
        "id": "character_03_cyber_tech",
        "display_name": "Cyber tech",
        "gender": "Female",
        "description": "Tech-oriented female variant with weapon layer for silhouette/accessory review.",
        "layers": [
            ("base", _sheet("CyberCity_CharacterCreatorKit_1/CyberCity Character Creator Kit/Female/Base/CyberCity_5")),
            ("bottoms", _sheet("CyberCity_CharacterCreatorKit_1/CyberCity Character Creator Kit/Female/Bottoms/CyberCity_18")),
            ("tops", _sheet("CyberCity_CharacterCreatorKit_2/CyberCity Character Creator Kit/Female/Tops/CyberCity_17")),
            ("head", _sheet("CyberCity_CharacterCreatorKit_2/CyberCity Character Creator Kit/Female/Head/CyberCity_12")),
            ("hair", _sheet("CyberCity_CharacterCreatorKit_1/CyberCity Character Creator Kit/Female/Hair/CyberCity_3")),
            ("accessories", _sheet("CyberCity_CharacterCreatorKit_1/CyberCity Character Creator Kit/Female/Accessories/CyberCity_13")),
            ("weapon", _sheet("CyberCity_CharacterCreatorKit_2/CyberCity Character Creator Kit/Female/Weapons/CyberCity_2")),
        ],
    },
    {
        "id": "character_04_street_bruiser",
        "display_name": "Street bruiser",
        "gender": "Male",
        "description": "Male variant with facial hair, accessory, and weapon layers for a heavier street silhouette.",
        "layers": [
            ("base", _sheet("CyberCity_CharacterCreatorKit_3/CyberCity Character Creator Kit/Male/Base/CyberCity_4")),
            ("bottoms", _sheet("CyberCity_CharacterCreatorKit_3/CyberCity Character Creator Kit/Male/Bottoms/CyberCity_16")),
            ("tops", _sheet("CyberCity_CharacterCreatorKit_4/CyberCity Character Creator Kit/Male/Tops/CyberCity_19")),
            ("head", _sheet("CyberCity_CharacterCreatorKit_4/CyberCity Character Creator Kit/Male/Head/CyberCity_6")),
            ("hair", _sheet("CyberCity_CharacterCreatorKit_3/CyberCity Character Creator Kit/Male/Hair/CyberCity_5")),
            ("facial_hair", _sheet("CyberCity_CharacterCreatorKit_3/CyberCity Character Creator Kit/Male/FacialHair/CyberCity_2")),
            ("accessories", _sheet("CyberCity_CharacterCreatorKit_3/CyberCity Character Creator Kit/Male/Accessories/CyberCity_11")),
            ("weapon", _sheet("CyberCity_CharacterCreatorKit_4/CyberCity Character Creator Kit/Male/Weapons/CyberCity_3")),
        ],
    },
    {
        "id": "character_05_nocturne_guard",
        "display_name": "Nocturne guard",
        "gender": "Male",
        "description": "Male guard/security-style variant with a different base, clothing set, hair, accessory, and weapon.",
        "layers": [
            ("base", _sheet("CyberCity_CharacterCreatorKit_3/CyberCity Character Creator Kit/Male/Base/CyberCity_2")),
            ("bottoms", _sheet("CyberCity_CharacterCreatorKit_3/CyberCity Character Creator Kit/Male/Bottoms/CyberCity_8")),
            ("tops", _sheet("CyberCity_CharacterCreatorKit_4/CyberCity Character Creator Kit/Male/Tops/CyberCity_7")),
            ("head", _sheet("CyberCity_CharacterCreatorKit_4/CyberCity Character Creator Kit/Male/Head/CyberCity_10")),
            ("hair", _sheet("CyberCity_CharacterCreatorKit_3/CyberCity Character Creator Kit/Male/Hair/CyberCity_9")),
            ("facial_hair", _sheet("CyberCity_CharacterCreatorKit_3/CyberCity Character Creator Kit/Male/FacialHair/CyberCity_1")),
            ("accessories", _sheet("CyberCity_CharacterCreatorKit_3/CyberCity Character Creator Kit/Male/Accessories/CyberCity_4")),
            ("weapon", _sheet("CyberCity_CharacterCreatorKit_4/CyberCity Character Creator Kit/Male/Weapons/CyberCity_6")),
        ],
    },
]


def _repo_path(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def _load_layer(path: Path) -> Image.Image:
    with Image.open(path) as image:
        rgba = image.convert("RGBA")
    if rgba.size != EXPECTED_SIZE:
        raise ValueError(f"Unexpected sheet size for {path}: {rgba.size}; expected {EXPECTED_SIZE}")
    return rgba


def _alpha_bbox(image: Image.Image) -> list[int] | None:
    bbox = image.getchannel("A").getbbox()
    if bbox is None:
        return None
    return [int(v) for v in bbox]


def _coverage(image: Image.Image) -> float:
    alpha = image.getchannel("A")
    hist = alpha.histogram()
    return sum(value * hist[value] for value in range(1, 256)) / float(image.size[0] * image.size[1] * 255)


def compose_character(character: dict[str, Any]) -> dict[str, Any]:
    print(f"Compositing {character['id']}...")
    composite = Image.new("RGBA", EXPECTED_SIZE, (0, 0, 0, 0))
    layer_metadata: list[dict[str, str]] = []

    for layer_name, rel_sheet in character["layers"]:
        sheet_path = KIT / rel_sheet
        if not sheet_path.exists():
            raise FileNotFoundError(sheet_path)
        layer = _load_layer(sheet_path)
        composite.alpha_composite(layer)
        layer.close()
        layer_metadata.append({
            "role": layer_name,
            "source_sheet": _repo_path(sheet_path),
        })

    output_path = OUTPUT_DIR / f"{character['id']}_sheet.png"
    composite.save(output_path)

    preview_frame = composite.crop((0, 0, FRAME_WIDTH, FRAME_HEIGHT))
    metrics = {
        "alpha_bbox_full_sheet": _alpha_bbox(composite),
        "alpha_coverage_full_sheet": round(_coverage(composite), 6),
        "first_frame_alpha_bbox": _alpha_bbox(preview_frame),
        "first_frame_alpha_coverage": round(_coverage(preview_frame), 6),
    }
    preview_frame.close()
    composite.close()

    return {
        "id": character["id"],
        "display_name": character["display_name"],
        "gender": character["gender"],
        "description": character["description"],
        "sheet_path": _repo_path(output_path),
        "frame_width": FRAME_WIDTH,
        "frame_height": FRAME_HEIGHT,
        "columns": SHEET_COLUMNS,
        "rows": SHEET_ROWS,
        "total_frames": SHEET_COLUMNS * SHEET_ROWS,
        "layers": layer_metadata,
        "metrics": metrics,
    }


def create_contact_sheet(character_metadata: list[dict[str, Any]]) -> str:
    thumb_w = 32
    thumb_h = 32
    label_h = 28
    margin = 16
    block_w = SHEET_COLUMNS * thumb_w
    block_h = label_h + SHEET_ROWS * thumb_h
    contact_w = block_w + margin * 2
    contact_h = margin + len(character_metadata) * (block_h + margin)
    contact = Image.new("RGBA", (contact_w, contact_h), (24, 26, 30, 255))
    draw = ImageDraw.Draw(contact)
    try:
        font = ImageFont.load_default()
    except Exception:
        font = None

    y = margin
    for meta in character_metadata:
        sheet_path = ROOT / meta["sheet_path"]
        with Image.open(sheet_path) as sheet:
            scaled = sheet.convert("RGBA").resize((block_w, SHEET_ROWS * thumb_h), Image.Resampling.NEAREST)
        title = f"{meta['id']} - {meta['display_name']} ({meta['gender']})"
        draw.text((margin, y), title, fill=(235, 238, 245, 255), font=font)
        contact.alpha_composite(scaled, (margin, y + label_h))
        # Draw light grid markers every 10 rows/columns for mapper orientation.
        x0 = margin
        y0 = y + label_h
        for col in range(0, SHEET_COLUMNS + 1, 10):
            x = x0 + col * thumb_w
            draw.line((x, y0, x, y0 + SHEET_ROWS * thumb_h), fill=(90, 100, 120, 180))
        for row in range(0, SHEET_ROWS + 1, 10):
            yy = y0 + row * thumb_h
            draw.line((x0, yy, x0 + block_w, yy), fill=(90, 100, 120, 180))
        scaled.close()
        y += block_h + margin

    output_path = OUTPUT_DIR / "manual_5pack_contact_sheet_preview.png"
    contact.save(output_path)
    contact.close()
    return _repo_path(output_path)


def write_report(metadata: dict[str, Any]) -> None:
    report_path = REPORTS_DIR / "2026-05-21_manual_5_character_composite_sheets_report.md"
    rows = "\n".join(
        f"| {char['id']} | {char['gender']} | `{char['sheet_path']}` | {len(char['layers'])} |"
        for char in metadata["characters"]
    )
    report = f"""# Manual 5 Character Composite Sheets Report

**Date:** 2026-05-21
**Scope:** Generated five PVGames composite character sheets plus contact-sheet preview for Character Animation Mapper review

## Goal

Create five varied character composite sheets from repo-local PVGames Character Creator Kit layers. Each output sheet uses the 200x200, 50-column, 50-row grid expected by the Character Animation Mapper for full-kit sheets.

## Files generated

| Character | Gender | Sheet | Layer count |
|---|---|---|---:|
{rows}

Additional outputs:

- Metadata: `{metadata['metadata_path']}`
- Contact sheet preview: `{metadata['contact_sheet_path']}`

## Safety

- Raw PVGames kit spritesheets were read only.
- No production player, Taco scene, autoload, mission logic, or project settings were modified.
- Outputs are isolated under `assets/characters/generated_player_visuals/manual_5pack_20260521/`.

## Mapper usage

Load any generated `*_sheet.png` into Character Animation Mapper with:

- Frame width: `200`
- Frame height: `200`
- Columns: `50`
- Rows: `50`

Use the contact sheet preview for quick visual comparison before detailed row/range review.

## Validation

- Source sheets were required to exist and match 10000x10000 pixels.
- Each generated character sheet is 10000x10000 pixels.
- Each generated character sheet has 2500 frames at 200x200.
"""
    report_path.write_text(report, encoding="utf-8")


def main() -> int:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    REPORTS_DIR.mkdir(parents=True, exist_ok=True)
    characters = [compose_character(character) for character in CHARACTERS]
    contact_sheet = create_contact_sheet(characters)
    metadata = {
        "schema_version": 1,
        "tool": "character_animation_generate_manual_5pack.py",
        "frame_width": FRAME_WIDTH,
        "frame_height": FRAME_HEIGHT,
        "columns": SHEET_COLUMNS,
        "rows": SHEET_ROWS,
        "total_frames_per_character": SHEET_COLUMNS * SHEET_ROWS,
        "output_dir": _repo_path(OUTPUT_DIR),
        "contact_sheet_path": contact_sheet,
        "characters": characters,
    }
    metadata_path = OUTPUT_DIR / "manual_5pack_metadata.json"
    metadata["metadata_path"] = _repo_path(metadata_path)
    metadata_path.write_text(json.dumps(metadata, indent=2), encoding="utf-8")
    write_report(metadata)
    print(json.dumps({
        "ok": True,
        "output_dir": metadata["output_dir"],
        "metadata": metadata["metadata_path"],
        "contact_sheet": contact_sheet,
        "characters": [c["sheet_path"] for c in characters],
    }, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
