#!/usr/bin/env python3
"""Static validation for 0M-C2A-FIX1 (sandbox repair, no production edits)."""
from __future__ import annotations

import json
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
REPORTS = ROOT / "docs/reports/character_animation_c2a"


def _git(args: list[str]) -> str:
    r = subprocess.run(
        ["git", "-C", str(ROOT), *args],
        capture_output=True,
        text=True,
        check=False,
    )
    return (r.stdout or "").strip()


def main() -> None:
    REPORTS.mkdir(parents=True, exist_ok=True)
    branch = _git(["branch", "--show-current"])
    diff_player = _git(["diff", "--name-only", "--", "scenes/characters/player.tscn"])
    diff_pg = _git(["diff", "--name-only", "--", "src/player/Player.gd"])
    diff_tb = _git(["diff", "--name-only", "--", "scenes/missions_iso/"])

    sandbox = (ROOT / "scenes/hideout/tools/CharacterAnimationSandbox_0MC2A.tscn").read_text(encoding="utf-8", errors="replace")
    ctrl = (ROOT / "scenes/hideout/tools/CharacterAnimationSandbox_0MC2AController.gd").read_text(encoding="utf-8", errors="replace")

    checks: dict[str, bool | str] = {}
    checks["branch_is_c2a"] = branch == "c2a-full-character-animation-20260509-172230"
    checks["player_tscn_untracked_or_clean"] = diff_player == ""
    checks["player_gd_untracked_or_clean"] = diff_pg == ""
    checks["taco_bell_scenes_clean"] = diff_tb == ""

    checks["sandbox_has_fix1_spriteframes_ext"] = "parmida_player_spriteframes_0mc2a_fix1.tres" in sandbox
    checks["sandbox_has_controller_script"] = "CharacterAnimationSandbox_0MC2AController.gd" in sandbox
    checks["sandbox_has_old_placeholder"] = "old_player_token_reference_0mc2.png" in sandbox
    checks["sandbox_has_static_parmida"] = "parmida_player_visual_0mc2.png" in sandbox
    checks["sandbox_has_AnimatedParmidaReference"] = "AnimatedParmidaReference" in sandbox
    checks["sandbox_has_DebugPanel"] = "DebugPanel" in sandbox and "DebugLabel" in sandbox
    checks["sandbox_has_BaselineGuide"] = "BaselineGuide" in sandbox
    checks["sandbox_has_ReferenceGrid"] = "ReferenceGrid" in sandbox
    checks["sandbox_no_PlayerVisualAnimator_on_animated"] = "PlayerVisualAnimator.gd" not in sandbox

    checks["controller_mentions_fix1_path"] = "parmida_player_spriteframes_0mc2a_fix1.tres" in ctrl
    checks["controller_mentions_fallback_frame"] = "idle_frame_00.png" in ctrl

    sf_fix1 = ROOT / "assets/characters/generated_player_visuals/c2a_animation/parmida_player_spriteframes_0mc2a_fix1.tres"
    sf_txt = sf_fix1.read_text(encoding="utf-8", errors="replace") if sf_fix1.exists() else ""
    checks["fix1_spriteframes_exists"] = sf_fix1.exists()
    checks["fix1_has_name_idle"] = '"name": "idle"' in sf_txt
    checks["fix1_has_name_walk"] = '"name": "walk"' in sf_txt
    checks["fix1_has_frames_arrays"] = "SubResource(\"idle_0\")" in sf_txt and "SubResource(\"walk_0\")" in sf_txt

    composite = ROOT / "assets/characters/generated_player_visuals/c2a_animation/parmida_player_composite_sheet_0mc2a.png"
    checks["composite_png_exists"] = composite.exists()

    backup = ROOT / "assets/characters/generated_player_visuals/c2a_animation/parmida_player_spriteframes_0mc2a.broken_format_backup_0mc2a_fix1.tres"
    checks["legacy_spriteframes_backup_exists"] = backup.exists()

    vgd = ROOT / "src/tools/editor/CharacterAnimationC2AFix1Validator.gd"
    checks["fix1_editor_validator_gd_exists"] = vgd.exists()

    # PASS if structural checks OK (cannot prove runtime visibility without Godot)
    hard_fail = not bool(checks["branch_is_c2a"])
    hard_fail = hard_fail or diff_player != "" or diff_pg != "" or diff_tb != ""

    structural = all(
        bool(checks[k])
        for k in (
            "fix1_spriteframes_exists",
            "fix1_has_name_idle",
            "fix1_has_name_walk",
            "sandbox_has_fix1_spriteframes_ext",
            "sandbox_has_controller_script",
            "sandbox_has_AnimatedParmidaReference",
            "sandbox_has_DebugPanel",
            "sandbox_has_BaselineGuide",
            "sandbox_has_ReferenceGrid",
            "sandbox_no_PlayerVisualAnimator_on_animated",
            "legacy_spriteframes_backup_exists",
            "fix1_editor_validator_gd_exists",
        )
    )

    result = {
        "branch": branch,
        "git_diff_player_tscn": diff_player or "(none)",
        "git_diff_player_gd": diff_pg or "(none)",
        "git_diff_taco_bell": diff_tb or "(none)",
        "checks": checks,
        "structural_pass": structural and not hard_fail,
        "note": "Runtime visibility must be confirmed in Godot (F6 on sandbox scene).",
    }
    out = REPORTS / "phase0mc2a_fix1_sandbox_validation.json"
    out.write_text(json.dumps(result, indent=2), encoding="utf-8")
    print(json.dumps({"structural_pass": result["structural_pass"], "wrote": str(out)}, indent=2))


if __name__ == "__main__":
    main()
