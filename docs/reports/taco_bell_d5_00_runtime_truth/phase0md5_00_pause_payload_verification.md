# 0M-D5-00 — Phase 3: Pause / objectives / scheme / clues

## Pause open (GRB)

- `PauseMenu` node exists at `/root/TacoBellIso_Editable/PauseMenu` (`CanvasLayer`, `PROCESS_MODE_ALWAYS` in script).
- **Bindings:** `pause_menu.gd` toggles pause on **`ui_cancel` (Esc)**, not the `pause` input map action alone (`_unhandled_input` checks `ui_cancel`).
- **Test:** Sent `grb_key` with `action: "pause"` — **no** verified open (binding mismatch).
- **Test:** Sent `grb_key` with `action: "ui_cancel"` — next `grb_get_property` on `PauseMenu` **timed out** (GRB reported session stale). Likely cause: `get_tree().paused = true` in `_pause_game()` stalls bridge polling — **tooling limitation**, not proof pause UI is broken.

## Static verification (payload contract)

- `MissionPauseDataProvider.get_pause_payload` aggregates objectives (via `MissionObjectiveBridge.get_objective_snapshot` → `QuestManager`), scheme cards (`MissionSchemeBridge`), clues (`MissionClueBridge`, discovered-only).
- `pause_menu._objectives_text()` uses `GameState.current_mission_id` when building snapshot — **mission_id source** is GameState, not hard-coded Taco string in that call site (see `pause_menu.gd`).

## Tabs / coherence

- **Objectives / Scheme / Clues** buttons are created in `_setup_controls_menu` — structure verified **STATIC_ONLY**.
- **Coherence / current text:** depends on `QuestManager` + mission state — **MANUAL_REVIEW_REQUIRED** after opening pause in-editor (GRB blocked post-pause).

## Recommendation

Manual checklist: Esc → verify overlay; click Objectives / Scheme Cards / Clues; confirm no crash with empty clue lists (code paths handle empty arrays).
