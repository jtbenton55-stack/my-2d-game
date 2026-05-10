#!/usr/bin/env python3
"""Static validation for 0M-C2A-FIX3."""
from __future__ import annotations

import json
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
REPORTS = ROOT / "docs/reports/character_animation_c2a"
FIX3 = ROOT / "assets/characters/generated_player_visuals/c2a_animation/fix3_stable"


def _git(args: list[str]) -> str:
    r = subprocess.run(["git", "-C", str(ROOT), *args], capture_output=True, text=True, check=False)
    return (r.stdout or "").strip()


def _read(p: Path) -> str:
    return p.read_text(encoding="utf-8", errors="replace")


def main() -> None:
    REPORTS.mkdir(parents=True, exist_ok=True)
    checks: dict[str, bool] = {}

    checks["branch_ok"] = _git(["branch", "--show-current"]) == "c2a-full-character-animation-20260509-172230"
    checks["player_tscn_clean"] = _git(["diff", "--name-only", "--", "scenes/characters/player.tscn"]) == ""
    checks["player_gd_clean"] = _git(["diff", "--name-only", "--", "src/player/Player.gd"]) == ""
    checks["taco_clean"] = _git(["diff", "--name-only", "--", "scenes/missions_iso/"]) == ""

    checks["prior_inventory_exists"] = (REPORTS / "phase0mc2a_fix3_prior_data_inventory.json").exists()
    checks["bad_idle_sheet_exists"] = (REPORTS / "phase0mc2a_fix3_current_bad_idle_frames.png").exists()
    checks["bad_walk_sheet_exists"] = (REPORTS / "phase0mc2a_fix3_current_bad_walk_frames.png").exists()
    checks["forensic_100_exists"] = (REPORTS / "phase0mc2a_fix3_frame_size_forensic_100x200.png").exists()
    checks["forensic_200_exists"] = (REPORTS / "phase0mc2a_fix3_frame_size_forensic_200x200.png").exists()
    checks["forensic_comparison_exists"] = (REPORTS / "phase0mc2a_fix3_frame_size_forensic_comparison.png").exists()
    checks["frame_size_decision_exists"] = (REPORTS / "phase0mc2a_fix3_frame_size_decision.json").exists()
    checks["grid_verify_exists"] = (REPORTS / "phase0mc2a_fix3_source_layer_grid_verification.json").exists()

    checks["fix3_folder_exists"] = FIX3.exists()
    checks["fix3_spriteframes_exists"] = (FIX3 / "parmida_player_spriteframes_0mc2a_fix3.tres").exists()
    checks["fix3_composite_exists"] = (FIX3 / "parmida_player_composite_sheet_0mc2a_fix3.png").exists()
    checks["fix3_metadata_exists"] = (FIX3 / "parmida_player_animation_metadata_0mc2a_fix3.json").exists()
    checks["stable_contact_sheet_exists"] = (REPORTS / "phase0mc2a_fix3_stable_frames_contact_sheet.png").exists()

    sf_txt = _read(FIX3 / "parmida_player_spriteframes_0mc2a_fix3.tres")
    checks["no_nested_animations_idle_bug"] = '"animations/idle"' not in sf_txt
    checks["has_idle_name"] = '"name": "idle"' in sf_txt
    checks["uses_subresource_idle0"] = 'SubResource("idle_0")' in sf_txt

    meta = json.loads(_read(FIX3 / "parmida_player_animation_metadata_0mc2a_fix3.json"))
    walk_files = sorted((FIX3 / "frames").glob("walk_*.png"))
    checks["metadata_walk_matches_files"] = meta["walk"]["included"] == (len(walk_files) > 0)

    idle_files = sorted((FIX3 / "frames").glob("idle_*.png"))
    checks["idle_frame_count_sane"] = 1 <= len(idle_files) <= 10
    checks["idle_frames_same_size"] = True
    if idle_files:
        from PIL import Image

        sizes = {Image.open(p).size for p in idle_files}
        fw, fh = int(meta["frame_width"]), int(meta["frame_height"])
        checks["idle_frames_same_size"] = sizes == {(fw, fh)}

    fq = json.loads(_read(REPORTS / "phase0mc2a_fix3_frame_quality.json"))
    idle_tags = fq.get("idle", {}).get("per_frame_tags", [])
    checks["full_body_automated_ok"] = all(t == "FULL_BODY" for t in idle_tags) if idle_tags else False
    checks["anchor_ok_or_reported"] = fq.get("idle", {}).get("foot_bottom_std") is not None

    ctrl = _read(ROOT / "scenes/hideout/tools/CharacterAnimationSandbox_0MC2AController.gd")
    checks["controller_fix3_primary"] = "SPRITEFRAMES_FIX3" in ctrl and "parmida_player_spriteframes_0mc2a_fix3.tres" in ctrl
    checks["controller_not_fix2_primary_order"] = ctrl.find("SPRITEFRAMES_FIX3") < ctrl.find("SPRITEFRAMES_FIX2")

    sandbox = _read(ROOT / "scenes/hideout/tools/CharacterAnimationSandbox_0MC2A.tscn")
    checks["sandbox_has_frame_viewer"] = "FrameByFrameViewer" in sandbox
    checks["sandbox_has_debug"] = "DebugPanel" in sandbox and "DebugLabel" in sandbox
    checks["sandbox_no_hardcoded_fix1_spriteframes"] = not re.search(
        r'sprite_frames\s*=\s*ExtResource.*fix1', sandbox
    )

    final_rep = (REPORTS / "phase0mc2a_fix3_stable_animation.json").exists()
    checks["final_report_exists"] = final_rep

    required = [k for k in checks if k not in ("full_body_automated_ok",)]
    structural = all(checks[k] for k in required)

    out = {
        "branch": _git(["branch", "--show-current"]),
        "structural_pass": structural,
        "full_body_automated_pass": checks["full_body_automated_ok"],
        "overall_status": "PARTIAL" if structural else "FAIL",
        "checks": checks,
        "note": "Structural pass does not equal visual PASS; review contact sheets + run sandbox in Godot.",
    }
    (REPORTS / "phase0mc2a_fix3_validation.json").write_text(json.dumps(out, indent=2), encoding="utf-8")
    lines = [
        "# Phase 0M-C2A-FIX3 — Static validation",
        "",
        f"- **structural_pass:** {structural}",
        f"- **full_body_automated_pass:** {checks['full_body_automated_ok']}",
        f"- **overall_status:** {out['overall_status']}",
        "",
        "## Checks",
        "",
    ]
    for k, v in sorted(checks.items()):
        lines.append(f"- **{k}:** {v}")
    lines.extend(["", out["note"], ""])
    (REPORTS / "phase0mc2a_fix3_validation.md").write_text("\n".join(lines), encoding="utf-8")
    print(json.dumps({"structural_pass": structural, "full_body_automated_pass": checks["full_body_automated_ok"]}, indent=2))


if __name__ == "__main__":
    main()
