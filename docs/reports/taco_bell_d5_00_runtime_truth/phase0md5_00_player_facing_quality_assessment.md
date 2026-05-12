# 0M-D5-00 — Phase 9: Player-facing quality

## Already fun / promising

- **Iso Taco layout** loads with rich marker/runtime scaffolding (56 scene markers, many runtime spawns) — scope feels like a real mission space (**VERIFIED_RUNTIME** tree + summary).
- **Dog companion** present — character fantasy reads (**VERIFIED_RUNTIME** node).
- **Sprint subsystem** exposes multipliers + stamina in live debug (**PARTIAL_RUNTIME**).

## Unclear / invisible

- **Objectives during play:** HUD ticker not validated; pause text not read live (**MANUAL_REVIEW_REQUIRED**).
- **Beam / alarm feedback:** Requires walking into zone — not auto-proven (**MANUAL_REVIEW_REQUIRED**).

## Unfinished (design vs polish)

- **Louis route** inspect-only deferred — alternate path not yet a mechanic (**STATIC_ONLY**).
- **Mission result celebration / evidence reward:** not exercised (**NOT_TESTED**).

## Broken?

- **No gameplay failure proven** by GRB; **11** engine errors on Hideout load warrant investigation separately (**PARTIAL_RUNTIME** logs only).

## Architecture vs player-facing

- `MissionObjectiveBridge.reset_runtime_objectives_for_mission` still `pass` — **player may not notice** if full scene reload resets Quest state; **developer risk** on partial-retry paths (**STATIC_ONLY**).

## Smallest high-impact player change

1. **HUD:** objective line + stamina bar + poop bag count (invisible state today).
2. **Pause:** ensure Esc overlay + tabs readable; consider explicit `taco_bell_drop` pin if `GameState.current_mission_id` ever drifts.

## Smallest regression-risk change

- Add a **manual + GRB smoke** checklist after any mission-state refactor; keep `get_runtime_debug_summary()` stable as contract.

## Should NOT do yet

- Refactor `IsoMissionBase`, split Phase0J/K, or widen combat/stealth scope before vertical slice UX is readable.

## Next player-facing improvement (evidence-based)

**HUD / clarity pass (0M-D5-02-UX)** ahead of D5-01, unless manual retry leak is confirmed.
