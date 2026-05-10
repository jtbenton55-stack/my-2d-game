# Global codebase inventory

- **entries:** 3179
- **autoloads:** 10

## Autoloads

- `GameState` → `res://src/autoload/GameState.gd`
- `SaveManager` → `res://src/autoload/SaveManager.gd`
- `AudioManager` → `res://src/autoload/AudioManager.gd`
- `SceneManager` → `res://src/autoload/SceneManager.gd`
- `DialogueManager` → `res://src/autoload/DialogueManager.gd`
- `QuestManager` → `res://src/autoload/QuestManager.gd`
- `CardManager` → `res://src/inventory/CardManager.gd`
- `CardEffects` → `res://src/autoload/CardEffects.gd`
- `EventBus` → `res://src/utils/EventBus.gd`
- `CollectibleManager` → `res://src/collectibles/CollectibleManager.gd`

## Note

Full machine list is in `global_codebase_inventory.json`.

`res://assets/` is **not** recursively enumerated (large binaries). Mission definition assets referenced by Taco scenes (e.g. `res://assets/missions/taco_bell_iso_blockout_definition.tres`) were verified by scene inspection, not by a full asset tree walk.
