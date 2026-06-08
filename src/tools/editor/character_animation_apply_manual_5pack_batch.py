#!/usr/bin/env python3
"""Clone reviewed Parmida animation map to manual 5-pack characters and emit validation SpriteFrames."""

from __future__ import annotations

import json
import re
import shutil
import sys
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
MAPS_DIR = ROOT / "resources" / "character_animation_maps"
PREVIEW_DIR = MAPS_DIR / "generated_preview"
SOURCE_MAP = MAPS_DIR / "character__working_manual_map.json"
SOURCE_TEMPLATE = "res://resources/character_animation_maps/character__working_manual_map.json"
APPLIED_FROM = "character_01_parmida_reference_variant"

TARGETS = [
    {
        "character_id": "character_02_neon_runner",
        "sheet": "res://assets/characters/generated_player_visuals/manual_5pack_20260521/character_02_neon_runner_sheet.png",
        "map": MAPS_DIR / "character_02_neon_runner_manual_animation_map.json",
        "spriteframes": PREVIEW_DIR / "character_02_neon_runner_preview_spriteframes.tres",
    },
    {
        "character_id": "character_03_cyber_tech",
        "sheet": "res://assets/characters/generated_player_visuals/manual_5pack_20260521/character_03_cyber_tech_sheet.png",
        "map": MAPS_DIR / "character_03_cyber_tech_manual_animation_map.json",
        "spriteframes": PREVIEW_DIR / "character_03_cyber_tech_preview_spriteframes.tres",
    },
    {
        "character_id": "character_04_street_bruiser",
        "sheet": "res://assets/characters/generated_player_visuals/manual_5pack_20260521/character_04_street_bruiser_sheet.png",
        "map": MAPS_DIR / "character_04_street_bruiser_manual_animation_map.json",
        "spriteframes": PREVIEW_DIR / "character_04_street_bruiser_preview_spriteframes.tres",
    },
    {
        "character_id": "character_05_nocturne_guard",
        "sheet": "res://assets/characters/generated_player_visuals/manual_5pack_20260521/character_05_nocturne_guard_sheet.png",
        "map": MAPS_DIR / "character_05_nocturne_guard_manual_animation_map.json",
        "spriteframes": PREVIEW_DIR / "character_05_nocturne_guard_preview_spriteframes.tres",
    },
]

REPRESENTATIVE = [
    "idle_toward_01",
    "walk_toward_01",
    "run_toward_01",
    "jump_toward_01",
    "fall_toward_01",
    "land_toward_01",
    "death_toward_01",
    "dodge_toward_01",
    "punch_toward_01",
    "stab_toward_01",
]


def backup_if_exists(path: Path, tag: str) -> Path | None:
    if not path.exists():
        return None
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup = path.with_name(f"{path.stem}_before_{tag}_{ts}{path.suffix}")
    shutil.copy2(path, backup)
    return backup


def validate_source(data: dict) -> list[str]:
    failures: list[str] = []
    anims = data.get("animations", [])
    if len(anims) != 591:
        failures.append(f"expected 591 animations, got {len(anims)}")
    names = [a.get("animation_name") for a in anims]
    if any(n.startswith("spear_stab_") for n in names if isinstance(n, str)):
        failures.append("spear_stab_* entries remain in source map")
    if any(a.get("review_status") != "reviewed" for a in anims):
        failures.append("source map has non-reviewed entries")
    for key, expected in [
        ("frame_width", 200),
        ("frame_height", 200),
        ("columns", 50),
        ("rows", 50),
    ]:
        if int(data.get(key, 0)) != expected:
            failures.append(f"source {key} expected {expected}, got {data.get(key)}")
    if len(set(names)) != len(names):
        failures.append("duplicate animation names in source map")
    return failures


def clone_map(source: dict, target_sheet: str, character_id: str) -> dict:
    cloned = json.loads(json.dumps(source))
    cloned["source_sheet"] = target_sheet
    cloned["source_map_template"] = SOURCE_TEMPLATE
    cloned["applied_from_character"] = APPLIED_FROM
    cloned["requires_visual_sandbox_validation"] = True
    return cloned


def atlas_region(global_index: int, columns: int, fw: int, fh: int) -> tuple[int, int, int, int]:
    row = global_index // columns
    col = global_index % columns
    return col * fw, row * fh, fw, fh


def frames_from_entry(entry: dict) -> list[int]:
    raw = entry.get("frames", [])
    if raw:
        return [int(v) for v in raw]
    start_f = int(entry.get("start_frame", 0))
    end_f = int(entry.get("end_frame", start_f))
    return list(range(start_f, end_f + 1))


def write_spriteframes_tres(map_data: dict, out_path: Path) -> int:
    sheet_path = str(map_data["source_sheet"])
    columns = int(map_data["columns"])
    fw = int(map_data["frame_width"])
    fh = int(map_data["frame_height"])
    max_frame = columns * int(map_data["rows"]) - 1

    atlas_ids: list[str] = []
    atlas_lines: list[str] = []
    animation_blocks: list[str] = []
    added = 0

    for entry in map_data.get("animations", []):
        if entry.get("review_status") != "reviewed":
            continue
        anim_name = str(entry.get("animation_name", ""))
        if not anim_name:
            continue
        frames = frames_from_entry(entry)
        if not frames:
            continue
        for g in frames:
            if g < 0 or g > max_frame:
                raise ValueError(f"frame {g} out of range for {anim_name}")
        frame_refs: list[str] = []
        for g in frames:
            atlas_id = f"AtlasTexture_{added}_{g}"
            atlas_ids.append(atlas_id)
            x, y, w, h = atlas_region(g, columns, fw, fh)
            atlas_lines.append(
                f'\n[sub_resource type="AtlasTexture" id="{atlas_id}"]\n'
                f'atlas = ExtResource("1_sheet")\n'
                f'region = Rect2({x}, {y}, {w}, {h})\n'
            )
            frame_refs.append(
                '{\n"duration": 1.0,\n"texture": SubResource("' + atlas_id + '")\n}'
            )
        loop = "true" if bool(entry.get("loop", True)) else "false"
        fps = float(entry.get("fps", 10.0))
        animation_blocks.append(
            "{\n"
            f'"frames": [{", ".join(frame_refs)}],\n'
            f'"loop": {loop},\n'
            f'"name": &"{anim_name}",\n'
            f'"speed": {fps}\n'
            "}"
        )
        added += 1

    load_steps = 2 + len(atlas_ids)
    header = (
        f'[gd_resource type="SpriteFrames" load_steps={load_steps} format=3]\n\n'
        f'[ext_resource type="Texture2D" path="{sheet_path}" id="1_sheet"]\n'
    )
    body = header + "".join(atlas_lines)
    body += "\n[resource]\n"
    body += "animations = [" + ", ".join(animation_blocks) + "]\n"
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(body, encoding="utf-8")
    return added


def validate_target_map(source: dict, target: dict, expected_sheet: str) -> list[str]:
    failures: list[str] = []
    src_anims = source.get("animations", [])
    tgt_anims = target.get("animations", [])
    if len(tgt_anims) != len(src_anims):
        failures.append("animation count mismatch")
    if target.get("source_sheet") != expected_sheet:
        failures.append("source_sheet mismatch")
    if any(a.get("review_status") != "reviewed" for a in tgt_anims):
        failures.append("non-reviewed entries in target map")
    names = [a.get("animation_name") for a in tgt_anims]
    if any(str(n).startswith("spear_stab_") for n in names):
        failures.append("spear_stab reintroduced")
    if len(set(names)) != len(names):
        failures.append("duplicate animation names")
    max_frame = int(target.get("columns", 50)) * int(target.get("rows", 50)) - 1
    for entry in tgt_anims:
        for g in frames_from_entry(entry):
            if g < 0 or g > max_frame:
                failures.append(f"frame {g} out of range in {entry.get('animation_name')}")
                break
    for key in ["schema_version", "frame_width", "frame_height", "columns", "rows", "tool"]:
        if target.get(key) != source.get(key):
            failures.append(f"top-level {key} changed")
    return failures


def validate_spriteframes_file(path: Path, map_data: dict) -> list[str]:
    failures: list[str] = []
    if not path.exists():
        failures.append("spriteframes missing")
        return failures
    text = path.read_text(encoding="utf-8", errors="replace")
    if '[gd_resource type="SpriteFrames"' not in text:
        failures.append("not a SpriteFrames resource")
    sheet = str(map_data.get("source_sheet", ""))
    if sheet and sheet not in text:
        failures.append("sheet ext_resource missing from spriteframes")
    reviewed = [a for a in map_data.get("animations", []) if a.get("review_status") == "reviewed"]
    for rep in REPRESENTATIVE:
        present = any(a.get("animation_name") == rep for a in reviewed)
        if present and f'&"{rep}"' not in text and f'"{rep}"' not in text:
            failures.append(f"representative animation missing from spriteframes: {rep}")
    anim_names = [str(a.get("animation_name", "")) for a in reviewed if a.get("animation_name")]
    found_count = sum(1 for n in anim_names if f'&"{n}"' in text or f'name": "{n}"' in text)
    if found_count != len(anim_names):
        failures.append(f"spriteframes animation count mismatch ({found_count} vs {len(anim_names)})")
    return failures


def generate_parmida_small_preview(source: dict) -> dict:
    out_path = PREVIEW_DIR / "character_01_parmida_reference_variant_preview_spriteframes.tres"
    backup = backup_if_exists(out_path, "parmida_small_preview")
    anim_count = write_spriteframes_tres(source, out_path)
    sf_failures = validate_spriteframes_file(out_path, source)
    return {
        "character_id": "character_01_parmida_reference_variant",
        "spriteframes_path": str(out_path),
        "spriteframes_backup": str(backup) if backup else None,
        "spriteframes_animation_count": anim_count,
        "failures": sf_failures,
    }


def main() -> int:
    source_hash_before = SOURCE_MAP.read_bytes()
    source = json.loads(SOURCE_MAP.read_text(encoding="utf-8"))
    failures = validate_source(source)
    if failures:
        print("SOURCE VALIDATION FAILED:", failures)
        return 1

    results: list[dict] = []
    results.append(generate_parmida_small_preview(source))
    for target in TARGETS:
        sheet_fs = ROOT / target["sheet"].replace("res://", "").replace("/", "\\")
        item = {"character_id": target["character_id"], "skipped": False, "failures": []}
        if not sheet_fs.exists():
            item["skipped"] = True
            item["failures"].append(f"sheet missing: {target['sheet']}")
            results.append(item)
            continue

        map_backup = backup_if_exists(target["map"], "manual_5pack_apply")
        sf_backup = backup_if_exists(target["spriteframes"], "manual_5pack_apply")
        item["map_backup"] = str(map_backup) if map_backup else None
        item["spriteframes_backup"] = str(sf_backup) if sf_backup else None

        cloned = clone_map(source, target["sheet"], target["character_id"])
        target["map"].write_text(json.dumps(cloned, indent="\t") + "\n", encoding="utf-8")
        item["map_path"] = str(target["map"])

        map_failures = validate_target_map(source, cloned, target["sheet"])
        if map_failures:
            item["failures"].extend(map_failures)
            results.append(item)
            continue

        try:
            anim_count = write_spriteframes_tres(cloned, target["spriteframes"])
            item["spriteframes_path"] = str(target["spriteframes"])
            item["spriteframes_animation_count"] = anim_count
        except Exception as exc:  # noqa: BLE001
            item["failures"].append(f"spriteframes generation failed: {exc}")
            results.append(item)
            continue

        sf_failures = validate_spriteframes_file(target["spriteframes"], cloned)
        item["failures"].extend(sf_failures)
        results.append(item)

    source_hash_after = SOURCE_MAP.read_bytes()
    if source_hash_before != source_hash_after:
        print("ERROR: source map was modified")
        return 2

    report = {
        "source_animation_count": len(source.get("animations", [])),
        "source_unchanged": True,
        "results": results,
    }
    print(json.dumps(report, indent=2))
    if any(r.get("failures") for r in results if not r.get("skipped")):
        return 3
    if all(r.get("skipped") for r in results):
        return 4
    return 0


if __name__ == "__main__":
    sys.exit(main())
