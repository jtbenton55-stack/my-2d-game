# Phase 2 — HUD design decision

1. **Objective ticker:** `ObjectiveLabel` — full-width top band with **left margin 232px** and **right margin 216px** to clear health (left) and mission strip (right). `autowrap` + `clip_text`.
2. **Stamina bar:** `SprintStaminaBar` under `MissionHudStrip` (top-right column).
3. **Poop count:** `PoopBagLabel` — `Bags: N` using `GameState.get_poop_bag_count()`.
4. **Control hint:** `ControlHint` under strip; **hidden by default** (`HUD.show_compact_control_hint` export default `false`).
5. **Health overlap:** Left bars unchanged; objective band inset; strip right-only.
6. **F1/F10/F11:** Strip uses layer 10 same as HUD; no new CanvasLayer; corners separated (F10 left-mid from prior work).
7. **Refresh:** ~12Hz `_process` accumulator + `EventBus.game_state_changed` for poop; objective from `MissionHudDataProvider` each tick in mission.
8. **Mission-only strip:** `MissionHudStrip.visible = GameState.is_in_mission`; objective text cleared when not in mission.
9. **F10:** Unchanged by this pass; retains raw counters.
