#!/usr/bin/env python3
"""Static validation for 0M-C2B (Parmida walk/run/fight discovery)."""
from __future__ import annotations

import json
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
REPORTS = ROOT / "docs/reports/character_animation_c2b"
C2B_ASSETS = ROOT / "assets/characters/generated_player_visuals/c2b_full_animation"
KIT_PREFIX = "assets/characters/pvgames_cyber_city_character_creator_kit"
EXPECTED_BRANCH = "c2a-full-character-animation-20260509-172230"


def _git(args: list[str]) -> str:
    r = subprocess.run(["git", "-C", str(ROOT), *args], capture_output=True, text=True, check=False)
    return (r.stdout or "").strip()


def _read(p: Path) -> str:
    return p.read_text(encoding="utf-8", errors="replace")


def _png_size(path: Path) -> tuple[int, int] | None:
    try:
        from PIL import Image

        with Image.open(path) as im:
            return im.size
    except Exception:
        return None


def main() -> None:
    REPORTS.mkdir(parents=True, exist_ok=True)
    checks: dict[str, bool] = {}

    branch = _git(["branch", "--show-current"])
    checks["branch_ok"] = branch == EXPECTED_BRANCH
    checks["player_tscn_clean"] = _git(["diff", "--name-only", "--", "scenes/characters/player.tscn"]) == ""
    checks["player_gd_clean"] = _git(["diff", "--name-only", "--", "src/player/Player.gd"]) == ""
    checks["taco_clean"] = _git(["diff", "--name-only", "--", "scenes/missions_iso/TacoBellIso_Editable.tscn", "scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn"]) == ""

    staged_kit = _git(["diff", "--name-only", "--", KIT_PREFIX])
    checks["raw_kit_unmodified_in_diff"] = staged_kit == ""

    checks["safety_md"] = (REPORTS / "phase0mc2b_safety_confirmation.md").exists()
    checks["safety_json"] = (REPORTS / "phase0mc2b_safety_confirmation.json").exists()
    checks["layers_md"] = (REPORTS / "phase0mc2b_selected_layers.md").exists()
    checks["layers_json"] = (REPORTS / "phase0mc2b_selected_layers.json").exists()
    checks["grid_md"] = (REPORTS / "phase0mc2b_200x200_grid_verification.md").exists()
    checks["grid_json"] = (REPORTS / "phase0mc2b_200x200_grid_verification.json").exists()
    checks["row_browser_master"] = (REPORTS / "phase0mc2b_all_rows_contact_sheet.png").exists()
    checks["row_classification_md"] = (REPORTS / "phase0mc2b_row_classification.md").exists()
    checks["row_classification_json"] = (REPORTS / "phase0mc2b_row_classification.json").exists()
    checks["row_sample_sheet"] = (REPORTS / "row_browser" / "row_00_contact_sheet.png").exists()
    checks["selection_md"] = (REPORTS / "phase0mc2b_animation_row_selection.md").exists()
    checks["selection_json"] = (REPORTS / "phase0mc2b_animation_row_selection.json").exists()
    checks["gen_report_md"] = (REPORTS / "phase0mc2b_generated_animation_report.md").exists()
    checks["gen_report_json"] = (REPORTS / "phase0mc2b_generated_animation_report.json").exists()

    checks["c2b_folder"] = C2B_ASSETS.exists()
    checks["c2b_spriteframes"] = (C2B_ASSETS / "parmida_player_spriteframes_0mc2b.tres").exists()
    checks["c2b_composite"] = (C2B_ASSETS / "parmida_player_composite_sheet_0mc2b.png").exists()
    checks["c2b_metadata"] = (C2B_ASSETS / "parmida_player_animation_metadata_0mc2b.json").exists()

    sf_txt = _read(C2B_ASSETS / "parmida_player_spriteframes_0mc2b.tres") if checks["c2b_spriteframes"] else ""
    checks["spriteframes_no_100x200"] = "100, 200" not in sf_txt and "100,200" not in sf_txt
    checks["spriteframes_uses_200"] = "200, 200" in sf_txt or "200,200" in sf_txt

    meta = {}
    if checks["c2b_metadata"]:
        meta = json.loads(_read(C2B_ASSETS / "parmida_player_animation_metadata_0mc2b.json"))
    sel = meta.get("selection", {}) if isinstance(meta, dict) else {}
    anims = meta.get("animations", {}) if isinstance(meta, dict) else {}

    checks["idle_frames_exist"] = bool(anims.get("idle", {}).get("files"))
    walk_files_meta = anims.get("walk", {}) if isinstance(anims.get("walk", {}), dict) else {}
    checks["walk_consistent_with_selection"] = (sel.get("walk_status") == "WALK_SELECTED") == bool(walk_files_meta.get("files"))
    run_list = anims.get("run", [])
    if not isinstance(run_list, list):
        run_list = []
    atk_list = anims.get("attack", [])
    if not isinstance(atk_list, list):
        atk_list = []
    checks["run_consistent"] = (sel.get("run_row") is None and len(run_list) == 0) or (sel.get("run_row") is not None and len(run_list) > 0)
    checks["attack_consistent"] = (sel.get("attack_row") is None and len(atk_list) == 0) or (sel.get("attack_row") is not None and len(atk_list) > 0)

    idle_frames = sorted((C2B_ASSETS / "frames").glob("idle_*.png")) if (C2B_ASSETS / "frames").exists() else []
    walk_frames = sorted((C2B_ASSETS / "frames").glob("walk_*.png"))
    run_frames = sorted((C2B_ASSETS / "frames").glob("run_*.png"))
    atk_frames = sorted((C2B_ASSETS / "frames").glob("attack_*.png"))
    checks["idle_all_200"] = all(_png_size(p) == (200, 200) for p in idle_frames) if idle_frames else False
    checks["walk_all_200_or_empty"] = (not walk_frames) or all(_png_size(p) == (200, 200) for p in walk_frames)
    checks["no_run_png_if_absent"] = len(run_frames) == 0
    checks["no_attack_png_if_absent"] = len(atk_frames) == 0

    checks["idle_contact"] = (REPORTS / "phase0mc2b_idle_contact_sheet.png").exists()
    checks["walk_contact_or_skipped"] = (REPORTS / "phase0mc2b_walk_contact_sheet.png").exists() or not walk_frames
    checks["combined_contact"] = (REPORTS / "phase0mc2b_combined_animation_contact_sheet.png").exists()
    checks["contact_analysis_json"] = (REPORTS / "phase0mc2b_animation_contact_sheet_analysis.json").exists()

    sandbox = _read(ROOT / "scenes/hideout/tools/CharacterAnimationSandbox_0MC2B.tscn") if (ROOT / "scenes/hideout/tools/CharacterAnimationSandbox_0MC2B.tscn").exists() else ""
    ctrl = _read(ROOT / "scenes/hideout/tools/CharacterAnimationSandbox_0MC2BController.gd") if (ROOT / "scenes/hideout/tools/CharacterAnimationSandbox_0MC2BController.gd").exists() else ""

    checks["sandbox_exists"] = "CharacterAnimationSandbox_0MC2B" in sandbox
    checks["sandbox_no_spriteframes_extresource"] = not re.search(
        r'ext_resource[^\n]*parmida_player_spriteframes_0mc2b\.tres', sandbox, re.I
    )
    checks["sandbox_frame_viewer"] = "FrameByFrameViewer" in sandbox and "PrevButton" in sandbox
    checks["controller_runtime_c2b_load"] = "load(SPRITEFRAMES_C2B)" in ctrl and "ResourceLoader.exists(SPRITEFRAMES_C2B)" in ctrl
    checks["controller_missing_labels"] = "RUN NOT FOUND SAFE" in ctrl and "ATTACK NOT FOUND SAFE" in ctrl
    checks["controller_promotion_no"] = "Production promotion allowed: NO" in ctrl

    design_md = (REPORTS / "phase0mc2b_future_production_animation_controller_design.md").exists()
    design_json = (REPORTS / "phase0mc2b_future_production_animation_controller_design.json").exists()
    checks["future_design_md"] = design_md
    checks["future_design_json"] = design_json

    final_md = (REPORTS / "phase0mc2b_full_animation_discovery.md").exists()
    final_json = (REPORTS / "phase0mc2b_full_animation_discovery.json").exists()
    checks["final_report_md"] = final_md
    checks["final_report_json"] = final_json

    required = [
        k
        for k in checks
        if k
        not in (
            "idle_all_200",
            "walk_all_200_or_empty",
        )
    ]
    structural = all(checks[k] for k in required)

    out = {
        "branch": branch,
        "expected_branch": EXPECTED_BRANCH,
        "structural_pass": structural,
        "checks": checks,
        "note": "Structural checks only; open CharacterAnimationSandbox_0MC2B.tscn in Godot for visual validation.",
    }
    (REPORTS / "phase0mc2b_validation.json").write_text(json.dumps(out, indent=2), encoding="utf-8")
    lines = [
        "# Phase 0M-C2B — Static validation",
        "",
        f"- **structural_pass:** {structural}",
        f"- **branch:** `{branch}`",
        "",
        "## Checks",
        "",
    ]
    for k, v in sorted(checks.items()):
        lines.append(f"- **{k}:** {v}")
    lines.extend(["", out["note"], ""])
    (REPORTS / "phase0mc2b_validation.md").write_text("\n".join(lines), encoding="utf-8")
    print(json.dumps({"structural_pass": structural}, indent=2))


if __name__ == "__main__":
    main()
