# 0M-D6-01-FIX7F — Final report

**Verdict: PASS (geometry + runtime probe)** — Doorway-rectangle solver succeeds in Godot MCP playtest. Jake should still confirm visual alignment in-editor (screenshot saved to `user://fix7f_beam_validation.png`).

## Root causes fixed

1. **Physics timing:** Beam setup ran before TileMap collision was queryable → all rays missed. Fixed via `_schedule_fix7_ambush_beam_physics_setup()` on `physics_frame` (one-shot).
2. **FIX7E single X:** Seed choke X was not centered in walkable opening. FIX7F searches X/Y grid and scores best doorway.
3. **Overlap false positives:** `intersect_shape` flagged wall-adjacent door edges. Replaced with `_fix7f_passage_walkable` point sampling.
4. **Ray length:** Shortened to 180px local probe to avoid distant parallel walls.

## Autonomous validation (Godot MCP Pro)

| Check | Result |
|-------|--------|
| `fix7f_mode` | `doorway_rect` |
| `fix7f_success` | `true` |
| `fix7f_fallback_used` | `false` |
| Visual height | 170px (top 619 → bottom 789) |
| Trigger size | 72 × 186 |
| Beam host | (8225, 704) |
| Screenshot | `user://fix7f_beam_validation.png` |

## Not autonomously confirmed

- `beam_trip` counter increment (teleport did not fire `body_entered`; zone wiring unchanged from FIX7A)
- Camera / wrong-code regressions (no code changes; not re-run in this session)

## Kimi

Not used.

## Next

- Jake visual confirm at AMBUSH hallway
- Optional: cleanup unused FIX7D/FIX7E helpers after sign-off
