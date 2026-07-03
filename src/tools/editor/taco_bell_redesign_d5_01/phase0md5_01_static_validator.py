from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[4]
REPORT_DIR = ROOT / "docs" / "reports" / "taco_bell_redesign_d5_01"
REPORT_PATH = REPORT_DIR / "phase0md5_01_static_validator_run.json"


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def require(condition: bool, message: str, errors: list[str]) -> None:
    if not condition:
        errors.append(message)


def main() -> int:
    errors: list[str] = []

    bridge = read("src/missions/objectives/MissionObjectiveBridge.gd")
    phase0j_pickup = read("src/missions/iso/runtime/Phase0JInteractablePickup.gd")
    phase0j_state = read("src/missions/iso/runtime/Phase0JMissionStateAdapter.gd")
    phase0j_label = read("src/missions/iso/runtime/Phase0JRuntimeMarkerLabel.gd")
    phase0k_bag = read("src/missions/iso/runtime/Phase0KBagObjectiveInteractable.gd")
    phase0k = read("src/missions/iso/runtime/Phase0KMissionCompletionController.gd")
    iso = read("src/levels/IsoMissionBase.gd")
    debug_panel = read("src/missions/iso/runtime/IsoMissionDebugPanel.gd")
    test = read("tests/mission_authoring/PhaseD501AttemptResetContractTest.gd")

    require("static func reset_runtime_objectives_for_mission(mission_id: String)" in bridge, "MissionObjectiveBridge reset function missing explicit mission_id implementation.", errors)
    require("QuestManager.objectives.erase(mid)" in bridge, "MissionObjectiveBridge does not clear mission objectives map.", errors)
    require("QuestManager.objective_records.erase(mid)" in bridge, "MissionObjectiveBridge does not clear objective records.", errors)
    require("QuestManager.active_objectives.erase(mid)" in bridge, "MissionObjectiveBridge does not clear active objectives.", errors)
    require("QuestManager.completed_objectives.erase(mid)" in bridge, "MissionObjectiveBridge does not clear completed objectives.", errors)
    require("static func seed_runtime_objectives_for_mission" in bridge, "MissionObjectiveBridge seed helper missing.", errors)

    require("func reset_attempt_state()" in phase0k, "Phase0K reset_attempt_state missing.", errors)
    for field in ["delivery_bag_collected = false", "code_gate_unlocked = false", "exit_unlocked = false", "mission_completed = false", "completed_objectives.clear()"]:
        require(field in phase0k, f"Phase0K reset missing {field}.", errors)
    require("MissionObjectiveBridge.seed_runtime_objectives_for_mission" in phase0k, "Phase0K objectives are not seeded through MissionObjectiveBridge.", errors)

    require("func reset_mission_runtime_for_new_attempt()" in iso, "IsoMissionBase reset entry missing.", errors)
    require("MissionObjectiveBridge.reset_runtime_objectives_for_mission(mid)" in iso, "IsoMissionBase does not reset mission objectives.", errors)
    require("_reset_d5_attempt_interactables()" in iso, "IsoMissionBase does not reset D5 scene-local interactables.", errors)
    require("interactable_reset" in iso, "IsoMissionBase does not report interactable reset metadata.", errors)
    require("alarm_triggered:AMBUSH_security_beam" in iso, "IsoMissionBase garage beam summary does not include authored beam trigger flag.", errors)
    require("_reset_phase0k_attempt_state()" in iso, "IsoMissionBase does not call Phase0K reset hook.", errors)
    require("d5_01_attempt_reset" in iso, "IsoMissionBase does not store D5-01 reset debug metadata.", errors)

    for reset_source, label in [
        (phase0j_pickup, "Phase0JInteractablePickup"),
        (phase0j_state, "Phase0JMissionStateAdapter"),
        (phase0j_label, "Phase0JRuntimeMarkerLabel"),
        (phase0k_bag, "Phase0KBagObjectiveInteractable"),
    ]:
        require("reset_attempt_state" in reset_source or "reset_collected" in reset_source, f"{label} has no D5 reset hook.", errors)
    require("collision_layer = 8" in phase0j_pickup and "monitoring = true" in phase0j_pickup, "Phase0J pickup reset does not restore interaction collision.", errors)
    require("collected_ids.clear()" in phase0j_state and "objective_flags.clear()" in phase0j_state, "Phase0J state reset does not clear collected/objective state.", errors)
    require("label.text.replace(\"\\nCOLLECTED\", \"\")" in phase0j_label, "Phase0J runtime label reset does not remove COLLECTED suffix.", errors)
    require("DELIVERY BAG\\nObjective\\nE/Q" in phase0k_bag, "Phase0K bag reset does not restore original label text.", errors)

    restart_block = debug_panel.split("func _on_restart() -> void:", 1)[1].split("\n\nfunc ", 1)[0]
    require("GameState.start_mission(mid)" in restart_block, "IsoMissionDebugPanel restart does not call GameState.start_mission.", errors)
    require("GameState.begin_mission_performance(mid)" not in restart_block, "IsoMissionDebugPanel restart still bypasses canonical start path.", errors)

    require("test_objective_bridge_reset_clears_only_target_mission_runtime_objectives" in test, "D5-01 bridge reset test missing.", errors)
    require("test_phase0k_reset_attempt_state_clears_bag_code_exit_and_reseeds_objectives" in test, "D5-01 Phase0K reset test missing.", errors)
    require("test_phase0j_bag_interactable_reset_restores_visual_collision_and_label" in test, "D5-01 Phase0J bag visual reset test missing.", errors)
    require("test_phase0j_state_adapter_reset_forgets_collected_delivery_bag" in test, "D5-01 Phase0J state reset test missing.", errors)

    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    payload = {
        "phase": "0M-D5-01",
        "ok": len(errors) == 0,
        "errors": errors,
        "checks": 33,
    }
    REPORT_PATH.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")

    if errors:
        for error in errors:
            print(f"FAIL: {error}")
        return 1
    print("PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
