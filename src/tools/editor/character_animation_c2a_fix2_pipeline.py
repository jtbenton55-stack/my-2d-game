#!/usr/bin/env python3
"""
0M-C2A-FIX2 — Rebuild Parmida animation frames on a fixed canvas (sandbox-only assets).

- Re-verifies 100x200 grid from PVGames kit sheets (read-only).
- Scans candidate strips (horizontal: fixed row, cols 0..9) vs (vertical: fixed col, rows 0..9).
- Picks stable idle + optional walk using heuristics (feet stability + motion consistency).
- Writes fix2_rebuilt outputs + contact sheets + JSON reports.
"""

from __future__ import annotations

import json
import math
import statistics
from dataclasses import dataclass, asdict
from pathlib import Path
from typing import Any

from PIL import Image, ImageDraw, ImageChops, ImageFont

Image.MAX_IMAGE_PIXELS = 200_000_000

ROOT = Path(__file__).resolve().parents[3]
KIT = ROOT / "assets/characters/pvgames_cyber_city_character_creator_kit"
C2A = ROOT / "assets/characters/generated_player_visuals/c2a_animation"
FIX2 = C2A / "fix2_rebuilt"
REPORTS = ROOT / "docs/reports/character_animation_c2a"

LAYERS: list[tuple[str, str]] = [
    ("base", "CyberCity_CharacterCreatorKit_1/CyberCity Character Creator Kit/Female/Base/CyberCity_3"),
    ("bottoms", "CyberCity_CharacterCreatorKit_1/CyberCity Character Creator Kit/Female/Bottoms/CyberCity_13"),
    ("tops", "CyberCity_CharacterCreatorKit_2/CyberCity Character Creator Kit/Female/Tops/CyberCity_24"),
    ("head", "CyberCity_CharacterCreatorKit_2/CyberCity Character Creator Kit/Female/Head/CyberCity_4"),
    ("hair", "CyberCity_CharacterCreatorKit_1/CyberCity Character Creator Kit/Female/Hair/CyberCity_7"),
]

FW, FH = 100, 200
N = 10


@dataclass
class StripMetrics:
    orientation: str  # "horizontal" | "vertical"
    index: int  # row if horizontal, col if vertical
    coverage_mean: float
    foot_bottom_std: float
    mse_seq_mean: float
    score: float
    rejected: str


def _alpha_bbox(im: Image.Image) -> tuple[int, int, int, int] | None:
    if im.mode != "RGBA":
        im = im.convert("RGBA")
    a = im.split()[3]
    return a.getbbox()


def _coverage(im: Image.Image) -> float:
    if im.mode != "RGBA":
        im = im.convert("RGBA")
    a = im.split()[3]
    hist = a.histogram()
    nz = sum(hist[1:])
    return nz / float(FW * FH)


def _mse(a: Image.Image, b: Image.Image) -> float:
    d = ImageChops.difference(a.convert("RGBA"), b.convert("RGBA"))
    h = d.histogram()
    # mean abs diff across RGBA channels
    total = sum(i * h[i] for i in range(256))
    return total / float(FW * FH * 4)


class LayerSheets:
    def __init__(self) -> None:
        self.images: dict[str, Image.Image] = {}
        for name, rel in LAYERS:
            p = KIT / rel / "Spritesheet.png"
            if not p.exists():
                raise FileNotFoundError(p)
            im = Image.open(p).convert("RGBA")
            if im.size != (10000, 10000):
                raise ValueError(f"Unexpected sheet size for {name}: {im.size}")
            self.images[name] = im

    def crop_cell(self, name: str, row: int, col: int) -> Image.Image:
        im = self.images[name]
        x0 = col * FW
        y0 = row * FH
        return im.crop((x0, y0, x0 + FW, y0 + FH)).copy()

    def composite(self, row: int, col: int) -> Image.Image:
        out = Image.new("RGBA", (FW, FH), (0, 0, 0, 0))
        for name, _rel in LAYERS:
            layer = self.crop_cell(name, row, col)
            out = Image.alpha_composite(out, layer)
        return out


def _foot_bottom(im: Image.Image) -> float | None:
    bb = _alpha_bbox(im)
    if not bb:
        return None
    return float(bb[3])


def _strip_horizontal(sheets: LayerSheets, row: int) -> tuple[list[Image.Image], StripMetrics]:
    frames = [sheets.composite(row, c) for c in range(N)]
    cov = sum(_coverage(f) for f in frames) / N
    feet = [_foot_bottom(f) for f in frames]
    if any(v is None for v in feet) or cov < 0.012:
        return frames, StripMetrics("horizontal", row, cov, 9999.0, 9999.0, 1e9, "low_coverage_or_empty")
    foot_std = float(statistics.pstdev([v for v in feet if v is not None]))
    mses = [_mse(frames[i], frames[i + 1]) for i in range(N - 1)]
    mse_m = float(sum(mses) / len(mses))
    score = foot_std * 12.0 + mse_m * 0.0007
    return frames, StripMetrics("horizontal", row, cov, foot_std, mse_m, score, "")


def _strip_vertical(sheets: LayerSheets, col: int) -> tuple[list[Image.Image], StripMetrics]:
    frames = [sheets.composite(r, col) for r in range(N)]
    cov = sum(_coverage(f) for f in frames) / N
    feet = [_foot_bottom(f) for f in frames]
    if any(v is None for v in feet) or cov < 0.012:
        return frames, StripMetrics("vertical", col, cov, 9999.0, 9999.0, 1e9, "low_coverage_or_empty")
    foot_std = float(statistics.pstdev([v for v in feet if v is not None]))
    mses = [_mse(frames[i], frames[i + 1]) for i in range(N - 1)]
    mse_m = float(sum(mses) / len(mses))
    score = foot_std * 12.0 + mse_m * 0.0007
    return frames, StripMetrics("vertical", col, cov, foot_std, mse_m, score, "")


def _pick_best_idle(cands: list[tuple[list[Image.Image], StripMetrics]]) -> tuple[list[Image.Image], StripMetrics]:
    ok = [(f, m) for f, m in cands if m.rejected == "" and math.isfinite(m.score)]
    ok.sort(key=lambda x: x[1].score)
    return ok[0]


def _pick_walk(
    sheets: LayerSheets,
    orient: str,
    idle: StripMetrics,
    idle_frames: list[Image.Image],
) -> tuple[list[Image.Image] | None, dict[str, Any]]:
    idle_mse = idle.mse_seq_mean
    idle_std = idle.foot_bottom_std
    best: tuple[float, list[Image.Image], StripMetrics] | None = None
    notes: list[str] = []

    if orient == "horizontal":
        for row in range(50):
            if row == idle.index:
                continue
            frames, m = _strip_horizontal(sheets, row)
            if m.rejected:
                continue
            if m.mse_seq_mean < idle_mse * 1.08:
                continue
            if m.foot_bottom_std > min(3.0, max(2.0, idle_std * 5.0)):
                continue
            if m.coverage_mean < idle.coverage_mean * 0.55:
                continue
            # prefer moderate motion, not insane
            motion = abs(m.mse_seq_mean - idle_mse * 1.35)
            jitter_penalty = max(0.0, m.foot_bottom_std - idle_std) * 5.0
            score = motion + jitter_penalty
            if best is None or score < best[0]:
                best = (score, frames, m)
    else:
        for col in range(100):
            if col == idle.index:
                continue
            frames, m = _strip_vertical(sheets, col)
            if m.rejected:
                continue
            if m.mse_seq_mean < idle_mse * 1.08:
                continue
            if m.foot_bottom_std > min(3.0, max(2.0, idle_std * 5.0)):
                continue
            if m.coverage_mean < idle.coverage_mean * 0.55:
                continue
            motion = abs(m.mse_seq_mean - idle_mse * 1.35)
            jitter_penalty = max(0.0, m.foot_bottom_std - idle_std) * 5.0
            score = motion + jitter_penalty
            if best is None or score < best[0]:
                best = (score, frames, m)

    if best is None:
        notes.append("No walk strip passed heuristics; exporting idle-only.")
        return None, {"kept_walk": False, "notes": notes}

    _, frames, m = best
    notes.append(
        f"Walk chosen: {m.orientation} index={m.index} mse={m.mse_seq_mean:.3f} foot_std={m.foot_bottom_std:.3f} cov={m.coverage_mean:.4f}"
    )
    return frames, {"kept_walk": True, "walk_metrics": asdict(m), "notes": notes}


def _save_frames(out_dir: Path, prefix: str, frames: list[Image.Image]) -> list[str]:
    paths: list[str] = []
    for i, fr in enumerate(frames):
        p = out_dir / f"{prefix}_{i:03d}.png"
        fr.save(p)
        paths.append(str(p.relative_to(ROOT)).replace("\\", "/"))
    return paths


def _build_composite_sheet(idle: list[Image.Image], walk: list[Image.Image] | None) -> Image.Image:
    w = FW * N
    h = FH * (2 if walk else 1)
    sheet = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    for i, fr in enumerate(idle):
        sheet.paste(fr, (i * FW, 0), fr)
    if walk:
        for i, fr in enumerate(walk):
            sheet.paste(fr, (i * FW, FH), fr)
    return sheet


def _write_spriteframes_tres(sheet_rel: str, out_tres: Path, has_walk: bool) -> None:
    lines: list[str] = [
        '[gd_resource type="SpriteFrames" format=3]',
        "",
        f'[ext_resource type="Texture2D" path="{sheet_rel}" id="1_sheet"]',
        "",
    ]
    for i in range(N):
        x = i * FW
        lines += [
            f'[sub_resource type="AtlasTexture" id="idle_{i}"]',
            'atlas = ExtResource("1_sheet")',
            f"region = Rect2({x}, 0, {FW}, {FH})",
            "",
        ]
    if has_walk:
        for i in range(N):
            x = i * FW
            lines += [
                f'[sub_resource type="AtlasTexture" id="walk_{i}"]',
                'atlas = ExtResource("1_sheet")',
                f"region = Rect2({x}, {FH}, {FW}, {FH})",
                "",
            ]
    idle_frames = ", ".join([f'SubResource("idle_{i}")' for i in range(N)])
    lines += ["[resource]", "animations = [ {"]
    lines += [
        f'"frames": [ {idle_frames} ],',
        '"loop": true,',
        '"name": "idle",',
        '"speed": 5.0',
    ]
    if has_walk:
        walk_frames = ", ".join([f'SubResource("walk_{i}")' for i in range(N)])
        lines += [
            "}, {",
            f'"frames": [ {walk_frames} ],',
            '"loop": true,',
            '"name": "walk",',
            '"speed": 9.0',
            "}",
        ]
    else:
        lines += ["}"]
    lines += ["]", ""]
    out_tres.write_text("\n".join(lines), encoding="utf-8")


def _contact_sheet(
    frames_by_title: list[tuple[str, list[Image.Image]]],
    out_png: Path,
    meta_sidecar: Path,
    label_bad: bool,
) -> dict[str, Any]:
    cell_pad = 6
    label_h = 22
    cols = N
    rows = len(frames_by_title)
    cw = FW + cell_pad * 2
    ch = FH + cell_pad * 2 + label_h
    img = Image.new("RGBA", (cols * cw + 40, rows * ch + 40), (30, 30, 34, 255))
    dr = ImageDraw.Draw(img)
    try:
        font = ImageFont.load_default()
    except Exception:  # noqa: BLE001
        font = None

    meta: dict[str, Any] = {"cells": []}
    for r, (title, frames) in enumerate(frames_by_title):
        for c, fr in enumerate(frames):
            x0 = 20 + c * cw
            y0 = 20 + r * ch
            dr.rectangle([x0, y0, x0 + cw - cell_pad, y0 + ch - cell_pad], outline=(200, 200, 200, 255))
            px = x0 + cell_pad
            py = y0 + cell_pad + label_h
            img.paste(fr, (px, py), fr)
            bb = _alpha_bbox(fr)
            if bb:
                dr.rectangle([px + bb[0], py + bb[1], px + bb[2], py + bb[3]], outline=(255, 80, 80, 255), width=1)
                foot_y = py + bb[3]
                dr.line([px, foot_y, px + FW, foot_y], fill=(255, 220, 60, 255), width=1)
            tag = "UNKNOWN"
            if bb:
                h = bb[3] - bb[1]
                w = bb[2] - bb[0]
                cov = _coverage(fr)
                if cov < 0.005:
                    tag = "BLANK"
                elif h < FH * 0.32 or w < FW * 0.22:
                    tag = "PARTIAL_BODY"
                elif h < FH * 0.48:
                    tag = "HALF_BODY"
                else:
                    tag = "FULL_BODY"
            if font:
                dr.text((x0 + cell_pad, y0 + 2), f"{title} [{c}] {tag}", fill=(240, 240, 240, 255), font=font)
            meta["cells"].append({"title": title, "index": c, "tag": tag, "bbox": bb})
    img.save(out_png)
    meta_sidecar.write_text(json.dumps(meta, indent=2), encoding="utf-8")
    return meta


def _frame_quality(frames: list[Image.Image], name: str) -> dict[str, Any]:
    feet = [_foot_bottom(f) for f in frames]
    bbs = [_alpha_bbox(f) for f in frames]
    foot_std = float(statistics.pstdev([f for f in feet if f is not None])) if all(f is not None for f in feet) else None
    tags = []
    for fr in frames:
        bb = _alpha_bbox(fr)
        cov = _coverage(fr)
        if cov < 0.005:
            tags.append("BLANK")
        elif not bb:
            tags.append("BLANK")
        else:
            h = bb[3] - bb[1]
            if h < FH * 0.40:
                tags.append("PARTIAL")
            else:
                tags.append("OK")
    return {
        "name": name,
        "foot_bottom_std": foot_std,
        "per_frame_tags": tags,
        "all_ok": all(t == "OK" for t in tags),
    }


def main() -> None:
    FIX2.mkdir(parents=True, exist_ok=True)
    (FIX2 / "frames").mkdir(parents=True, exist_ok=True)
    REPORTS.mkdir(parents=True, exist_ok=True)

    sheets = LayerSheets()

    horiz: list[tuple[list[Image.Image], StripMetrics]] = []
    for row in range(50):
        horiz.append(_strip_horizontal(sheets, row))
    vert: list[tuple[list[Image.Image], StripMetrics]] = []
    for col in range(100):
        vert.append(_strip_vertical(sheets, col))

    best_h = _pick_best_idle(horiz)
    best_v = _pick_best_idle(vert)

    if best_h[1].score <= best_v[1].score:
        orient = "horizontal"
        idle_frames, idle_m = best_h
        idle_strip_desc = f"row={idle_m.index}, cols=0..{N - 1}"
    else:
        orient = "vertical"
        idle_frames, idle_m = best_v
        idle_strip_desc = f"col={idle_m.index}, rows=0..{N - 1}"

    walk_frames, walk_pick = _pick_walk(sheets, orient, idle_m, idle_frames)
    has_walk = walk_frames is not None

    # Remove stale walk frames from prior runs when exporting idle-only.
    for stale in (FIX2 / "frames").glob("walk_*.png"):
        try:
            stale.unlink()
        except OSError:
            pass

    idle_paths = _save_frames(FIX2 / "frames", "idle", idle_frames)
    walk_paths: list[str] = []
    if walk_frames:
        walk_paths = _save_frames(FIX2 / "frames", "walk", walk_frames)

    sheet = _build_composite_sheet(idle_frames, walk_frames if has_walk else None)
    sheet_path = FIX2 / "parmida_player_composite_sheet_0mc2a_fix2.png"
    sheet.save(sheet_path)

    sheet_rel = "res://assets/characters/generated_player_visuals/c2a_animation/fix2_rebuilt/parmida_player_composite_sheet_0mc2a_fix2.png"
    tres_path = FIX2 / "parmida_player_spriteframes_0mc2a_fix2.tres"
    _write_spriteframes_tres(sheet_rel, tres_path, has_walk)

    meta = {
        "frame_width": FW,
        "frame_height": FH,
        "verified_kit_sheet_size": [10000, 10000],
        "orientation_chosen": orient,
        "idle": {
            "strip": idle_strip_desc,
            "metrics": asdict(idle_m),
            "frame_files": idle_paths,
        },
        "walk": {
            "included": has_walk,
            "pick": walk_pick,
            "frame_files": walk_paths,
        },
        "layers": [{"name": n, "path": str((KIT / rel / "Spritesheet.png").relative_to(ROOT)).replace("\\", "/")} for n, rel in LAYERS],
        "rules": {
            "fixed_canvas": True,
            "no_per_frame_trim": True,
            "same_grid_all_layers": True,
        },
    }
    (FIX2 / "parmida_player_animation_metadata_0mc2a_fix2.json").write_text(json.dumps(meta, indent=2), encoding="utf-8")

    # Bad frames contact sheet from legacy composite (FIX1 sheet layout)
    legacy = Image.open(C2A / "parmida_player_composite_sheet_0mc2a.png").convert("RGBA")
    bad_idle = [legacy.crop((i * FW, 0, (i + 1) * FW, FH)).copy() for i in range(N)]
    bad_walk = [legacy.crop((i * FW, FH, (i + 1) * FW, FH * 2)).copy() for i in range(N)]
    _contact_sheet(
        [("BAD_idle_row0_cols0-9 (FIX1 layout)", bad_idle), ("BAD_walk_row10_cols0-9 (FIX1 layout)", bad_walk)],
        REPORTS / "phase0mc2a_fix2_current_bad_frames_contact_sheet.png",
        REPORTS / "phase0mc2a_fix2_current_bad_frames_contact_sheet.json",
        True,
    )

    rebuilt_sets: list[tuple[str, list[Image.Image]]] = [("REBUILT_idle", idle_frames)]
    if walk_frames:
        rebuilt_sets.append(("REBUILT_walk", walk_frames))
    _contact_sheet(
        rebuilt_sets,
        REPORTS / "phase0mc2a_fix2_rebuilt_frames_contact_sheet.png",
        REPORTS / "phase0mc2a_fix2_rebuilt_frames_contact_sheet.json",
        False,
    )

    quality = {
        "idle": _frame_quality(idle_frames, "idle"),
        "walk": _frame_quality(walk_frames, "walk") if walk_frames else {"name": "walk", "included": False},
        "walk_included": has_walk,
    }
    (REPORTS / "phase0mc2a_fix2_rebuilt_frame_quality.json").write_text(json.dumps(quality, indent=2), encoding="utf-8")

    diagnosis = {
        "primary": "G — WRONG_ROW_SELECTED + L — SOURCE_LAYOUT_MISUNDERSTOOD",
        "secondary": ["K — BAD_FIX1_SPRITEFRAMES (atlas regions matched broken composite)", "B — WRONG_ATLAS_REGION (symptom of wrong row/column semantics)"],
        "explanation": (
            "FIX1 composite used idle=kit row 0 cols 0..9 and walk=kit row 10 cols 0..9. "
            "On PVGames mega-sheets, advancing columns on arbitrary rows often traverses unrelated poses/directions, "
            "causing half-body glitches and anchor jitter. FIX2 selects a strip orientation (horizontal vs vertical) "
            "and indices with stable feet + coherent motion before rebuilding fixed-canvas frames."
        ),
        "idle_selected_metrics": asdict(idle_m),
        "orientation": orient,
    }
    (REPORTS / "phase0mc2a_fix2_glitch_diagnosis.json").write_text(json.dumps(diagnosis, indent=2), encoding="utf-8")

    print("FIX2 pipeline complete.")
    print("orientation:", orient, "idle:", idle_strip_desc, "walk:", has_walk)


if __name__ == "__main__":
    main()
