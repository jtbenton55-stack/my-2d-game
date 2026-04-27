# CURRENT_STATE.md — Untitled Heist RPG

## Last Updated
2026-04-27 by game (Mission 2 - Velvet Paw Jazz Club)

## What's Working

### Save/Load (V2)
- **SaveManager.gd** — Rewritten to use `GameState.to_dict()` / `from_dict()`
  - 3 save slots + auto-save slot 0
  - Version tracking (0.2.0) for future migrations
  - Save metadata includes: health, mission progress, intel, failure count

### Level System (V2 API)
- **LevelBase.gd** — Updated V1 → V2 API
  - `start_heist()` → `start_mission()`
  - `complete_heist()` → `complete_mission()` + `end_mission()`
  - Added `_get_mission_id()` override hook
  - Safe signal disconnection in cleanup
- **TestMissionRoom.gd** — Generic test room for spine validation
  - Configurable `mission_id` and `guard_count`
  - Debug hotkeys: PageDown=complete, PageUp=fail
  - Integrates with MissionResult UI

### Scene Management (V2 API)
- **SceneManager.gd** — Fixed V1 references
  - `is_in_heist` → `is_in_mission`
  - `player_data.position` → `player_position`
  - `player_data.current_scene` → `player_current_scene`

### Autoloads
- **CardManager** — Added to project.godot autoloads
  - Was missing, causing `get_node("/root/CardManager")` failures

### UI
- **MissionResult** — New success/failure screen
  - Connects to `EventBus.show_mission_result` and `show_failure_screen`
  - Auto-triggers on `mission_completed` signal
  - Shows rewards (intel, cards, polaroids) on success
  - Shows failure intel, attempt count, clue progress on failure
  - Returns to hideout on continue

## Files Changed

| File | Change |
|------|--------|
| `src/autoload/SaveManager.gd` | Rewritten for V2 GameState |
| `src/levels/LevelBase.gd` | V1 → V2 API migration |
| `src/autoload/SceneManager.gd` | V1 → V2 API migration |
| `src/combat/CombatSystem.gd` | Fixed `player_data.stealth` → `source.is_stealth` |
| `src/ui/PauseMenu.gd` | Fixed `is_in_heist` → `is_in_mission` |
| `src/player/Player.gd` | Fixed `player_data.position` → `player_position` |
| `project.godot` | Added CardManager autoload |
| `src/ui/MissionResult.gd` | **NEW** — Mission result screen |
| `scenes/ui/MissionResult.tscn` | **NEW** — Mission result scene |
| `src/levels/TestMissionRoom.gd` | **NEW** — Generic test mission |
| `scenes/missions/TestMissionRoom.tscn` | **NEW** — Test mission scene |
| `docs/CURRENT_STATE.md` | **NEW** — This file |
| `src/enemies/Goon.gd` | **NEW** — Basic melee enemy (simpler than Guard) |
| `scenes/characters/goon.tscn` | **NEW** — Goon enemy scene (placeholder visuals) |
| `src/missions/TacoBellMission.gd` | **NEW** — Mission 1 logic (Louis dialogue, sniff trail, bag pickup, collectibles) |
| `scenes/missions/TacoBellMission.tscn` | **NEW** — Mission 1 scene (alley layout, spawns, zones) |
| `assets/missions/taco_bell/README.md` | **NEW** — Asset placeholder notes for mission 1 |
| `src/enemies/Bruiser.gd` | **NEW** — Slow heavy enemy with telegraphed slam attacks |
| `scenes/characters/bruiser.tscn` | **NEW** — Bruiser enemy scene (placeholder visuals) |
| `src/missions/JazzClubMission.gd` | **NEW** — Mission 2 logic (Yordano, music puzzle, ledger, escape) |
| `scenes/missions/JazzClubMission.tscn` | **NEW** — Mission 2 scene (jazz club layout, VIP, backstage, bar, stage) |

## How to Test

### Save/Load
1. Start game, change some state (complete a mission, take damage)
2. Call `SaveManager.save_game(1)` from debug console
3. Change state again
4. Call `SaveManager.load_game(1)` — state should restore

### Mission Flow (Spine Loop)
1. Enter TestMissionRoom from hideout
2. Reach exit zone → MissionResult success screen → returns to hideout
3. Or call `get_tree().current_scene.fail_level("test")` → MissionResult failure screen
4. Check GameState: `completed_missions`, `failed_attempts`, `intel_points`

### CardManager
1. `get_node("/root/CardManager").get_unlocked_cards()` should work without error

### Mission 1: Taco Bell Drop
1. Start mission from hideout
2. Talk to Louis → follow sniff trail → find bag → escape
3. Collect polaroid and trinket along the way
4. Success returns to hideout with rewards

### Mission 2: Velvet Paw Jazz Club
1. Start mission from hideout (unlocked after completing taco_bell_drop)
2. Talk to Yordano at the bar for hints
3. Approach music puzzle in VIP area (sequence: D-G-C-E)
4. Solve puzzle → ledger becomes collectible
5. Grab ledger → escape through backstage exit
6. Yordano helps with escape if friend favor earned
7. Collectibles: Polaroid (near stage), Trinket (Yordano's drumstick at bar)
8. Enemies: Bouncers (tougher Guards), Bruisers (slow/heavy with telegraphed attacks)
9. Stationery Queen card allows unlimited puzzle retries

## Known Risks

1. ~~**MissionData scenes don't exist yet** — `taco_bell_drop` references `res://scenes/missions/TacoBellMission.tscn` which doesn't exist. TestMissionRoom.tscn is the fallback.~~ **FIXED** — TacoBellMission.tscn created
2. **HeistTutorial.gd still extends LevelBase** — Should work since LevelBase was fixed, but `complete_level()` calls `super.complete_level()` which now uses V2 API.
3. **No actual `fail_level()` trigger** — TestMissionRoom has it, but real missions need to call it when player dies or is detected.
4. **MissionResult not added to root** — Scene exists but isn't auto-instantiated. Need to either add to autoloads or instantiate from SceneManager/LevelBase.
5. **Missing `assets/themes/default_theme.tres`** — UI scenes reference it but it doesn't exist. Pre-existing issue; Godot will fall back to default theme.
6. **TacoBellMission not wired to player death** — `fail_mission()` exists but isn't called on `player_died` signal yet.
7. **JazzClubMission not wired to player death** — Same issue as TacoBellMission.
8. **Bruiser AnimatedSprite2D** — Bruiser uses placeholder Polygon2D visuals like Goon. No sprite frames exist yet.
9. **Music puzzle audio** — Currently visual-only feedback. AudioManager integration needed for note sounds.
10. **Yordano dialogue JSON** — Exists in `assets/dialogue/yordano.json` but JazzClubMission uses inline dialogue arrays. Consider migrating to DialogueManager V2.

## In Progress (hands-missing-systems) — COMPLETED

- ✅ CollectibleManager — `src/collectibles/CollectibleManager.gd`, autoload, GameState plants/diamonds
- ✅ DialogueBox UI — `scenes/ui/DialogueBox.tscn` + `src/ui/DialogueBox.gd`
- ✅ NPC Base Scene — `scenes/characters/NPC.tscn` + `src/characters/NPC.gd`
- ✅ Hideout V2 Features — updated `src/levels/Hideout.gd`
- ✅ JSON dialogue files — `assets/dialogue/{louis,jake,mere,dom,yordano}.json`
- ✅ Mission 1: Taco Bell Drop — full mission scene + logic
- ✅ Mission 2: Velvet Paw Jazz Club — full mission scene + logic + Bruiser enemy + music puzzle

## What's Next

1. Add MissionResult to autoloads or instantiate it in SceneManager
2. Test TacoBellMission — test full spine
3. Test JazzClubMission — test full spine including music puzzle and Bruiser combat
4. Wire up player death / detection to call `fail_level()` / `fail_mission()`
5. Test full spine: Hideout → MissionSelect → SchemeCardMenu → Mission → Result → Hideout
6. Add audio feedback to music puzzle (note sounds via AudioManager)
7. Create actual sprite frames for Bruiser enemy
8. Mission 3: Rewrite Room (Mere's mission)
