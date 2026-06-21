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
    dead_drop = root / "src/missions/iso/authoring/mechanics/DeadDropNode.gd"
    object_swap = root / "src/missions/iso/authoring/mechanics/ObjectSwapNode.gd"
    bug_plant = root / "src/missions/iso/authoring/mechanics/BugPlantNode.gd"
    eavesdrop = root / "src/missions/iso/authoring/mechanics/EavesdropZone.gd"
    sequence_step = root / "src/missions/iso/authoring/sequences/CustomSequenceStep.gd"
    sequence_resource = root / "src/missions/iso/authoring/sequences/CustomSequenceResource.gd"
    sequence_runner = root / "src/missions/iso/authoring/sequences/CustomSequenceRunner.gd"
    template = root / "scenes/missions/iso/authoring/TerminalHackNodeTemplate.tscn"
    power_template = root / "scenes/missions/iso/authoring/PowerCircuitNodeTemplate.tscn"
    switch_template = root / "scenes/missions/iso/authoring/TimedSwitchNodeTemplate.tscn"
    plate_template = root / "scenes/missions/iso/authoring/PressurePlateNodeTemplate.tscn"
    dead_drop_template = root / "scenes/missions/iso/authoring/DeadDropNodeTemplate.tscn"
    object_swap_template = root / "scenes/missions/iso/authoring/ObjectSwapNodeTemplate.tscn"
    bug_plant_template = root / "scenes/missions/iso/authoring/BugPlantNodeTemplate.tscn"
    eavesdrop_template = root / "scenes/missions/iso/authoring/EavesdropZoneTemplate.tscn"
    dock = root / "addons/mission_dock/MissionDock.gd"
    dev_scene = root / "scenes/dev/mission_authoring/MechanicAuthoringTestRoom.tscn"
    side_job_scene = root / "scenes/dev/mission_authoring/Phase9SideJobProofRoom.tscn"
    taco_scene = root / "scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn"
    tests = root / "tests/mission_authoring/TerminalHackNodeTest.gd"
    phase9b_tests = root / "tests/mission_authoring/Phase9BPowerPuzzleNodeTest.gd"
    phase9c_to_9f_tests = root / "tests/mission_authoring/Phase9CTo9FPuzzleSideJobNodeTest.gd"
    phase9g_to_9i_tests = root / "tests/mission_authoring/Phase9GTo9ISideJobCompletionTest.gd"
    roadmap = root / "docs/PLUG_AND_PLAY_MISSION_SYSTEM_ROADMAP.md"
    blueprint = root / "docs/PLUG_AND_PLAY_IMPLEMENTATION_BLUEPRINT.md"
    guide = root / "docs/MECHANIC_AUTHORING_FOUNDATION_GUIDE.md"
    report = root / "reports/ai/2026-06-20_phase9a_terminal_hack_node_report.md"
    phase9b_report = root / "reports/ai/2026-06-20_phase9b_power_puzzle_nodes_report.md"
    phase9c_to_9f_report = root / "reports/ai/2026-06-21_phase9c_9f_puzzle_side_job_nodes_report.md"
    phase9g_to_9i_report = root / "reports/ai/2026-06-21_phase9g_9i_side_job_completion_report.md"

    for path in (
        terminal,
        power_circuit,
        timed_switch,
        pressure_plate,
        dead_drop,
        object_swap,
        bug_plant,
        eavesdrop,
        sequence_step,
        sequence_resource,
        sequence_runner,
        template,
        power_template,
        switch_template,
        plate_template,
        dead_drop_template,
        object_swap_template,
        bug_plant_template,
        eavesdrop_template,
        dock,
        dev_scene,
        side_job_scene,
        taco_scene,
        tests,
        phase9b_tests,
        phase9c_to_9f_tests,
        phase9g_to_9i_tests,
        roadmap,
        blueprint,
        guide,
        report,
        phase9b_report,
        phase9c_to_9f_report,
        phase9g_to_9i_report,
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
        '"DeadDropNode"',
        '"ObjectSwapNode"',
        '"BugPlantNode"',
        '"EavesdropZone"',
        "TerminalHackNode.gd",
        "PowerCircuitNode.gd",
        "TimedSwitchNode.gd",
        "PressurePlateNode.gd",
        "DeadDropNode.gd",
        "ObjectSwapNode.gd",
        "BugPlantNode.gd",
        "EavesdropZone.gd",
        "Press E: Hack terminal",
        "Press E: Check circuit",
        "Press E: Trigger switch",
        "Step onto pressure plate",
        "Press E: Use dead drop",
        "Press E: Swap object",
        "Press E: Plant bug",
        "Stay hidden and listen",
        "missing_terminal_id",
        "missing_hack_completed_flag",
        "missing_circuit_id",
        "missing_switch_id",
        "missing_plate_id",
        "missing_drop_id",
        "missing_swap_id",
        "missing_bug_id",
        "missing_eavesdrop_id",
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
        (
            dead_drop,
            "DeadDropNode",
            (
                "class_name DeadDropNode",
                "extends InteractiveContainer",
                "drop_mode",
                "func use_dead_drop",
                "func get_dead_drop_summary",
                "MissionInventoryScript",
            ),
        ),
        (
            object_swap,
            "ObjectSwapNode",
            (
                "class_name ObjectSwapNode",
                "extends MechanicAreaBase",
                "required_item_id",
                "replacement_item_id",
                "func swap_object",
                "func get_swap_summary",
            ),
        ),
        (
            bug_plant,
            "BugPlantNode",
            (
                "class_name BugPlantNode",
                "extends MechanicAreaBase",
                "bug_item_id",
                "planted_flag",
                "func plant_bug",
                "func get_bug_summary",
            ),
        ),
        (
            eavesdrop,
            "EavesdropZone",
            (
                "class_name EavesdropZone",
                "extends MechanicAreaBase",
                "listen_seconds",
                "func start_eavesdrop",
                "func complete_eavesdrop",
                "func get_eavesdrop_summary",
            ),
        ),
    ):
        text = read_text(path)
        for needle in needles:
            require_contains(errors, text, needle, label)

    for path, label, needles in (
        (sequence_step, "CustomSequenceStep", ("class_name CustomSequenceStep", "depends_on_step_ids", "completion_flag")),
        (sequence_resource, "CustomSequenceResource", ("class_name CustomSequenceResource", "func ordered_steps", "func find_step")),
        (sequence_runner, "CustomSequenceRunner", ("class_name CustomSequenceRunner", "func complete_step", "step_dependencies_missing", "sequence_step_completed")),
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
        (dead_drop_template, "DeadDropNodeTemplate", ("DeadDropNodeTemplate", "DeadDropNode.gd", "CHANGE_ME_DROP_ID")),
        (object_swap_template, "ObjectSwapNodeTemplate", ("ObjectSwapNodeTemplate", "ObjectSwapNode.gd", "CHANGE_ME_SWAP_ID")),
        (bug_plant_template, "BugPlantNodeTemplate", ("BugPlantNodeTemplate", "BugPlantNode.gd", "CHANGE_ME_BUG_ID")),
        (eavesdrop_template, "EavesdropZoneTemplate", ("EavesdropZoneTemplate", "EavesdropZone.gd", "CHANGE_ME_EAVESDROP_ID")),
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
        "DeadDropNode_phase9c_retrieve",
        "phase9c_dead_drop_complete",
        "ObjectSwapNode_phase9d_swap",
        "phase9d_object_swapped",
        "BugPlantNode_phase9e_plant",
        "phase9e_bug_planted",
        "EavesdropZone_phase9f_listen",
        "phase9f_eavesdrop_complete",
    ):
        require_contains(errors, scene_text, needle, "MechanicAuthoringTestRoom")

    side_job_scene_text = read_text(side_job_scene)
    for needle in (
        "Phase9G_PoopBagCalibrationCourse",
        "TimedSwitch_phase9g_start",
        "PressurePlate_phase9g_hold",
        "PowerCircuit_phase9g_finish",
        "Phase9GSequenceRunner",
        "phase9g_poop_bag_calibration_course",
        "Phase9H_BentleySnackTrail",
        "DeadDrop_phase9h_retrieve",
        "ObjectSwap_phase9h_swap",
        "BugPlant_phase9h_bug",
        "Eavesdrop_phase9h_listen",
        "Phase9HSequenceRunner",
        "phase9h_bentley_snack_trail",
    ):
        require_contains(errors, side_job_scene_text, needle, "Phase9SideJobProofRoom")

    taco_scene_text = read_text(taco_scene)
    for needle in (
        "PpTacoSouthSideJobSignoff",
        "SideObjectiveNode.gd",
        "pp_taco_south_route_open",
        "pp_taco_south_side_job_signoff",
        "pp_taco_south_side_job_complete",
        "include_legacy_candidates = false",
        "Phase9I-SideJobProductionGate",
    ):
        require_contains(errors, taco_scene_text, needle, "Taco Phase 9I production gate")

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
        "test_dead_drop_deposit_removes_item_and_sets_facts",
        "test_dead_drop_retrieve_grants_item",
        "test_object_swap_consumes_required_item_and_grants_replacement",
        "test_bug_plant_and_eavesdrop_set_ordered_side_job_facts",
        "test_custom_sequence_runner_enforces_step_dependencies",
        "test_templates_and_dev_scene_contain_phase9c_to_9f_nodes",
    ):
        require_contains(errors, read_text(phase9c_to_9f_tests), needle, "Phase9CTo9FPuzzleSideJobNodeTest")

    for needle in (
        "test_phase9_side_job_proof_room_contains_two_distinct_side_jobs",
        "test_phase9g_poop_bag_calibration_course_flow_uses_reusable_nodes",
        "test_phase9h_bentley_snack_trail_flow_uses_different_node_combination",
        "test_phase9i_taco_production_gate_is_isolated_and_route_gated",
    ):
        require_contains(errors, read_text(phase9g_to_9i_tests), needle, "Phase9GTo9ISideJobCompletionTest")

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
    for doc_path, label in ((roadmap, "Roadmap"), (blueprint, "Blueprint"), (guide, "Guide"), (phase9c_to_9f_report, "Phase 9C-9F AI report")):
        doc_text = read_text(doc_path)
        require_contains(errors, doc_text, "Phase 9C-9F", label)
        require_contains(errors, doc_text, "DeadDropNode", label)
        require_contains(errors, doc_text, "ObjectSwapNode", label)
        require_contains(errors, doc_text, "BugPlantNode", label)
        require_contains(errors, doc_text, "EavesdropZone", label)
        require_contains(errors, doc_text, "CustomSequenceRunner", label)
    for doc_path, label in ((roadmap, "Roadmap"), (blueprint, "Blueprint"), (guide, "Guide"), (phase9g_to_9i_report, "Phase 9G-9I AI report")):
        doc_text = read_text(doc_path)
        require_contains(errors, doc_text, "Phase 9G-9I", label)
        require_contains(errors, doc_text, "Phase9SideJobProofRoom", label)
        require_contains(errors, doc_text, "Poop Bag Calibration Course", label)
        require_contains(errors, doc_text, "Bentley's Snack Trail", label)
        require_contains(errors, doc_text, "PpTacoSouthSideJobSignoff", label)

    result = {
        "pass": len(errors) == 0,
        "errors": errors,
        "warnings": warnings,
        "limitations": [
            "Static validator cannot execute GDScript; focused GdUnit and headless scene smoke cover runtime contracts.",
            "Phase 9G-9I completes Phase 9 with two small side-job proofs and a tiny route-gated Taco signoff; no global puzzle manager, save schema, tail target, or carry-object controller is added.",
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
