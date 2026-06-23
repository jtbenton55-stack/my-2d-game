#!/usr/bin/env python3
"""Phase 11A-11F paper trail / deniability validator."""
from __future__ import annotations

import json
import sys
from pathlib import Path

REPORT_DIR = "phase11_paper_trail"


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

    trace_event = root / "src/missions/iso/runtime/paper_trail/PaperTrailTraceEvent.gd"
    adapter = root / "src/missions/iso/runtime/paper_trail/PaperTrailAdapter.gd"
    cleanup_node = root / "src/missions/iso/authoring/mechanics/AuditTrailCleanupNode.gd"
    heat_sink = root / "src/missions/iso/authoring/mechanics/HeatSinkObject.gd"
    door_memory = root / "src/missions/iso/authoring/mechanics/DoorStateMemoryNode.gd"
    fact_bridge = root / "src/missions/iso/authoring/core/MissionFactBridge.gd"
    effect = root / "src/missions/iso/authoring/core/MissionEffect.gd"
    applier = root / "src/missions/iso/authoring/core/MissionEffectApplier.gd"
    game_state = root / "src/autoload/GameState.gd"
    result_ui = root / "src/ui/MissionResult.gd"
    mission_dock = root / "addons/mission_dock/MissionDock.gd"
    templates = [
        root / "scenes/missions/iso/authoring/AuditTrailCleanupNodeTemplate.tscn",
        root / "scenes/missions/iso/authoring/HeatSinkObjectTemplate.tscn",
        root / "scenes/missions/iso/authoring/DoorStateMemoryNodeTemplate.tscn",
    ]
    dev_scene = root / "scenes/dev/mission_authoring/Phase11PaperTrailProofRoom.tscn"
    tests = root / "tests/mission_authoring/Phase11PaperTrailDeniabilityTest.gd"
    roadmap = root / "docs/PLUG_AND_PLAY_MISSION_SYSTEM_ROADMAP.md"
    blueprint = root / "docs/PLUG_AND_PLAY_IMPLEMENTATION_BLUEPRINT.md"
    report = root / "reports/ai/2026-06-22_phase11_paper_trail_deniability_report.md"

    required = [trace_event, adapter, cleanup_node, heat_sink, door_memory, fact_bridge, effect, applier, game_state, result_ui, mission_dock, dev_scene, tests, roadmap, blueprint, report, *templates]
    for path in required:
        if not path.is_file():
            errors.append(f"missing required file: {path.relative_to(root)}")

    trace_text = read_text(trace_event)
    for needle in ('class_name PaperTrailTraceEvent', 'static func make_event', '"trace_id"', '"mission_id"', '"source_id"', '"trace_type"', '"severity"', '"can_cleanup"', '"cleanup_requirement"'):
        require_contains(errors, trace_text, needle, "PaperTrailTraceEvent")

    adapter_text = read_text(adapter)
    for needle in ('class_name PaperTrailAdapter', 'static func record_trace', 'static func cleanup_traces', 'static func redirect_traces', 'static func get_summary', 'static func annotate_mission_result'):
        require_contains(errors, adapter_text, needle, "PaperTrailAdapter")

    for path, label, needles in (
        (cleanup_node, "AuditTrailCleanupNode", ('class_name AuditTrailCleanupNode', 'cleanup_trace', 'cleanup_requirement', 'cleanup_strength')),
        (heat_sink, "HeatSinkObject", ('class_name HeatSinkObject', 'redirect_trace', 'explanation_id', 'severity_reduction')),
        (door_memory, "DoorStateMemoryNode", ('class_name DoorStateMemoryNode', 'record_door_memory', 'door_state', 'PaperTrailAdapterScript.record_trace')),
    ):
        text = read_text(path)
        for needle in needles:
            require_contains(errors, text, needle, label)

    for path, label, needles in (
        (fact_bridge, "MissionFactBridge", ('paper_trace_active', 'paper_trace_type_count', 'paper_trail_result_state', 'PaperTrailAdapterScript.get_fact_value')),
        (effect, "MissionEffect", ('RECORD_PAPER_TRACE', 'CLEANUP_PAPER_TRACE', 'REDIRECT_PAPER_TRACE')),
        (applier, "MissionEffectApplier", ('_apply_record_paper_trace', '_apply_cleanup_paper_trace', '_apply_redirect_paper_trace')),
        (game_state, "GameState", ('PaperTrailAdapterScript.reset_mission', 'PaperTrailAdapterScript.annotate_mission_result')),
        (result_ui, "MissionResult", ('Paper Trail:', 'paper_trail')),
        (mission_dock, "MissionDock", ('AuditTrailCleanupNode', 'HeatSinkObject', 'DoorStateMemoryNode', 'paper_trace_active', 'RECORD_PAPER_TRACE')),
    ):
        text = read_text(path)
        for needle in needles:
            require_contains(errors, text, needle, label)

    for template in templates:
        text = read_text(template)
        require_contains(errors, text, template.stem, template.stem)

    scene_text = read_text(dev_scene)
    for needle in ('Phase11PaperTrailProofRoom', 'DoorStateMemoryNode_phase11e_door_memory', 'AuditTrailCleanupNode_phase11c_cleanup', 'HeatSinkObject_phase11d_misdirection'):
        require_contains(errors, scene_text, needle, "Phase11PaperTrailProofRoom")

    test_text = read_text(tests)
    for needle in ('test_trace_event_schema_is_inspectable', 'test_adapter_records_cleans_redirects_and_summarizes', 'test_effect_applier_routes_paper_trail_effects', 'test_mechanic_nodes_extend_base_and_change_trace_state', 'test_mission_result_receives_paper_trail_summary', 'test_templates_and_dev_scene_contain_phase11_nodes'):
        require_contains(errors, test_text, needle, "Phase11PaperTrailDeniabilityTest")

    for doc_path, label in ((roadmap, "Roadmap"), (blueprint, "Blueprint"), (report, "AI report")):
        doc_text = read_text(doc_path)
        require_contains(errors, doc_text, "Phase 11A-11F", label)
        require_contains(errors, doc_text, "PaperTrailAdapter", label)
        require_contains(errors, doc_text, "AuditTrailCleanupNode", label)
        require_contains(errors, doc_text, "HeatSinkObject", label)
        require_contains(errors, doc_text, "DoorStateMemoryNode", label)

    result = {
        "pass": len(errors) == 0,
        "errors": errors,
        "warnings": warnings,
        "limitations": [
            "Static validator cannot execute GDScript; GdUnit and headless scene smoke cover runtime contracts.",
            "Phase 11 stores paper-trail state runtime-first and intentionally does not add save-schema fields.",
        ],
    }
    out_dir = root / "docs/reports" / REPORT_DIR
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / "phase11_paper_trail_validator_run.json").write_text(json.dumps(result, indent=2), encoding="utf-8")

    if errors:
        print("FAIL")
        for error in errors:
            print(f"  ERROR: {error}")
        return 1
    print("PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
