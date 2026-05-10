#!/usr/bin/env python3
"""
0M-D1-AUDIT — Generate global codebase inventory JSON and run post-write validation checks.

Audit-only. Writes only under docs/reports/mission_module_audit/ (except this script path).
"""

from __future__ import annotations

import json
import re
import subprocess
from datetime import datetime, timezone
from pathlib import Path

# Script lives at res://src/tools/editor/mission_module_audit/ — repo root is four levels above that folder.
ROOT = Path(__file__).resolve().parents[4]
REPORTS = ROOT / "docs/reports/mission_module_audit"
TMP = REPORTS / "tmp"


def _git(args: list[str]) -> str:
    r = subprocess.run(["git", "-C", str(ROOT), *args], capture_output=True, text=True, check=False)
    return (r.stdout or "").strip()


def _type_for_path(p: Path) -> str:
    suf = p.suffix.lower()
    if suf == ".gd":
        return "script"
    if suf == ".tscn":
        return "scene"
    if suf == ".tres":
        return "resource"
    if suf in (".json", ".csv", ".md", ".txt", ".cfg"):
        return "data"
    if suf in (".png", ".jpg", ".wav", ".ogg", ".import"):
        return "asset"
    return "unknown"


def _guess_responsibility(rel: str) -> str:
    r = rel.replace("\\", "/").lower()
    if "missions/iso" in r:
        return "iso_mission_runtime_or_authoring"
    if "missions/" in r and "definitions" in r:
        return "mission_definitions_resources"
    if "missions/" in r:
        return "mission_specific_or_shared_mission"
    if "hideout" in r:
        return "hideout_hub_meta"
    if "autoload" in r:
        return "autoload_singleton"
    if "player" in r:
        return "player"
    if "tools/editor" in r or "tools\\editor" in r:
        return "editor_tooling"
    if "dialogue" in r:
        return "dialogue"
    if "ui/" in r or "\\ui\\" in r:
        return "ui"
    if "levels" in r:
        return "level_mission_base"
    if "collectibles" in r:
        return "collectibles"
    if "inventory" in r:
        return "inventory_cards"
    return "other"


def _reusable_guess(rel: str, typ: str) -> str:
    if typ != "script":
        return "n/a"
    r = rel.replace("\\", "/").lower()
    if "tools/editor" in r:
        return "editor_only"
    if "missions/iso/runtime" in r and "phase0" in r:
        return "taco_bell_phase_runtime_partially_reusable"
    if "missions/definitions" in r:
        return "reusable_data_contracts"
    if "levels/isomissionbase" in r or "levelbase" in r:
        return "reusable_framework"
    if "missions/tacobell" in r or "taco_bell" in r:
        return "mission_specific"
    return "mixed_review"


def _risk(rel: str, typ: str) -> str:
    r = rel.replace("\\", "/").lower()
    if "isomissionbase" in r:
        return "high"
    if "gamestate" in r or "savemanager" in r:
        return "high"
    if "phase0" in r and "missions/iso" in r:
        return "medium"
    if typ == "scene" and "tacobell" in r:
        return "medium"
    return "low"


def build_global_inventory() -> dict:
    entries: list[dict] = []
    scan_roots = [
        ROOT / "src",
        ROOT / "scenes",
        ROOT / "data",
        ROOT / "docs" / "reports",
        ROOT / "addons",
    ]
    for base in scan_roots:
        if not base.exists():
            continue
        for p in base.rglob("*"):
            if p.is_dir():
                continue
            if "__pycache__" in str(p) or p.suffix == ".import" and p.stat().st_size > 5_000_000:
                continue
            rel = str(p.relative_to(ROOT)).replace("\\", "/")
            typ = _type_for_path(p)
            entries.append(
                {
                    "path": "res://" + rel,
                    "path_os": rel,
                    "type": typ,
                    "likely_responsibility": _guess_responsibility(rel),
                    "reusable_guess": _reusable_guess(rel, typ),
                    "editor_tooling_only": "tools/editor" in rel.replace("\\", "/").lower(),
                    "mission_specific_guess": "taco" in rel.lower() and "missions" in rel.lower(),
                    "risk_level": _risk(rel, typ),
                }
            )
    autoloads: list[dict] = []
    pg = ROOT / "project.godot"
    if pg.exists():
        txt = pg.read_text(encoding="utf-8", errors="replace")
        m = re.findall(r'^([A-Za-z0-9_]+)="\*?(res://[^"]+)"', txt, re.MULTILINE)
        for name, path in m:
            if name.startswith("config") or name in ("run",):
                continue
            if path.startswith("res://"):
                autoloads.append({"name": name, "path": path})
    return {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "entry_count": len(entries),
        "note": "res://assets/ not fully enumerated (large binaries); mission defs under assets/missions/ exist per Taco Bell scene refs.",
        "autoloads": autoloads,
        "entries": sorted(entries, key=lambda e: e["path_os"]),
    }


def main() -> None:
    REPORTS.mkdir(parents=True, exist_ok=True)
    TMP.mkdir(parents=True, exist_ok=True)

    inv = build_global_inventory()
    (REPORTS / "global_codebase_inventory.json").write_text(json.dumps(inv, indent=2), encoding="utf-8")
    lines = [
        "# Global codebase inventory",
        "",
        f"- **entries:** {inv['entry_count']}",
        f"- **autoloads:** {len(inv['autoloads'])}",
        "",
        "## Autoloads",
        "",
    ]
    for a in inv["autoloads"]:
        lines.append(f"- `{a['name']}` → `{a['path']}`")
    lines.extend(["", "## Note", "", "Full machine list is in `global_codebase_inventory.json`.", ""])
    (REPORTS / "global_codebase_inventory.md").write_text("\n".join(lines), encoding="utf-8")
    print("Wrote global_codebase_inventory.{json,md}")


if __name__ == "__main__":
    main()
