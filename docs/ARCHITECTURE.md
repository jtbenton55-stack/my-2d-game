# Godot Architecture

## Spine
`MainMenu -> Hideout -> MissionSelect -> SchemeCardMenu -> Mission -> MissionResult -> Hideout`

Side hub flow:
`Hideout <-> CityHub`, `Hideout -> CrewMenu`, `Hideout -> PolaroidGallery`

Final flow:
`SterlingTowerMission -> Ending -> Hideout/MainMenu`

## Autoloads
- `GameState`: mission progress, failed attempts, cards, polaroids, crew, upgrades, settings.
- `SceneManager`: scene transitions and mission start/end routing.
- `DialogueManager`: current dialogue queue and line events.
- `QuestManager`: active objective text.
- `AudioManager`: music and SFX cues.
- `CardManager`: loads SchemeCard resources.
- `CardEffects`: translates selected cards into stat and route modifiers.
- `CollectibleManager`: polaroid catalog and collection helpers.
- `EventBus`: global signals and normal game logging.

## Scene Families
- `scenes/hideout`: cozy hub and progression board.
- `scenes/missions`: compact mission rooms that extend `LevelBase`.
- `scenes/ui`: mission selection, cards, results, crew, gallery, dialogue, HUD.
- `scenes/characters`: player, Bentley, NPCs, reusable enemies.

## Implementation Rules
- Build the meta-loop first, then add mission-specific content.
- Prefer small data-driven checks such as `GameState.has_selected_card("card_id")`.
- Failure should call `GameState.fail_mission()` and return to a supportive result screen.
- Success should unlock at least one of: mission, card, polaroid, crew favor, trophy/dialogue.
- Keep stretch features isolated so MVP remains shippable.
