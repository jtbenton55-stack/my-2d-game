# GAME-ROADMAP-01 — Phase 8: Next Prompt Recommendation

## Recommended next phase

**PHASE 0M-D5-01 — Taco Bell attempt-reset contract (single-writer objectives, beam armed flag, Phase0K seed reset)**

## Why this is next

This is the single change that:

1. **Unblocks the entire Taco vertical slice.** Without it, every other P0/P1 (Louis bypass, HUD ticker, three-bag pickup contract, mission-result celebratory beat, Sterling clue board) will inherit broken or leaky state across attempts.
2. **Is already designed.** The D4 spec (`docs/reports/taco_bell_redesign_d4/phase0md4_d5_implementation_spec.json`) ships a clear, scoped implementation plan with files-to-touch, files-to-forbid, acceptance criteria, and validators. Nothing else has comparable scaffolding.
3. **Touches the smallest possible surface.** `MissionObjectiveBridge.gd`, `Phase0KMissionCompletionController.gd`, `IsoMissionBase.gd`, optionally one new `TacoBellAttemptResetHooks.gd`. Player.gd, project.godot, and the playable Taco scene stay untouched.
4. **Has the lowest risk in the P0 set.** Pause payload (R2/D5-02) is a 1-method fix and can ship in the same pass. Louis bypass (R5/D5-03) is risky without R1 landed.
5. **Is the smallest change that adds player-visible value.** Once attempt reset is honest, retrying Taco feels coherent: objective lines update, alarm rearms, debug HUD counters zero out.

## Why alternatives are NOT next

| Candidate | Reason not next |
|-----------|-----------------|
| Continue with full D5-01 + 02 + 03 in one pass | Too wide; D5-03 (Louis bypass) is medium-risk and depends on D5-01. Split it. |
| Replan D5 based on this audit | Replanning is unnecessary: D4 spec aligns with this audit. Treat this audit as a confidence vote in D5-01. |
| Build a playable Taco objective spine directly (no reset) | The objective spine is **the** thing that desyncs; fixing it without reset is masking the symptom. |
| Fix launch/pause/objective UX | Pause UX (D5-02) is included in this recommendation. Launch already works. |
| Clean stale systems | High-value but **must not be combined with gameplay code changes** (per roadmap "things to avoid"). Schedule as a separate doc-hygiene pass. |
| Add mission result/return loop | Belongs in P1 right after D5-01. |
| Improve hideout loop | Belongs in P2; hideout already works well enough to support Taco vertical slice. |
| Add a small fun feature | Risk of feature creep before the foundation is honest. |
| Stabilize validators/runtime | Already mostly green; D5 validator (R11) bundled with later vertical-slice steps. |
| README/doc cleanup | High-value but separate pass (R4). |

## Scope of the recommended next prompt

This recommendation covers **D5-01 only**. A parallel doc-hygiene pass for R4 is allowed if scheduled as a separate prompt (no code touches in that pass).

### Allowed files (write)

- `src/missions/objectives/MissionObjectiveBridge.gd` (implement reset + ensure single-writer for primary objective publish)
- `src/missions/iso/runtime/Phase0KMissionCompletionController.gd` (extract `_seed_objectives` into a reset-friendly form; subscribe to attempt boundary)
- `src/levels/IsoMissionBase.gd` (add explicit call to bridge reset on `EventBus.mission_started` for the current mission id; do not refactor anything else)
- `src/missions/taco_bell/TacoBellAttemptResetHooks.gd` (new, optional — keeps Taco-specific reset hooks out of `IsoMissionBase`)
- `src/tools/editor/taco_bell_redesign_d5_01/phase0md5_01_static_validator.py` (new)
- `docs/reports/taco_bell_redesign_d5_01/*.md` and `*.json` (new)

### Forbidden files (must not touch)

- `src/player/Player.gd`
- `src/player/PlayerStaminaController.gd`
- `project.godot`
- `scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`
- `scenes/missions_iso/TacoBellIso_Editable.tscn`
- `scenes/missions/TacoBellMission.tscn`
- `scenes/hideout/HideoutHub.tscn`
- `assets/**` raw assets
- Any `.tscn` file (no scene edits in this pass)

### Acceptance criteria

1. **Static:** New `D5-01` static validator passes (checks: `MissionObjectiveBridge.reset_runtime_objectives_for_mission` body is non-empty; `IsoMissionBase` calls bridge reset on `mission_started` for active mission; `Phase0KMissionCompletionController` exposes a `_seed_objectives` that can be safely re-invoked; no edits to forbidden files).
2. **Static:** D4 validator still passes (no regression).
3. **Static:** D2A-FIX2 sprint validators still pass.
4. **Runtime (manual or GRB):** Launch Taco → fail → relaunch (or use mission-board "Replay") → confirm:
   - `garage_beam_armed == true` again
   - `QuestManager.active_objective` reflects mission phase, not last attempt's leftover line
   - Pause objectives tab shows current phase, not stale
   - Phase0K `delivery_bag_collected`, `code_gate_unlocked`, `exit_unlocked`, `completed_objectives` all reset to fresh state.
5. **Runtime:** Sprint (Ctrl/C) and Dodge (Space) regression-free.
6. **Git:** No diff in any forbidden file at end of pass.

### Risks

- Touching `IsoMissionBase` is always slightly risky (2632 LOC). Mitigation: limit edits to one call site plus a small public method; no signature changes; reset call is additive.
- Phase0K and Bridge could disagree on what "primary objective" means; recommend that **the Bridge is the single publisher** and Phase0K becomes a **subscriber** that mirrors state without writing QuestManager directly.
- The "stub" in `MissionObjectiveBridge` may have been intentional as a no-op until D5-01 — confirm by reading existing comments/docstrings before adding behavior.

### Manual decisions needed (flag for human)

- Should `TacoBellAttemptResetHooks.gd` be created as a separate file, or inline the small hook into `IsoMissionBase`? Recommendation: separate file in `src/missions/taco_bell/` to honor the Bible's "Taco owns flavor" principle and ownership map.
- Should we add an `EventBus.attempt_started(mission_id)` signal for clarity, or piggyback on existing `mission_started`? Recommendation: piggyback for now.

## Exact summary to use when asking ChatGPT for the next prompt

> "Please generate the next Cursor prompt as **PHASE 0M-D5-01 — Taco Bell attempt-reset contract**. The scope is exactly what `docs/reports/taco_bell_redesign_d4/phase0md4_d5_implementation_spec.json` describes for the D5-01 phase plus the audit's R1 in `docs/reports/full_repo_roadmap_audit/phase7_prioritized_roadmap.md`. Implement only `MissionObjectiveBridge.reset_runtime_objectives_for_mission`, hook it from `IsoMissionBase` at attempt boundary, and make `Phase0KMissionCompletionController._seed_objectives` safely re-invokable. Allowed writes: `src/missions/objectives/MissionObjectiveBridge.gd`, `src/missions/iso/runtime/Phase0KMissionCompletionController.gd`, `src/levels/IsoMissionBase.gd`, optional new `src/missions/taco_bell/TacoBellAttemptResetHooks.gd`, plus `src/tools/editor/taco_bell_redesign_d5_01/*` and `docs/reports/taco_bell_redesign_d5_01/*`. Forbidden: `Player.gd`, `PlayerStaminaController.gd`, `project.godot`, every `.tscn` file, `assets/**`. Acceptance: D5-01 static validator passes, all D4 / D2A-FIX2 validators still pass, manual Taco retry confirms `garage_beam_armed` re-arms and `QuestManager.active_objective` reflects current phase. Pause payload Taco mission_id fix (D5-02) and Louis bypass parity (D5-03) are **not** in this pass."

## Hard assertions

- `next_prompt_recommendation_created`: **true**
- `recommendation_based_on_full_audit`: **true**

See `phase8_next_prompt_recommendation.json`.
