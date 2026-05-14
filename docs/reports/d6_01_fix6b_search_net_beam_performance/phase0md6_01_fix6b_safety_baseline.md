# PHASE 0M-D6-01-FIX6B Safety Baseline

## Pre-Implementation Safety Check

**Date**: 2026-05-13  
**Phase**: D6-01-FIX6B — Search Net Security Behavior / Guard Performance / Far-Right Beam Placement

### Assertions

- ASSERT repo_root_confirmed == true
- ASSERT current_branch_recorded == true
- ASSERT git_status_recorded == true
- ASSERT d6_01_fix6b_scope_confirmed == true
- ASSERT protected_files_identified == true

### Repository Status

```
Repo Root: C:\Users\jtben\Documents\PBD 2026\OpenClaw\main\games\my-2d-game
Current Branch: c2a-full-character-animation-20260509-172230
Git Status: Clean (prior changes from FIX6/FIX6A committed)
```

### Scope Confirmation

This pass implements:
1. Heat-scaled security "search net" behavior for guards
2. Guard performance lifecycle management (sleep/despawn distant inactive guards)
3. Far-right hallway red beam placement (immediately before bag room)
4. F10 debug updates for search net and lifecycle visibility

### Protected Files

**Forbidden (will not edit):**
- project.godot
- src/player/Player.gd
- src/player/PlayerStaminaController.gd
- scenes/characters/player.tscn
- assets/* (raw/generated)
- scenes/missions_iso/TacoBellIso_Editable.tscn (noncanonical)

**Allowed with caution:**
- src/levels/IsoMissionBase.gd (primary target)
- src/missions/iso/runtime/IsoMissionDebugPanel.gd (F10 updates)

**Allowed:**
- docs/reports/d6_01_fix6b_search_net_beam_performance/*
- src/tools/editor/d6_01_fix6b_search_net_beam_performance/*

### Target Scene

**Confirmed playable:**
- res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn

### Beam Placement Note

The temporary red beam is:
- Tagged: `D6_FIX6B_TEMP_SECURITY_BEAM_REMOVE_OR_FINALIZE_IN_LEVEL_PASS`
- Location: Far-right hallway immediately before bag room
- Position: 80px before bag objective (was 260px)
- Removal: Deferred to later level design pass

### Result

**All safety checks passed. Proceeding with implementation.**
