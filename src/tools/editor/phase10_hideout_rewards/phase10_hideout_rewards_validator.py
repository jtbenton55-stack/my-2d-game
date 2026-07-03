from pathlib import Path


ROOT = Path(__file__).resolve().parents[4]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def require(path: str, needle: str) -> None:
    text = read(path)
    if needle not in text:
        raise SystemExit(f"Missing expected text in {path}: {needle}")


def main() -> None:
    required_files = [
        "src/hideout/HideoutRewardAdapter.gd",
        "src/hideout/HideoutStateController.gd",
        "src/hideout/HideoutManager.gd",
        "src/hideout/HideoutMissionBoardController.gd",
        "tests/mission_authoring/Phase10HideoutRewardAdapterTest.gd",
    ]
    for rel in required_files:
        if not (ROOT / rel).exists():
            raise SystemExit(f"Missing required Phase 10 file: {rel}")

    require("src/hideout/HideoutRewardAdapter.gd", "static func build_contract")
    require("src/hideout/HideoutRewardAdapter.gd", "apply_all_completed_rewards_to_state")
    require("src/hideout/HideoutRewardAdapter.gd", "TACO_BELL_STORE_UNLOCKS")
    require("src/hideout/HideoutStateController.gd", "func apply_mission_reward_contract")
    require("src/hideout/HideoutManager.gd", "HideoutRewardAdapter.apply_all_completed_rewards_to_state")
    require("src/hideout/HideoutManager.gd", "GameState.complete_mission(\"taco_bell_drop\")")
    require("src/hideout/HideoutManager.gd", "HideoutRewardAdapter.apply_completed_mission_rewards_to_state(_state, \"taco_bell_drop\")")
    require("src/hideout/HideoutMissionBoardController.gd", "DEV: Mark Taco Bell Complete")
    require("src/hideout/HideoutMissionBoardController.gd", "dev_mark_taco_bell_complete")
    require("tests/mission_authoring/Phase10HideoutRewardAdapterTest.gd", "test_completed_rewards_survive_save_load_contract_path")
    require("tests/mission_authoring/Phase10HideoutRewardAdapterTest.gd", "test_dev_taco_completion_shortcut_uses_game_state_completion_path")
    print("PHASE10_HIDEOUT_REWARDS_VALIDATOR_PASS")


if __name__ == "__main__":
    main()
