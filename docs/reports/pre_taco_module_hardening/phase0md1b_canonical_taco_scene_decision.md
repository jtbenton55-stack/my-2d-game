# Canonical Taco Bell scene (0M-D1B)

## Recommendation

**Canonical redesign base:** `res://scenes/missions_iso/TacoBellIso_Editable.tscn`

**Non-canonical (retained):** `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn` — Phase0J/K sandbox; not deleted.

## Why

- Leaner scene tree; fewer parallel controllers → less duplicate effort during art/layout redesign.
- `SceneManager` already prefers `TacoBellIso_Editable.tscn` for `taco_bell_drop` in debug builds (working launch path).
- Same `IsoMissionBase` + blockout definition as redesign test; framework changes apply to both until scenes diverge intentionally.

## Next Taco redesign prompt

Author against **`TacoBellIso_Editable.tscn`**. Pull features from `RedesignTest` only when explicitly migrating a subsystem.

See JSON for assertions and migration notes.
