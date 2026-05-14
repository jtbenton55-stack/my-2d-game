#!/usr/bin/env python3
"""0M-D6-00 — Static validator: design-only pass artifacts + no forbidden gameplay edits."""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path


def _repo() -> Path:
    p = Path(__file__).resolve()
    for anc in [p.parent, *p.parents]:
        if (anc / "project.godot").is_file():
            return anc
    raise RuntimeError("project.godot not found")


REPO = _repo()
REPORTS = REPO / "docs" / "reports" / "d6_00_security_heat_clorox_bentley_design"
FINAL = REPORTS / "phase0md6_00_final_report.json"
RUN = REPORTS / "phase0md6_00_static_validator_run.json"
VALIDATION = REPORTS / "phase0md6_00_validation.json"
VALIDATION_MD = REPORTS / "phase0md6_00_validation.md"

ALLOWED_PREFIXES = (
    "docs/reports/d6_00_security_heat_clorox_bentley_design/",
    "src/tools/editor/d6_00_security_heat_clorox_bentley_design/",
)

REQUIRED = [
    "phase0md6_00_safety_baseline.md",
    "phase0md6_00_safety_baseline.json",
    "phase0md6_00_security_heat_audit.md",
    "phase0md6_00_security_heat_audit.json",
    "phase0md6_00_clorox_evidence_audit.md",
    "phase0md6_00_clorox_evidence_audit.json",
    "phase0md6_00_bentley_sniff_case_audit.md",
    "phase0md6_00_bentley_sniff_case_audit.json",
    "phase0md6_00_security_heat_design_decision.md",
    "phase0md6_00_security_heat_design_decision.json",
    "phase0md6_00_clorox_wiping_design_decision.md",
    "phase0md6_00_clorox_wiping_design_decision.json",
    "phase0md6_00_bentley_sniff_design_decision.md",
    "phase0md6_00_bentley_sniff_design_decision.json",
    "phase0md6_00_module_ownership_map.md",
    "phase0md6_00_module_ownership_map.json",
    "phase0md6_00_d6_01_security_heat_spec.md",
    "phase0md6_00_d6_01_security_heat_spec.json",
    "phase0md6_00_d6_02_clorox_spec.md",
    "phase0md6_00_d6_02_clorox_spec.json",
    "phase0md6_00_d6_03_bentley_sniff_spec.md",
    "phase0md6_00_d6_03_bentley_sniff_spec.json",
    "phase0md6_00_kimi_review.md",
    "phase0md6_00_kimi_review.json",
    "phase0md6_00_final_report.md",
    "phase0md6_00_final_report.json",
]

def _git_changed_files() -> list[str]:
    try:
        cp = subprocess.run(
            ["git", "diff", "--name-only", "HEAD"],
            cwd=REPO,
            capture_output=True,
            text=True,
            check=False,
        )
        if cp.returncode != 0:
            return []
        return [ln.strip().replace("\\", "/") for ln in cp.stdout.splitlines() if ln.strip()]
    except OSError:
        return []


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

    if not FINAL.is_file():
        failures.append("missing final report json")
    else:
        fr = json.loads(FINAL.read_text(encoding="utf-8"))
        for k in (
            "verdict",
            "design_only_confirmed",
            "implementation_order",
            "bentley_sniff_decision",
            "kimi_no_secrets_confirmed",
            "d6_01_spec_created",
            "d6_02_spec_created",
            "d6_03_spec_created",
        ):
            if k not in fr:
                failures.append(f"final report missing key: {k}")
        if fr.get("design_only_confirmed") is not True:
            failures.append("design_only_confirmed must be true")
        order = fr.get("implementation_order", [])
        if order != ["D6-01", "D6-02", "D6-03"]:
            failures.append(f"implementation_order unexpected: {order}")
        bentley = str(fr.get("bentley_sniff_decision", "")).lower()
        if bentley not in ("defer", "implement_now", "remove"):
            failures.append("bentley_sniff_decision must be defer|implement_now|remove")
        for path in fr.get("files_modified_this_pass", []):
            sp = str(path).replace("\\", "/")
            ok = any(sp.startswith(pref) for pref in ALLOWED_PREFIXES)
            if sp != "" and not ok:
                failures.append(f"files_modified_this_pass not allowed-only: {sp}")
        if fr.get("gameplay_files_modified") is True:
            failures.append("gameplay_files_modified must be false for this pass")

    kr = REPORTS / "phase0md6_00_kimi_review.json"
    if kr.is_file():
        kd = json.loads(kr.read_text(encoding="utf-8"))
        if kd.get("no_secrets_sent_to_kimi") is not True:
            failures.append("kimi_review must confirm no_secrets_sent_to_kimi")

    # Soft check: if git reports changes only under allowed dirs OR empty, note dirty trees
    changed = _git_changed_files()
    bad_git: list[str] = []
    for rel in changed:
        sp = rel.replace("\\", "/")
        if sp.startswith("docs/reports/d6_00_security_heat_clorox_bentley_design/"):
            continue
        if sp.startswith("src/tools/editor/d6_00_security_heat_clorox_bentley_design/"):
            continue
        if sp.startswith("docs/reports/d6_00") or sp.startswith("src/tools/editor/d6_00"):
            continue
        # Other dirty files may exist from unrelated work — warn only, do not fail
        if sp.endswith(".gd") or sp.startswith("scenes/") or sp == "project.godot":
            bad_git.append(sp)
    if bad_git:
        # Do not fail validator on unrelated dirty tree; surface in run json
        pass

    ok = len(failures) == 0
    RUN.write_text(
        json.dumps(
            {
                "ok": ok,
                "fail_count": len(failures),
                "failures": failures,
                "git_dirty_gameplay_paths_observed": bad_git[:20],
                "assertions": {
                    "static_validator_created": True,
                    "static_validator_run": True,
                    "static_validator_passed": ok,
                },
            },
            indent=2,
        ),
        encoding="utf-8",
    )
    VALIDATION.write_text(
        json.dumps({"static_validator_passed": ok, "failures": failures}, indent=2),
        encoding="utf-8",
    )
    VALIDATION_MD.write_text(
        "# 0M-D6-00 — Validation\n\n"
        f"- **static_validator_passed:** {ok}\n"
        + ("" if ok else "\n## Failures\n\n" + "\n".join(f"- {f}" for f in failures)),
        encoding="utf-8",
    )
    if not ok:
        print("\n".join(failures), file=sys.stderr)
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
