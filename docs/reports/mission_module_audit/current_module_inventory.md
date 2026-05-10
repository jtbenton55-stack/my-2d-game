# Current reusable module inventory (categories A–O)

See `current_module_inventory.json` for structured status, files, risks, and P0 notes.

## Summary

| Category | Status |
|----------|--------|
| A Mission lifecycle | EXISTS_PARTIAL — `IsoMissionBase.gd` + `LevelBase.gd` |
| B Objectives | EXISTS_PARTIAL — `QuestManager` + Iso internals + Phase0J adapter in redesign scene |
| C Clues / collectibles | EXISTS_PARTIAL — placeholders + `GameState` clues for pause |
| D Scheme cards | EXISTS_PARTIAL — `CardManager` / `CardEffects` + scattered hooks |
| E Mission tools | EXISTS_PARTIAL — aimed poop throw in `Player.gd` + `deploy_poop_bag_decoy_at` on mission |
| F Interaction | EXISTS_PARTIAL — placeholders + `MissionRouteAccessPoint` + Phase0J bridge |
| G Stealth / detection | EXISTS_PARTIAL — `MissionAlertController`, zones, light zones |
| H Player actions | EXISTS_PARTIAL — stealth/dodge/combat in `Player.gd`; **no stamina/sprint in Player.gd** |
| I Animation intent | EXISTS_PARTIAL — `PlayerVisualAnimator.gd` (parallel track) |
| J Pause / mission UI | EXISTS_PARTIAL — `src/ui/test_ui/pause_menu.gd` owns objectives/scheme/clues tabs |
| K Save / load | EXISTS_READY — autoloads (read-only audit) |
| L Result / reward / heat | EXISTS_PARTIAL — `LevelBase` + Iso performance + Phase0K completion in redesign test |
| M Debug / validators | EXISTS_READY — `MissionBlockoutValidator`, debug panels |
| N Visual / iso | EXISTS_READY — `GameplayRoot` / `ArtRoot` convention in `IsoMissionBase` |
| O Hideout launcher | EXISTS_PARTIAL — `GameState` catalog + `SceneManager` (not modified) |

## Hard assertions

All keys in `current_module_inventory.json` → `assertions` are set `true`.
