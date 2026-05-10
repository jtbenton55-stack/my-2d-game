#!/usr/bin/env python3
"""0M-D2 mission foundation static checks (repo-local, no Godot required)."""
from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
REPORTS = ROOT / "docs" / "reports" / "mission_foundation_d2"

EXPANDED = "res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn"
LEGACY = "res://scenes/missions_iso/TacoBellIso_Editable.tscn"
CLASSIC = "res://scenes/missions/TacoBellMission.tscn"


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

    ok("repo_root", ROOT.name == "my-2d-game", str(ROOT))
    ok("expanded_taco_scene", (ROOT / "scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn").exists(), EXPANDED)
    ok("legacy_taco_scene", (ROOT / "scenes/missions_iso/TacoBellIso_Editable.tscn").exists(), LEGACY)
    ok("classic_taco_scene", (ROOT / "scenes/missions_iso/../missions/TacoBellMission.tscn").exists() or (ROOT / "scenes/missions/TacoBellMission.tscn").exists(), CLASSIC)

    resolver = ROOT / "src/missions/MissionSceneResolver.gd"
    rtxt = _read(resolver) if resolver.exists() else ""
    for fn in (
        "resolve_playable_scene_path",
        "get_default_scene_path",
        "get_debug_scene_path",
        "get_scene_roles",
        "is_legacy_scene_path",
        "get_resolution_report",
    ):
        ok(f"resolver_api_{fn}", fn in rtxt, resolver.as_posix())

    ok(
        "taco_resolves_redesign",
        "mission_id == TACO_BELL_MISSION_ID" in rtxt and "return PLAYABLE_EXPANDED_TACO_ISO" in rtxt,
        "resolve_playable_scene_path early return",
    )

    mb = _read(ROOT / "src/hideout/HideoutMissionBoardController.gd")
    ok("mission_board_no_tacoscene_const", "const TACO_BELL_SCENE" not in mb, "HideoutMissionBoardController")
    ok("mission_board_uses_resolver", "MissionSceneResolver.resolve_playable_scene_path" in mb, "HideoutMissionBoardController")

    cat = _read(ROOT / "src/hideout/HideoutStationCatalog.gd")
    ok("catalog_no_tacoscene_const", "const TACO_BELL_SCENE" not in cat, "HideoutStationCatalog")
    ok("catalog_uses_resolver", "MissionSceneResolver.resolve_playable_scene_path" in cat, "HideoutStationCatalog")

    sm = _read(ROOT / "src/autoload/SceneManager.gd")
    ok("scene_manager_start_mission_resolver", "MissionSceneResolver.resolve_playable_scene_path" in sm, "SceneManager.start_mission")
    ok("scene_manager_pending_clear_uses_resolver", "MissionSceneResolver.resolve_playable_scene_path(GameState.current_mission_id)" in sm, "pending_mission_id clear")

    dbg = _read(ROOT / "src/missions/iso/runtime/IsoMissionDebugPanel.gd")
    ok("iso_debug_restart_resolver", "MissionSceneResolver.resolve_playable_scene_path" in dbg, "IsoMissionDebugPanel._on_restart")

    godot_txt = _read(ROOT / "project.godot")
    ok("sprint_action_present", bool(re.search(r"^sprint=\{", godot_txt, re.M)), "project.godot [input] sprint")
    backups = list((REPORTS / "backups").glob("project.phase0md2_input_backup.*.godot")) if (REPORTS / "backups").exists() else []
    ok("project_godot_backup_exists", len(backups) > 0, str(backups[-1]) if backups else "none")

    # project.godot should only gain sprint vs backup (best-effort: backup has no sprint block)
    if backups:
        btxt = _read(backups[-1])
        ok("backup_has_no_sprint_action", not re.search(r"^sprint=\{", btxt, re.M), backups[-1].name)

    prov = ROOT / "src/missions/ui/MissionPauseDataProvider.gd"
    ptxt = _read(prov) if prov.exists() else ""
    for fn in (
        "get_objective_snapshot",
        "get_scheme_card_snapshot",
        "get_clue_snapshot",
        "get_pause_payload",
        "has_mission_context",
        "get_provider_id",
    ):
        ok(f"pause_provider_{fn}", fn in ptxt, prov.as_posix())

    mob = ROOT / "src/missions/objectives/MissionObjectiveBridge.gd"
    mobt = _read(mob) if mob.exists() else ""
    ok("objective_bridge_snapshot", "get_objective_snapshot" in mobt, str(mob))
    ok("objective_bridge_id", "get_bridge_id" in mobt, str(mob))

    clue = ROOT / "src/missions/clues/MissionClueBridge.gd"
    ok("clue_bridge_file", clue.exists(), str(clue))
    sch = ROOT / "src/missions/schemes/MissionSchemeBridge.gd"
    ok("scheme_bridge_file", sch.exists(), str(sch))

    pause = _read(ROOT / "src/ui/test_ui/pause_menu.gd")
    ok("pause_menu_uses_provider", "MissionPauseDataProvider" in pause, "pause_menu.gd")

    stamina = _read(ROOT / "src/player/PlayerStaminaController.gd")
    ok("stamina_no_animation_dependency_note", "no animation dependency" in stamina.lower(), "PlayerStaminaController header")
    ok("stamina_sprint_action_default", 'sprint_action_name: String = "sprint"' in stamina, "PlayerStaminaController")

    # Taco scenes + player scene not modified in working tree (informational)
    diff_names = _git(["diff", "--name-only", "--"])
    protected = [
        "scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn",
        "scenes/missions_iso/TacoBellIso_Editable.tscn",
        "scenes/characters/player.tscn",
    ]
    touched = [ln for ln in diff_names.splitlines() if ln.strip()]
    bad = [p for p in protected if p in touched]
    ok("protected_scenes_untouched_in_diff", len(bad) == 0, ",".join(bad) if bad else "clean")

    # JSON reports parseable
    parse_fail: list[str] = []
    for jp in sorted(REPORTS.glob("phase0md2_*.json")):
        try:
            json.loads(_read(jp))
        except json.JSONDecodeError as e:
            parse_fail.append(f"{jp.name}: {e}")
    ok("d2_json_reports_parseable", len(parse_fail) == 0, "; ".join(parse_fail[:3]))

    out_path = REPORTS / "phase0md2_static_validator_run.json"
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(results, indent=2), encoding="utf-8")

    print(json.dumps({"ok": results["ok"], "written": str(out_path), "failed": [k for k, v in results["checks"].items() if not v["pass"]]}, indent=2))
    return 0 if results["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
