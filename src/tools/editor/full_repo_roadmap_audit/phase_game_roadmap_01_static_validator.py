"""
PHASE GAME-ROADMAP-01 — Static validator

Verifies:
1. All required reports exist (markdown + json pairs per phase).
2. JSON reports are parseable and have the expected hard-assertion flags = true.
3. Single best next action / next 3 / next 10 / avoid-now lists are present in
   `phase7_prioritized_roadmap.json`.
4. Protected gameplay files were NOT modified by this pass (no diff entries since
   the audit folder was created).

The validator is intentionally conservative: it reads files only, never modifies
the repo, never depends on Godot being installed. It writes a machine-readable
run report next to itself for downstream consumption.
"""

from __future__ import annotations

import json
import os
import subprocess
import sys
from pathlib import Path
from typing import Any, Dict, List, Tuple

REPO_ROOT = Path(__file__).resolve().parents[4]
AUDIT_DIR = REPO_ROOT / "docs" / "reports" / "full_repo_roadmap_audit"
VALIDATOR_DIR = REPO_ROOT / "src" / "tools" / "editor" / "full_repo_roadmap_audit"

REQUIRED_REPORTS: List[Tuple[str, str]] = [
    ("phase0_safety_baseline.md", "phase0_safety_baseline.json"),
    ("phase1_full_repo_inventory.md", "phase1_full_repo_inventory.json"),
    ("phase2_current_game_state.md", "phase2_current_game_state.json"),
    ("phase2b_mission_bible_alignment_audit.md", "phase2b_mission_bible_alignment_audit.json"),
    ("phase3_system_health_audit.md", "phase3_system_health_audit.json"),
    ("phase4_documentation_truth_reconciliation.md", "phase4_documentation_truth_reconciliation.json"),
    ("phase5_architecture_risk_audit.md", "phase5_architecture_risk_audit.json"),
    ("phase6_feature_opportunity_audit.md", "phase6_feature_opportunity_audit.json"),
    ("phase7_prioritized_roadmap.md", "phase7_prioritized_roadmap.json"),
    ("phase8_next_prompt_recommendation.md", "phase8_next_prompt_recommendation.json"),
]

REQUIRED_ASSERTIONS: Dict[str, List[str]] = {
    "phase0_safety_baseline.json": [
        "repo_root_confirmed",
        "current_branch_recorded",
        "git_status_recorded",
        "audit_only_mode",
        "protected_gameplay_files_unmodified_pre_pass",
        "taco_scenes_unmodified_pre_pass",
        "project_godot_unmodified_pre_pass",
        "player_gd_unmodified_pre_pass",
        "raw_assets_unmodified_pre_pass",
    ],
    "phase1_full_repo_inventory.json": [
        "repo_inventory_completed",
        "major_systems_identified",
    ],
    "phase2_current_game_state.json": [
        "current_game_state_summarized",
        "playable_loop_identified_or_missing_reported",
    ],
    "phase2b_mission_bible_alignment_audit.json": [
        "mission_bible_searched",
        "mission_bible_found_or_missing_reported",
        "mission_bible_alignment_audit_created",
        "mission_list_compared_to_repo",
        "core_loop_compared_to_repo",
        "roadmap_implications_extracted",
    ],
    "phase3_system_health_audit.json": [
        "system_health_audit_completed",
        "each_major_system_classified",
    ],
    "phase4_documentation_truth_reconciliation.json": [
        "documentation_reconciled",
        "stale_reports_identified",
        "conflicting_guidance_identified_or_none",
    ],
    "phase5_architecture_risk_audit.json": [
        "architecture_risks_identified",
        "highest_risks_prioritized",
    ],
    "phase6_feature_opportunity_audit.json": [
        "feature_opportunities_identified",
        "features_prioritized_by_timing",
    ],
    "phase7_prioritized_roadmap.json": [
        "roadmap_created",
        "single_best_next_action_identified",
        "next_3_actions_identified",
        "next_10_actions_identified",
        "avoid_now_list_created",
    ],
    "phase8_next_prompt_recommendation.json": [
        "next_prompt_recommendation_created",
        "recommendation_based_on_full_audit",
    ],
}

PROTECTED_FILES: List[str] = [
    "project.godot",
    "src/player/Player.gd",
    "src/player/PlayerStaminaController.gd",
    "scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn",
    "scenes/missions_iso/TacoBellIso_Editable.tscn",
    "scenes/missions/TacoBellMission.tscn",
    "scenes/hideout/HideoutHub.tscn",
]

PROTECTED_DIR_PREFIXES: List[str] = [
    "assets/",
]


def _add(check: Dict[str, Any], key: str, ok: bool, detail: str = "") -> None:
    check[key] = {"pass": ok, "detail": detail}


def _git(args: List[str]) -> Tuple[int, str, str]:
    try:
        result = subprocess.run(
            ["git", *args],
            cwd=str(REPO_ROOT),
            capture_output=True,
            text=True,
            check=False,
        )
        return result.returncode, result.stdout, result.stderr
    except FileNotFoundError:
        return 127, "", "git not found"


def check_required_reports(check: Dict[str, Any]) -> None:
    for md_name, json_name in REQUIRED_REPORTS:
        md_path = AUDIT_DIR / md_name
        json_path = AUDIT_DIR / json_name
        _add(check, f"report_exists::{md_name}", md_path.is_file(), str(md_path))
        _add(check, f"report_exists::{json_name}", json_path.is_file(), str(json_path))


def check_json_parseable_and_assertions(check: Dict[str, Any]) -> None:
    for json_name, asserted_keys in REQUIRED_ASSERTIONS.items():
        json_path = AUDIT_DIR / json_name
        if not json_path.is_file():
            _add(check, f"json_parses::{json_name}", False, "missing")
            continue
        try:
            data = json.loads(json_path.read_text(encoding="utf-8"))
            _add(check, f"json_parses::{json_name}", True, "")
        except Exception as exc:
            _add(check, f"json_parses::{json_name}", False, f"parse error: {exc}")
            continue
        assertions = data.get("assertions", {}) if isinstance(data, dict) else {}
        for key in asserted_keys:
            value = bool(assertions.get(key, False))
            _add(
                check,
                f"assert::{json_name}::{key}",
                value,
                "true" if value else "missing or false",
            )


def check_roadmap_has_required_lists(check: Dict[str, Any]) -> None:
    json_path = AUDIT_DIR / "phase7_prioritized_roadmap.json"
    if not json_path.is_file():
        _add(check, "roadmap::file_exists", False, "missing")
        return
    try:
        data = json.loads(json_path.read_text(encoding="utf-8"))
    except Exception as exc:
        _add(check, "roadmap::parse", False, str(exc))
        return
    _add(check, "roadmap::single_best_next_action", bool(data.get("single_best_next_action")), str(data.get("single_best_next_action", "")))
    n3 = data.get("next_3_actions", []) or []
    _add(check, "roadmap::next_3_actions", len(n3) == 3, f"count={len(n3)}")
    n10 = data.get("next_10_actions", []) or []
    _add(check, "roadmap::next_10_actions", len(n10) == 10, f"count={len(n10)}")
    avoid = data.get("avoid_now_list", []) or []
    _add(check, "roadmap::avoid_now_list", len(avoid) >= 1, f"count={len(avoid)}")


def check_protected_files_clean(check: Dict[str, Any]) -> None:
    rc, out, err = _git(["status", "--porcelain"])
    if rc != 0:
        _add(check, "git::status", False, err.strip() or out.strip())
        return
    _add(check, "git::status", True, "ok")
    modified: List[str] = []
    for line in out.splitlines():
        line = line.rstrip()
        if not line:
            continue
        path = line[3:].strip()
        # ignore quoted paths that include spaces (basic strip is fine here)
        for protected in PROTECTED_FILES:
            if path == protected:
                modified.append(path)
        for prefix in PROTECTED_DIR_PREFIXES:
            if path.startswith(prefix):
                modified.append(path)
    _add(
        check,
        "protected::no_modifications",
        len(modified) == 0,
        f"modified={modified}" if modified else "none",
    )
    # Targeted protected-file diff checks (in case status is empty but a file changed quietly)
    diff_rc, diff_out, diff_err = _git(["diff", "--name-only"])
    if diff_rc == 0:
        diff_files = [l.strip() for l in diff_out.splitlines() if l.strip()]
        for protected in PROTECTED_FILES:
            _add(
                check,
                f"protected::diff::{protected}",
                protected not in diff_files,
                "modified" if protected in diff_files else "clean",
            )
    else:
        _add(check, "protected::diff::git_failed", False, diff_err.strip())


def main() -> int:
    summary: Dict[str, Any] = {
        "ok": True,
        "repo_root": str(REPO_ROOT),
        "audit_dir": str(AUDIT_DIR),
        "checks": {},
        "warnings": [],
    }

    check_required_reports(summary["checks"])
    check_json_parseable_and_assertions(summary["checks"])
    check_roadmap_has_required_lists(summary["checks"])
    check_protected_files_clean(summary["checks"])

    for key, value in summary["checks"].items():
        if not value.get("pass", False):
            summary["ok"] = False

    out_path = AUDIT_DIR / "phase_game_roadmap_01_static_validator_run.json"
    out_path.write_text(json.dumps(summary, indent=2), encoding="utf-8")

    print(json.dumps({"ok": summary["ok"], "out": str(out_path), "fail_count": sum(1 for v in summary["checks"].values() if not v.get("pass"))}, indent=2))
    return 0 if summary["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
