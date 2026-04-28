# OpenClaw Spine Rescue Rewrite

This project has been rewritten to prioritize a stable Godot 4.6 playable spine:

Title Screen -> Hideout -> Mission Select -> Scheme Card Draft -> Mission -> Success/Failure -> Mission Result -> Hideout.

## What changed

- Replaced the brittle swarm-generated scripts with smaller defensive scripts.
- Preserved the existing scene/resource layout where practical.
- Added missing support assets:
  - `res://assets/themes/default_theme.tres`
  - `res://icon.svg`
- Simplified missions so they use a shared `LevelBase.gd` contract.
- Simplified player, Bentley, enemy, UI, save, card, quest, dialogue, scene, and collectible systems.
- Removed reliance on long mission-specific scripts until the spine is stable.

## Known limitation

I could not run the Godot editor/headless validator inside this environment because the Godot executable is not installed here.  The scripts were rewritten for Godot 4.x syntax and checked for missing resource references, obvious stale paths, and common syntax hazards, but you should still open the project in Godot 4.6 and run the main scene.

## First thing to test in Godot

1. Open `project.godot`.
2. Run the project.
3. Click `New Game`.
4. In the Hideout, move to the heist/mission zone and press `E`.
5. Select a mission.
6. Select up to 3 cards.
7. Start the mission.
8. Reach the exit.
9. Confirm the result screen returns you to the hideout.

## Controls

- WASD: move
- Left click/controller A: attack
- Space: dodge
- E: interact/advance dialogue
- Shift: stealth/Bentley bark fallback
- Escape: pause

## Next recommended pass

After confirming the spine runs, re-add polish one mission at a time:
1. Taco Bell Drop pickup/exit tuning.
2. Jazz Club setlist puzzle.
3. Rewrite Room legal/screenwriting puzzle.
4. Car Chase dedicated driving mode.
5. Sterling Tower scripted friend-favor finale.
