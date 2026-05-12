# 0M-D4 — Mission design blueprint (RedesignTest)

## 1–4. Title, fantasy, goal, tone

- **Title:** Parmida vs. The Neon Drive-Thru (working title).
- **Fantasy:** Neon Taco Bell delivery zone becomes a birthday-safe stealth-heist set piece — clever, chaotic, readable.
- **Goal:** Finish the delivery chain, survive separated **code gate** and **security beam** beats, optionally gather clues, exit clean.
- **Tone:** Funny, slightly gross (poop bag comedy), non-cruel, clear UI hints.

## 5. Map zones / mission areas

See `phase0md4_mission_design_blueprint.json` `zones` array — aligned with existing **ZoneLabels** and garage/market layout in the expanded scene.

## 6–9. Objectives, optional, failure, completion

- **Main sequence:** JSON `objective_sequence` — maps to D5 wiring order; exact copy can be refined in `TacoBellDialogueProvider` / Quest strings.
- **Optional:** Polaroid/clue pickups already hinted by adapter categories (`polaroid`, `evidence_clue`).
- **Failure:** Prefer **retry via mission reload** over permanent GameState lock until economy is ready.
- **Completion:** Today’s code path: **Phase0KMissionCompletionController** + `GameState.complete_mission` + `SceneManager.show_mission_result` — D5 should not fork a third completion path.

## 10–13. Routes

- **Main route:** Market → hub → garage approach → keypad pocket → **code gate** → post-gate buffer → **security beam** zone → bag room → south corridor → exit.
- **Louis bypass:** Scene data: **bypasses `garage_entry_beam`** — player skips the **beam ambush challenge** (not the keypad). Narratively: “Louis knows the gross employee entrance.”
- **Risk/reward:** Skip beam timing stress but possibly miss a clue or scheme trigger tied to beam zone — D5 can tune rewards later.

## 14–20. Mechanic roles

- **Beam:** One-shot alarm + escalation signal to `MissionAlertController`; must not re-trigger same attempt.
- **Code gate:** `Phase0JCodeGateController` — blocker collision, wrong-code guard spawn hook.
- **Poop bag:** Aimed throw (T) + click; `MissionToolSurfaceHelper` dispatches to mission surface; decoy radius in `IsoMissionBase.deploy_poop_bag_decoy_at`.
- **Clues / evidence:** Bridges + Phase0JMissionStateAdapter sync.
- **Scheme cards:** Passive modifiers via `CardEffects` / `MissionSchemeBridge` — mission should be completable without equipping specific cards.
- **Dialogue:** `TacoBellDialogueProvider` for callouts.
- **Reset:** Attempt counters in `_attempt_runtime_state`; D5 aligns QuestManager list reset with reload boundary.
- **Reward:** Defer heat economy; minimal XP/mission complete flag via existing `GameState` path.

## 21–22. Onboarding & tests

- **Onboarding:** Pause **Objectives** tab is primary (fed by **`MissionPauseDataProvider`**); Phase0JDebugHUD is dev-only fallback — D5 should reduce reliance on debug HUD for player-readable state.
- **Manual test checklist:** See final plan `manual_review_checklist` + D5 runtime table.

Assertions: blueprint JSON flags all true.
