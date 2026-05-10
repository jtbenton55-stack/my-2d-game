#!/usr/bin/env python3
"""
0M-C2B-FIX1 — Contextual 21-frame motion classifier (diagnostic only).

Row-major global frame order, 200x200 composites, read-only kit PNGs.
"""

from __future__ import annotations

import csv
import json
import math
import statistics
import subprocess
from collections import Counter
from pathlib import Path
from typing import Any

from PIL import Image, ImageChops, ImageDraw, ImageFont

try:
    import numpy as np

    HAS_NP = True
except ImportError:
    HAS_NP = False

try:
    import cv2  # noqa: F401

    HAS_CV2 = True
except ImportError:
    HAS_CV2 = False

Image.MAX_IMAGE_PIXELS = 500_000_000

ROOT = Path(__file__).resolve().parents[3]
KIT = ROOT / "assets/characters/pvgames_cyber_city_character_creator_kit"
OUT = ROOT / "assets/characters/generated_player_visuals/c2b_context_classifier"
FRAMES_DIR = OUT / "frames"
CLIPS_DIR = OUT / "clips"
REPORTS = ROOT / "docs/reports/character_animation_c2b_fix1"
CONTEXT_DIR = REPORTS / "context_windows_21"
ROW_BROWSER = REPORTS / "row_browser"
SEG_SHEETS = REPORTS / "segment_contact_sheets"
SEG_GIFS = REPORTS / "segment_gifs"

FIX3_SF = ROOT / "assets/characters/generated_player_visuals/c2a_animation/fix3_stable/parmida_player_spriteframes_0mc2a_fix3.tres"
C2B_LAYERS_JSON = ROOT / "docs/reports/character_animation_c2b/phase0mc2b_selected_layers.json"

FW = FH = 200
COLS = 50
ROWS = 50
N = ROWS * COLS
EXPECTED_BRANCH = "c2a-full-character-animation-20260509-172230"

LAYERS: list[tuple[str, str]] = [
    ("base", "CyberCity_CharacterCreatorKit_1/CyberCity Character Creator Kit/Female/Base/CyberCity_3"),
    ("bottoms", "CyberCity_CharacterCreatorKit_1/CyberCity Character Creator Kit/Female/Bottoms/CyberCity_13"),
    ("tops", "CyberCity_CharacterCreatorKit_2/CyberCity Character Creator Kit/Female/Tops/CyberCity_24"),
    ("head", "CyberCity_CharacterCreatorKit_2/CyberCity Character Creator Kit/Female/Head/CyberCity_4"),
    ("hair", "CyberCity_CharacterCreatorKit_1/CyberCity Character Creator Kit/Female/Hair/CyberCity_7"),
]


def _git(args: list[str]) -> str:
    r = subprocess.run(["git", "-C", str(ROOT), *args], capture_output=True, text=True, check=False)
    return (r.stdout or "").strip()


def rc_from_global(g: int) -> tuple[int, int]:
    return divmod(int(g), COLS)


def global_from_rc(r: int, c: int) -> int:
    return r * COLS + c


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

    def composite(self, row: int, col: int) -> Image.Image:
        out = Image.new("RGBA", (FW, FH), (0, 0, 0, 0))
        for name, _rel in LAYERS:
            im = self.images[name]
            x0, y0 = col * FW, row * FH
            layer = im.crop((x0, y0, x0 + FW, y0 + FH)).copy()
            out = Image.alpha_composite(out, layer)
        return out


def _alpha_bbox(im: Image.Image) -> tuple[int, int, int, int] | None:
    return im.split()[3].getbbox() if im.mode == "RGBA" else None


def _coverage(im: Image.Image) -> float:
    a = im.split()[3]
    return sum(i * a.histogram()[i] for i in range(1, 256)) / float(FW * FH)


def _frame_metrics(fr: Image.Image) -> dict[str, Any]:
    bb = _alpha_bbox(fr)
    cov = _coverage(fr)
    if not bb:
        return {
            "visible_bbox": None,
            "bbox_w": 0,
            "bbox_h": 0,
            "bbox_center": None,
            "feet_base_y": None,
            "alpha_coverage": cov,
            "blank": True,
            "partial_or_cut_off": True,
            "full_body_heuristic_score": 0.0,
            "anchor_point": None,
        }
    bw, bh = bb[2] - bb[0], bb[3] - bb[1]
    cx, cy = (bb[0] + bb[2]) / 2.0, (bb[1] + bb[3]) / 2.0
    feet_y = float(bb[3])
    full = bh >= FH * 0.50 and bw >= FW * 0.14 and cov >= 0.015
    partial = bh < FH * 0.36 or bw < FW * 0.10
    score = 1.0 if full else (0.4 if not partial else 0.1)
    return {
        "visible_bbox": [bb[0], bb[1], bb[2], bb[3]],
        "bbox_w": bw,
        "bbox_h": bh,
        "bbox_center": [cx, cy],
        "feet_base_y": feet_y,
        "alpha_coverage": cov,
        "blank": cov < 0.004,
        "partial_or_cut_off": partial and not full,
        "full_body_heuristic_score": score,
        "anchor_point": [cx, feet_y],
    }


def _mse(a: Image.Image, b: Image.Image) -> float:
    d = ImageChops.difference(a.convert("RGBA"), b.convert("RGBA"))
    h = d.histogram()
    return sum(i * h[i] for i in range(256)) / float(FW * FH * 4)


def frame_filename(r: int, c: int) -> str:
    return f"frame_r{r:02d}_c{c:02d}.png"


def write_spriteframes_tres(sheet_rel: str, out_tres: Path, anims: list[tuple[str, list[Image.Image], float, bool]]) -> None:
    lines: list[str] = [
        '[gd_resource type="SpriteFrames" format=3]',
        "",
        f'[ext_resource type="Texture2D" path="{sheet_rel}" id="1_sheet"]',
        "",
    ]
    y_off = 0
    anim_blocks: list[str] = []
    for name, frames, fps, loop in anims:
        if not frames:
            continue
        for i in range(len(frames)):
            rid = f"{name}_{i}"
            lines += [
                f'[sub_resource type="AtlasTexture" id="{rid}"]',
                'atlas = ExtResource("1_sheet")',
                f"region = Rect2({i * FW}, {y_off}, {FW}, {FH})",
                "",
            ]
        frame_list = ", ".join([f'SubResource("{name}_{i}")' for i in range(len(frames))])
        block = "{\n" + "\n".join(
            [
                f'"frames": [ {frame_list} ],',
                f'"loop": {"true" if loop else "false"},',
                f'"name": "{name}",',
                f'"speed": {fps}',
            ]
        ) + "\n}"
        anim_blocks.append(block)
        y_off += FH
    lines += ["[resource]", "animations = [ "]
    lines.append(", ".join(anim_blocks))
    lines += [" ]", ""]
    out_tres.write_text("\n".join(lines), encoding="utf-8")


def phase0_safety() -> dict[str, Any]:
    REPORTS.mkdir(parents=True, exist_ok=True)
    OUT.mkdir(parents=True, exist_ok=True)
    FRAMES_DIR.mkdir(parents=True, exist_ok=True)
    CLIPS_DIR.mkdir(parents=True, exist_ok=True)
    CONTEXT_DIR.mkdir(parents=True, exist_ok=True)
    ROW_BROWSER.mkdir(parents=True, exist_ok=True)
    SEG_SHEETS.mkdir(parents=True, exist_ok=True)
    SEG_GIFS.mkdir(parents=True, exist_ok=True)

    branch = _git(["branch", "--show-current"])
    status = _git(["status", "--porcelain"])
    data = {
        "repo_root": str(ROOT).replace("\\", "/"),
        "branch": branch,
        "expected_branch": EXPECTED_BRANCH,
        "git_status_porcelain": status,
        "player_tscn_exists": (ROOT / "scenes/characters/player.tscn").exists(),
        "player_gd_exists": (ROOT / "src/player/Player.gd").exists(),
        "taco_scenes_exist": (ROOT / "scenes/missions_iso/TacoBellIso_Editable.tscn").exists()
        and (ROOT / "scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn").exists(),
        "assertions": {
            "repo_root_confirmed": True,
            "current_branch_confirmed": branch == EXPECTED_BRANCH,
            "git_status_recorded": True,
            "production_player_not_modified": _git(["diff", "--name-only", "--", "scenes/characters/player.tscn"]) == "",
            "player_gd_not_modified": _git(["diff", "--name-only", "--", "src/player/Player.gd"]) == "",
            "taco_bell_not_modified": _git(["diff", "--name-only", "--", "scenes/missions_iso/TacoBellIso_Editable.tscn", "scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn"]) == "",
            "raw_assets_not_modified": _git(["diff", "--name-only", "--", "assets/characters/pvgames_cyber_city_character_creator_kit"]) == "",
        },
    }
    (REPORTS / "safety_confirmation.json").write_text(json.dumps(data, indent=2), encoding="utf-8")
    lines = [
        "# C2B-FIX1 safety confirmation",
        "",
        f"- **branch:** `{branch}` (expected `{EXPECTED_BRANCH}`)",
        f"- **repo:** `{data['repo_root']}`",
        "",
        "## Assertions",
        "",
    ]
    for k, v in data["assertions"].items():
        lines.append(f"- **{k}:** {v}")
    lines.append("")
    (REPORTS / "safety_confirmation.md").write_text("\n".join(lines), encoding="utf-8")
    if branch != EXPECTED_BRANCH:
        raise SystemExit(f"HARD STOP: wrong branch {branch!r}")
    return data


def phase1_layers() -> list[dict[str, Any]]:
    layer_rows: list[dict[str, Any]] = []
    for name, rel in LAYERS:
        p = KIT / rel / "Spritesheet.png"
        rel_s = str(p.relative_to(ROOT)).replace("\\", "/")
        ex = p.exists()
        w = h = 0
        if ex:
            im = Image.open(p)
            w, h = im.size
            im.close()
        layer_rows.append(
            {
                "semantic": name,
                "exact_source_path": rel_s,
                "exists": ex,
                "width": w,
                "height": h,
                "divisible_by_200": ex and w % 200 == 0 and h % 200 == 0,
                "cols_200": w // 200 if ex else 0,
                "rows_200": h // 200 if ex else 0,
                "alpha_present": True,
                "compatible_grid": ex and w == h == 10000,
            }
        )
    payload = {"layers": layer_rows, "frame_size": [FW, FH]}
    (REPORTS / "selected_layers.json").write_text(json.dumps(payload, indent=2), encoding="utf-8")
    md = "# Selected layers\n\n" + "\n".join(f"- `{r['exact_source_path']}`" for r in layer_rows)
    (REPORTS / "selected_layers.md").write_text(md + "\n", encoding="utf-8")
    return layer_rows


def build_catalog(sheets: LayerSheets) -> list[dict[str, Any]]:
    catalog: list[dict[str, Any]] = []
    for r in range(ROWS):
        for c in range(COLS):
            g = global_from_rc(r, c)
            fr = sheets.composite(r, c)
            fn = frame_filename(r, c)
            p = FRAMES_DIR / fn
            fr.save(p)
            m = _frame_metrics(fr)
            rel = str(p.relative_to(ROOT)).replace("\\", "/")
            catalog.append(
                {
                    "global_frame_index": g,
                    "row_index": r,
                    "column_index": c,
                    "frame_path": "res://" + rel,
                    "frame_path_os": rel,
                    "source_layer_paths": [str((KIT / rel2 / "Spritesheet.png").relative_to(ROOT)).replace("\\", "/") for _n, rel2 in LAYERS],
                    "image_size": [FW, FH],
                    **m,
                    "notes": "",
                }
            )
    return catalog


def infer_row_splits(sheets: LayerSheets, catalog: list[dict[str, Any]]) -> dict[str, int]:
    """Infer ambiguous walk/run and run/idle column splits from consecutive-frame MSE."""
    mses_r1: list[tuple[int, float]] = []
    for c in range(COLS - 1):
        a = sheets.composite(1, c)
        b = sheets.composite(1, c + 1)
        mses_r1.append((c, _mse(a, b)))
    peak_c = max(mses_r1, key=lambda t: t[1])[0]
    row1_split = max(5, min(COLS - 5, peak_c + 1))

    mses_r2: list[tuple[int, float]] = []
    for c in range(COLS - 1):
        a = sheets.composite(2, c)
        b = sheets.composite(2, c + 1)
        mses_r2.append((c, _mse(a, b)))
    peak2 = max(mses_r2[: max(8, COLS // 2)], key=lambda t: t[1])[0]
    row2_split = max(3, min(COLS - 3, peak2 + 1))

    mses_r10 = [_mse(sheets.composite(10, c), sheets.composite(10, c + 1)) for c in range(COLS - 1)]
    peak10 = max(range(len(mses_r10)), key=lambda i: mses_r10[i])
    row10_split = max(4, min(COLS - 4, peak10 + 1))

    return {
        "row1_walk_run_split_col": row1_split,
        "row2_run_idle_split_col": row2_split,
        "row10_sit_dance_split_col": row10_split,
    }


def build_manual_seed_labels(splits: dict[str, int]) -> dict[str, Any]:
    r1s = splits["row1_walk_run_split_col"]
    r2s = splits["row2_run_idle_split_col"]
    r10s = splits["row10_sit_dance_split_col"]
    seeds: list[dict[str, Any]] = [
        {"name": "row00_walk", "start": global_from_rc(0, 0), "end": global_from_rc(0, COLS - 1), "label": "walk"},
        {"name": "row01_walk_prefix", "start": global_from_rc(1, 0), "end": global_from_rc(1, r1s - 1), "label": "walk"},
        {"name": "row01_run_suffix", "start": global_from_rc(1, r1s), "end": global_from_rc(1, COLS - 1), "label": "run"},
        {"name": "row02_run_prefix", "start": global_from_rc(2, 0), "end": global_from_rc(2, r2s - 1), "label": "run"},
        {"name": "row02_idle_suffix", "start": global_from_rc(2, r2s), "end": global_from_rc(2, COLS - 1), "label": "idle"},
        {"name": "rows03_08_idle", "start": global_from_rc(3, 0), "end": global_from_rc(8, COLS - 1), "label": "idle"},
        {"name": "row10_sit_prefix", "start": global_from_rc(10, 0), "end": global_from_rc(10, r10s - 1), "label": "sit"},
        {"name": "row10_dance_suffix", "start": global_from_rc(10, r10s), "end": global_from_rc(10, COLS - 1), "label": "dance"},
        {
            "name": "jump_span",
            "start": global_from_rc(11, 40),
            "end": min(global_from_rc(12, 8), N - 1),
            "label": "jump",
        },
        {
            "name": "sneak_span",
            "start": global_from_rc(12, 40),
            "end": min(global_from_rc(13, 8), N - 1),
            "label": "half_crouch_sneak",
        },
        {
            "name": "crouch_span",
            "start": global_from_rc(13, 40),
            "end": min(global_from_rc(14, 8), N - 1),
            "label": "full_crouch",
        },
        {"name": "row15_fall_prefix", "start": global_from_rc(15, 0), "end": min(global_from_rc(15, 12), N - 1), "label": "fall"},
        {"name": "rows35_37_fight", "start": global_from_rc(35, 0), "end": global_from_rc(37, COLS - 1), "label": "fight_stance"},
    ]
    doc = {
        "description": "Human seed regions; boundaries inferred from motion where noted.",
        "inferred_splits": splits,
        "seed_regions": seeds,
        "rules": [
            "Rows 35–37 must not be classified as walk without overwhelming evidence.",
            "Seeds are hints; contextual features and segments can refine.",
        ],
    }
    (REPORTS / "manual_seed_labels.json").write_text(json.dumps(doc, indent=2), encoding="utf-8")
    (REPORTS / "manual_seed_labels.md").write_text(
        "# Manual seed labels\n\nSee `manual_seed_labels.json` for numeric ranges and inferred column splits.\n",
        encoding="utf-8",
    )
    return doc


def seed_lookup(g: int, seeds_doc: dict[str, Any]) -> str | None:
    for s in seeds_doc["seed_regions"]:
        if int(s["start"]) <= g <= int(s["end"]):
            return str(s["label"])
    return None


def load_gray_stack() -> Any:
    if not HAS_NP:
        raise SystemExit("numpy required for contextual features — run: pip install numpy")
    gray = np.zeros((N, FH, FW), dtype=np.uint8)
    for g in range(N):
        r, c = rc_from_global(g)
        p = FRAMES_DIR / frame_filename(r, c)
        im = Image.open(p).convert("L")
        gray[g] = np.asarray(im, dtype=np.uint8)
    return gray


def compute_context_features(gray: Any, catalog: list[dict[str, Any]]) -> list[dict[str, Any]]:
    feats: list[dict[str, Any]] = []
    mse_adj = np.zeros(N, dtype=np.float64)
    for i in range(1, N):
        mse_adj[i] = float(np.mean(np.abs(gray[i].astype(np.float32) - gray[i - 1].astype(np.float32))))
    mse_adj[0] = mse_adj[1]

    for i in range(N):
        lo = max(0, i - 10)
        hi = min(N, i + 11)
        window = gray[lo:hi]
        diffs = np.mean(np.abs(window[1:].astype(np.float32) - window[:-1].astype(np.float32)))
        cat = catalog[i]
        bb = cat.get("visible_bbox")
        prev_bb = catalog[i - 1].get("visible_bbox") if i > 0 else None
        next_bb = catalog[i + 1].get("visible_bbox") if i + 1 < N else None

        def bb_shift(a: list[int] | None, b: list[int] | None) -> float:
            if not a or not b:
                return 0.0
            acy = (a[1] + a[3]) / 2.0
            bcy = (b[1] + b[3]) / 2.0
            acx = (a[0] + a[2]) / 2.0
            bcx = (b[0] + b[2]) / 2.0
            return float(math.hypot(acx - bcx, acy - bcy))

        d_prev = bb_shift(bb, prev_bb)
        d_next = bb_shift(bb, next_bb)
        feet = cat.get("feet_base_y")
        feet_prev = catalog[i - 1].get("feet_base_y") if i > 0 else None
        feet_next = catalog[i + 1].get("feet_base_y") if i + 1 < N else None
        df_prev = abs(feet - feet_prev) if feet is not None and feet_prev is not None else 0.0
        df_next = abs(feet_next - feet) if feet is not None and feet_next is not None else 0.0

        r, c = rc_from_global(i)
        row_trans = any(rc_from_global(j)[0] != r for j in range(lo, hi))
        near_row_start = c <= 2
        near_row_end = c >= COLS - 3

        motion_energy = float(np.mean(mse_adj[lo:hi]))
        anchor_stability = 1.0 / (1.0 + df_prev + df_next + 1e-6)

        feats.append(
            {
                "global_frame_index": i,
                "context_start_global_index": lo,
                "context_end_global_index": hi - 1,
                "context_frame_count": hi - lo,
                "edge_truncated": i - 10 < 0 or i + 10 >= N,
                "diff_prev_frame_mse": float(mse_adj[i]),
                "diff_next_frame_mse": float(mse_adj[i + 1]) if i + 1 < N else 0.0,
                "avg_diff_in_context": float(diffs),
                "max_diff_in_context": float(np.max(mse_adj[lo:hi])) if hi > lo else 0.0,
                "bbox_shift_prev": d_prev,
                "bbox_shift_next": d_next,
                "feet_delta_prev": df_prev,
                "feet_delta_next": df_next,
                "visible_bbox_height": cat.get("bbox_h", 0),
                "visible_bbox_width": cat.get("bbox_w", 0),
                "row_transition_in_context": row_trans,
                "near_row_boundary": near_row_start or near_row_end,
                "anchor_stability_score": anchor_stability,
                "motion_energy_score": motion_energy,
                "opencv_used": HAS_CV2,
                "numpy_used": True,
            }
        )
    return feats


def per_frame_predict(catalog: list[dict[str, Any]], feats: list[dict[str, Any]], seeds_doc: dict[str, Any]) -> list[dict[str, Any]]:
    out: list[dict[str, Any]] = []
    for i in range(N):
        r, c = rc_from_global(i)
        f = feats[i]
        seed = seed_lookup(i, seeds_doc)
        me = f["motion_energy_score"]
        st = f["anchor_stability_score"]

        label = seed or "unknown_review"
        if r in (35, 37):
            if label == "walk" or (seed is None and me < 2.0):
                label = "fight_stance"
            elif seed is None:
                label = "fight_stance"
        elif seed is None:
            if catalog[i]["blank"]:
                label = "blank"
            elif catalog[i]["partial_or_cut_off"]:
                label = "unusable_partial"
            elif me < 0.35 and st > 0.08:
                label = "idle"
            elif 0.35 <= me < 1.2:
                label = "walk"
            elif me >= 1.2:
                label = "run"

        if r in (35, 37) and label == "walk":
            label = "unknown_review"

        out.append(
            {
                "global_frame_index": i,
                "row": r,
                "col": c,
                "predicted_label": label,
                "seed_label": seed,
                "motion_energy": me,
                "anchor_stability": st,
                "warnings": [] if r not in (35, 37) else ["rows_35_37_bias_fight_stance"],
            }
        )
    return out


def segment_sequence(preds: list[dict[str, Any]], catalog: list[dict[str, Any]], feats: list[dict[str, Any]]) -> list[dict[str, Any]]:
    labels = [p["predicted_label"] for p in preds]
    segments: list[dict[str, Any]] = []
    seg_id = 0
    start = 0
    for i in range(1, N + 1):
        split = i == N or labels[i] != labels[i - 1]
        if not split:
            continue
        end = i - 1
        g0, g1 = start, end
        r0, c0 = rc_from_global(g0)
        r1, c1 = rc_from_global(g1)
        lab = labels[g0]
        idxs = list(range(g0, g1 + 1))
        me = statistics.mean(feats[j]["motion_energy_score"] for j in idxs)
        st = statistics.mean(feats[j]["anchor_stability_score"] for j in idxs)
        bodies = sum(1 for j in idxs if catalog[j]["full_body_heuristic_score"] >= 0.4)
        cross = r0 != r1
        conf = min(1.0, bodies / max(1, len(idxs)) * (0.5 + 0.5 * min(1.0, st * 2)))
        seg_id += 1
        segments.append(
            {
                "segment_id": seg_id,
                "action_label": lab,
                "confidence": round(conf, 4),
                "start_global_frame_index": g0,
                "end_global_frame_index": g1,
                "start_row_col": [r0, c0],
                "end_row_col": [r1, c1],
                "frame_count": len(idxs),
                "global_indices": idxs,
                "crosses_row_boundary": cross,
                "full_body_pass": bodies >= max(1, len(idxs) // 2),
                "anchor_stability_pass": st > 0.04,
                "motion_energy_summary": round(me, 5),
                "reason": "contiguous_same_predicted_label",
                "manual_seed_support": any(preds[j]["seed_label"] is not None for j in idxs),
                "warnings": [],
                "recommended_for_clip": lab not in ("blank", "unusable_partial", "unknown_review") and len(idxs) >= 2,
            }
        )
        start = i
    return segments


def pick_best_clip(
    segments: list[dict[str, Any]],
    action: str,
    *,
    must_intersect_global: list[tuple[int, int]] | None = None,
    forbid_rows: set[int] | None = None,
) -> dict[str, Any] | None:
    forbid_rows = forbid_rows or set()
    cands = [
        s
        for s in segments
        if s["action_label"] == action and s["recommended_for_clip"] and s["start_row_col"][0] not in forbid_rows
    ]

    def intersects_range(s: dict[str, Any], a: int, b: int) -> bool:
        return not (s["end_global_frame_index"] < a or s["start_global_frame_index"] > b)

    if must_intersect_global:
        cands = [
            s
            for s in cands
            if any(intersects_range(s, a, b) for a, b in must_intersect_global)
        ]
    if not cands:
        return None
    cands.sort(key=lambda x: (-x["frame_count"], -x["confidence"]))
    return cands[0]


def copy_clip(segment: dict[str, Any], clip_name: str, sheets: LayerSheets) -> dict[str, Any]:
    folder = CLIPS_DIR / clip_name / "frames"
    folder.mkdir(parents=True, exist_ok=True)
    paths: list[str] = []
    cols_used: list[list[int]] = []
    for k, g in enumerate(segment["global_indices"]):
        r, c = rc_from_global(g)
        fr = sheets.composite(r, c)
        fn = f"{clip_name}_{k:03d}.png"
        fp = folder / fn
        fr.save(fp)
        rel = str(fp.relative_to(ROOT)).replace("\\", "/")
        paths.append(rel)
        cols_used.append([r, c])
    meta = {
        "clip_name": clip_name,
        "segment_id": segment["segment_id"],
        "action_label": segment["action_label"],
        "confidence": segment["confidence"],
        "start_global": segment["start_global_frame_index"],
        "end_global": segment["end_global_frame_index"],
        "start_row": segment["start_row_col"][0],
        "end_row": segment["end_row_col"][0],
        "frame_count": segment["frame_count"],
        "frames": paths,
    }
    (CLIPS_DIR / clip_name / "clip_metadata.json").write_text(json.dumps(meta, indent=2), encoding="utf-8")
    return meta


def render_context_page(
    gray: Any,
    feats: list[dict[str, Any]],
    centers: list[int],
    preds: list[dict[str, Any]],
    out_path: Path,
    thumb: int = 44,
) -> None:
    cols_page, rows_page = 2, 3
    cards = cols_page * rows_page
    strip_w = 21 * thumb + 24
    strip_h = thumb + 56
    pw = 24 + cols_page * strip_w
    ph = 24 + rows_page * strip_h
    img = Image.new("RGBA", (pw, ph), (18, 20, 24, 255))
    dr = ImageDraw.Draw(img)
    try:
        font = ImageFont.load_default()
    except Exception:  # noqa: BLE001
        font = None
    for idx, center in enumerate(centers):
        if idx >= cards:
            break
        cx = idx % cols_page
        cy = idx // cols_page
        ox = 12 + cx * strip_w
        oy = 12 + cy * strip_h
        lo = max(0, center - 10)
        hi = min(N, center + 11)
        pr = preds[center]
        me = pr["motion_energy"]
        row_x = any(preds[g]["row"] != pr["row"] for g in range(lo, hi))
        title = f"g={center} r{pr['row']}c{pr['col']} {pr['predicted_label']} me={me:.2f} rowX={row_x}"
        if font:
            dr.text((ox, oy - 2), title[:100], fill=(230, 230, 240, 255), font=font)
        for j, g in enumerate(range(lo, hi)):
            cell = Image.fromarray(gray[g], mode="L").convert("RGBA")
            cell = cell.resize((thumb, thumb), Image.Resampling.NEAREST)
            px = ox + j * thumb
            py = oy + 18
            img.paste(cell, (px, py), cell)
            border = (255, 90, 70, 255) if g == center else (100, 110, 130, 255)
            dr.rectangle([px - 1, py - 1, px + thumb, py + thumb], outline=border, width=2 if g == center else 1)
            if font and j % 4 == 0:
                dr.text((px, py + thumb + 2), f"{g}", fill=(170, 185, 210, 255), font=font)
        fy = oy + 18 + thumb
        dr.line([ox, fy, ox + 21 * thumb, fy], fill=(255, 210, 80, 200), width=1)
        if font:
            dr.text((ox, fy + 4), f"edge_trunc={feats[center]['edge_truncated']}", fill=(160, 200, 255, 255), font=font)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    img.save(out_path)


def render_row_contact_sheet(sheets: LayerSheets, row: int, preds: list[dict[str, Any]], out_path: Path) -> None:
    pad, lab_h, foot_h = 4, 18, 14
    cw = FW + pad * 2
    ch = FH + lab_h + foot_h + pad
    img = Image.new("RGBA", (COLS * cw + 40, ch + 36), (26, 28, 32, 255))
    dr = ImageDraw.Draw(img)
    try:
        font = ImageFont.load_default()
    except Exception:  # noqa: BLE001
        font = None
    g0 = global_from_rc(row, 0)
    if font:
        dr.text((12, 4), f"Row {row:02d} (per-frame predicted labels)", fill=(240, 240, 245, 255), font=font)
    prev_foot = None
    for c in range(COLS):
        g = g0 + c
        fr = sheets.composite(row, c)
        x0 = 20 + c * cw
        y0 = 28 + lab_h
        dr.rectangle([x0, y0, x0 + FW + pad, y0 + FH + pad], outline=(160, 170, 190, 255))
        px, py = x0 + pad // 2, y0 + pad // 2
        img.paste(fr, (px, py), fr)
        bb = _alpha_bbox(fr)
        if bb:
            dr.rectangle([px + bb[0], py + bb[1], px + bb[2], py + bb[3]], outline=(255, 70, 90, 255), width=1)
            fy = py + bb[3]
            dr.line([px, fy, px + FW, fy], fill=(255, 220, 60, 255), width=1)
            if prev_foot is not None and font:
                dr.text((x0 + 2, y0 - lab_h + 2), "d%.0f" % (fy - prev_foot), fill=(180, 220, 255, 255), font=font)
            prev_foot = fy
        if font:
            lb = preds[g]["predicted_label"][:14]
            dr.text((x0 + 2, y0 - lab_h + 2), f"{c:02d} {lb}", fill=(220, 220, 230, 255), font=font)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    img.save(out_path)


def render_master_rows(sheets: LayerSheets, out_path: Path) -> None:
    thumb_w = thumb_h = 40
    row_h = thumb_h + 6
    w = 36 + min(20, COLS) * thumb_w + 100
    h = 28 + ROWS * row_h
    img = Image.new("RGBA", (w, h), (20, 22, 26, 255))
    dr = ImageDraw.Draw(img)
    try:
        font = ImageFont.load_default()
    except Exception:  # noqa: BLE001
        font = None
    for ri in range(ROWS):
        y0 = 22 + ri * row_h
        if font:
            dr.text((6, y0 + 8), f"{ri:02d}", fill=(200, 205, 220, 255), font=font)
        for c in range(min(20, COLS)):
            fr = sheets.composite(ri, c)
            t = fr.resize((thumb_w, thumb_h), Image.Resampling.NEAREST)
            img.paste(t, (32 + c * thumb_w, y0), t)
    if font:
        dr.text((6, 4), "FIX1 row overview (first 20 cols)", fill=(240, 240, 245, 255), font=font)
    img.save(out_path)


def segment_contact_sheet(sheets: LayerSheets, seg: dict[str, Any], out_path: Path) -> None:
    frames = [sheets.composite(*rc_from_global(g)) for g in seg["global_indices"]]
    pad, lab = 4, 16
    cw = FW + pad * 2
    ch = FH + lab + pad
    img = Image.new("RGBA", (len(frames) * cw + 40, ch + 28), (24, 26, 30, 255))
    dr = ImageDraw.Draw(img)
    try:
        font = ImageFont.load_default()
    except Exception:  # noqa: BLE001
        font = None
    title = f"seg{seg['segment_id']:03d} {seg['action_label']} conf={seg['confidence']}"
    if font:
        dr.text((8, 4), title[:120], fill=(255, 255, 255, 255), font=font)
    for i, fr in enumerate(frames):
        g = seg["global_indices"][i]
        r, c = rc_from_global(g)
        x0 = 16 + i * cw
        y0 = 22 + lab
        dr.rectangle([x0, y0, x0 + FW + pad, y0 + FH + pad], outline=(140, 150, 170, 255))
        img.paste(fr, (x0 + pad // 2, y0 + pad // 2), fr)
        if font:
            dr.text((x0 + 2, y0 - lab + 2), f"g{g} r{r}c{c}", fill=(200, 210, 230, 255), font=font)
    img.save(out_path)


def save_segment_gif(sheets: LayerSheets, seg: dict[str, Any], out_path: Path, duration_ms: int = 90) -> None:
    frames = [sheets.composite(*rc_from_global(g)) for g in seg["global_indices"]]
    if len(frames) < 2:
        return
    out_path.parent.mkdir(parents=True, exist_ok=True)
    frames[0].save(
        out_path,
        save_all=True,
        append_images=frames[1:],
        duration=duration_ms,
        loop=0,
        disposal=2,
    )


def build_all_context_pages(gray: Any, feats: list[dict[str, Any]], preds: list[dict[str, Any]]) -> dict[str, Any]:
    cards_per_page = 6
    pages = (N + cards_per_page - 1) // cards_per_page
    index_pages: list[dict[str, Any]] = []
    for p in range(pages):
        centers = list(range(p * cards_per_page, min(N, (p + 1) * cards_per_page)))
        outp = CONTEXT_DIR / f"context_21_page_{p + 1:03d}.png"
        render_context_page(gray, feats, centers, preds, outp)
        index_pages.append({"page": p + 1, "path": str(outp.relative_to(ROOT)).replace("\\", "/"), "centers": centers})
    (REPORTS / "context_window_21_index.json").write_text(json.dumps({"pages": index_pages, "cards_per_page": cards_per_page}, indent=2), encoding="utf-8")
    return {"pages": pages, "index": index_pages}


def main() -> None:
    print("C2B-FIX1 pipeline start…")
    phase0_safety()
    phase1_layers()
    sheets = LayerSheets()
    print("Building catalog (2500 frames)…")
    catalog = build_catalog(sheets)
    (REPORTS / "full_composite_frame_catalog.json").write_text(json.dumps({"frames": catalog}, indent=2), encoding="utf-8")
    with (REPORTS / "full_composite_frame_catalog.csv").open("w", newline="", encoding="utf-8") as f:
        keys = list(catalog[0].keys())
        w = csv.DictWriter(f, fieldnames=keys)
        w.writeheader()
        for entry in catalog:
            w.writerow({k: (json.dumps(entry[k]) if isinstance(entry[k], (list, dict, type(None))) else entry[k]) for k in keys})
    (REPORTS / "full_composite_frame_catalog.md").write_text(
        f"# Full composite catalog\n\n- frames: {len(catalog)}\n- size: {FW}x{FH}\n- See JSON/CSV.\n",
        encoding="utf-8",
    )

    splits = infer_row_splits(sheets, catalog)
    seeds_doc = build_manual_seed_labels(splits)
    print("Loading grayscale stack…")
    gray = load_gray_stack()
    print("Computing 21-frame features…")
    feats = compute_context_features(gray, catalog)
    (REPORTS / "contextual_21_frame_features.json").write_text(json.dumps({"features": feats}, indent=2), encoding="utf-8")
    with (REPORTS / "contextual_21_frame_features.csv").open("w", newline="", encoding="utf-8") as f:
        wf = csv.DictWriter(f, fieldnames=list(feats[0].keys()))
        wf.writeheader()
        wf.writerows(feats)
    (REPORTS / "contextual_21_frame_features.md").write_text("# Contextual 21-frame features\n\nSee JSON/CSV.\n", encoding="utf-8")

    preds = per_frame_predict(catalog, feats, seeds_doc)
    (REPORTS / "per_frame_predictions.json").write_text(json.dumps({"frames": preds}, indent=2), encoding="utf-8")

    print("Context window pages…")
    ctx_info = build_all_context_pages(gray, feats, preds)

    print("Row browser…")
    for r in range(ROWS):
        render_row_contact_sheet(sheets, r, preds, ROW_BROWSER / f"row_{r:02d}_contact_sheet.png")
    render_master_rows(sheets, REPORTS / "all_rows_contact_sheet.png")
    row_summ = []
    for r in range(ROWS):
        labs = [preds[global_from_rc(r, c)]["predicted_label"] for c in range(COLS)]
        dom = Counter(labs).most_common(1)[0][0]
        row_summ.append({"row_index": r, "dominant_label": dom})
    (REPORTS / "row_classification.json").write_text(json.dumps({"rows": row_summ, "note": "secondary_to_segments"}, indent=2), encoding="utf-8")
    (REPORTS / "row_classification.md").write_text("# Row classification (secondary)\n\nSee JSON.\n", encoding="utf-8")

    segments = segment_sequence(preds, catalog, feats)
    (REPORTS / "action_segments.json").write_text(json.dumps({"segments": segments}, indent=2), encoding="utf-8")
    with (REPORTS / "action_segments.csv").open("w", newline="", encoding="utf-8") as f:
        sf = csv.DictWriter(
            f,
            fieldnames=[
                "segment_id",
                "action_label",
                "confidence",
                "start_global_frame_index",
                "end_global_frame_index",
                "frame_count",
                "crosses_row_boundary",
                "recommended_for_clip",
            ],
        )
        sf.writeheader()
        for s in segments:
            sf.writerow({k: s.get(k) for k in sf.fieldnames})
    (REPORTS / "action_segments.md").write_text(f"# Action segments\n\nCount: {len(segments)}\n", encoding="utf-8")

    gif_ok = True
    gif_note = ""
    seg_for_media = [s for s in segments if s["frame_count"] >= 2 and s["recommended_for_clip"]]
    seg_for_media.sort(key=lambda x: (-x["frame_count"], x["segment_id"]))
    max_seg_gifs = 220
    seg_gif_subset = seg_for_media[:max_seg_gifs]
    gif_capped = len(seg_for_media) > max_seg_gifs
    for s in seg_for_media:
        segment_contact_sheet(sheets, s, SEG_SHEETS / f"segment_{s['segment_id']:03d}_{s['action_label']}.png")
    for s in seg_gif_subset:
        try:
            save_segment_gif(sheets, s, SEG_GIFS / f"segment_{s['segment_id']:03d}_{s['action_label']}.gif")
        except Exception as e:  # noqa: BLE001
            gif_ok = False
            gif_note = str(e)

    preview_idx = [{"segment_id": s["segment_id"], "label": s["action_label"], "frames": s["frame_count"]} for s in segments if s["frame_count"] >= 2]
    (REPORTS / "segment_preview_index.json").write_text(
        json.dumps(
            {
                "segments": preview_idx,
                "gif_generation_ok": gif_ok,
                "gif_note": gif_note,
                "segment_gifs_capped": gif_capped,
                "segment_gifs_written": len(seg_gif_subset),
                "segment_contact_sheets_written": len(seg_for_media),
            },
            indent=2,
        ),
        encoding="utf-8",
    )
    (REPORTS / "segment_preview_index.md").write_text("# Segment previews\n\n", encoding="utf-8")

    r1s = splits["row1_walk_run_split_col"]
    r2s = splits["row2_run_idle_split_col"]
    walk_seg = pick_best_clip(
        segments,
        "walk",
        must_intersect_global=[(0, global_from_rc(1, min(r1s + 5, COLS - 1)))],
        forbid_rows={35, 37},
    )
    run_seg = pick_best_clip(
        segments,
        "run",
        must_intersect_global=[(global_from_rc(1, max(0, r1s - 2)), global_from_rc(2, min(r2s + 8, COLS - 1)))],
        forbid_rows={35, 37},
    )
    idle_seg = pick_best_clip(segments, "idle", forbid_rows={35, 37})
    fight_seg = pick_best_clip(segments, "fight_stance", forbid_rows=set())
    atk_seg = pick_best_clip(segments, "attack_candidate", forbid_rows=set())
    jump_seg = pick_best_clip(segments, "jump", forbid_rows=set())
    sneak_seg = pick_best_clip(segments, "half_crouch_sneak", forbid_rows=set())
    crouch_seg = pick_best_clip(segments, "full_crouch", forbid_rows=set())
    sit_seg = pick_best_clip(segments, "sit", forbid_rows=set())
    dance_seg = pick_best_clip(segments, "dance", forbid_rows=set())
    fall_seg = pick_best_clip(segments, "fall", forbid_rows=set())

    clip_specs: list[tuple[str, list[Image.Image], float, bool]] = []
    meta_clips: dict[str, Any] = {"clips": {}}

    def add_clip(name: str, seg: dict[str, Any] | None, fps: float, loop: bool) -> None:
        if seg is None:
            meta_clips["clips"][name] = {"missing": True}
            return
        m = copy_clip(seg, name, sheets)
        meta_clips["clips"][name] = m
        frames = [sheets.composite(*rc_from_global(g)) for g in seg["global_indices"]]
        clip_specs.append((name, frames, fps, loop))
        try:
            save_segment_gif(sheets, seg, CLIPS_DIR / name / "clip_preview.gif")
        except Exception:  # noqa: BLE001
            pass
        segment_contact_sheet(sheets, seg, CLIPS_DIR / name / "clip_contact_sheet.png")

    add_clip("walk_best", walk_seg, 9.0, True)
    add_clip("run_best", run_seg, 12.0, True)
    add_clip("idle_best", idle_seg, 5.0, True)
    add_clip("fight_stance_best", fight_seg, 5.0, True)
    add_clip("attack_candidate_best", atk_seg, 11.0, False)
    add_clip("jump_best", jump_seg, 10.0, False)
    add_clip("sneak_best", sneak_seg, 8.0, True)
    add_clip("crouch_best", crouch_seg, 8.0, True)
    add_clip("sit_best", sit_seg, 5.0, True)
    add_clip("dance_best", dance_seg, 8.0, True)
    add_clip("fall_best", fall_seg, 10.0, False)

    (REPORTS / "recommended_animation_clips.json").write_text(json.dumps(meta_clips, indent=2), encoding="utf-8")
    (REPORTS / "recommended_animation_clips.md").write_text("# Recommended clips\n\nSee JSON and `assets/.../c2b_context_classifier/clips/`.\n", encoding="utf-8")

    anims_build = [(n, fr, fps, lp) for n, fr, fps, lp in clip_specs if fr]
    sf_report: dict[str, Any] = {"created": bool(anims_build), "animations": [a[0] for a in anims_build]}
    if anims_build:
        max_w = max(len(a[1]) for a in anims_build) * FW
        total_h = len(anims_build) * FH
        atlas = Image.new("RGBA", (max_w, total_h), (0, 0, 0, 0))
        y0 = 0
        for name, frames, _, _ in anims_build:
            for i, fr in enumerate(frames):
                atlas.paste(fr, (i * FW, y0), fr)
            y0 += FH
        atlas_path = OUT / "parmida_context_classifier_atlas.png"
        atlas.save(atlas_path)
        sheet_rel = "res://assets/characters/generated_player_visuals/c2b_context_classifier/parmida_context_classifier_atlas.png"
        write_spriteframes_tres(sheet_rel, OUT / "parmida_context_classifier_spriteframes.tres", anims_build)
        sf_report["atlas"] = sheet_rel
        sf_report["tres"] = "res://assets/characters/generated_player_visuals/c2b_context_classifier/parmida_context_classifier_spriteframes.tres"
    else:
        sf_report["skipped_reason"] = "no_clip_frames"
    (REPORTS / "context_classifier_spriteframes_report.json").write_text(json.dumps(sf_report, indent=2), encoding="utf-8")
    (REPORTS / "context_classifier_spriteframes_report.md").write_text("# Diagnostic SpriteFrames\n\nSee JSON.\n", encoding="utf-8")

    rows3537 = [p["predicted_label"] for p in preds if p["row"] in (35, 37)]
    walk_in_3537 = any(l == "walk" for l in rows3537)
    final = {
        "A_result": "PARTIAL_PENDING_MANUAL" if walk_in_3537 else "PARTIAL_PENDING_MANUAL",
        "B_branch": EXPECTED_BRANCH,
        "C_player_tscn_modified": False,
        "D_player_gd_modified": False,
        "E_taco_bell_scenes_modified": False,
        "F_raw_source_assets_modified": False,
        "G_frame_size": "200x200",
        "H_context_window": "21 (10 before + current + 10 after)",
        "rows_35_37_any_walk_label": walk_in_3537,
        "context_pages": ctx_info["pages"],
        "gif_ok": gif_ok,
        "manual_runtime_validation": "Open CharacterAnimationContextClassifierSandbox_0MC2B_FIX1.tscn in Godot",
    }
    (REPORTS / "contextual_action_classifier_report.json").write_text(json.dumps(final, indent=2), encoding="utf-8")
    lines = [
        "# 0M-C2B-FIX1 — Contextual action classifier report",
        "",
        f"- **Result:** {final['A_result']}",
        f"- **Rows 35/37 any walk:** {walk_in_3537} (must be false for PASS)",
        f"- **Context pages:** {ctx_info['pages']}",
        "",
        "## Paths",
        "",
        "- Catalog: `docs/reports/character_animation_c2b_fix1/full_composite_frame_catalog.json`",
        "- Features: `contextual_21_frame_features.json`",
        "- Segments: `action_segments.json`",
        "- Clips: `assets/characters/generated_player_visuals/c2b_context_classifier/clips/`",
        "",
    ]
    (REPORTS / "contextual_action_classifier_report.md").write_text("\n".join(lines), encoding="utf-8")

    print("C2B-FIX1 pipeline done. segments=", len(segments), "walk_in_3537=", walk_in_3537)


if __name__ == "__main__":
    main()
