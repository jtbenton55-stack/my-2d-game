# D6-01 — Taco Security / Heat MVP (implementation spec — not implemented here)

## Purpose

Unify **security-related outcomes** (camera, guard, beam, wrong code, alarm) under a **single event vocabulary** and explicit **heat policy** so designers can reason about replay pressure without duplicating counters.

## Why now

Heat already mutates iso missions via `_apply_heat_profile`, but **sources of increments** are implicit. Without adapter, D6-02/D6-03 will attach ad-hoc hooks and double-count.

## Allowed files (expected)

- `src/missions/iso/runtime/MissionSecurityEventAdapter.gd` (new)
- `src/missions/iso/runtime/MissionAlertController.gd` (small call-site edits)
- `src/missions/iso/runtime/MissionSecurityCamera.gd` (wrap calls)
- Beam / gate scripts in `src/missions/iso/runtime/**` (surgical)
- `src/autoload/GameState.gd` (policy helpers only — avoid schema break)
- `src/missions/iso/runtime/IsoMissionDebugPanel.gd` (F10 fields)
- `src/missions/ui/MissionPauseDataProvider.gd` or pause text provider (one line)

## Forbidden / high caution

- `project.godot` (unless adding **no** new actions — prefer none)
- `scenes/missions_iso/*.tscn` layout edits — **avoid**; prefer markers already present
- `Player.gd` — **out of scope** unless adapter needs a one-line signal (prefer not)
- Broad `IsoMissionBase.gd` refactor — **forbidden**; only call existing public hooks

## Systems reused

- `MissionAlertController`, `mission_performance`, `get_mission_heat`, `_apply_heat_profile`

## Systems added

- `SecurityEvent` dictionary contract + adapter routing table

## Data model

```text
SecurityEvent { kind: String, source_id: String, severity: int, flags: Dictionary }
HeatPolicyResult { increment_failed_attempts: int, record_performance: Dictionary }
```

## UI / F10

- F10: rolling log last 8 events + heat + alert state
- Pause: “Heat: X/5 — means …” tooltip text via provider

## Save/load

- Reuse existing `failed_attempts`; migration **not** required if only changing increment sites

## Acceptance criteria

1. Tripping beam emits **one** normalized event visible in F10.
2. Wrong-code threshold still respects `_heat_profile`.
3. No duplicate `alarms_triggered` increments for same frame classification unless policy says so.
4. `get_mission_heat` changes only through documented policy functions.

## Runtime test checklist

- Launch Taco iso; trip camera; trip wrong code; verify F10 counts; finish mission fail/success; verify heat integer.

## Static validator checklist (for D6-01 pass)

- No new InputMap actions unless justified
- `MissionBlockoutValidator` still passes

## Risks / fallback

- **Risk:** event spam performance — throttle adapter to once/frame coalesce.
- **Fallback:** if adapter slips schedule, **document** interim counter mapping in `IsoMissionDebugPanel` only.

## Next prompt A-block

Include: adapter file path, policy table screenshot in text, heat before/after integers, F10 excerpt.

## Assertions

| Assertion | Value |
|-----------|--------|
| d6_01_spec_created | true |
