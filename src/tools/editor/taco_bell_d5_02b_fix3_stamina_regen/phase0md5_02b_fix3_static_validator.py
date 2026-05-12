#!/usr/bin/env python3
"""0M-D5-02B-FIX3 — Static validator for stamina regen fix reports + code invariants."""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path


def _repo() -> Path:
    p = Path(__file__).resolve()
    for anc in [p.parent, *p.parents]:
        if (anc / "project.godot").is_file():
            return anc
    raise RuntimeError("project.godot not found")


REPO = _repo()
REPORTS = REPO / "docs" / "reports" / "taco_bell_d5_02b_fix3_stamina_regen"
FINAL = REPORTS / "phase0md5_02b_fix3_stamina_regen_final_report.json"
RUN = REPORTS / "phase0md5_02b_fix3_static_validator_run.json"
VALIDATION = REPORTS / "phase0md5_02b_fix3_validation.json"
VALIDATION_MD = REPORTS / "phase0md5_02b_fix3_validation.md"

REQUIRED = [
    "phase0md5_02b_fix3_safety_baseline.md",
    "phase0md5_02b_fix3_safety_baseline.json",
    "phase0md5_02b_fix3_stamina_regen_audit.md",
    "phase0md5_02b_fix3_stamina_regen_audit.json",
    "phase0md5_02b_fix3_kimi_preimplementation_review.md",
    "phase0md5_02b_fix3_kimi_preimplementation_review.json",
    "phase0md5_02b_fix3_stamina_regen_fix.md",
    "phase0md5_02b_fix3_stamina_regen_fix.json",
    "phase0md5_02b_fix3_hud_non_regression.md",
    "phase0md5_02b_fix3_hud_non_regression.json",
    "phase0md5_02b_fix3_runtime_validation.md",
    "phase0md5_02b_fix3_runtime_validation.json",
    "phase0md5_02b_fix3_self_review.md",
    "phase0md5_02b_fix3_self_review.json",
    "phase0md5_02b_fix3_stamina_regen_final_report.md",
    "phase0md5_02b_fix3_stamina_regen_final_report.json",
]

FORBIDDEN_MODIFIED = (
    "project.godot",
    "scenes/missions_iso/",
    "scenes/missions/TacoBellMission.tscn",
    "scenes/hideout/HideoutHub.tscn",
    "scenes/characters/player.tscn",
    "assets/",
)


def main() -> int:
    failures: list[str] = []

    for name in REQUIRED:
        p = REPORTS / name
        if not p.is_file():
            failures.append(f"missing {p.relative_to(REPO)}")
        elif name.endswith(".json"):
            try:
                json.loads(p.read_text(encoding="utf-8"))
            except json.JSONDecodeError as e:
                failures.append(f"bad json {name}: {e}")

    psc = REPO / "src" / "player" / "PlayerStaminaController.gd"
    if not psc.is_file():
        failures.append("missing PlayerStaminaController.gd")
    else:
        txt = psc.read_text(encoding="utf-8", errors="replace")
        if "regen_rate_per_sec" not in txt:
            failures.append("PlayerStaminaController missing regen_rate_per_sec")
        if "process_frame" not in txt:
            failures.append("PlayerStaminaController missing process_frame")
        if "current_stamina = minf(max_stamina" not in txt:
            failures.append("PlayerStaminaController regen must use minf(max_stamina, ...)")
        if re.search(r"current_stamina\s*=\s*mini\s*\(\s*max_stamina", txt):
            failures.append("PlayerStaminaController must not use mini() for float stamina regen clamp")
        if "maxf(0.0" not in txt and "maxf(0," not in txt:
            failures.append("PlayerStaminaController drain clamp (maxf) not found")
        if "get_sprint_runtime_debug" not in (REPO / "src" / "player" / "Player.gd").read_text(
            encoding="utf-8", errors="replace"
        ):
            failures.append("Player.gd missing get_sprint_runtime_debug")

    pg = (REPO / "src" / "player" / "Player.gd").read_text(encoding="utf-8", errors="replace")
    if "process_frame(delta, wants_sprint" not in pg:
        failures.append("Player.gd must call process_frame with wants_sprint for regen after release")

    hud = (REPO / "src" / "ui" / "HUD.gd").read_text(encoding="utf-8", errors="replace")
    if "MissionHudDataProvider.get_hud_payload" not in hud:
        failures.append("HUD.gd missing MissionHudDataProvider.get_hud_payload")
    if "SprintStaminaBar" not in hud:
        failures.append("HUD.gd missing SprintStaminaBar")
    if "PoopBagLabel" not in hud:
        failures.append("HUD.gd missing PoopBagLabel")
    if "objective_label" not in hud and "ObjectiveLabel" not in hud:
        failures.append("HUD.gd missing objective ticker wiring")

    if not (REPO / "src" / "missions" / "ui" / "MissionHudDataProvider.gd").is_file():
        failures.append("MissionHudDataProvider.gd missing")

    if not FINAL.is_file():
        failures.append("missing final report json")
    else:
        fr = json.loads(FINAL.read_text(encoding="utf-8"))
        for k in ("root_cause", "files_modified_this_pass", "kimi_used", "runtime_verdict"):
            if k not in fr:
                failures.append(f"final report missing {k}")
        for path in fr.get("files_modified_this_pass", []):
            sp = str(path).replace("\\", "/")
            for bad in FORBIDDEN_MODIFIED:
                if bad in sp:
                    failures.append(f"forbidden modified path in final report: {sp}")

    ok = len(failures) == 0
    run_payload = {
        "ok": ok,
        "fail_count": len(failures),
        "failures": failures,
        "assertions": {
            "static_validator_created": True,
            "static_validator_run": True,
            "static_validator_passed": ok,
        },
    }
    RUN.write_text(json.dumps(run_payload, indent=2), encoding="utf-8")

    val = {
        "static_validator_passed": ok,
        "failures": failures,
        "validator_script": str(Path(__file__).relative_to(REPO)).replace("\\", "/"),
    }
    VALIDATION.write_text(json.dumps(val, indent=2), encoding="utf-8")
    VALIDATION_MD.write_text(
        "# 0M-D5-02B-FIX3 — Validation summary\n\n"
        f"- **static_validator_passed:** {ok}\n"
        f"- **fail_count:** {len(failures)}\n"
        + ("" if ok else "\n## Failures\n\n" + "\n".join(f"- {f}" for f in failures)),
        encoding="utf-8",
    )

    if not ok:
        print("\n".join(failures), file=sys.stderr)
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
