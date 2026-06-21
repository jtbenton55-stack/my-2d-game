#!/usr/bin/env python3
"""Phase 9 puzzle/side-job kit validator."""
from __future__ import annotations

import json
import sys
from pathlib import Path

REPORT_DIR = "phase9_puzzle_side_job_kit"


def repo_root() -> Path:
    return Path(__file__).resolve().parents[4]


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8") if path.is_file() else ""


def require_contains(errors: list[str], text: str, needle: str, label: str) -> None:
    if needle not in text:
        errors.append(f"{label} missing `{needle}`")


def main() -> int:
    root = repo_root()
    errors: list[str] = []
    warnings: list[str] = []

    terminal = root / "src/missions/iso/authoring/mechanics/TerminalHackNode.gd"
    template = root / "scenes/missions/iso/authoring/TerminalHackNodeTemplate.tscn"
    dock = root / "addons/mission_dock/MissionDock.gd"
    dev_scene = root / "scenes/dev/mission_authoring/MechanicAuthoringTestRoom.tscn"
    tests = root / "tests/mission_authoring/TerminalHackNodeTest.gd"
    roadmap = root / "docs/PLUG_AND_PLAY_MISSION_SYSTEM_ROADMAP.md"
    blueprint = root / "docs/PLUG_AND_PLAY_IMPLEMENTATION_BLUEPRINT.md"
    guide = root / "docs/MECHANIC_AUTHORING_FOUNDATION_GUIDE.md"
    report = root / "reports/ai/2026-06-20_phase9a_terminal_hack_node_report.md"

    for path in (terminal, template, dock, dev_scene, tests, roadmap, blueprint, guide, report):
        if not path.is_file():
            errors.append(f"missing required file: {path.relative_to(root)}")

    terminal_text = read_text(terminal)
    for needle in (
        "class_name TerminalHackNode",
        "LockedInteractionNode.gd",
        "func hack",
        "func set_unlocked_flag",
        "func get_hack_summary",
        "terminal_id",
        "hack_completed_flag",
    ):
        require_contains(errors, terminal_text, needle, "TerminalHackNode")

    dock_text = read_text(dock)
    for needle in (
        '"TerminalHackNode"',
        "TerminalHackNode.gd",
        "Press E: Hack terminal",
        "missing_terminal_id",
        "missing_hack_completed_flag",
    ):
        require_contains(errors, dock_text, needle, "MissionDock")

    template_text = read_text(template)
    for needle in ("TerminalHackNodeTemplate", "TerminalHackNode.gd", "CHANGE_ME_TERMINAL_ID"):
        require_contains(errors, template_text, needle, "TerminalHackNodeTemplate")

    scene_text = read_text(dev_scene)
    for needle in (
        "TerminalHackNode_phase9a_terminal",
        "phase9a_terminal",
        "phase9a_terminal_hacked",
        "phase9a_terminal_hack_effect_set",
    ):
        require_contains(errors, scene_text, needle, "MechanicAuthoringTestRoom")

    test_text = read_text(tests)
    for needle in (
        "test_terminal_hack_node_extends_locked_interaction_node",
        "test_terminal_hack_sets_completion_flag_and_effects",
        "test_interface_methods_route_to_hack",
        "test_template_and_dev_scene_contain_terminal_hack",
    ):
        require_contains(errors, test_text, needle, "TerminalHackNodeTest")

    for doc_path, label in ((roadmap, "Roadmap"), (blueprint, "Blueprint"), (guide, "Guide"), (report, "AI report")):
        doc_text = read_text(doc_path)
        require_contains(errors, doc_text, "Phase 9A", label)
        require_contains(errors, doc_text, "TerminalHackNode", label)

    result = {
        "pass": len(errors) == 0,
        "errors": errors,
        "warnings": warnings,
        "limitations": [
            "Static validator cannot execute GDScript; focused GdUnit and headless scene smoke cover runtime contracts.",
            "Phase 9A adds terminal/hack authoring only; side jobs and broader puzzle nodes remain later Phase 9 packets.",
        ],
    }
    out_dir = root / "docs/reports" / REPORT_DIR
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / "phase9_puzzle_side_job_validator_run.json").write_text(json.dumps(result, indent=2), encoding="utf-8")

    if errors:
        print("FAIL")
        for error in errors:
            print(f"  ERROR: {error}")
        for warning in warnings:
            print(f"  WARN: {warning}")
        return 1
    print("PASS")
    for warning in warnings:
        print(f"  WARN: {warning}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
