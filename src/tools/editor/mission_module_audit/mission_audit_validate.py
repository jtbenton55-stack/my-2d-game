#!/usr/bin/env python3
"""Audit-only: validate mission module audit reports and protected-path git diff."""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
REPORTS = ROOT / "docs/reports/mission_module_audit"

REQUIRED = [
    "safety_baseline.md",
    "safety_baseline.json",
    "global_codebase_inventory.md",
    "global_codebase_inventory.json",
    "current_module_inventory.md",
    "current_module_inventory.json",
    "taco_bell_current_architecture_audit.md",
    "taco_bell_current_architecture_audit.json",
    "spaghetti_risk_audit.md",
    "spaghetti_risk_audit.json",
    "reusable_module_gap_analysis.md",
    "reusable_module_gap_analysis.json",
    "module_ownership_map.md",
    "module_ownership_map.json",
    "recommended_implementation_sequence.md",
    "recommended_implementation_sequence.json",
    "phase0md1_module_spine_audit.md",
    "phase0md1_module_spine_audit.json",
]

PROTECTED = [
    "scenes/characters/player.tscn",
    "src/player/Player.gd",
    "scenes/missions_iso/TacoBellIso_Editable.tscn",
    "scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn",
    "scenes/hideout/HideoutHub.tscn",
    "project.godot",
]


def _git_diff_names() -> list[str]:
    r = subprocess.run(
        ["git", "-C", str(ROOT), "diff", "--name-only", "HEAD"],
        capture_output=True,
        text=True,
        check=False,
    )
    lines = [ln.strip().replace("\\", "/") for ln in (r.stdout or "").splitlines() if ln.strip()]
    return lines


def main() -> int:
    results: dict = {"ok": True, "checks": []}

    for name in REQUIRED:
        p = REPORTS / name
        chk = {"file": name, "exists": p.exists()}
        if not p.exists():
            results["ok"] = False
        elif name.endswith(".json"):
            try:
                json.loads(p.read_text(encoding="utf-8"))
                chk["json_parseable"] = True
            except json.JSONDecodeError as e:
                chk["json_parseable"] = False
                chk["error"] = str(e)
                results["ok"] = False
        results["checks"].append(chk)

    dirty = set(_git_diff_names())
    prot_hits = [p for p in PROTECTED if p in dirty]
    results["protected_paths_in_git_diff_head"] = prot_hits
    results["protected_clean"] = len(prot_hits) == 0
    if prot_hits:
        results["ok"] = False

    own = REPORTS / "module_ownership_map.json"
    if own.exists():
        results["module_ownership_rows"] = len(own.read_text(encoding="utf-8"))

    gap = REPORTS / "reusable_module_gap_analysis.json"
    if gap.exists():
        g = json.loads(gap.read_text(encoding="utf-8"))
        results["gap_spine_items"] = len(g.get("spine_items", []))
        if results["gap_spine_items"] < 20:
            results["ok"] = False
            results["gap_spine_items_ok"] = False
        else:
            results["gap_spine_items_ok"] = True

    inv = REPORTS / "current_module_inventory.json"
    if inv.exists():
        data = json.loads(inv.read_text(encoding="utf-8"))
        nc = len(data.get("categories", {}))
        results["module_categories_count"] = nc
        results["all_module_categories_checked"] = nc >= 15
        if nc < 15:
            results["ok"] = False
            results["module_categories_ok"] = False
        else:
            results["module_categories_ok"] = True

    tb = REPORTS / "taco_bell_current_architecture_audit.json"
    if tb.exists():
        tbd = json.loads(tb.read_text(encoding="utf-8"))
        mn = tbd.get("must_not_forget", [])
        results["must_not_forget_count"] = len(mn)
        if len(mn) < 7:
            results["ok"] = False
            results["must_not_forget_ok"] = False
        else:
            results["must_not_forget_ok"] = True

    seq = REPORTS / "recommended_implementation_sequence.json"
    if seq.exists():
        sq = json.loads(seq.read_text(encoding="utf-8"))
        inp = str(sq.get("immediate_next_pass", "")).strip()
        results["implementation_phases"] = len(sq.get("phases", []))
        results["immediate_next_pass"] = inp
        results["immediate_next_pass_len"] = len(inp)
        if len(inp) < 80:
            results["ok"] = False
            results["immediate_next_pass_ok"] = False
        else:
            results["immediate_next_pass_ok"] = True

    REPORTS.mkdir(parents=True, exist_ok=True)
    (REPORTS / "validation.json").write_text(json.dumps(results, indent=2), encoding="utf-8")
    lines = [
        "# Validation — mission module audit",
        "",
        f"- **overall_ok:** {results['ok']}",
        f"- **protected paths dirty vs HEAD:** {prot_hits or 'none'}",
        "",
        "## Checks",
        "",
    ]
    for c in results["checks"]:
        lines.append(f"- `{c['file']}`: exists={c.get('exists')}" + (f", json_ok={c.get('json_parseable')}" if "json_parseable" in c else ""))
    lines.append("")
    (REPORTS / "validation.md").write_text("\n".join(lines), encoding="utf-8")
    return 0 if results["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
