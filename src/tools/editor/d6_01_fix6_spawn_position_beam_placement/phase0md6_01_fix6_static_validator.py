#!/usr/bin/env python3
import json
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[4]
REPORT_DIR = ROOT / "docs" / "reports" / "d6_01_fix6_spawn_position_beam_placement"

REQUIRED_STEMS = [
    "phase0md6_01_fix6_safety_baseline",
    "phase0md6_01_fix6_kimi_connectivity_repair",
    "phase0md6_01_fix6_spawn_coordinate_audit",
    "phase0md6_01_fix6_reachable_spawn_strategy",
    "phase0md6_01_fix6_spawn_truth_probe_plan",
    "phase0md6_01_fix6_kimi_review",
    "phase0md6_01_fix6_player_reachable_spawn_fix",
    "phase0md6_01_fix6_camera_reachable_spawn_restore",
    "phase0md6_01_fix6_wrong_code_reachable_spawn_restore",
    "phase0md6_01_fix6_warp_removal_verification",
    "phase0md6_01_fix6_right_hallway_beam_fix",
    "phase0md6_01_fix6_f10_spawn_truth_cleanup",
    "phase0md6_01_fix6_heat_hideout_note",
    "phase0md6_01_fix6_static_self_review",
    "phase0md6_01_fix6_runtime_validation",
    "phase0md6_01_fix6_validation",
    "phase0md6_01_fix6_final_report",
]

FORBIDDEN_MODIFIED = [
    "project.godot",
    "src/player/Player.gd",
    "src/player/PlayerStaminaController.gd",
    "scenes/characters/player.tscn",
]


def git_changed_files() -> list[str]:
    proc = subprocess.run(
        ["git", "diff", "--name-only"],
        cwd=ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    return [line.strip().replace("\\", "/") for line in proc.stdout.splitlines() if line.strip()]


def load_json(stem: str) -> dict:
    path = REPORT_DIR / f"{stem}.json"
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def main() -> int:
    errors: list[str] = []
    for stem in REQUIRED_STEMS:
        if not (REPORT_DIR / f"{stem}.md").exists():
            errors.append(f"Missing markdown report: {stem}.md")
        json_path = REPORT_DIR / f"{stem}.json"
        if not json_path.exists():
            errors.append(f"Missing JSON report: {stem}.json")
            continue
        try:
            data = load_json(stem)
        except Exception as exc:  # noqa: BLE001 - validator should report parse failures plainly.
            errors.append(f"JSON parse failed for {stem}.json: {exc}")
            continue
        assertions = data.get("assertions", {})
        for key, value in assertions.items():
            if value is not True:
                errors.append(f"Assertion not true in {stem}.json: {key}={value!r}")

    final_md = (REPORT_DIR / "phase0md6_01_fix6_final_report.md").read_text(encoding="utf-8") if (REPORT_DIR / "phase0md6_01_fix6_final_report.md").exists() else ""
    required_final_phrases = [
        "root cause",
        "requested",
        "chosen",
        "actual",
        "far-left",
        "camera",
        "wrong-code",
        "purple warp",
        "red beam",
        "Kimi",
        "runtime validation",
        "manual checklist",
    ]
    for phrase in required_final_phrases:
        if phrase.lower() not in final_md.lower():
            errors.append(f"Final report missing phrase: {phrase}")

    changed = git_changed_files()
    for protected in FORBIDDEN_MODIFIED:
        if protected in changed:
            errors.append(f"Forbidden protected file modified: {protected}")
    if any(path.startswith("assets/") for path in changed):
        errors.append("Raw/generated asset path modified.")
    for path in changed:
        if path.endswith(".gd") and "save_key" in Path(ROOT / path).read_text(encoding="utf-8", errors="ignore").lower():
            errors.append(f"Potential new save key mention requires review: {path}")

    result = {
        "passed": not errors,
        "errors": errors,
        "checked_report_count": len(REQUIRED_STEMS),
        "changed_files": changed,
    }
    print(json.dumps(result, indent=2))
    return 0 if not errors else 1


if __name__ == "__main__":
    raise SystemExit(main())
