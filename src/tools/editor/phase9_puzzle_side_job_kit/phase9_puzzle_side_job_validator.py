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
    power_circuit = root / "src/missions/iso/authoring/mechanics/PowerCircuitNode.gd"
    timed_switch = root / "src/missions/iso/authoring/mechanics/TimedSwitchNode.gd"
    pressure_plate = root / "src/missions/iso/authoring/mechanics/PressurePlateNode.gd"
    template = root / "scenes/missions/iso/authoring/TerminalHackNodeTemplate.tscn"
    power_template = root / "scenes/missions/iso/authoring/PowerCircuitNodeTemplate.tscn"
    switch_template = root / "scenes/missions/iso/authoring/TimedSwitchNodeTemplate.tscn"
    plate_template = root / "scenes/missions/iso/authoring/PressurePlateNodeTemplate.tscn"
    dock = root / "addons/mission_dock/MissionDock.gd"
    dev_scene = root / "scenes/dev/mission_authoring/MechanicAuthoringTestRoom.tscn"
    tests = root / "tests/mission_authoring/TerminalHackNodeTest.gd"
    phase9b_tests = root / "tests/mission_authoring/Phase9BPowerPuzzleNodeTest.gd"
    roadmap = root / "docs/PLUG_AND_PLAY_MISSION_SYSTEM_ROADMAP.md"
    blueprint = root / "docs/PLUG_AND_PLAY_IMPLEMENTATION_BLUEPRINT.md"
    guide = root / "docs/MECHANIC_AUTHORING_FOUNDATION_GUIDE.md"
    report = root / "reports/ai/2026-06-20_phase9a_terminal_hack_node_report.md"
    phase9b_report = root / "reports/ai/2026-06-20_phase9b_power_puzzle_nodes_report.md"

    for path in (
        terminal,
        power_circuit,
        timed_switch,
        pressure_plate,
        template,
        power_template,
        switch_template,
        plate_template,
        dock,
        dev_scene,
        tests,
        phase9b_tests,
        roadmap,
        blueprint,
        guide,
        report,
        phase9b_report,
    ):
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
        '"PowerCircuitNode"',
        '"TimedSwitchNode"',
        '"PressurePlateNode"',
        "TerminalHackNode.gd",
        "PowerCircuitNode.gd",
        "TimedSwitchNode.gd",
        "PressurePlateNode.gd",
        "Press E: Hack terminal",
        "Press E: Check circuit",
        "Press E: Trigger switch",
        "Step onto pressure plate",
        "missing_terminal_id",
        "missing_hack_completed_flag",
        "missing_circuit_id",
        "missing_switch_id",
        "missing_plate_id",
    ):
        require_contains(errors, dock_text, needle, "MissionDock")

    for path, label, needles in (
        (
            power_circuit,
            "PowerCircuitNode",
            (
                "class_name PowerCircuitNode",
                "extends MechanicAreaBase",
                "required_power_flags",
                "func check_circuit",
                "func get_circuit_summary",
                "MissionFactBridge.set_fact_value",
            ),
        ),
        (
            timed_switch,
            "TimedSwitchNode",
            (
                "class_name TimedSwitchNode",
                "extends MechanicAreaBase",
                "switch_flag",
                "func trigger_switch",
                "func refresh_timer_state",
                "func get_switch_summary",
            ),
        ),
        (
            pressure_plate,
            "PressurePlateNode",
            (
                "class_name PressurePlateNode",
                "extends MechanicAreaBase",
                "pressed_flag",
                "func press",
                "func release",
                "func get_plate_summary",
            ),
        ),
    ):
        text = read_text(path)
        for needle in needles:
            require_contains(errors, text, needle, label)

    template_text = read_text(template)
    for needle in ("TerminalHackNodeTemplate", "TerminalHackNode.gd", "CHANGE_ME_TERMINAL_ID"):
        require_contains(errors, template_text, needle, "TerminalHackNodeTemplate")
    for path, label, needles in (
        (power_template, "PowerCircuitNodeTemplate", ("PowerCircuitNodeTemplate", "PowerCircuitNode.gd", "CHANGE_ME_CIRCUIT_ID")),
        (switch_template, "TimedSwitchNodeTemplate", ("TimedSwitchNodeTemplate", "TimedSwitchNode.gd", "CHANGE_ME_SWITCH_ID")),
        (plate_template, "PressurePlateNodeTemplate", ("PressurePlateNodeTemplate", "PressurePlateNode.gd", "CHANGE_ME_PLATE_ID")),
    ):
        text = read_text(path)
        for needle in needles:
            require_contains(errors, text, needle, label)

    scene_text = read_text(dev_scene)
    for needle in (
        "TerminalHackNode_phase9a_terminal",
        "phase9a_terminal",
        "phase9a_terminal_hacked",
        "phase9a_terminal_hack_effect_set",
        "PowerCircuitNode_phase9b_circuit",
        "TimedSwitchNode_phase9b_switch",
        "PressurePlateNode_phase9b_plate",
        "phase9b_switch_active",
        "phase9b_plate_pressed",
        "phase9b_circuit_powered",
    ):
        require_contains(errors, scene_text, needle, "MechanicAuthoringTestRoom")

    test_text = read_text(tests)
    for needle in (
        "test_phase9b_nodes_extend_mechanic_area_base",
        "test_timed_switch_sets_and_expires_mission_flag",
        "test_pressure_plate_sets_and_clears_pressed_flag",
        "test_power_circuit_requires_linked_flags_before_powering",
        "test_templates_and_dev_scene_contain_phase9b_nodes",
    ):
        require_contains(errors, read_text(phase9b_tests), needle, "Phase9BPowerPuzzleNodeTest")

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
    for doc_path, label in ((roadmap, "Roadmap"), (blueprint, "Blueprint"), (guide, "Guide"), (phase9b_report, "Phase 9B AI report")):
        doc_text = read_text(doc_path)
        require_contains(errors, doc_text, "Phase 9B", label)
        require_contains(errors, doc_text, "PowerCircuitNode", label)
        require_contains(errors, doc_text, "TimedSwitchNode", label)
        require_contains(errors, doc_text, "PressurePlateNode", label)

    result = {
        "pass": len(errors) == 0,
        "errors": errors,
        "warnings": warnings,
        "limitations": [
            "Static validator cannot execute GDScript; focused GdUnit and headless scene smoke cover runtime contracts.",
            "Phase 9B adds power circuits, timed switches, and pressure plates only; side jobs and custom sequences remain later Phase 9 packets.",
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
