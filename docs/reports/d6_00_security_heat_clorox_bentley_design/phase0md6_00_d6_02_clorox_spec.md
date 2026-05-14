# D6-02 — Clorox wiping MVP (implementation spec — not implemented here)

## Purpose

Ship **1–3 optional wipeable traces** in Taco iso proving cleanup fantasy + **one** scoring/heat hook.

## Why after D6-01

So heat adjustments from security events do not fight an independent cleanup subsystem.

## Allowed files

- `src/missions/iso/runtime/WipeableTrace.gd` (new) or reuse `MissionMechanicHook` patterns
- `src/missions/iso/placeholders/**` only if marker contract already exists
- `src/autoload/GameState.gd` — optional `mission_performance` key `traces_cleaned`
- `src/missions/iso/runtime/IsoMissionDebugPanel.gd` — counter
- **Scene markers** — prefer data-only additions in **authoring** pipeline; if `.tscn` edits unavoidable, separate micro-pass

## Forbidden

- Mandatory wipe to exit
- New player mode / inventory screen
- Linking to hideout evidence board clues automatically

## Acceptance criteria

1. Player can ignore all wipes and still complete Taco.
2. Completing a wipe shows clear feedback under 1.5s.
3. Exactly **one** primary reward channel documented (performance **xor** heat micro-adjustment).

## Tests

- Wipe while guard sees player → interrupt.
- F10 shows `traces_cleaned`.

## Assertions

| Assertion | Value |
|-----------|--------|
| d6_02_spec_created | true |
