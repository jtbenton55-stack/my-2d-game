#!/usr/bin/env python3
"""Static validation for Phase 17 Taco route activation + level-builder readiness."""

from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[4]
REPORT_DIR = ROOT / "docs" / "reports" / "phase17_level_builder_readiness"
REPORT_PATH = REPORT_DIR / "phase17_level_builder_readiness_validation.json"


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def require(condition: bool, message: str, failures: list[str]) -> None:
    if not condition:
        failures.append(message)


def main() -> int:
    failures: list[str] = []
    checks: list[dict[str, object]] = []

    required_files = [
        "src/missions/iso/runtime/MissionQAChecklistPanel.gd",
        "src/missions/iso/runtime/IsoMissionDebugPanel.gd",
        "src/missions/iso/runtime/Phase16GarageManagerDeniabilityController.gd",
        "src/ui/MissionResult.gd",
        "addons/mission_dock/MissionDock.gd",
        "src/missions/iso/dev/Phase17LevelBuilderProofHarness.gd",
        "scenes/dev/mission_authoring/NewMissionStarterTemplate.tscn",
        "scenes/dev/mission_authoring/Phase17LevelBuilderReadinessProofRoom.tscn",
        "tests/mission_authoring/Phase17LevelBuilderReadinessTest.gd",
        "scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn",
    ]
    for rel in required_files:
        exists = (ROOT / rel).exists()
        checks.append({"check": "required_file", "path": rel, "ok": exists})
        require(exists, f"Missing required file: {rel}", failures)

    if not failures:
        qa_panel = read("src/missions/iso/runtime/MissionQAChecklistPanel.gd")
        debug_panel = read("src/missions/iso/runtime/IsoMissionDebugPanel.gd")
        controller = read("src/missions/iso/runtime/Phase16GarageManagerDeniabilityController.gd")
        result_ui = read("src/ui/MissionResult.gd")
        dock = read("addons/mission_dock/MissionDock.gd")
        harness = read("src/missions/iso/dev/Phase17LevelBuilderProofHarness.gd")
        starter_scene = read("scenes/dev/mission_authoring/NewMissionStarterTemplate.tscn")
        proof_scene = read("scenes/dev/mission_authoring/Phase17LevelBuilderReadinessProofRoom.tscn")
        phase17_test = read("tests/mission_authoring/Phase17LevelBuilderReadinessTest.gd")
        taco_scene = read("scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn")

        required_tokens = {
            "qa_panel": (qa_panel, ["MODE_PHASE17", "Phase 17 - Garage Routes", "phase16_route", "_run_phase16_route", "run_cleanup_redirect_trace"]),
            "debug_panel": (debug_panel, ["phase17_route", "_get_phase16_summary"]),
            "controller": (controller, ["last_route_label", "func get_summary()", "_route_label", "Clean Social"]),
            "result_ui": (result_ui, ["last_route_label", "- Route: %s"]),
            "dock": (dock, ["LEVEL_BUILDER_AUDIT_SCRIPTS", "phase16_dev_trigger_found", "level_builder_mechanic_mix", "taco_bridge_legacy_candidates_enabled"]),
            "harness": (harness, ["class_name Phase17LevelBuilderProofHarness", "run_integrated_proof", "PaperTrailAdapterScript", "SocialStealthAdapterScript", "ReactiveNpcBrainAdapterScript", "emit_noise"]),
            "starter_scene": (starter_scene, ["NewMissionStarterTemplate", "RuntimeHelpers", "MissionInteractionBridge", "MissionMechanics", "include_legacy_candidates = false"]),
            "proof_scene": (proof_scene, ["Phase17LevelBuilderReadinessProofRoom", "SearchZone_level_builder_entry", "RewardNode_level_builder_badge", "RouteUnlockNode_level_builder_service_hall", "CompanionCommandPoint_level_builder_bentley", "NoiseEmitterNode_level_builder_decoy", "Run Integrated Proof"]),
            "test": (phase17_test, ["test_f12_phase17_routes_are_qa_only_actions", "test_non_taco_level_builder_proof_runs_multiple_systems", "test_mission_dock_and_static_validator_cover_phase17_readiness"]),
        }
        for group, (text, tokens) in required_tokens.items():
            for token in tokens:
                ok = token in text
                checks.append({"check": f"{group}_token", "token": token, "ok": ok})
                require(ok, f"{group} missing token: {token}", failures)

        forbidden_qa_tokens = ["func interact", "extends Area2D", "Input.is_action"]
        dev_trigger = read("src/missions/iso/dev/Phase16GarageDeniabilityDevTrigger.gd")
        for token in forbidden_qa_tokens:
            ok = token not in dev_trigger
            checks.append({"check": "dev_trigger_stays_callable_only", "token": token, "ok": ok})
            require(ok, f"Phase 16 dev trigger must remain callable-only: {token}", failures)

        bridge_safe = "include_legacy_candidates = false" in taco_scene and "include_legacy_candidates = true" not in taco_scene
        checks.append({"check": "taco_bridge_scope_preserved", "ok": bridge_safe})
        require(bridge_safe, "Taco MissionInteractionBridge scope changed or legacy candidates enabled.", failures)

        no_player_hook = "Phase16GarageDeniabilityDevTrigger" in taco_scene and "Phase17Player" not in taco_scene
        checks.append({"check": "no_new_player_facing_hook", "ok": no_player_hook})
        require(no_player_hook, "Phase 17 should not add a normal player-facing route hook before manual Taco QA.", failures)

    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    REPORT_PATH.write_text(json.dumps({"ok": not failures, "failures": failures, "checks": checks}, indent=2) + "\n", encoding="utf-8")

    if failures:
        print("Phase 17 level-builder readiness validation FAILED")
        for failure in failures:
            print(f"- {failure}")
        return 1
    print(f"Phase 17 level-builder readiness validation PASS ({len(checks)} checks)")
    print(f"Report: {REPORT_PATH.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
