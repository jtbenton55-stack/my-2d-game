#!/usr/bin/env python3
"""Static validation for Phase 18 Taco player-facing garage route actions."""

from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[4]
REPORT_DIR = ROOT / "docs" / "reports" / "phase18_taco_player_routes"
REPORT_PATH = REPORT_DIR / "phase18_taco_player_routes_validation.json"


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def require(condition: bool, message: str, failures: list[str]) -> None:
    if not condition:
        failures.append(message)


def main() -> int:
    failures: list[str] = []
    checks: list[dict[str, object]] = []

    required_files = [
        "src/missions/iso/authoring/mechanics/EncounterRouteActionNode.gd",
        "src/missions/iso/runtime/Phase16GarageManagerDeniabilityController.gd",
        "src/ui/MissionResult.gd",
        "addons/mission_dock/MissionDock.gd",
        "tests/mission_authoring/Phase18TacoPlayerRouteActionTest.gd",
        "scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn",
    ]
    for rel in required_files:
        exists = (ROOT / rel).exists()
        checks.append({"check": "required_file", "path": rel, "ok": exists})
        require(exists, f"Missing required file: {rel}", failures)

    if not failures:
        route_action = read("src/missions/iso/authoring/mechanics/EncounterRouteActionNode.gd")
        controller = read("src/missions/iso/runtime/Phase16GarageManagerDeniabilityController.gd")
        result_ui = read("src/ui/MissionResult.gd")
        dock = read("addons/mission_dock/MissionDock.gd")
        test = read("tests/mission_authoring/Phase18TacoPlayerRouteActionTest.gd")
        scene = read("scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn")

        required_tokens = {
            "route_action": (route_action, ["class_name EncounterRouteActionNode", "ALLOWED_ROUTE_METHODS", "phase18_player_route_action", "route_choice_flag", "required_completed_objective_id", "required_controller_bool_property", "route_already_selected"]),
            "controller": (controller, ["last_route_style_label", "route_style_label", "func _route_style_label", "Evidence-Strong"]),
            "result_ui": (result_ui, ["last_route_style_label", "- Style: %s"]),
            "dock": (dock, ["EncounterRouteActionNode", "phase18_player_route_action_found", "missing_encounter_route_controller_path"]),
            "test": (test, ["test_route_action_gates_until_code_gate_objective_is_complete", "test_route_action_can_gate_on_phase0k_controller_bool", "test_route_action_records_choice_and_locks_other_routes", "test_taco_scene_contains_phase18_player_route_actions_and_preserves_bridge_scope"]),
            "scene": (scene, ["EncounterRouteActionNode.gd", "Phase18GarageRouteActions", "Phase18GarageRoutePrompt", "Phase18CleanSocialRouteAction", "Phase18BentleyDistractionRouteAction", "Phase18EvidenceRouteAction", "Phase18MessyAuthorityRouteAction", "required_controller_bool_property = &\"code_gate_unlocked\"", "prompt_target_path = NodePath(\"../../PlugAndPlayPilot/Phase18GarageRoutePrompt\")"]),
        }
        for group, (text, tokens) in required_tokens.items():
            for token in tokens:
                ok = token in text
                checks.append({"check": f"{group}_token", "token": token, "ok": ok})
                require(ok, f"{group} missing token: {token}", failures)

        route_methods = [
            "run_clean_social_route",
            "run_bentley_distraction_route",
            "run_evidence_route",
            "run_messy_authority_route",
        ]
        for method in route_methods:
            ok = method in scene and method in route_action
            checks.append({"check": "route_method_wired", "method": method, "ok": ok})
            require(ok, f"Route method is not wired in both scene and action script: {method}", failures)

        bridge_safe = "include_legacy_candidates = false" in scene and "include_legacy_candidates = true" not in scene
        checks.append({"check": "taco_bridge_scope_preserved", "ok": bridge_safe})
        require(bridge_safe, "Taco MissionInteractionBridge scope changed or legacy candidates enabled.", failures)

        forbidden_scene_tokens = ["Phase18GarageRouteActions\nmetadata/dev_only = true", "Input.is_action", "global suspicion manager", "LimboAI"]
        for token in forbidden_scene_tokens:
            ok = token not in scene
            checks.append({"check": "forbidden_scene_token_absent", "token": token, "ok": ok})
            require(ok, f"Forbidden Taco scene token present: {token}", failures)

    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    REPORT_PATH.write_text(json.dumps({"ok": not failures, "failures": failures, "checks": checks}, indent=2) + "\n", encoding="utf-8")

    if failures:
        print("Phase 18 Taco player route validation FAILED")
        for failure in failures:
            print(f"- {failure}")
        return 1
    print(f"Phase 18 Taco player route validation PASS ({len(checks)} checks)")
    print(f"Report: {REPORT_PATH.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
