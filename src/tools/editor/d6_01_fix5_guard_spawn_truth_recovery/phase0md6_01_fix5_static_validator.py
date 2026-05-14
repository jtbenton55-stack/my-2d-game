#!/usr/bin/env python3
from __future__ import annotations
import json
import subprocess
import sys
from pathlib import Path

def find_repo(start: Path) -> Path:
    for p in [start] + list(start.parents):
        if (p / "project.godot").is_file():
            return p
    raise RuntimeError("repo root not found")

REPO = find_repo(Path(__file__).resolve().parent)
REPORT = REPO / "docs" / "reports" / "d6_01_fix5_guard_spawn_truth_recovery"
REQ = [
"phase0md6_01_fix5_safety_baseline",
"phase0md6_01_fix5_regression_diff_audit",
"phase0md6_01_fix5_spawn_pipeline_audit",
"phase0md6_01_fix5_map_bounds_spawn_location_audit",
"phase0md6_01_fix5_runtime_probe_plan",
"phase0md6_01_fix5_kimi_review",
"phase0md6_01_fix5_guard_spawn_cap_repair",
"phase0md6_01_fix5_camera_spawn_restore",
"phase0md6_01_fix5_wrong_code_spawn_restore",
"phase0md6_01_fix5_remove_test_warp",
"phase0md6_01_fix5_visible_beam_right_hallway",
"phase0md6_01_fix5_f10_spawn_truth_cleanup",
"phase0md6_01_fix5_heat_hideout_note",
"phase0md6_01_fix5_static_self_review",
"phase0md6_01_fix5_runtime_validation",
"phase0md6_01_fix5_final_report",
]

def assertion_errors(data: dict) -> list[str]:
    out=[]
    a=data.get("assertions")
    if isinstance(a, dict):
        for k,v in a.items():
            if v is not True:
                out.append(f"assertion_not_true:{k}")
    return out

def main() -> int:
    errs=[]
    for stem in REQ:
        md=REPORT/f"{stem}.md"
        js=REPORT/f"{stem}.json"
        if not md.is_file(): errs.append(f"missing_md:{md.name}")
        if not js.is_file(): errs.append(f"missing_json:{js.name}")
        if js.is_file():
            try:
                data=json.loads(js.read_text(encoding="utf-8"))
            except Exception as e:
                errs.append(f"bad_json:{js.name}:{e}")
            else:
                errs.extend(assertion_errors(data))
    final_js=REPORT/"phase0md6_01_fix5_final_report.json"
    if final_js.is_file():
        f=json.loads(final_js.read_text(encoding="utf-8"))
        for k in ["exact_root_cause","offmap_consumed_cap_before_fix5","camera_visible_guard_spawn","wrong_code_visible_guard_spawn","purple_warp_removed","red_beam_status","runtime_validation","kimi_status"]:
            if k not in f: errs.append(f"final_missing:{k}")
    else:
        errs.append("missing_final_report_json")

    proc=subprocess.run(["git","diff","--name-only","HEAD"], cwd=str(REPO), capture_output=True, text=True, check=False)
    changed=[x.strip().replace('\\','/') for x in proc.stdout.splitlines() if x.strip()]
    forb=["project.godot","src/player/Player.gd","src/player/PlayerStaminaController.gd","scenes/characters/player.tscn"]
    for f in forb:
        if any(c==f or c.endswith(f) for c in changed):
            errs.append(f"forbidden_modified:{f}")
    if any(c.startswith("assets/") for c in changed):
        errs.append("assets_modified")

    iso=(REPO/"src/levels/IsoMissionBase.gd").read_text(encoding="utf-8", errors="replace")
    for n in ["_count_functional_security_response_guards","_count_raw_security_response_guards","_count_invalid_security_response_guards","_record_security_spawn_probe","_ensure_d6_fix5_runtime_helpers","D6_FIX5_TEMP_SECURITY_BEAM_REMOVE_OR_FINALIZE_IN_LEVEL_PASS"]:
        if n not in iso: errs.append(f"iso_missing:{n}")
    if "_setup_d6_fix4_garage_code_test_warp" in iso:
        errs.append("fix4_warp_setup_still_present")

    panel=(REPO/"src/missions/iso/runtime/IsoMissionDebugPanel.gd").read_text(encoding="utf-8", errors="replace")
    for n in ["Guard cap: functional","Last spawn: source","Beam status"]:
        if n not in panel: errs.append(f"panel_missing:{n}")

    out={
      "assertions":{
        "static_validator_created":True,
        "static_validator_run":True,
        "static_validator_passed":len(errs)==0
      },
      "errors":errs,
      "changed_files":changed[:80]
    }
    (REPORT/"phase0md6_01_fix5_static_validator_run.json").write_text(json.dumps(out,indent=2)+"\n", encoding="utf-8")
    (REPORT/"phase0md6_01_fix5_validation.json").write_text(json.dumps(out,indent=2)+"\n", encoding="utf-8")
    (REPORT/"phase0md6_01_fix5_validation.md").write_text("# FIX5 validation\n\n" + ("**PASS**\n" if not errs else "**FAIL**\n") + "\n".join(f"- {e}" for e in errs)+"\n", encoding="utf-8")

    if final_js.is_file() and not errs:
        f=json.loads(final_js.read_text(encoding="utf-8"))
        f["static_validator"]="PASS"
        final_js.write_text(json.dumps(f, indent=2)+"\n", encoding="utf-8")

    print("VALIDATOR_PASS" if not errs else "VALIDATOR_FAIL")
    return 0 if not errs else 1

if __name__ == "__main__":
    raise SystemExit(main())
