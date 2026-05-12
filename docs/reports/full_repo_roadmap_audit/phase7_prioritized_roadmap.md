# GAME-ROADMAP-01 — Phase 7: Prioritized Roadmap

Horizons:

- **P0** — Immediate stabilization / unblockers (within the current sprint).
- **P1** — Next playable vertical slice (Taco is "actually good" end-to-end).
- **P2** — Core-loop improvement (Hideout↔Mission feedback, Mission Bible global systems wired on Taco).
- **P3** — Content expansion (Phase 1 second + third showcase missions).
- **P4** — Polish and juice (audio, art, animation integration, accessibility).
- **P5** — Long-term architecture / future-proofing (IsoMissionBase extraction, framework split).
- **DROP_FOR_NOW** — explicitly off the menu right now.
- **UNKNOWN** — needs human decision.

For each item: **goal**, **why now**, **evidence**, **dependencies**, **files/systems likely touched**, **acceptance criteria**, **test plan**, **risk**, **size**, **implementation or design-only**.

---

## P0 — Immediate stabilization / unblockers

### R1 — Attempt-reset contract (D5-01)
- **Goal:** Implement `MissionObjectiveBridge.reset_runtime_objectives_for_mission(mission_id)` + hook from attempt boundary so QuestManager lines, Phase0K seed dictionary, `_attempt_runtime_state`, and beam-armed flag all clear on every retry path.
- **Why now:** The single biggest playability gap on Taco; D4 P0; spaghetti-risk row 2 + 5.
- **Evidence:** `MissionObjectiveBridge.gd` is a 6-line shell; `Phase0KMissionCompletionController._seed_objectives` runs at `_ready`; `LevelBase.fail_level` doesn't call iso reset.
- **Dependencies:** none.
- **Likely touches:** `src/missions/objectives/MissionObjectiveBridge.gd`, `src/missions/iso/runtime/Phase0KMissionCompletionController.gd`, `src/levels/IsoMissionBase.gd`. Optional new: `src/missions/taco_bell/TacoBellAttemptResetHooks.gd`.
- **Forbidden:** `Player.gd`, `PlayerStaminaController.gd`, `project.godot`, `TacoBellIso_Editable_RedesignTest.tscn`.
- **Acceptance:** Reload Taco twice (fail → return → relaunch); no stale Quest lines; `garage_beam_armed == true` again; debug HUD counters reset.
- **Test plan:** D5 static validator + manual Taco retry checklist.
- **Risk:** Low/Medium (touches IsoMissionBase). **Size:** S/M. **Impl.**

### R2 — Pause payload pinned to Taco `mission_id` (D5-02)
- **Goal:** Pause tabs receive non-empty `mission_id` when active scene is Taco; objectives/scheme/clues snapshots return Taco-relevant rows.
- **Why now:** D4 P0; pause is currently the only UX surface that owns objectives/scheme/clues; payload context is the seam where they meet.
- **Evidence:** `MissionPauseDataProvider._effective_mission_id` falls back to `GameState.current_mission_id`.
- **Dependencies:** none.
- **Likely touches:** `src/ui/test_ui/pause_menu.gd`, optional small `src/levels/IsoMissionBase.gd` getter.
- **Acceptance:** Open pause in Taco → all three tabs show Taco rows; cycling tabs doesn't crash.
- **Risk:** Very low. **Size:** XS. **Impl.**

### R3 — Pause shows the next required objective in bold
- **Goal:** Pause objectives tab visually emphasizes the immediate next step.
- **Why now:** Single biggest player-facing clarity win for almost no cost.
- **Evidence:** `QuestManager.active_objective` exists, `_update_next_required_objective()` already runs in `IsoMissionBase`.
- **Dependencies:** R1 (so reset is honest first).
- **Likely touches:** `src/ui/test_ui/pause_menu.gd` (`_objectives_text`).
- **Acceptance:** Open pause; next-required line visually distinct.
- **Risk:** none. **Size:** XS. **Impl.**

### R4 — Annotate stale docs (D1B canonical + README banner)
- **Goal:** Add "SUPERSEDED — see <newer report>" headers to:
  - `docs/reports/pre_taco_module_hardening/phase0md1b_canonical_taco_scene_decision.md`
  - `docs/reports/mission_foundation_d2a_sprint_fix/*.md` + `_fix1_sprint_runtime/*.md`
  - `docs/reports/character_animation_c2a/*.md` (+ c2b partial)
  - And add a `STATUS: outdated` banner at top of `README.md`.
- **Why now:** Future agents (and humans) are getting misled.
- **Evidence:** Phase 4 reconciliation.
- **Likely touches:** docs only. **No code changes.**
- **Acceptance:** Each annotated file references the current report by path.
- **Risk:** none. **Size:** S. **Design-only.**

---

## P1 — Next playable vertical slice (Taco "actually good" end-to-end)

### R5 — Louis bypass actually neutralizes beam alarm (D5-03)
- **Goal:** When player enters Louis route access marker, set runtime flag that disables `garage_entry_beam` alarm penalty for the rest of the attempt.
- **Why now:** Marquee scheme of Taco; gives the friend system its first concrete win.
- **Evidence:** D4 audit; markers declare `bypasses_challenge_id`; router still `INSPECT_ONLY_DEFERRED`.
- **Dependencies:** R1 (so reset clears the bypass between attempts).
- **Likely touches:** new `src/missions/taco_bell/TacoBellRouteBypassController.gd`; `src/missions/iso/runtime/Phase0JMechanicRouter.gd` (flip ROUTE_* parity); minor `src/levels/IsoMissionBase.gd` listener wiring.
- **Acceptance:** Walk Louis route → beam alarm does NOT trigger when crossing the garage entry zone. Main route → beam triggers once.
- **Test plan:** D5 validator checks router parity + adapter listens to route signal; runtime check via GRB / manual.
- **Risk:** Medium. **Size:** M. **Impl.**

### R6 — Mission Result + Hideout Return celebratory beat
- **Goal:** After Taco completion, `MissionResult` lists rewards, Bentley/Louis line plays; on return to hideout, polaroid is visibly added to gallery shelf if earned.
- **Why now:** Closes the run emotionally; satisfies Mission Bible "memory dialogue" intent.
- **Dependencies:** R1, R5.
- **Likely touches:** `src/ui/MissionResult.gd`, `src/levels/Hideout.gd` (or hideout state controller), `GameState.complete_mission` reward path (no signature change).
- **Acceptance:** Beat the mission → result screen shows ≥3 reward lines and a one-line dialogue → return to hideout → polaroid appears in gallery.
- **Risk:** Low. **Size:** S. **Impl.**

### R7 — HUD: objective ticker + stamina bar + poop bag count
- **Goal:** Three small HUD elements that telegraph the immediate gameplay state.
- **Why now:** Players "play through the HUD" — without these the mechanics are invisible.
- **Dependencies:** R1.
- **Likely touches:** `src/ui/HUD.gd`, `scenes/ui/hud.tscn` (only HUD scene — explicitly NOT mission scenes).
- **Acceptance:** Open Taco → see current objective, stamina bar drains/refills, poop bag count visible.
- **Risk:** Low. **Size:** S–M. **Impl.**

### R8 — Three-poop-bag pickup contract for Taco
- **Goal:** Three poop bag pickups in Taco scene reachable on the main path; "Responsible Crime Lord" bonus already plumbed in `GameState`.
- **Why now:** Bible per-mission checklist; tool surface needs gameplay reps.
- **Dependencies:** R1 (so per-attempt counter resets).
- **Likely touches:** `scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn` — **scene edit** — if scene edits prove unavoidable, document in D5 spec. Prefer marker definitions in the mission definition resource if possible.
- **Acceptance:** ≥3 poop bag pickups appear, picking them up updates HUD, and triggers Responsible Crime Lord bonus message.
- **Risk:** Medium (scene edit). **Size:** S. **Impl.**

### R9 — First Sterling clue posts to Evidence Board on Taco success
- **Goal:** On Taco complete, register a Sterling clue ("delivery routes hide Sterling shipments") and have it appear in the Evidence Board panel.
- **Why now:** Story spine begins; gives the Bible's "leverage layer per mission" first beat.
- **Dependencies:** R6.
- **Likely touches:** `src/missions/taco_bell/TacoBellDialogueProvider.gd` (or a small TacoBell completion hook), `src/hideout/HideoutEvidenceBoardController.gd`, `GameState.evidence_clues`.
- **Acceptance:** Beat Taco → open Evidence Board → see new clue card.
- **Risk:** Low. **Size:** S. **Impl.**

### R10 — Onboarding micro-tutorial (Jake hideout greet + sprint banner + poop bag first-pickup tip)
- **Goal:** New player sees mission board prompt + sprint hint + bag pickup tip without scripted cutscene.
- **Why now:** Without onboarding, none of the systems are visible to a fresh player.
- **Dependencies:** R7.
- **Likely touches:** `src/hideout/HideoutCharacterController.gd`, `src/ui/HUD.gd`, `src/collectibles/PoopBagPickup.gd`.
- **Acceptance:** New game → Jake greets in hideout; in mission, sprint hint after 5s of no sprint; first bag pickup → 1-line tutorial.
- **Risk:** Low. **Size:** S. **Impl.**

### R11 — D5 static + runtime validators
- **Goal:** Per the D4 D5-05 plan, add `src/tools/editor/taco_bell_redesign_d5/*.py` validators that confirm R1–R5 invariants (objective reset present, router parity flipped, payload keys, HUD pieces wired). Report in `docs/reports/taco_bell_redesign_d5/`.
- **Why now:** Lock the vertical slice behind automated checks.
- **Dependencies:** R1, R2, R5, R7.
- **Risk:** Low. **Size:** S. **Impl.**

---

## P2 — Core loop improvement

### R12 — Per-mission small mutation table for Taco on iso playable
- **Goal:** Migrate `_apply_taco_bell_mutations` logic out of legacy classic script into a Taco adapter the iso playable consumes.
- **Why now:** Bible heat loop unbroken on the actual playable scene.
- **Dependencies:** R1.
- **Risk:** Low. **Size:** M. **Impl.**

### R13 — Mission Board panel: real status strip per mission
- **Goal:** "Available / X clues / polaroid ✓ / heat L1" line per mission instead of generic "Locked. Future job scaffold."
- **Why now:** Hideout becomes more interesting.
- **Risk:** Low. **Size:** M. **Impl.**

### R14 — Hideout dialogue reacts to last mission result
- **Goal:** Bentley/Jake have one-line reaction based on `GameState.last_mission_result.success`.
- **Risk:** Low. **Size:** S. **Impl.**

### R15 — Clean Getaway tracking (perfect moment polaroid)
- **Goal:** Surface `mission_performance[mission].perfect_moment_earned` as a polaroid + visible badge.
- **Risk:** Low. **Size:** S. **Impl.**

### R16 — Scene backups cleanup pass
- **Goal:** Move all `HideoutHub.phase0m*_backup.*.tscn` + `TacoBellIso_Editable_RedesignTest.<phase>_backup.*.tscn` into `docs/reports/<phase>/backups/`.
- **Why now:** Reduces scene-folder noise; lower agent-confusion risk.
- **Risk:** Low — but **important**: ensure no `.import` references break, run editor refresh, confirm no scene path references inside `.tscn` files.
- **Size:** S. **Impl** (file moves only).

---

## P3 — Content expansion (Phase 1 showcase mission #2 + #3)

### R17 — Migrate Jazz Club to iso framework
- **Goal:** Build `TacoBellIso_Editable_RedesignTest`-style scene for Jazz Club using `IsoMissionBase` + minimal Phase0J/K. Yordano-route equivalent of Louis.
- **Why now:** Bible's Phase 1 second showcase; second mission proves the spine is reusable.
- **Dependencies:** R1–R11, R16, plus framework split if needed.
- **Risk:** Medium. **Size:** L. **Impl.**

### R18 — Migrate Rewrite Room to iso framework
- **Goal:** Third Phase 1 showcase mission.
- **Dependencies:** R17.
- **Risk:** Medium. **Size:** L. **Impl.**

### R19 — Sterling clue chain across Taco → Jazz → Rewrite
- **Goal:** Three clues form a single visible thread in Evidence Board.
- **Dependencies:** R17.
- **Risk:** Low. **Size:** M. **Impl.**

---

## P4 — Polish and juice

### R20 — One ambience loop per mission + one alarm sting
- Size S–M; deferred until P1 stabilizes.

### R21 — Iso visual polish: light zone shading, alert HUD ladder, vision cone outline
- Size S–M; later.

### R22 — Adopt c2b_fix1 contextual classifier SpriteFrames for Parmida walk/run/idle
- Size M; deferred until missions ship.

### R23 — Accessibility: outline pulse, hold-to-interact, larger dialogue option
- Size S each; can ship as a single accessibility pass.

### R24 — Storefront purchasable cosmetic decor item
- Size S; gates the meta-progression loop.

---

## P5 — Long-term architecture / future-proofing

### R25 — Extract `IsoMissionBase` into `framework/` modules
- Split into `RuntimeSpawner`, `RouteSubsystem`, `AlarmSubsystem`, `MarkerIndex`, `TacoBellFlavorAdapter`.
- Mandatory before more than two missions live on the same monolith.
- Size XL.

### R26 — Rename Phase0J/K to `framework/` + `taco_bell/` adapters
- Mandatory before Jazz Club imports controllers.
- Size M.

### R27 — Replace Player ↔ scene-root duck typing with `IToolMissionSurface` group or signals
- Removes per-mission requirement to re-implement `deploy_poop_bag_decoy_at`.
- Size M.

### R28 — Mission unlock graph as a resource
- Externalize `GameState._unlock_next_missions` into a `MissionUnlockGraph.tres`.
- Size M.

### R29 — Headless Godot CI
- Run `godot --headless --check-only` on PR + static validators.
- Size M.

---

## DROP_FOR_NOW (explicit do-not-touch)

- Full procedural mutation system.
- Full combat AI / new enemy types.
- Full stealth AI overhaul.
- Sterling Tower full design / boss fight.
- Rewriting `Player.gd` for animation gating.
- Replacing pause menu skin.
- Switching playable Taco scene back to `TacoBellIso_Editable.tscn`.
- Deleting any legacy mission scene/script.
- Single-pass refactor of `IsoMissionBase`.
- Combining doc-hygiene work with gameplay PRs.

---

## UNKNOWN — needs human decision

- **Should the classic `LevelBase`-style mission scenes be archived now or after their iso replacements are ready?** Recommendation: keep them, defer.
- **Should the `iso_vertical_slice` mission entry be removed from `GameState.mission_catalog`?** Recommendation: keep for dev convenience.
- **Single visual style for Phase 1 missions** — pick before R17 starts.

---

## Single best next action

**R1 — Attempt-reset contract (D5-01)**

This is the smallest, most evidence-supported change that unlocks the entire vertical-slice chain. Every other P0/P1 either depends on it or becomes more reliable when it lands.

## Next 3 actions

1. **R1** — Attempt-reset contract.
2. **R2** — Pause payload pinned to Taco mission_id.
3. **R4** — Annotate stale docs (D1B canonical + README banner) — *(can ship as a parallel design-only pass before, during, or after R1/R2).*

## Next 10 actions

1. R1 — Attempt-reset contract (D5-01).
2. R2 — Pause payload Taco mission_id (D5-02).
3. R4 — Annotate stale docs + README banner.
4. R3 — Pause shows next required objective in bold.
5. R11 — D5 static + runtime validators landed.
6. R5 — Louis bypass neutralizes beam alarm (D5-03).
7. R7 — HUD: objective ticker + stamina bar + poop bag count.
8. R8 — Three poop-bag pickup contract for Taco.
9. R6 — Mission Result + Hideout Return celebratory beat.
10. R9 — First Sterling clue posts to Evidence Board on Taco success.

## Things to avoid right now

- Editing `Player.gd`, `PlayerStaminaController.gd`, or `project.godot` (except via a focused hotfix pass with its own audit).
- Modifying the playable Taco scene unless absolutely required for R8.
- Touching `IsoMissionBase` in ways that change non-attempt-reset behavior.
- Deleting any legacy scenes / scripts.
- Splitting `IsoMissionBase` into modules right now.
- Combining doc-hygiene with gameplay work.
- Force-pushing or rewriting git history.

## Things to defer

- Phase 2/3/4 missions until Phase 1 ships.
- Animation gating, audio assets, accessibility polish, art replacement.
- `IsoMissionBase` extraction.
- Framework split of Phase0J/K.
- Mission Bible Addendum rewrite (do after Phase 1 ships).

## Things to stop doing

- Treating `TacoBellMission.tscn` (classic story room) as the canonical surface — it isn't.
- Citing D1B canonical-scene decision as current.
- Adding new mission ids to the catalog before the existing ones have at least scaffold playable parity.
- Documenting features as "complete" in README without code matching.

## Hard assertions

- `roadmap_created`: **true**
- `single_best_next_action_identified`: **true** (R1)
- `next_3_actions_identified`: **true**
- `next_10_actions_identified`: **true**
- `avoid_now_list_created`: **true**

See `phase7_prioritized_roadmap.json`.
