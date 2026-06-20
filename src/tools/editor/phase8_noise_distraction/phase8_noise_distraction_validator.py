#!/usr/bin/env python3
"""Phase 8A-8D-lite noise/distraction validator."""
from __future__ import annotations

import json
import sys
from pathlib import Path

REPORT_DIR = "phase8_noise_distraction"


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

    noise_event = root / "src/missions/iso/runtime/noise/NoiseEvent.gd"
    noise_emitter = root / "src/missions/iso/runtime/noise/NoiseEmitterNode.gd"
    distraction = root / "src/missions/iso/authoring/mechanics/DistractionObject.gd"
    event_bus = root / "src/utils/EventBus.gd"
    alert_controller = root / "src/missions/iso/runtime/MissionAlertController.gd"
    dog_companion = root / "src/player/DogCompanion.gd"
    mission_dock = root / "addons/mission_dock/MissionDock.gd"
    debug_panel = root / "src/missions/iso/runtime/IsoMissionDebugPanel.gd"
    noise_template = root / "scenes/missions/iso/authoring/NoiseEmitterNodeTemplate.tscn"
    distraction_template = root / "scenes/missions/iso/authoring/DistractionObjectTemplate.tscn"
    dev_scene = root / "scenes/dev/mission_authoring/MechanicAuthoringTestRoom.tscn"
    tests = root / "tests/mission_authoring/NoiseDistractionTest.gd"
    roadmap = root / "docs/PLUG_AND_PLAY_MISSION_SYSTEM_ROADMAP.md"
    blueprint = root / "docs/PLUG_AND_PLAY_IMPLEMENTATION_BLUEPRINT.md"
    guide = root / "docs/MECHANIC_AUTHORING_FOUNDATION_GUIDE.md"
    report = root / "reports/ai/2026-06-20_phase8a_8d_lite_noise_distraction_report.md"

    required_files = (
        noise_event,
        noise_emitter,
        distraction,
        event_bus,
        alert_controller,
        dog_companion,
        mission_dock,
        debug_panel,
        noise_template,
        distraction_template,
        dev_scene,
        tests,
        roadmap,
        blueprint,
        guide,
        report,
    )
    for path in required_files:
        if not path.is_file():
            errors.append(f"missing required file: {path.relative_to(root)}")

    event_text = read_text(noise_event)
    for needle in (
        "class_name NoiseEvent",
        "static func make_event",
        '"noise_id"',
        '"source_id"',
        '"position"',
        '"radius"',
        '"strength"',
        '"kind"',
        '"team"',
        "static func is_point_in_range",
    ):
        require_contains(errors, event_text, needle, "NoiseEvent")

    emitter_text = read_text(noise_emitter)
    for needle in (
        "class_name NoiseEmitterNode",
        "extends \"res://src/missions/iso/authoring/mechanics/MechanicAreaBase.gd\"",
        "func emit_noise",
        "mission_noise_emitted.emit",
        "register_noise_event",
        "func get_noise_summary",
    ):
        require_contains(errors, emitter_text, needle, "NoiseEmitterNode")

    distraction_text = read_text(distraction)
    for needle in (
        "class_name DistractionObject",
        "NoiseEmitterNode.gd",
        'noise_kind = "decoy"',
        'noise_team = "player"',
    ):
        require_contains(errors, distraction_text, needle, "DistractionObject")

    for path, label, needles in (
        (event_bus, "EventBus", ("signal mission_noise_emitted",)),
        (alert_controller, "MissionAlertController", ("signal noise_event_registered", "func register_noise_event", "func get_noise_debug_summary", "add_to_group(\"iso_alert_controller\")")),
        (dog_companion, "DogCompanion", ("NoiseEventHelper", "_emit_noise_event", "last_noise_result", "register_noise_event")),
        (debug_panel, "IsoMissionDebugPanel", ("noise_events=", "get_noise_debug_summary")),
    ):
        text = read_text(path)
        for needle in needles:
            require_contains(errors, text, needle, label)

    dock_text = read_text(mission_dock)
    for needle in (
        '"NoiseEmitterNode"',
        '"DistractionObject"',
        "NoiseEmitterNode.gd",
        "DistractionObject.gd",
        "Press E: Emit noise",
        "Press E: Create distraction",
        "missing_noise_id",
    ):
        require_contains(errors, dock_text, needle, "MissionDock")

    for template_path, label, script_name in (
        (noise_template, "NoiseEmitterNodeTemplate", "NoiseEmitterNode.gd"),
        (distraction_template, "DistractionObjectTemplate", "DistractionObject.gd"),
    ):
        template_text = read_text(template_path)
        require_contains(errors, template_text, label, label)
        require_contains(errors, template_text, script_name, label)

    scene_text = read_text(dev_scene)
    for needle in (
        "MissionAlertController",
        "NoiseEmitterNode_phase8a_bark_lure",
        "DistractionObject_phase8d_decoy",
        "phase8_noise_emitted",
        "phase8_distraction_used",
    ):
        require_contains(errors, scene_text, needle, "MechanicAuthoringTestRoom")

    test_text = read_text(tests)
    for needle in (
        "test_noise_event_schema_and_range_helper",
        "test_noise_emitter_applies_effect_and_routes_to_alert_controller",
        "test_bentley_bark_emits_noise_event_to_alert_controller",
        "test_distraction_object_defaults_to_player_decoy_noise",
        "test_templates_and_dev_scene_contain_phase8_nodes",
    ):
        require_contains(errors, test_text, needle, "NoiseDistractionTest")

    for doc_path, label in ((roadmap, "Roadmap"), (blueprint, "Blueprint"), (guide, "Guide"), (report, "AI report")):
        doc_text = read_text(doc_path)
        require_contains(errors, doc_text, "Phase 8A-8D-lite", label)
        require_contains(errors, doc_text, "NoiseEmitterNode", label)
        require_contains(errors, doc_text, "DistractionObject", label)

    if "NoiseListenerComponent" not in read_text(blueprint):
        warnings.append("blueprint no longer mentions future listener component")

    result = {
        "pass": len(errors) == 0,
        "errors": errors,
        "warnings": warnings,
        "limitations": [
            "Static validator cannot execute GDScript; GdUnit and headless scene smoke cover runtime contracts.",
            "Phase 8A-8D-lite records and routes noise events, but full guard listener/pathing AI remains deferred.",
            "Production Taco placement remains deferred pending manual mission-design placement.",
        ],
    }
    out_dir = root / "docs/reports" / REPORT_DIR
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / "phase8_noise_distraction_validator_run.json").write_text(json.dumps(result, indent=2), encoding="utf-8")

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
