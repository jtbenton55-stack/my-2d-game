# 0M-D4 — D5 implementation spec (evidence-based)

## 1. Executive summary

The expanded **RedesignTest** mission already contains **IsoMissionBase**, **Phase0J** (code gate + adapters + router), **Phase0K** (completion + Louis exit), **beam one-shot** logic in `IsoMissionBase`, and **D2 pause bridges**. The **highest-risk gap** for a “clean redesign” is not missing art—it is **fragmented mission state**: objectives are written from multiple places, **`MissionObjectiveBridge.reset_runtime_objectives_for_mission` is a stub**, and **Louis’s bypass is declared in markers but deferred in `Phase0JMechanicRouter`**. D5 should therefore target a **small, testable vertical slice: attempt reset + objective/pause sync + Louis beam-bypass wiring**, not a feature dump.

## 2. Audit-derived D5 target

See JSON field `d5_target` — one sentence.

## 3. Evidence from D4 findings

Listed in `phase0md4_d5_implementation_spec.json` under `derived_from_d4_findings`.

## 4. D5 focus area classification table

See JSON `focus_area_classifications` (keys → P0/P1/P2/P3/DROP_FOR_NOW).

## 5–9. P0 / P1 / P2-P3 / DROP / UNKNOWN

- **P0 / P1 / P2 / P3 / DROP / UNKNOWN:** JSON arrays `p0_items` … `unknown_items`.

## 10–11. Must preserve / must avoid

JSON `must_preserve`, `must_avoid`.

## 12. Safest playable vertical-slice target

**D5 Target:** Same as JSON `d5_target`.

**Player can (after D5):**

- Launch **taco_bell_drop** and land in **RedesignTest** (unchanged resolver).
- See **pause objectives** that match the current mission phase after reload/retry.
- Walk **main path** and trigger the **garage_entry_beam** alarm at most once per attempt.
- Use **Louis shortcut** and observe a **different runtime outcome** for the beam challenge than the main path (bypass or neutralization — exact implementation in D5-03).
- Use **poop bag aimed throws** where the mission surface supports them (existing Player + tool surface).
- **Complete / return** using existing `GameState` / `SceneManager` flow when objectives satisfied.

**D5 is successful when:** JSON `acceptance_criteria`.

**D5 should stop before:** JSON `stop_conditions` + scope: full stealth AI, full combat, animation-gated logic, large `IsoMissionBase` refactors, map redesign.

## 13. D5 phase-by-phase implementation plan

See JSON `d5_phases` — five ordered phases (reset contract, pause context, Louis bypass, poop QA, validators).

## 14. Module ownership for D5 mechanics

Cross-reference `phase0md4_taco_module_ownership_map.md`.

## 15–17. Files likely modified / created / must not touch

JSON `likely_modified_files`, `likely_created_files`, `protected_files`.

## 18. Scene node edit plan

JSON `likely_scene_node_edits` — **prefer zero scene edits** in D5-01/02; only D5-03 if signal wiring cannot be done via existing nodes + code.

## 19–20. Static / runtime validation plans

JSON `static_validation`, `runtime_validation`.

## 21–23. Acceptance, stop conditions, revert

JSON `acceptance_criteria`, `stop_conditions`, `revert_notes`.

## 24. Recommended exact next prompt focus

JSON `recommended_next_prompt_focus`.

---

Hard assertions: all JSON boolean flags at top of `phase0md4_d5_implementation_spec.json` are **true**.
