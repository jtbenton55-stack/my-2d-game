#!/usr/bin/env python3
"""0M-D5-02B-FIX4 — Static validator for stamina regen tuning reports."""
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
REPORTS = REPO / "docs" / "reports" / "taco_bell_d5_02b_fix4_stamina_regen_tuning"
FINAL = REPORTS / "phase0md5_02b_fix4_stamina_regen_tuning_final_report.json"
RUN = REPORTS / "phase0md5_02b_fix4_static_validator_run.json"
VALIDATION = REPORTS / "phase0md5_02b_fix4_validation.json"
VALIDATION_MD = REPORTS / "phase0md5_02b_fix4_validation.md"

REQUIRED = [
    "phase0md5_02b_fix4_safety_baseline.md",
    "phase0md5_02b_fix4_safety_baseline.json",
    "phase0md5_02b_fix4_stamina_tuning_audit.md",
    "phase0md5_02b_fix4_stamina_tuning_audit.json",
    "phase0md5_02b_fix4_stamina_tuning_fix.md",
    "phase0md5_02b_fix4_stamina_tuning_fix.json",
    "phase0md5_02b_fix4_non_regression.md",
    "phase0md5_02b_fix4_non_regression.json",
    "phase0md5_02b_fix4_runtime_validation.md",
    "phase0md5_02b_fix4_runtime_validation.json",
    "phase0md5_02b_fix4_stamina_regen_tuning_final_report.md",
    "phase0md5_02b_fix4_stamina_regen_tuning_final_report.json",
]

FORBIDDEN = (
    "project.godot",
    "scenes/missions_iso/",
    "scenes/missions/TacoBellMission.tscn",
    "scenes/hideout/HideoutHub.tscn",
    "scenes/characters/player.tscn",
    "assets/",
)


def _parse_rate_assign(txt: str, var_name: str) -> float | None:
    mloc = re.search(rf"{re.escape(var_name)}\s*:\s*float\s*=\s*(.+)", txt)
    if not mloc:
        return None
    s = mloc.group(1).strip()
    if "##" in s:
        s = s.split("##", 1)[0].strip()
    if "/" in s:
        parts = [p.strip() for p in s.split("/", 1)]
        if len(parts) == 2:
            try:
                return float(parts[0]) / float(parts[1])
            except ValueError:
                return None
    try:
        return float(s)
    except ValueError:
        return None


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
    parsed_regen: float | None = None
    parsed_drain: float | None = None
    if not psc.is_file():
        failures.append("missing PlayerStaminaController.gd")
    else:
        txt = psc.read_text(encoding="utf-8", errors="replace")
        if "regen_rate_per_sec" not in txt:
            failures.append("PlayerStaminaController missing regen_rate_per_sec")
        if "process_frame" not in txt:
            failures.append("PlayerStaminaController missing process_frame")
        if "minf(max_stamina" not in txt:
            failures.append("PlayerStaminaController regen must use minf clamp")
        parsed_regen = _parse_rate_assign(txt, "regen_rate_per_sec")
        if parsed_regen is None:
            failures.append("could not parse regen_rate_per_sec from script")
        elif parsed_regen >= 22.0:
            failures.append(f"regen_rate_per_sec should be < 22 (got {parsed_regen})")
        parsed_drain = _parse_rate_assign(txt, "drain_rate_per_sec")
        if parsed_drain is None:
            failures.append("could not parse drain_rate_per_sec from script")
        elif parsed_drain < 40.0 or parsed_drain > 60.0:
            failures.append(f"drain_rate_per_sec {parsed_drain} outside 40–60 sanity band (expect ~50)")

        if '"current_stamina"' not in txt or '"max_stamina"' not in txt:
            failures.append("get_stamina_snapshot must expose current_stamina and max_stamina")

    if not FINAL.is_file():
        failures.append("missing final report json")
    else:
        fr = json.loads(FINAL.read_text(encoding="utf-8"))
        for k in (
            "old_regen_rate_per_sec",
            "new_regen_rate_per_sec",
            "estimated_full_refill_seconds",
            "kimi_used",
            "manual_test_checklist",
        ):
            if k not in fr:
                failures.append(f"final report missing key: {k}")
        old_r = float(fr.get("old_regen_rate_per_sec", 0.0))
        new_r = float(fr.get("new_regen_rate_per_sec", 0.0))
        if new_r >= old_r:
            failures.append("new regen rate must be slower than old per audit")
        refill = float(fr.get("estimated_full_refill_seconds", 0.0))
        if refill < 6.5 or refill > 22.0:
            failures.append(
                f"estimated_full_refill_seconds {refill} outside 6.5–22s sanity band (tunable regen)"
            )
        if parsed_regen is not None and abs(parsed_regen - new_r) > 0.05:
            failures.append(
                f"script regen_rate_per_sec {parsed_regen} vs final report new_regen_rate_per_sec {new_r}"
            )
        if "new_drain_rate_per_sec" in fr and parsed_drain is not None:
            dr = float(fr["new_drain_rate_per_sec"])
            if abs(parsed_drain - dr) > 0.05:
                failures.append(
                    f"script drain_rate_per_sec {parsed_drain} vs final report new_drain_rate_per_sec {dr}"
                )
        if not isinstance(fr.get("manual_test_checklist"), list) or len(fr["manual_test_checklist"]) < 10:
            failures.append("manual_test_checklist missing or too short")
        for path in fr.get("files_modified_this_pass", []):
            sp = str(path).replace("\\", "/")
            for bad in FORBIDDEN:
                if bad in sp:
                    failures.append(f"forbidden path in files_modified_this_pass: {sp}")

    hud = (REPO / "src" / "ui" / "HUD.gd").read_text(encoding="utf-8", errors="replace")
    if "objective_label" not in hud and "ObjectiveLabel" not in hud:
        failures.append("HUD.gd objective ticker wiring not found")
    if "SprintStaminaBar" not in hud:
        failures.append("HUD.gd missing SprintStaminaBar")
    if "PoopBagLabel" not in hud:
        failures.append("HUD.gd missing PoopBagLabel")

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
    val = {"static_validator_passed": ok, "failures": failures}
    VALIDATION.write_text(json.dumps(val, indent=2), encoding="utf-8")
    VALIDATION_MD.write_text(
        "# 0M-D5-02B-FIX4 — Validation\n\n"
        f"- **static_validator_passed:** {ok}\n"
        + ("" if ok else "\n## Failures\n\n" + "\n".join(f"- {f}" for f in failures)),
        encoding="utf-8",
    )
    if not ok:
        print("\n".join(failures), file=sys.stderr)
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
