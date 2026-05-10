#!/usr/bin/env python3
"""
0M-D2A-FIX2 static sprint / debug harness validator.
Run from repo root: python src/tools/editor/mission_foundation_d2a_fix2_sprint_runtime_debug/phase0md2a_fix2_sprint_runtime_validator.py
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path


def _read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace")


def _fail(msgs: list[str], errors: list[str]) -> None:
    errors.extend(msgs)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", type=Path, default=None, help="Project root (default: cwd)")
    args = ap.parse_args()
    root: Path = args.root or Path.cwd()
    errors: list[str] = []
    warnings: list[str] = []

    godot = root / "project.godot"
    player = root / "src" / "player" / "Player.gd"
    stamina = root / "src" / "player" / "PlayerStaminaController.gd"
    overlay = root / "src" / "player" / "PlayerSprintDebugOverlay.gd"
    harness_gd = root / "scenes" / "hideout" / "tools" / "PlayerSprintRuntimeTest_0MD2A_FIX2.gd"
    harness_tscn = root / "scenes" / "hideout" / "tools" / "PlayerSprintRuntimeTest_0MD2A_FIX2.tscn"
    taco_a = root / "scenes" / "missions_iso" / "TacoBellIso_Editable_RedesignTest.tscn"
    taco_b = root / "scenes" / "missions_iso" / "TacoBellIso_Editable.tscn"
    backup_glob = root / "docs" / "reports" / "mission_foundation_d2a_fix2_sprint_runtime_debug" / "backups"

    for p, label in [
        (godot, "project.godot"),
        (player, "Player.gd"),
        (stamina, "PlayerStaminaController.gd"),
        (overlay, "PlayerSprintDebugOverlay.gd"),
        (harness_gd, "PlayerSprintRuntimeTest_0MD2A_FIX2.gd"),
        (harness_tscn, "PlayerSprintRuntimeTest_0MD2A_FIX2.tscn"),
    ]:
        if not p.is_file():
            _fail([f"missing {label}: {p}"], errors)

    if errors:
        print(json.dumps({"ok": False, "errors": errors}, indent=2))
        return 1

    gtxt = _read_text(godot)
    ptxt = _read_text(player)
    stxt = _read_text(stamina)
    otxt = _read_text(overlay)

    if not re.search(r"(?m)^sprint=\{", gtxt):
        _fail(["project.godot: no sprint={ block"], errors)
    if "dodge={" not in gtxt:
        _fail(["project.godot: no dodge action"], errors)
    if '"physical_keycode":32' not in gtxt:
        _fail(["project.godot: dodge should bind Space (physical_keycode 32)"], errors)

    sprint_chunk = gtxt.split("sprint=", 1)[1][:1200] if "sprint=" in gtxt else ""
    if '"physical_keycode":4194326' not in sprint_chunk and "4194326" not in sprint_chunk:
        _fail(["project.godot: sprint block missing Ctrl (4194326)"], errors)
    if '"physical_keycode":67' not in sprint_chunk:
        _fail(["project.godot: sprint should include documented C fallback (physical_keycode 67)"], errors)
    if '"physical_keycode":32' in sprint_chunk:
        _fail(["project.godot: Space (32) must not be bound on sprint"], errors)

    for needle in [
        "func is_sprint_requested",
        "func is_sprint_active",
        "func get_speed_multiplier",
        "func get_debug_snapshot",
        "func get_sprint_signal_chain_debug",
    ]:
        if needle not in stxt:
            _fail([f"PlayerStaminaController.gd missing {needle}"], errors)

    if "get_action_strength" not in stxt:
        _fail(["PlayerStaminaController: is_sprint_requested should use get_action_strength"], errors)
    if "is_key_pressed(KEY_CTRL)" not in stxt:
        _fail(["PlayerStaminaController: expected Input.is_key_pressed(KEY_CTRL) in is_sprint_requested"], errors)

    for needle in [
        "func get_sprint_runtime_debug",
        "_stamina_controller.process_frame",
        "get_speed_multiplier",
        "_SprintDebugOverlayScript",
        "PlayerSprintDebugOverlay.gd",
    ]:
        if needle not in ptxt:
            _fail([f"Player.gd missing {needle}"], errors)

    mult_hits = len(re.findall(r"sprint_mult", ptxt))
    if mult_hits < 2:
        _fail(["Player.gd: expected sprint_mult usage"], errors)
    if ptxt.count("move_speed *= sprint_mult") != 1:
        _fail(["Player.gd: sprint multiplier should apply to move_speed exactly once (move_speed *= sprint_mult)"], errors)

    if re.search(r"if\s+combat_on\s*:[\s\S]{0,120}sprint_mult\s*=\s*1", ptxt):
        _fail(["Player.gd: suspicious permanent sprint kill tied to combat_on"], errors)

    if "run_animation_required" not in stxt:
        _fail(["PlayerStaminaController: run_animation_required should be documented false in debug"], errors)

    if "class_name PlayerSprintDebugOverlay" not in otxt:
        _fail(["PlayerSprintDebugOverlay.gd should declare class_name PlayerSprintDebugOverlay"], errors)
    for k in ["ctrl_physical_pressed", "sprint_action_pressed", "is_sprint_requested", "velocity_length_post_slide"]:
        if k not in otxt:
            _fail([f"overlay should reference {k}"], errors)

    # Reports dir + sample JSON parse
    rep_dir = root / "docs" / "reports" / "mission_foundation_d2a_fix2_sprint_runtime_debug"
    for name in [
        "phase0md2a_fix2_safety_baseline.json",
        "phase0md2a_fix2_debug_overlay.json",
        "phase0md2a_fix2_failure_chain_audit.json",
        "phase0md2a_fix2_implementation.json",
        "phase0md2a_fix2_test_harness.json",
        "phase0md2a_fix2_validation.json",
        "phase0md2a_fix2_runtime_validation.json",
        "phase0md2a_fix2_final_safety_review.json",
        "phase0md2a_fix2_sprint_runtime_debug_fix.json",
    ]:
        jp = rep_dir / name
        if not jp.is_file():
            _fail([f"missing report json: {jp}"], errors)
        else:
            try:
                json.loads(jp.read_text(encoding="utf-8"))
            except json.JSONDecodeError as e:
                _fail([f"invalid json {jp}: {e}"], errors)

    if not list(backup_glob.glob("project.phase0md2a_fix2_sprint_backup.*.godot")):
        warnings.append(f"no project.godot backup under {backup_glob} (expected FIX2 backup)")

    # git diff for protected scenes (best-effort)
    def _git_diff_paths() -> list[str]:
        try:
            out = subprocess.run(
                ["git", "diff", "--name-only", "HEAD"],
                cwd=str(root),
                capture_output=True,
                text=True,
                timeout=30,
            )
            if out.returncode != 0:
                return []
            return [ln.strip() for ln in out.stdout.splitlines() if ln.strip()]
        except (OSError, subprocess.TimeoutExpired):
            return []

    changed = set(_git_diff_paths())
    for rel in [
        "scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn",
        "scenes/missions_iso/TacoBellIso_Editable.tscn",
        "scenes/hideout/HideoutHub.tscn",
        "scenes/characters/player.tscn",
    ]:
        if rel.replace("\\", "/") in changed or rel in changed:
            warnings.append(f"git diff vs HEAD includes protected file (verify intent): {rel}")

    if taco_a.is_file() and taco_b.is_file():
        pass
    else:
        warnings.append("Taco mission scene paths missing on disk (unexpected)")

    ok = len(errors) == 0
    out = {
        "ok": ok,
        "errors": errors,
        "warnings": warnings,
        "root": str(root.resolve()),
    }
    print(json.dumps(out, indent=2))
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
