#!/usr/bin/env python3
"""Static validation for Corner Store Cashout production skeleton mission."""

from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
MISSION_ID = "corner_store_cashout"
SCENE_REL = "scenes/missions_iso/CornerStoreCashout_Editable.tscn"
REPORT_DIR = ROOT / "docs" / "reports" / f"{MISSION_ID}_production_skeleton"
REPORT_PATH = REPORT_DIR / f"{MISSION_ID}_production_skeleton_validation.json"

REQUIRED_MECHANIC_TOKENS = [
    "SearchZone_csc_entry_clue",
    "InventoryPickupNode_csc_fake_badge",
    "LockedInteractionNode_csc_office_door",
    "RewardNode_csc_scam_folder",
    "TerminalHackNode_csc_security_log",
    "PowerCircuitNode_csc_camera_power",
    "PressurePlateNode_csc_stockroom_plate",
    "TimedSwitchNode_csc_freezer_timer",
    "RouteUnlockNode_csc_alley_route",
    "CompanionCommandPoint_csc_bentley_bark",
    "NoiseEmitterNode_csc_chip_aisle_noise",
    "DeadDropNode_csc_alley_drop",
    "SideObjectiveNode_csc_coupon_scam",
    "EncounterRouteActionNode_csc_clean_social",
    "EncounterRouteActionNode_csc_bentley_route",
    "EncounterRouteActionNode_csc_evidence_route",
    "EncounterRouteActionNode_csc_messy_route",
    "ExtractionZone_csc_alley_extract",
    "CustomSequenceRunner_csc_side_job",
]

REQUIRED_FLAGS = [
    "csc_entry_clue_found",
    "csc_badge_collected",
    "csc_checkpoint_open",
    "csc_terminal_hacked",
    "csc_evidence_collected",
    "csc_route_selected",
    "csc_extracted",
]


def read(rel: str) -> str:
    return (ROOT / rel).read_text(encoding="utf-8")


def require(condition: bool, message: str, failures: list[str]) -> None:
    if not condition:
        failures.append(message)


def main() -> int:
    failures: list[str] = []
    checks: list[dict[str, object]] = []

    required_files = [
        SCENE_REL,
        "assets/missions/corner_store_cashout_definition.tres",
        "src/missions/iso/runtime/CornerStoreCashoutMissionController.gd",
        "src/missions/iso/runtime/CornerStoreCashoutEncounterController.gd",
        "src/missions/iso/dev/CornerStoreCashoutLayoutBootstrap.gd",
        "src/missions/iso/dev/CornerStoreCashoutIntegratedProofHarness.gd",
        "tests/mission_authoring/CornerStoreCashoutProductionSkeletonTest.gd",
    ]
    for rel in required_files:
        ok = (ROOT / rel).exists()
        checks.append({"check": "required_file", "path": rel, "ok": ok})
        require(ok, f"Missing required file: {rel}", failures)

    wiring_files = {
        "game_state": "src/autoload/GameState.gd",
        "resolver": "src/missions/MissionSceneResolver.gd",
        "hideout_catalog": "src/hideout/HideoutStationCatalog.gd",
        "hideout_board": "src/hideout/HideoutMissionBoardController.gd",
        "hideout_manager": "src/hideout/HideoutManager.gd",
    }
    wiring_tokens = {
        "game_state": [f'"{MISSION_ID}"', SCENE_REL, 'unlock_mission("corner_store_cashout")'],
        "resolver": ["CORNER_STORE_MISSION_ID", SCENE_REL],
        "hideout_catalog": [MISSION_ID, "launch_corner_store_cashout"],
        "hideout_board": ["launch_corner_store_cashout", MISSION_ID],
        "hideout_manager": ["launch_corner_store_cashout", "confirm_launch_corner_store_cashout"],
    }
    for group, rel in wiring_files.items():
        text = read(rel) if (ROOT / rel).exists() else ""
        for token in wiring_tokens[group]:
            ok = token in text
            checks.append({"check": f"{group}_token", "token": token, "ok": ok})
            require(ok, f"{group} missing token: {token}", failures)

    if (ROOT / SCENE_REL).exists() and not failures:
        scene = read(SCENE_REL)
        structure_tokens = [
            "GameplayRoot",
            "LayoutRoot",
            "EntityRoot",
            "RuntimeHelpers",
            "MissionMechanics",
            "ArtRoot",
            "CameraBounds",
            "FloorLayer",
            "WallLayer",
            "CoverLayer",
            "CollisionBarrierLayer",
            "MarkerTileLayer",
            "CornerStoreCashoutMissionController",
            "MissionInteractionBridge",
            "CornerStoreCashoutEncounterController",
            "MissionAlertController",
            "CornerStoreCashoutIntegratedProofHarness",
            "DebugProof",
            'name="default" type="Marker2D" parent="GameplayRoot/SpawnPoints"',
            "ExtractionZone_csc_alley_extract",
        ]
        for token in structure_tokens:
            ok = token in scene
            checks.append({"check": "scene_structure", "token": token, "ok": ok})
            require(ok, f"Scene missing structure token: {token}", failures)

        bridge_safe = "include_legacy_candidates = false" in scene
        checks.append({"check": "bridge_scope_safe", "ok": bridge_safe})
        require(bridge_safe, "MissionInteractionBridge must set include_legacy_candidates = false", failures)

        for token in REQUIRED_MECHANIC_TOKENS:
            ok = token in scene
            checks.append({"check": "mechanic_present", "token": token, "ok": ok})
            require(ok, f"Scene missing mechanic node: {token}", failures)

        for flag in REQUIRED_FLAGS:
            ok = flag in scene
            checks.append({"check": "flag_present", "token": flag, "ok": ok})
            require(ok, f"Scene missing mission flag reference: {flag}", failures)

        route_methods = [
            "run_clean_social_route",
            "run_bentley_distraction_route",
            "run_evidence_route",
            "run_messy_authority_route",
        ]
        for method in route_methods:
            ok = method in scene
            checks.append({"check": "route_method", "token": method, "ok": ok})
            require(ok, f"Scene missing route method wiring: {method}", failures)

        route_paths_ok = (
            'controller_path = NodePath("../../RuntimeHelpers/CornerStoreCashoutEncounterController")' in scene
            and 'required_controller_bool_path = NodePath("../../RuntimeHelpers/CornerStoreCashoutMissionController")' in scene
            and 'NodePath("../RuntimeHelpers/' not in scene
        )
        checks.append({"check": "route_action_node_paths_resolve", "ok": route_paths_ok})
        require(route_paths_ok, "EncounterRouteActionNode paths must use ../../RuntimeHelpers (nodes live under GameplayRoot/MissionMechanics)", failures)

        debug_proof_ok = (
            '[node name="DebugProof" type="CanvasLayer" parent="GameplayRoot"]' in scene
            and 'name="GameplayRoot/DebugProof"' not in scene
        )
        checks.append({"check": "debug_proof_node_name_valid", "ok": debug_proof_ok})
        require(debug_proof_ok, "DebugProof must be a valid node name (no slash) parented to GameplayRoot", failures)

        no_root_mission_controller = '[node name="MissionController" type="Node" parent="."]' not in scene
        checks.append({"check": "no_root_mission_controller", "ok": no_root_mission_controller})
        require(no_root_mission_controller, "Scene must not include duplicate root MissionController node", failures)

        no_duplicate_entity_root = scene.count('[node name="EntityRoot" type="Node2D" parent="."]') == 0
        checks.append({"check": "entity_root_under_gameplay", "ok": no_duplicate_entity_root})
        require(no_duplicate_entity_root, "EntityRoot must live under GameplayRoot, not scene root", failures)

        no_phase0 = "Phase0J" not in scene and "Phase0K" not in scene
        checks.append({"check": "no_phase0j_phase0k_dependency", "ok": no_phase0})
        require(no_phase0, "Corner Store scene must not depend on Taco-only Phase0J/Phase0K nodes", failures)

        duplicate_mechanic_ids = re.findall(r'mechanic_id = &"([^"]+)"', scene)
        dupes = sorted({mid for mid in duplicate_mechanic_ids if duplicate_mechanic_ids.count(mid) > 1})
        ok = not dupes
        checks.append({"check": "unique_mechanic_ids", "ok": ok, "duplicates": dupes})
        require(ok, f"Duplicate mechanic_id values in scene: {dupes}", failures)

    controller = read("src/missions/iso/runtime/CornerStoreCashoutMissionController.gd")
    for token in ["complete_mission_and_exit", "request_exit_completion", "sync_from_mission_facts", "are_exit_requirements_met"]:
        ok = token in controller
        checks.append({"check": "mission_controller_token", "token": token, "ok": ok})
        require(ok, f"Mission controller missing token: {token}", failures)

    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    payload = {"ok": not failures, "mission_id": MISSION_ID, "failures": failures, "checks": checks}
    REPORT_PATH.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")

    if failures:
        print("Corner Store Cashout production skeleton validation FAILED")
        for failure in failures:
            print(f"- {failure}")
        return 1
    print(f"Corner Store Cashout production skeleton validation PASS ({len(checks)} checks)")
    print(f"Report: {REPORT_PATH.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
