# Debug audit (2026-04-30)

Scope: changes for legal-safe collectible IDs, shelf UI rename, `GameState` defaults, and documentation.

## Static checks

- **Grep:** No remaining `Smiski` / `SmiskiShelf` references in `src/` or `scenes/` after migration.
- **Linter:** `read_lints` on edited GDScript files — no issues reported.
- **Risk:** `debug_unlock_all_missions` was `true` by default (release-unfriendly); now `false` with tests still able to force off during resets.

## Manual verification (when Godot is available)

1. New game: only `taco_bell_drop` should appear on the mission board unless `debug_unlock_all_missions` is enabled in `GameState` or project tooling.
2. Collect optional pickups in Taco Bell / Jazz Club; hideout **Collectibles shelf** lists Glow Guys / Shelf Goblins; polaroid gallery shows matching memory entries.
3. Load an old save that still lists `taco_bell_smiskis` / `velvet_smiskis` in JSON: after load, `collected_polaroids` should contain canonical IDs only.

## Follow-ups (design / not blocking this patch)

- Heat / restart mutation tables: partially specified in `docs/MISSION_BIBLE.md`; wire per mission as needed.
- Bentley poop bags, evidence clue graph, and Tower crew-chain assists: implement against `GameState` / `QuestManager` as features land.
