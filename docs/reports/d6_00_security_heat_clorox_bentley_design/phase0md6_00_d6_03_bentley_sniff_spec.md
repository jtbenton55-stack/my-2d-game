# D6-03 — Bentley sniff / Case-the-joint MVP or defer (implementation spec — not implemented here)

## Purpose

Decide whether to **expand** the existing **Case the Joint** pulse or **only document + instrument**.

## Default (per design decision)

**DEFER expansion** — ship **F10 metrics + group coverage audit** in a micro PR **or** 1-day polish if timeboxed.

## If implementing light MVP

- Extend `_collect_case_targets` group list; tune range/cooldown constants.
- Optional: `src/ui/test_ui/controls_overlay.gd` / pause copy — text only.

## Allowed files (when implementing)
- `src/ui/test_ui/controls_overlay.gd` / pause copy — text only
- **No** `project.godot` rebinding

## Forbidden

- Minimap
- Playable Bentley character swap
- New Input action

## Acceptance criteria

1. No regression in sprint/dash/HUD.
2. Pulse never highlights > N nodes (performance cap stays).
3. If deferred: documentation updated + F10 shows “pulse disabled by flag” dev setting.

## Assertions

| Assertion | Value |
|-----------|--------|
| d6_03_spec_created | true |
