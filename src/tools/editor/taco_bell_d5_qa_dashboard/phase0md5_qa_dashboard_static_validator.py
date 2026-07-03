from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[4]
REPORT_DIR = ROOT / "docs" / "reports" / "taco_bell_d5_qa_dashboard"
REPORT_PATH = REPORT_DIR / "phase0md5_qa_dashboard_static_validator_run.json"


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def require(condition: bool, message: str, errors: list[str]) -> None:
    if not condition:
        errors.append(message)


def main() -> int:
    errors: list[str] = []
    panel = read("src/missions/iso/runtime/MissionQAChecklistPanel.gd")
    debug_panel = read("src/missions/iso/runtime/IsoMissionDebugPanel.gd")
    taco_scene = read("scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn")

    for mode in ["MODE_D5_01", "MODE_D5_02", "MODE_D5_03"]:
        require(mode in panel, f"Missing {mode} dashboard mode.", errors)
    for label in ["D5-01 - Attempt Reset", "D5-02 - Pause Context", "D5-03 - Louis Beam Bypass"]:
        require(label in panel, f"Missing selector label {label}.", errors)
    for render_func in ["_render_d5_01", "_render_d5_02", "_render_d5_03"]:
        require(f"func {render_func}" in panel, f"Missing {render_func} renderer.", errors)

    require("_body.bbcode_enabled = true" in panel, "QA body does not enable BBCode color status rendering.", errors)
    require("GridContainer.new()" in panel and "ActionButtons" in panel, "Action button container missing.", errors)
    for action_label in ["Go Code Gate", "Go Bag", "Go Exit", "Go Main Beam", "Go Louis Route", "Grant Louis Card", "Remove Louis Card", "Reset Attempt", "Restart Scene"]:
        require(action_label in panel, f"Missing QA action button {action_label}.", errors)
    require("teleport_marker" in panel and "_find_marker_node_recursive" in panel, "Dashboard does not resolve live scene markers.", errors)
    require("_node_string_property" in panel, "Dashboard marker lookup does not use safe property string reader.", errors)
    require("String(node.get" not in panel, "Dashboard marker lookup still uses unsafe String(node.get(...)) conversion.", errors)
    require("teleport_node" in panel and "fallback_node_path" in panel, "Dashboard does not support runtime/fallback node path teleports.", errors)
    for marker_id in [
        "code_gate_garage_office",
        "objective_retrieve_delivery_bag",
        "objective_escape_and_return_to_louis",
        "player_spawn_main",
        "spawn_route_louis_entry",
    ]:
        require(marker_id in panel, f"Dashboard missing real Taco marker target {marker_id}.", errors)
        require(marker_id in taco_scene, f"Taco RedesignTest scene missing marker target {marker_id}.", errors)
    require("AlarmZone_garage_entry_beam" in panel, "Dashboard missing runtime garage beam node target.", errors)
    require("AMBUSH_security_beam" in panel, "Dashboard missing authored beam fallback target.", errors)
    require("AMBUSH_security_beam" in taco_scene, "Taco RedesignTest scene missing authored beam fallback node.", errors)
    require("reset_mission_runtime_for_new_attempt" in panel, "Dashboard does not expose D5 attempt reset hook.", errors)
    require("GameState.start_mission(mid)" in panel, "Dashboard restart does not use canonical GameState.start_mission.", errors)
    require("MissionPauseDataProvider.get_pause_payload" in panel, "D5-02 dashboard does not read pause payload.", errors)
    require("garage_beam_armed" in panel and "garage_beam_triggered" in panel, "D5 dashboards do not show beam state.", errors)
    require("_status_badge" in panel and "_status_color" in panel, "Colored status badge helpers missing.", errors)
    require("QA_PANEL_TOGGLE_KEY := KEY_F12" in debug_panel, "QA panel hotkey is not F12.", errors)

    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    payload = {
        "phase": "0M-D5-QA-DASHBOARD",
        "ok": len(errors) == 0,
        "errors": errors,
        "checks": 45,
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
