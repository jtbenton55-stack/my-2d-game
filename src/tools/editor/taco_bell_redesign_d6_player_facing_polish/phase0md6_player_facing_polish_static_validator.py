from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[4]
REPORT_DIR = ROOT / "docs" / "reports" / "taco_bell_redesign_d6_player_facing_polish"
REPORT_PATH = REPORT_DIR / "phase0md6_player_facing_polish_static_validator_run.json"


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def require(condition: bool, message: str, errors: list[str]) -> None:
    if not condition:
        errors.append(message)


def main() -> int:
    errors: list[str] = []

    game_state = read("src/autoload/GameState.gd")
    hud_provider = read("src/missions/ui/MissionHudDataProvider.gd")
    pause_provider = read("src/missions/ui/MissionPauseDataProvider.gd")
    hud = read("src/ui/HUD.gd")
    pause_menu = read("src/ui/test_ui/pause_menu.gd")
    mission_result = read("src/ui/MissionResult.gd")
    result_scene = read("scenes/ui/MissionResult.tscn")
    test = read("tests/mission_authoring/PhaseD6PlayerFacingPolishTest.gd")

    require("TACO_SUCCESS_STERLING_CLUE_ID" in game_state, "Taco success Sterling clue id missing.", errors)
    require("func get_poop_bag_bonus_status" in game_state, "GameState poop-bag bonus status contract missing.", errors)
    require("_annotate_player_facing_mission_result" in game_state, "Mission result player-facing annotation missing.", errors)
    require("_ensure_taco_success_sterling_clue" in game_state, "Taco success clue posting helper missing.", errors)
    require("ensure_and_discover_sterling_clue(TACO_SUCCESS_STERLING_CLUE_ID" in game_state, "Taco success does not post to Sterling/evidence clue data.", errors)
    require("evidence_clues" in game_state and "Evidence clue:" in game_state, "Taco result does not expose evidence clue reward/result data.", errors)

    require("MissionPauseDataProvider.get_next_objective_text" in hud_provider, "HUD provider does not use pause next-objective seam.", errors)
    require("poop_bags_collected_this_attempt" in hud_provider, "HUD payload missing attempt poop-bag count.", errors)
    require("poop_bag_status_text" in hud_provider, "HUD payload missing player-facing poop-bag status text.", errors)
    require("Run: %d/%d" in hud, "HUD does not render run poop-bag progress.", errors)

    require("static func get_next_objective_text" in pause_provider, "Pause provider next-objective helper missing.", errors)
    require('"is_next"' in pause_provider, "Pause objective rows are not marked as next.", errors)
    require("NEXT - " in pause_menu, "Pause objectives panel does not highlight the next objective.", errors)
    require("Next: %s" in pause_menu, "Pause objectives panel missing next objective summary line.", errors)

    require("continue_label" in mission_result, "Mission result does not use continue button label payload.", errors)
    require("poop_bag_status" in mission_result, "Mission result does not render poop-bag status.", errors)
    require("Evidence Board:" in mission_result, "Mission result does not render evidence board clues.", errors)
    require("Next:" in mission_result, "Mission result does not render next steps.", errors)
    require("theme_override_font_sizes/font_size = 18" in result_scene, "MissionResult scene was not resized for richer result text.", errors)

    require("test_taco_success_posts_first_sterling_clue_and_result_status" in test, "D6 Taco result/clue GdUnit test missing.", errors)
    require("test_pause_provider_marks_taco_next_objective" in test, "D6 pause next-objective GdUnit test missing.", errors)
    require("test_hud_payload_exposes_next_objective_and_three_bag_status" in test, "D6 HUD/poop status GdUnit test missing.", errors)

    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    payload = {
        "phase": "0M-D6-player-facing-polish",
        "ok": len(errors) == 0,
        "errors": errors,
        "checks": 22,
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
