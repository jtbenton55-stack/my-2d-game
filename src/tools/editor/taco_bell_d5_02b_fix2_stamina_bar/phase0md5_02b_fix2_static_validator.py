#!/usr/bin/env python3
"""0M-D5-02B-FIX2 — Static validator for stamina bar fix reports."""
from __future__ import annotations

import json
import sys
from pathlib import Path


def _repo() -> Path:
    p = Path(__file__).resolve()
    for anc in [p.parent, *p.parents]:
        if (anc / "project.godot").is_file():
            return anc
    raise RuntimeError("project.godot not found")


REPO = _repo()
REPORTS = REPO / "docs" / "reports" / "taco_bell_d5_02b_fix2_stamina_bar"
FINAL = REPORTS / "phase0md5_02b_fix2_stamina_bar_final_report.json"
RUN = REPORTS / "phase0md5_02b_fix2_static_validator_run.json"

REQUIRED = [
    "phase0md5_02b_fix2_safety_baseline.md",
    "phase0md5_02b_fix2_safety_baseline.json",
    "phase0md5_02b_fix2_stamina_static_audit.md",
    "phase0md5_02b_fix2_stamina_static_audit.json",
    "phase0md5_02b_fix2_runtime_truth.md",
    "phase0md5_02b_fix2_runtime_truth.json",
    "phase0md5_02b_fix2_stamina_fix.md",
    "phase0md5_02b_fix2_stamina_fix.json",
    "phase0md5_02b_fix2_non_regression.md",
    "phase0md5_02b_fix2_non_regression.json",
    "phase0md5_02b_fix2_validation.md",
    "phase0md5_02b_fix2_validation.json",
    "phase0md5_02b_fix2_stamina_bar_final_report.md",
    "phase0md5_02b_fix2_stamina_bar_final_report.json",
]

FORBIDDEN = (
    "project.godot",
    "src/player/Player.gd",
    "src/player/PlayerStaminaController.gd",
    "scenes/missions_iso/",
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

    for rel in (
        "src/ui/HUD.gd",
        "scenes/ui/hud.tscn",
        "src/missions/ui/MissionHudDataProvider.gd",
    ):
        if not (REPO / rel).is_file():
            failures.append(f"missing {rel}")

    hud = (REPO / "src/ui/HUD.gd").read_text(encoding="utf-8", errors="replace")
    if "stamina_fallback" not in hud:
        failures.append("HUD.gd missing stamina_fallback handling")
    if "SprintStaminaBar" not in hud:
        failures.append("HUD.gd missing SprintStaminaBar reference")

    prov = (REPO / "src/missions/ui/MissionHudDataProvider.gd").read_text(encoding="utf-8", errors="replace")
    if "has_stamina_snapshot" not in prov and "current_stamina" not in prov:
        failures.append("MissionHudDataProvider missing stamina snapshot logic")
    if "stamina_fallback" not in prov:
        failures.append("MissionHudDataProvider missing stamina_fallback in payload")

    tscn = (REPO / "scenes/ui/hud.tscn").read_text(encoding="utf-8", errors="replace")
    if "SprintStaminaBar" not in tscn:
        failures.append("hud.tscn missing SprintStaminaBar")
    if "StyleBoxFlat_StaminaFill" not in tscn:
        failures.append("hud.tscn missing stamina fill style")

    dup = [REPO / "scenes/ui/hud2.tscn", REPO / "src/ui/HUD2.gd"]
    for p in dup:
        if p.is_file():
            failures.append(f"unexpected duplicate HUD {p}")

    if not FINAL.is_file():
        failures.append("missing final report json")
    else:
        fr = json.loads(FINAL.read_text(encoding="utf-8"))
        for k in ("root_cause", "files_modified_this_pass", "verdict"):
            if k not in fr:
                failures.append(f"final report missing {k}")
        for path in fr.get("files_modified_this_pass", []):
            sp = str(path).replace("\\", "/")
            for bad in FORBIDDEN:
                if bad in sp:
                    failures.append(f"forbidden modified path {sp}")

    ok = len(failures) == 0
    RUN.write_text(
        json.dumps(
            {
                "ok": ok,
                "fail_count": len(failures),
                "failures": failures,
                "assertions": {
                    "static_validator_created": True,
                    "static_validator_run": True,
                    "static_validator_passed": ok,
                },
            },
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )
    if FINAL.is_file():
        fr = json.loads(FINAL.read_text(encoding="utf-8"))
        fr["static_validator_result"] = "PASS" if ok else "FAIL"
        FINAL.write_text(json.dumps(fr, indent=2) + "\n", encoding="utf-8")
    val = REPORTS / "phase0md5_02b_fix2_validation.json"
    if val.is_file():
        v = json.loads(val.read_text(encoding="utf-8"))
        v.setdefault("assertions", {})["static_validator_passed"] = ok
        v.setdefault("assertions", {})["static_validator_run"] = True
        val.write_text(json.dumps(v, indent=2) + "\n", encoding="utf-8")

    print(json.dumps({"ok": ok, "out": str(RUN)}, indent=2))
    if failures:
        for f in failures:
            print(f, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
