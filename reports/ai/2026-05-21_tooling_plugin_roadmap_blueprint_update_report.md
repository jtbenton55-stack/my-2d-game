# Tooling / Plugin Roadmap Blueprint Update Report

**Date:** 2026-05-21

**Scope:** Documentation update only.

## Goal

Update the plug-and-play roadmap and implementation blueprint to place these planned systems in the correct sequence:

- PVGames Object Palette v2 brush/repeat placement
- Mission Paint Dock
- Mission Authoring Palette
- Mission Assist Browser
- Larger Scene/Asset Browser
- Recommended editor gizmos
- Manual Animation Mapper/Reviewer
- Custom chronographic sequences instead of a large orchestrator
- CameraBridge, PlayerControlBridge, MissionDialogueBridge expansion
- PhantomCamera integration behind CameraBridge
- Resonant visual audio manager integration behind AudioVisualBridge
- LimboAI deferral until mature NPC/social/guard behavior work

## Files Changed

| File | Change |
|---|---|
| `docs/PLUG_AND_PLAY_MISSION_SYSTEM_ROADMAP.md` | Added timing/order for editor tools, paint tools, manual animation mapping, custom sequences, Resonant, PhantomCamera, PlayerControlBridge, and LimboAI deferral. |
| `docs/PLUG_AND_PLAY_IMPLEMENTATION_BLUEPRINT.md` | Added concrete folders/contracts for focused editor tools, gizmo table, animation-map source of truth, sequence Resources, and plugin bridge boundaries. |
| `docs/TACO_PAINT_READINESS_CHECKLIST.md` | Added blueprint reading requirement and packet-type guidance for PVGames brush mode, Mission Paint Dock, and animation mapper work. |
| `docs/MECHANIC_AUTHORING_FOUNDATION_GUIDE.md` | Added current limitations and future editor-tooling order after mechanic foundation validation. |

## Key Decisions Captured

- Build focused tools before one large scene/asset browser.
- Upgrade the existing PVGames Object Palette into brush/repeat placement before large visual passes.
- Keep Mission Paint Dock visual-only; do not mix collision or mission logic into paint packets.
- Treat generated animation classifier labels as untrusted; promote only manually reviewed row/column animation maps.
- Use custom chronographic sequence Resources instead of a giant global orchestrator.
- Route PhantomCamera through `CameraBridge` and Resonant through `AudioVisualBridge`.
- Keep LimboAI deferred until current authored security/Bentley approaches are insufficient for NPC/social behavior.

## Validation

| Check | Result |
|---|---|
| Grep for requested feature names across `docs/*.md` | Passed |
| `git diff --check` | Passed; existing CRLF warnings remain in unrelated tracked palette files |
| Runtime/editor checks | Not applicable; docs only |

## Notes

- Nowledge Mem working memory could not be loaded in this session because the `nmem` CLI is not installed.
- Existing unrelated dirty/untracked repo state was preserved.
