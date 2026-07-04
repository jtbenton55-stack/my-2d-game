#!/usr/bin/env python3
"""Static validation for Phase 16 Taco garage-manager deniability adoption."""

from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[4]
REPORT_DIR = ROOT / "docs" / "reports" / "phase16_taco_garage_deniability"
REPORT_PATH = REPORT_DIR / "phase16_taco_garage_deniability_validation.json"


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def require(condition: bool, message: str, failures: list[str]) -> None:
    if not condition:
        failures.append(message)


def main() -> int:
    failures: list[str] = []
    checks: list[dict[str, object]] = []

    required_files = [
        "src/missions/iso/runtime/Phase16GarageManagerDeniabilityController.gd",
        "src/missions/iso/dev/Phase16GarageDeniabilityDevTrigger.gd",
        "tests/mission_authoring/Phase16TacoGarageDeniabilityTest.gd",
        "scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn",
    ]
    for rel in required_files:
        exists = (ROOT / rel).exists()
        checks.append({"check": "required_file", "path": rel, "ok": exists})
        require(exists, f"Missing required file: {rel}", failures)

    if not failures:
        controller = read("src/missions/iso/runtime/Phase16GarageManagerDeniabilityController.gd")
        dev_trigger = read("src/missions/iso/dev/Phase16GarageDeniabilityDevTrigger.gd")
        scene = read("scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn")
        test = read("tests/mission_authoring/Phase16TacoGarageDeniabilityTest.gd")

        for token in [
            "extends EncounterController",
            "PaperTrailAdapterScript",
            "SocialStealthAdapterScript",
            "ReactiveNpcBrainAdapterScript",
            "run_clean_social_route",
            "run_bentley_distraction_route",
            "run_evidence_route",
            "run_messy_authority_route",
            "run_cleanup_redirect_trace",
            "get_phase16_summary",
        ]:
            ok = token in controller
            checks.append({"check": "controller_token", "token": token, "ok": ok})
            require(ok, f"Controller missing token: {token}", failures)

        for token in [
            "class_name Phase16GarageDeniabilityDevTrigger",
            "controller_path",
            "run_clean_social_route",
            "run_bentley_distraction_route",
            "run_evidence_route",
            "run_messy_authority_route",
            "run_cleanup_redirect_trace",
            "phase16_garage_deniability_dev_trigger",
        ]:
            ok = token in dev_trigger
            checks.append({"check": "dev_trigger_token", "token": token, "ok": ok})
            require(ok, f"Dev trigger missing token: {token}", failures)

        for token in ["func interact", "is_interaction_available", "extends Area2D", "Input.is_action"]:
            ok = token not in dev_trigger
            checks.append({"check": "dev_trigger_no_interaction_scan", "token": token, "ok": ok})
            require(ok, f"Dev trigger must not act as a player interactable/input hook: {token}", failures)

        for token in [
            "Phase16GarageManagerDeniabilityController.gd",
            "Phase16GarageManagerDeniabilityController",
            "Phase16GarageDeniabilityDevTrigger.gd",
            "Phase16GarageDeniabilityDevTrigger",
            "parent=\"GameplayRoot/PlugAndPlayPilot\"",
            "mission_id_override = \"taco_bell_drop\"",
            "start_on_ready = false",
            "metadata/dev_only = true",
            "include_legacy_candidates = false",
        ]:
            ok = token in scene
            checks.append({"check": "scene_token", "token": token, "ok": ok})
            require(ok, f"Taco scene missing token: {token}", failures)

        for token in [
            "test_clean_social_route_uses_social_and_encounter_adapters",
            "test_bentley_and_evidence_routes_record_deniability_state",
            "test_messy_route_reports_authority_without_global_manager",
            "test_taco_scene_contains_phase16_controller_and_preserves_bridge_scope",
            "test_dev_trigger_calls_controller_without_interaction_scanning",
        ]:
            ok = token in test
            checks.append({"check": "test_token", "token": token, "ok": ok})
            require(ok, f"Focused GdUnit test missing token: {token}", failures)

        forbidden_scene_tokens = ["include_legacy_candidates = true", "LimboAI", "global suspicion manager"]
        for token in forbidden_scene_tokens:
            ok = token not in scene
            checks.append({"check": "forbidden_scene_token_absent", "token": token, "ok": ok})
            require(ok, f"Forbidden Taco scene token present: {token}", failures)

    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    REPORT_PATH.write_text(json.dumps({"ok": not failures, "failures": failures, "checks": checks}, indent=2) + "\n", encoding="utf-8")

    if failures:
        print("Phase 16 Taco garage-manager deniability validation FAILED")
        for failure in failures:
            print(f"- {failure}")
        return 1
    print(f"Phase 16 Taco garage-manager deniability validation PASS ({len(checks)} checks)")
    print(f"Report: {REPORT_PATH.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
