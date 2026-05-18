#!/usr/bin/env python3
"""PHASE 0M-D6-04A F10 security debug panel cleanup static validator."""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

REPORT_DIR = "d6_04a_f10_security_debug_cleanup"
FORBIDDEN_PREFIXES = (
    "project.godot",
    "src/player/Player.gd",
    "src/player/PlayerStaminaController.gd",
    "src/enemies/Guard.gd",
    "scenes/characters/player.tscn",
    "assets/",
)
FORBIDDEN_SUFFIXES = (".tscn",)
LEGACY_GEOMETRY_MARKERS = (
    "fix7f_chosen_x",
    "fix7f_chosen_probe_y",
    "fix7e_visual_trigger_mismatch",
    "choke_x",
    "probe_y",
    "top_hit",
    "bottom_hit",
    "FIX7D",
    "FIX7E",
    "FIX7F geometry",
)
REQUIRED_SECTIONS = (
    "--- Mission ---",
    "--- Security Authoring ---",
    "--- Event Router ---",
    "--- AMBUSH Beam ---",
    "--- Authored Camera ---",
    "--- Guard Spawn / AI ---",
)
REQUIRED_D6_FIELDS = (
    "d6_03_security_router_active",
    "d6_04_runtime_authored_camera_count",
    "d6_04_last_beam_event_handled",
    "Manual test: cross AMBUSH beam",
)


def repo_root() -> Path:
    return Path(__file__).resolve().parents[4]


def git_changed(root: Path) -> list[str]:
    out: list[str] = []
    for args in (["git", "diff", "--name-only"], ["git", "diff", "--cached", "--name-only"]):
        r = subprocess.run(args, cwd=str(root), capture_output=True, text=True, check=False)
        for ln in r.stdout.splitlines():
            s = ln.strip().replace("\\", "/")
            if s:
                out.append(s)
    return list(dict.fromkeys(out))


def main() -> int:
    root = repo_root()
    rd = root / "docs" / "reports" / REPORT_DIR
    errors: list[str] = []

    panel = root / "src/missions/iso/runtime/IsoMissionDebugPanel.gd"
    if not panel.is_file():
        errors.append("missing IsoMissionDebugPanel.gd")
        pt = ""
    else:
        pt = panel.read_text(encoding="utf-8")
        if "SHOW_LEGACY_SECURITY_DEBUG" not in pt:
            errors.append("missing SHOW_LEGACY_SECURITY_DEBUG constant")
        elif "SHOW_LEGACY_SECURITY_DEBUG := false" not in pt and "SHOW_LEGACY_SECURITY_DEBUG = false" not in pt:
            errors.append("SHOW_LEGACY_SECURITY_DEBUG must default to false")
        if "_build_authoring_security_f10_lines" not in pt:
            errors.append("missing _build_authoring_security_f10_lines helper")
        for section in REQUIRED_SECTIONS:
            if section not in pt:
                errors.append(f"missing F10 section heading: {section}")
        for field in REQUIRED_D6_FIELDS:
            if field not in pt:
                errors.append(f"missing D6-04 display field reference: {field}")
        if "_build_legacy_security_f10_lines" not in pt:
            errors.append("missing legacy subsection builder")
        # Default view must not embed FIX7 geometry spam in _refresh_status sec_lines block.
        refresh_start = pt.find("func _refresh_status")
        refresh_end = pt.find("func _build_authoring_security_f10_lines", refresh_start)
        if refresh_start == -1:
            errors.append("missing _refresh_status")
        else:
            refresh_block = pt[refresh_start:refresh_end] if refresh_end != -1 else pt[refresh_start:]
            for marker in LEGACY_GEOMETRY_MARKERS:
                if marker in refresh_block:
                    errors.append(f"legacy geometry marker in _refresh_status: {marker}")
        legacy_fn = pt[pt.find("func _build_legacy_security_f10_lines") :]
        authoring_fn = pt[pt.find("func _build_authoring_security_f10_lines") : pt.find("func _build_legacy_security_f10_lines")]
        for marker in ("choke_x", "probe_y", "fix7f_chosen_x"):
            if marker in authoring_fn:
                errors.append(f"legacy geometry shown in default authoring builder: {marker}")

    allowed_prefixes = (
        "src/missions/iso/runtime/IsoMissionDebugPanel.gd",
        "src/tools/editor/d6_04a_f10_security_debug_cleanup/",
        "docs/reports/d6_04a_f10_security_debug_cleanup/",
    )
    changed = git_changed(root)
    warnings: list[str] = []
    for path in changed:
        norm = path.replace("\\", "/")
        if any(norm.startswith(p) for p in allowed_prefixes):
            continue
        for bad in FORBIDDEN_PREFIXES:
            if norm.startswith(bad):
                warnings.append(f"pre-existing or out-of-scope change (not D6-04A): {path}")
        if any(norm.endswith(suf) for suf in FORBIDDEN_SUFFIXES):
            warnings.append(f"pre-existing or out-of-scope scene change (not D6-04A): {path}")

    rd.mkdir(parents=True, exist_ok=True)
    result = {
        "pass": len(errors) == 0,
        "errors": errors,
        "warnings": warnings,
        "changed_files": changed,
    }
    (rd / "phase0md6_04a_static_validator_run.json").write_text(json.dumps(result, indent=2), encoding="utf-8")
    print("PASS" if result["pass"] else "FAIL")
    for err in errors:
        print(f"  - {err}")
    return 0 if result["pass"] else 1


if __name__ == "__main__":
    sys.exit(main())
