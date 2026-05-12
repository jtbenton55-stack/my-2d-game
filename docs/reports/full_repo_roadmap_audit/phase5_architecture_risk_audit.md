# GAME-ROADMAP-01 — Phase 5: Architecture / Spaghetti Risk Audit

Severities: **critical / high / medium / low**. Each risk lists the evidence path, why it matters, the likely fix, and **when** to fix it (now / next-pass / after-vertical-slice / after-Phase-1 / never).

## Top risks (by severity)

### 1. CRITICAL — `IsoMissionBase.gd` monolith
- **Evidence:** `src/levels/IsoMissionBase.gd` — **2632 LOC** owning tile painting, marker indexing, runtime spawning of guards/cameras/alarms/routes/encounters/transitions, code gate blockers, Louis corridor literals, poop bag decoy spawn, debug panel, layout profiles, dev harness, attempt runtime state. Confirmed by `mission_module_audit/spaghetti_risk_audit.json:risks[0]`.
- **Why it matters:** Every Taco fix touches a multi-system file. Every new iso mission will inherit (or fork) this monolith. Extraction is the largest implementation cost in the roadmap.
- **Likely fix:** Extract into `RuntimeSpawner`, `RouteSubsystem`, `AlarmSubsystem`, `MarkerIndex`, `TacoBellFlavorAdapter`. Keep base thin.
- **When:** **After Taco vertical slice ships.** Do **NOT** split it before D5-01 lands, or risk breaking the only playable mission.
- **What not to do:** Don't try to refactor + add features in one pass.

### 2. CRITICAL — Triple objective writers + reset stub
- **Evidence:** Three writers documented in `taco_bell_redesign_d4/phase0md4_taco_module_ownership_map.md`:
  - `IsoMissionBase._required_objective_ids` → `MissionObjectiveBridge.publish_primary_objective` → `QuestManager`
  - `Phase0KMissionCompletionController._seed_objectives` (separate seed pass)
  - `Phase0JObjectiveAdapter` writes on adapter events
  - `MissionObjectiveBridge.reset_runtime_objectives_for_mission` is a **no-op stub** (`MissionObjectiveBridge.gd` is 6 lines including docstrings).
- **Why it matters:** Reload/retry desync, pause vs HUD disagreement, false hints.
- **Likely fix:** Implement `MissionObjectiveBridge.reset_runtime_objectives_for_mission(mission_id)` that clears QuestManager + Phase0K + mission node state at attempt boundary; pick **one publisher** per event type; subscribers re-derive.
- **When:** **Now** — this is D5-01.

### 3. HIGH — Louis route bypass declared in markers but not in router
- **Evidence:** `taco_bell_redesign_d4/phase0md4_existing_taco_mechanic_audit.md` row "Louis bypasses real challenge" — markers declare `bypasses_challenge_id="garage_entry_beam"`; `Phase0JMechanicRouter` classifies ROUTE_* as `INSPECT_ONLY_DEFERRED`.
- **Why it matters:** The marquee scheme of Taco ("use friend favors") currently does nothing at runtime.
- **Likely fix:** Small `TacoBellRouteBypassController.gd` listening to route access markers; when active for Louis path, disable beam alarm penalty.
- **When:** D5-03, **after** D5-01 + D5-02.

### 4. HIGH — Player ↔ scene-root duck typing for tools
- **Evidence:** `Player._try_throw_poop_bag` calls `scene.has_method("deploy_poop_bag_decoy_at")` on the current scene root (`mission_module_audit/spaghetti_risk_audit.json:risks[2]`).
- **Why it matters:** Every new mission must re-implement that exact method name, or aimed-throw breaks silently.
- **Likely fix:** Replace with `IToolMissionSurface` interface or use a group lookup + signal-based throw request. Most of the work is already in `MissionToolSurfaceHelper`.
- **When:** **After Taco vertical slice** (P2). Don't touch Player.gd in D5.

### 5. HIGH — Attempt reset not proven on all death/retry paths
- **Evidence:** `mission_module_audit/spaghetti_risk_audit.json:risks[7]`. `LevelBase.fail_level` does not call `IsoMissionBase._reset_attempt_runtime_state`; reset depends on full scene reload after result UI.
- **Why it matters:** If in-scene retry is ever supported, attempt counters, Quest lines, beam-armed flag will all leak across attempts.
- **Likely fix:** Sub-task of D5-01: call `reset_mission_runtime_for_new_attempt` on `EventBus.mission_started` when same mission_id is re-entered.
- **When:** **Now (D5-01).**

### 6. HIGH — Phase0J / Phase0K controllers named generically but scoped to Taco
- **Evidence:** Phase0J* / Phase0K* files under `src/missions/iso/runtime/` are instantiated only by `TacoBellIso_Editable_RedesignTest.tscn`. Names suggest framework-level but content is Taco-specific (e.g., `TacoBellDialogue.gd`, `Phase0KLouisExitInteractable.gd`).
- **Why it matters:** Future iso missions will either get accidental Taco coupling or copy the whole stack.
- **Likely fix:** Move Taco-specific behavior to `src/missions/taco_bell/` (already partially started with `TacoBellDialogueProvider.gd`); promote truly generic logic to `src/missions/iso/framework/` (rename Phase0J/K accordingly).
- **When:** **After Taco vertical slice ships**, before Jazz Club work begins.

### 7. HIGH — Two Taco "story" surfaces with different controller stacks
- **Evidence:** `scenes/missions/TacoBellMission.tscn` (classic, `LevelBase`-based, `TacoBellMission.gd` ~780 LOC) vs `scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn` (iso, `IsoMissionBase` + Phase0J/K).
- **Why it matters:** Catalog points to classic; resolver overrides for playable. A naive future fix could "repair" the catalog and break the override.
- **Likely fix:** Either retire the classic Taco script + scene (move to `docs/reports/.../legacy_archive/`) or keep but rename to `TacoBellMission_legacy_classic.{gd,tscn}` and add `@deprecated` comments.
- **When:** **After Taco vertical slice** (P2/P3); do not delete now.

### 8. MEDIUM — Production pause menu lives under `src/ui/test_ui/`
- **Evidence:** RedesignTest instances `src/ui/test_ui/pause_menu.gd`.
- **Why it matters:** Path implies "test" but is production; future agent may delete or mis-style.
- **Likely fix:** Move to `src/ui/mission/pause/pause_menu.{gd,tscn}` with no behavior change.
- **When:** P3.

### 9. MEDIUM — SaveManager doesn't own runtime attempt state (good) but mission catalog conflates "playable" and "metadata"
- **Evidence:** `GameState.mission_catalog["taco_bell_drop"].scene_path` still points to classic story room; resolver overrides.
- **Why it matters:** Catalog "truth" depends on knowing about the override.
- **Likely fix:** Add a `playable_scene_path` field in catalog; default to `scene_path`. Or document the override explicitly.
- **When:** P2.

### 10. MEDIUM — Mission unlock progression encoded only in `_unlock_next_missions`
- **Evidence:** `GameState._unlock_next_missions` (~30 lines of branching match) is the only source of truth for the Sterling unlock graph.
- **Why it matters:** Mission Bible structure lives in code, hard for designers to see.
- **Likely fix:** Move to a `MissionUnlockGraph.gd` resource or dictionary; keep helper function.
- **When:** P2.

### 11. MEDIUM — Hardcoded world cells (beam / Louis corridor) inside `IsoMissionBase`
- **Evidence:** `mission_module_audit/spaghetti_risk_audit.json:risks[6]`. `Vector2i` literals for garage beam and Louis box.
- **Why it matters:** Art redesign breaks gameplay silently.
- **Likely fix:** Drive everything from markers; remove literals after marker bake is stable.
- **When:** After Taco vertical slice.

### 12. MEDIUM — `Hideout.gd` legacy script alongside `HideoutHub.tscn`
- **Evidence:** `src/levels/Hideout.gd` exists but production hideout uses `HideoutManager.gd`.
- **Why it matters:** Misleading; future agent might edit the wrong file.
- **Likely fix:** Rename to `Hideout_legacy.gd` or move to legacy folder.
- **When:** P3.

### 13. MEDIUM — Scene backups inside `scenes/**`
- **Evidence:** 22 `HideoutHub.phase0m*_backup.*.tscn`, 15 `TacoBellIso_Editable_RedesignTest.<phase>_backup.*.tscn`, plus pvgames PNGs in scenes/hideout/.
- **Why it matters:** Clutter; risk of mis-load; complicates `Glob`/`rg` for current state.
- **Likely fix:** Move backups to `docs/reports/<phase>/backups/`.
- **When:** P3 cleanup.

### 14. LOW — `CardManager` autoload lives under `src/inventory/` instead of `src/autoload/`
- **Evidence:** `project.godot` autoload entry `CardManager="*res://src/inventory/CardManager.gd"`.
- **Why it matters:** Inconsistent layout; future agent might move file and forget to update autoload.
- **Likely fix:** Move to `src/autoload/CardManager.gd` and update autoload path; or accept and document.
- **When:** P3.

### 15. LOW — `Phase0JMechanicRouter` "parity" table embeds policy decisions
- **Evidence:** `Phase0JMechanicRouter.parity_by_category` dictionary maps categories to `INSPECT_ONLY_DEFERRED` / `READY` / etc.
- **Why it matters:** Policy in code is fine, but flipping a category from `DEFERRED` to active without a checklist is dangerous.
- **Likely fix:** When Louis bypass goes live (D5-03), update ROUTE_* entries and add a static check in the D5 validator.
- **When:** D5-03.

### 16. LOW — Multiple "Phase0J/Phase0K" naming layers makes it hard to search
- **Evidence:** Phase0J, Phase0JA, Phase0JB, Phase0JB2, Phase0JC, Phase0K, Phase0KB are all referenced (validation reports + scene file names).
- **Why it matters:** Discoverability.
- **Likely fix:** Document a single short index in `docs/reference/` after vertical slice.
- **When:** P3.

### 17. LOW — Multiple character animation phases (c2a, c2a_fix1/2/3, c2b, c2b_fix1) without a "current state" pointer
- **Evidence:** 6 c2a/c2b folders under `docs/reports/`.
- **Why it matters:** Future agent picks the wrong one.
- **Likely fix:** Single index doc in `docs/reference/character_animation_current.md` pointing to `c2b_fix1` outputs.
- **When:** P3.

### 18. LOW — `addons/godot_mcp` + `addons/godot-runtime-bridge` autoload coupling
- **Evidence:** Three MCP-related autoloads.
- **Why it matters:** Editor-time tooling shouldn't block runtime; "pause tree drops bridge" was observed in D1B-RT2.
- **Likely fix:** None required; document.
- **When:** Never (unless it gets in the way).

### 19. LOW — Mission UI scenes scattered (`scenes/ui/`, `src/ui/evidence_board/`, `src/ui/loadout/`)
- **Evidence:** Scene files live in both `scenes/ui/` and inside `src/ui/<subsystem>/`.
- **Why it matters:** Mild convention drift.
- **Likely fix:** Pick one and migrate over time.
- **When:** P3.

### 20. LOW — No headless CI
- **Evidence:** 41 Python validators run locally; no Godot --headless validation.
- **Why it matters:** Regressions sneak in.
- **Likely fix:** Optional `godot --headless --check-only`.
- **When:** P4.

## Risk → priority matrix

| Severity | Count | "When" |
|----------|-------|--------|
| Critical | 2 | 1 now (objective writers), 1 after vertical slice (`IsoMissionBase` split) |
| High | 5 | 2 now (Louis bypass + attempt reset), 3 after vertical slice |
| Medium | 5 | mix of P2/P3 |
| Low | 8 | P3/P4 |

## Hard assertions

- `architecture_risks_identified`: **true** (20 catalogued)
- `highest_risks_prioritized`: **true** (P0 set: triple writers, reset, Louis bypass)
- `nothing_modified_in_repo`: **true**

See `phase5_architecture_risk_audit.json`.
