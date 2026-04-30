# Decisions

## 2026-04-28: Build Spine Before Stretch Content
The project prioritizes a complete replayable meta-loop over a large unfinished RPG. The working spine is Hideout -> Mission Select -> Scheme Cards -> Mission -> Result -> Hideout.

## 2026-04-28: Use Compact Systems To Imply Scale
Nocturne City should feel large through district names, recurring contacts, cards, polaroids, and crew favors rather than a huge map.

## 2026-04-28: Failure Is Progress
Failure returns to the hideout/result screen with intel and supportive dialogue. No "Game Over" language in normal play.

## 2026-04-28: Avoid Direct IP Copying
Homage NPCs and jokes are allowed, but no copied designs, logos, powers, or exact franchise dialogue.

## 2026-04-29: Scheme Cards Are Passive Loadouts
Cards chosen before a mission apply automatically (buffs, perks, or Taco Bell–specific bypasses). No in-mission hotkey; visibility comes from the HUD card strip plus `EventBus.card_triggered` toasts when something fires.

## 2026-04-29: Jazz Club Mission Structure
Wrong setlist is a timed alarm hunt (overlay + extra guards + resolve), not a hard fail. Correct setlist unlocks vertical progression (stairs/upstairs) where the real ledger lives behind a boss encounter (reused bruiser pattern first). Shared UI (`readable_note`) uses `CanvasLayer` so mission `Node2D` roots don’t clip fullscreen controls.
