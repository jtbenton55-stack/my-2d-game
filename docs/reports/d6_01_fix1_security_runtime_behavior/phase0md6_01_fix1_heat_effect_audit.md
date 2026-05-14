# Heat effect audit

**Persistent heat**  
- `failed_attempts` per mission id, capped at 5 for profile (`GameState` / mission failure path — D6-01).

**Application**  
- `IsoMissionBase._apply_heat_profile()` runs on attempt setup; adjusts wrong-code tolerance, camera timing/sensitivity, optional extra camera/guard pressure, scent-related modifiers per existing tables.

**FIX1 hardening**  
- Slightly stronger **heat == 1** camera multipliers so replay-2 is easier to notice in playtest without new save keys or systems.

**Mid-run**  
- Cameras/beam/wrong-code alarms still do **not** bump persistent heat directly.
