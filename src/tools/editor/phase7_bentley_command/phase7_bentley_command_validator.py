#!/usr/bin/env python3
"""Phase 7 Bentley command-point validator."""
from __future__ import annotations

import json
import sys
from pathlib import Path

REPORT_DIR = "phase7_bentley_command"


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

    companion_point = root / "src/missions/iso/authoring/mechanics/CompanionCommandPoint.gd"
    companion_template = root / "scenes/missions/iso/authoring/CompanionCommandPointTemplate.tscn"
    dog_companion = root / "src/player/DogCompanion.gd"
    mission_dock = root / "addons/mission_dock/MissionDock.gd"
    tests = root / "tests/mission_authoring/CompanionCommandPointTest.gd"
    dev_scene = root / "scenes/dev/mission_authoring/MechanicAuthoringTestRoom.tscn"
    roadmap = root / "docs/PLUG_AND_PLAY_MISSION_SYSTEM_ROADMAP.md"
    blueprint = root / "docs/PLUG_AND_PLAY_IMPLEMENTATION_BLUEPRINT.md"
    guide = root / "docs/MECHANIC_AUTHORING_FOUNDATION_GUIDE.md"
    report = root / "reports/ai/2026-06-20_phase7a_7d_lite_bentley_command_points_report.md"

    required_files = (
        companion_point,
        companion_template,
        dog_companion,
        mission_dock,
        tests,
        dev_scene,
        roadmap,
        blueprint,
        guide,
        report,
    )
    for path in required_files:
        if not path.is_file():
            errors.append(f"missing required file: {path.relative_to(root)}")

    point_text = read_text(companion_point)
    for needle in (
        "class_name CompanionCommandPoint",
        "extends MechanicAreaBase",
        "@export_enum(\"bark\", \"sniff\", \"fetch\")",
        "func run_command",
        "evaluate_requirements(actor)",
        "apply_success_effects(context)",
        "apply_failure_effects(context)",
        "func _find_companion",
        "command_%s",
    ):
        require_contains(errors, point_text, needle, "CompanionCommandPoint")

    dog_text = read_text(dog_companion)
    for needle in (
        "func command_bark",
        "func command_sniff",
        "func command_fetch",
        "func _try_fetch(actor",
        "get_bentley_bark_radius_multiplier",
        "EventBus.bentley_ability_used.emit(\"fetch\")",
        "reward_kind == \"item\"",
    ):
        require_contains(errors, dog_text, needle, "DogCompanion")

    dock_text = read_text(mission_dock)
    for needle in (
        "\"CompanionCommandPoint\"",
        "CompanionCommandPoint.gd",
        "Press E: Ask Bentley",
        "missing_companion_command",
    ):
        require_contains(errors, dock_text, needle, "MissionDock")

    template_text = read_text(companion_template)
    for needle in (
        "CompanionCommandPointTemplate",
        "CompanionCommandPoint.gd",
        "command_type = \"bark\"",
        "Press E: Ask Bentley",
    ):
        require_contains(errors, template_text, needle, "CompanionCommandPointTemplate")

    test_text = read_text(tests)
    for needle in (
        "test_bark_command_calls_companion_and_applies_effects",
        "test_requirement_failure_blocks_companion_command",
        "test_dog_companion_public_command_api",
        "test_dog_companion_fetch_interacts_with_fetchable_node",
        "test_dev_scene_contains_phase7_command_points",
    ):
        require_contains(errors, test_text, needle, "CompanionCommandPointTest")

    scene_text = read_text(dev_scene)
    for needle in (
        "CompanionCommandPoint_phase7_bark",
        "CompanionCommandPoint_phase7_sniff",
        "CompanionCommandPoint_phase7_fetch",
        "InventoryPickupNode_phase7_fetch_token",
        "phase7_bark_command_used",
        "phase7_sniff_command_used",
        "phase7_fetch_command_used",
        "fetch_range = 800.0",
    ):
        require_contains(errors, scene_text, needle, "MechanicAuthoringTestRoom")

    for doc_path, label in ((roadmap, "Roadmap"), (blueprint, "Blueprint"), (guide, "Guide"), (report, "AI report")):
        doc_text = read_text(doc_path)
        require_contains(errors, doc_text, "Phase 7A-7D-lite", label)
        require_contains(errors, doc_text, "CompanionCommandPoint", label)

    if "BentleyCrawlspaceConnector" not in read_text(roadmap):
        warnings.append("roadmap crawlspace future scope label not found")

    result = {
        "pass": len(errors) == 0,
        "errors": errors,
        "warnings": warnings,
        "limitations": [
            "Static validator cannot execute GDScript; focused/full GdUnit and headless scene smoke cover runtime contracts.",
            "Phase 7E-7G crawlspace, wait marker, and card-specific command tuning remain deferred.",
            "Bark currently proves the command/effect hook; full noise/listener AI is deferred to the noise/distraction phase.",
        ],
    }
    out_dir = root / "docs/reports" / REPORT_DIR
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / "phase7_bentley_command_validator_run.json").write_text(
        json.dumps(result, indent=2), encoding="utf-8"
    )

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
