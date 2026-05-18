# D6-04A F10 Security Debug Panel Cleanup — Implementation Report

## Goal

Reorganize the F10 compact debug HUD security block into a concise, authoring-focused view for manual D6-04 camera/beam testing. Display/reporting only; no gameplay changes.

## Branch

`c2a-full-character-animation-20260509-172230`

## Files changed (this pass)

| File | Change |
|------|--------|
| `src/missions/iso/runtime/IsoMissionDebugPanel.gd` | Replaced ~280-line inline `sec_lines` block with `_build_authoring_security_f10_lines()` and helpers; added `SHOW_LEGACY_SECURITY_DEBUG := false` |
| `src/tools/editor/d6_04a_f10_security_debug_cleanup/phase0md6_04a_static_validator.py` | New static validator |
| `docs/reports/d6_04a_f10_security_debug_cleanup/*` | Reports |

## Files intentionally not modified

- `src/levels/IsoMissionBase.gd` (summary keys unchanged)
- Beam/camera/router/guard runtime scripts
- Scenes, `project.godot`, player/HUD/input

## Implementation summary

1. **`SHOW_LEGACY_SECURITY_DEBUG`** — defaults `false`. When `true`, appends compact FIX7 legacy subsection via `_build_legacy_security_f10_lines()`.

2. **`_build_authoring_security_f10_lines()`** — builds seven logical sections:
   - Mission (id, heat, alert, code)
   - Security Authoring (root + counts)
   - Event Router
   - AMBUSH Beam
   - Authored Camera
   - Guard Spawn / AI
   - Manual test help line

3. **Helpers** — `_yes_no`, `_dash_if_empty`, `_short_path`, listener/rejection formatters, direct-fallback labels, `_force_chase_label`.

4. **Removed from default F10** — FIX7A–F geometry solver fields, anchor path spam, choke/probe/hit diagnostics, duplicate D6 section headers, full active-guard path lists.

## Rollback

Revert `IsoMissionDebugPanel.gd` to prior `sec_lines` inline block (git history) or set `SHOW_LEGACY_SECURITY_DEBUG = true` for partial legacy visibility without restoring full clutter.
