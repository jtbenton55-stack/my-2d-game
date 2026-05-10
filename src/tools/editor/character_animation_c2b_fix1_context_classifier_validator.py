#!/usr/bin/env python3
"""Static validation for 0M-C2B-FIX1 contextual classifier."""
from __future__ import annotations

import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
REPORTS = ROOT / "docs/reports/character_animation_c2b_fix1"
OUT = ROOT / "assets/characters/generated_player_visuals/c2b_context_classifier"
EXPECTED_BRANCH = "c2a-full-character-animation-20260509-172230"


def _git(args: list[str]) -> str:
    r = subprocess.run(["git", "-C", str(ROOT), *args], capture_output=True, text=True, check=False)
    return (r.stdout or "").strip()


def _read(p: Path) -> str:
    return p.read_text(encoding="utf-8", errors="replace")


def main() -> None:
    checks: dict[str, bool] = {}

    checks["branch_ok"] = _git(["branch", "--show-current"]) == EXPECTED_BRANCH
    checks["player_tscn_clean"] = _git(["diff", "--name-only", "--", "scenes/characters/player.tscn"]) == ""
    checks["player_gd_clean"] = _git(["diff", "--name-only", "--", "src/player/Player.gd"]) == ""
    checks["taco_clean"] = _git(["diff", "--name-only", "--", "scenes/missions_iso/TacoBellIso_Editable.tscn", "scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn"]) == ""
    checks["kit_clean"] = _git(["diff", "--name-only", "--", "assets/characters/pvgames_cyber_city_character_creator_kit"]) == ""

    checks["safety_json"] = (REPORTS / "safety_confirmation.json").exists()
    checks["layers_json"] = (REPORTS / "selected_layers.json").exists()
    checks["catalog_json"] = (REPORTS / "full_composite_frame_catalog.json").exists()
    checks["features_json"] = (REPORTS / "contextual_21_frame_features.json").exists()
    checks["context_index"] = (REPORTS / "context_window_21_index.json").exists()
    checks["context_page_001"] = (REPORTS / "context_windows_21" / "context_21_page_001.png").exists()
    checks["manual_seeds"] = (REPORTS / "manual_seed_labels.json").exists()
    checks["row_browser_row00"] = (REPORTS / "row_browser" / "row_00_contact_sheet.png").exists()
    checks["all_rows_master"] = (REPORTS / "all_rows_contact_sheet.png").exists()
    checks["segments_json"] = (REPORTS / "action_segments.json").exists()
    checks["segment_sheet_exists"] = any((REPORTS / "segment_contact_sheets").glob("segment_*.png"))
    seg_gifs = list((REPORTS / "segment_gifs").glob("*.gif"))
    checks["segment_gif_or_capped"] = len(seg_gifs) > 0 or (REPORTS / "segment_preview_index.json").exists()
    checks["clips_meta"] = (REPORTS / "recommended_animation_clips.json").exists()
    checks["sandbox_tscn"] = (ROOT / "scenes/hideout/tools/CharacterAnimationContextClassifierSandbox_0MC2B_FIX1.tscn").exists()
    checks["sandbox_ctrl"] = (ROOT / "scenes/hideout/tools/CharacterAnimationContextClassifierSandbox_0MC2B_FIX1.gd").exists()
    sb = _read(ROOT / "scenes/hideout/tools/CharacterAnimationContextClassifierSandbox_0MC2B_FIX1.tscn")
    checks["sandbox_no_hardwired_context_tres"] = "parmida_context_classifier_spriteframes.tres" not in sb
    checks["sandbox_has_frame_viewer"] = "FrameViewer" in sb and "PrevButton" in sb

    preds_path = REPORTS / "per_frame_predictions.json"
    checks["per_frame_preds"] = preds_path.exists()
    walk_3537 = False
    if preds_path.exists():
        data = json.loads(_read(preds_path))
        for fr in data.get("frames", []):
            if int(fr.get("row", -1)) in (35, 37) and fr.get("predicted_label") == "walk":
                walk_3537 = True
                break
    checks["rows_35_37_not_walk"] = not walk_3537

    clips = json.loads(_read(REPORTS / "recommended_animation_clips.json")) if checks["clips_meta"] else {}
    wb = (clips.get("clips") or {}).get("walk_best") or {}
    checks["walk_best_not_rows_35_37"] = True
    checks["walk_best_row00_or_early_row01"] = False
    if isinstance(wb, dict) and not wb.get("missing"):
        sr = int(wb.get("start_row", 99))
        checks["walk_best_not_rows_35_37"] = sr not in (35, 36, 37)
        checks["walk_best_row00_or_early_row01"] = sr <= 1
    rb = (clips.get("clips") or {}).get("run_best") or {}
    checks["run_best_overlaps_row1_or_2"] = False
    if isinstance(rb, dict) and not rb.get("missing"):
        sr = int(rb.get("start_row", 99))
        er = int(rb.get("end_row", -1))
        checks["run_best_overlaps_row1_or_2"] = (sr <= 2 <= er) or sr in (1, 2)

    if isinstance(wb, dict) and wb.get("missing"):
        checks["walk_best_not_rows_35_37"] = True
        checks["walk_best_row00_or_early_row01"] = True
    if isinstance(rb, dict) and rb.get("missing"):
        checks["run_best_overlaps_row1_or_2"] = True

    tres_path = OUT / "parmida_context_classifier_spriteframes.tres"
    checks["diagnostic_tres_or_skipped"] = tres_path.exists() or (REPORTS / "context_classifier_spriteframes_report.json").exists()
    if tres_path.exists():
        tt = _read(tres_path)
        checks["tres_no_100x200"] = "100, 200" not in tt and "100,200" not in tt

    try:
        from PIL import Image

        sample = OUT / "frames" / "frame_r00_c00.png"
        checks["frame_200"] = sample.exists() and Image.open(sample).size == (200, 200) if sample.exists() else False
    except Exception:  # noqa: BLE001
        checks["frame_200"] = sample.exists() if (OUT / "frames" / "frame_r00_c00.png").exists() else False

    required = [k for k in checks if k not in ("frame_200",)]
    structural = all(checks[k] for k in required)

    out = {
        "branch": _git(["branch", "--show-current"]),
        "structural_pass": structural,
        "checks": checks,
        "note": "Visual PASS requires manual Godot sandbox + contact sheet review.",
    }
    REPORTS.mkdir(parents=True, exist_ok=True)
    (REPORTS / "validation.json").write_text(json.dumps(out, indent=2), encoding="utf-8")
    lines = ["# C2B-FIX1 validation", "", f"- **structural_pass:** {structural}", ""]
    for k, v in sorted(checks.items()):
        lines.append(f"- **{k}:** {v}")
    lines.extend(["", out["note"], ""])
    (REPORTS / "validation.md").write_text("\n".join(lines), encoding="utf-8")
    print(json.dumps({"structural_pass": structural}, indent=2))


if __name__ == "__main__":
    main()
