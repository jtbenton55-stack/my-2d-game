#!/usr/bin/env python3
"""0M-D2A-FIX1 sprint runtime static checks."""
from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
REPORTS = ROOT / "docs" / "reports" / "mission_foundation_d2a_fix1_sprint_runtime"


def _read(p: Path) -> str:
    return p.read_text(encoding="utf-8", errors="replace")


def _git(args: list[str]) -> str:
    try:
        return subprocess.check_output(["git"] + args, cwd=ROOT, text=True, stderr=subprocess.STDOUT).strip()
    except (subprocess.CalledProcessError, FileNotFoundError) as e:
        return f"<git_error:{e}>"


def main() -> int:
    results: dict = {"ok": True, "checks": {}, "warnings": []}

    def ok(name: str, cond: bool, detail: str = "") -> None:
        results["checks"][name] = {"pass": cond, "detail": detail}
        if not cond:
            results["ok"] = False

    godot = _read(ROOT / "project.godot")
    sm = re.search(r"^sprint=\{.*?^\}", godot, re.S | re.M)
    sprint_block = sm.group(0) if sm else ""
    dm = re.search(r"^dodge=\{.*?^\}", godot, re.S | re.M)
    dodge_block = dm.group(0) if dm else ""

    ok("sprint_action_exists", "sprint={" in godot, "project.godot")
    ok("sprint_ctrl_only_no_space", '"physical_keycode":32' not in sprint_block, "Space must stay dodge-only")
    ok("sprint_has_ctrl_4194326", '"physical_keycode":4194326' in sprint_block, "KEY_CTRL")
    ok("dodge_preserves_space", '"physical_keycode":32' in dodge_block, "dodge Space")

    pg = _read(ROOT / "src/player/Player.gd")
    ok("player_calls_process_frame", "_stamina_controller.process_frame" in pg, "Player.gd")
    ok("player_uses_is_sprint_active_for_mult", "is_sprint_active()" in pg, "Player.gd")
    ok("player_no_permanent_combat_sprint_block", "(not combat_on) and (not is_stealth) and InputMap.has_action" not in pg, "old gate gone")
    ok("player_dash_suppress", "dash_active" in pg and "legacy_dodge_burst" in pg, "Player.gd")
    ok("player_debug_snapshot", "get_sprint_runtime_debug" in pg, "Player.gd")

    st = _read(ROOT / "src/player/PlayerStaminaController.gd")
    ok("stamina_is_sprint_requested", "func is_sprint_requested" in st, "PlayerStaminaController")
    ok("stamina_key_ctrl_fallback", "is_physical_key_pressed(KEY_CTRL)" in st, "Ctrl runtime fallback")
    ok("stamina_is_sprint_active", "func is_sprint_active" in st, "PlayerStaminaController")
    ok("stamina_debug_snapshot", "func get_debug_snapshot" in st, "PlayerStaminaController")
    ok("stamina_no_run_anim", "run_animation_required" in st and "false" in st, "debug flag")

    diff = _git(["diff", "--name-only", "--"])
    touched = set(diff.splitlines())
    ok("taco_clean", not any("TacoBellIso" in t for t in touched), str(touched))
    ok("player_tscn_clean", "scenes/characters/player.tscn" not in touched, str(touched))

    parse_fail: list[str] = []
    for jp in sorted(REPORTS.glob("phase0md2a_fix1_*.json")):
        try:
            json.loads(_read(jp))
        except json.JSONDecodeError as e:
            parse_fail.append(f"{jp.name}: {e}")
    ok("fix1_json_parseable", len(parse_fail) == 0, "; ".join(parse_fail[:5]))

    REPORTS.mkdir(parents=True, exist_ok=True)
    out_path = REPORTS / "phase0md2a_fix1_sprint_runtime_validator_run.json"
    out_path.write_text(json.dumps(results, indent=2), encoding="utf-8")
    print(json.dumps({"ok": results["ok"], "written": str(out_path), "failed": [k for k, v in results["checks"].items() if not v["pass"]]}, indent=2))
    return 0 if results["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
