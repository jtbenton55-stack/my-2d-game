# 0M-D5-02A — Phase 6: D5-02B HUD readiness

## Goal

Add **objective ticker**, **stamina bar**, **poop bag count**, optional **one-line control hint**, without reviving corner debug clutter.

## Items

### 1. Objective ticker

- **Owner:** `src/ui/HUD.gd` + `res://scenes/ui/hud.tscn`
- **Data:** `QuestManager` / `EventBus.objective_updated` (existing HUD hooks)
- **Visibility:** Always on during missions; **max width** + ellipsis or scroll **single line** only
- **Pause:** Detailed list stays in `pause_menu.gd` (already scrollable)
- **Avoid:** `IsoMissionBase`, `Player.gd`, Taco scenes for text only — prefer HUD + EventBus

### 2. Stamina bar

- **Owner:** HUD (thin `ProgressBar` near health)
- **Data:** Read-only from `GameState` or small bridge — **do not** duplicate stamina logic in HUD; prefer signal from player stack **without** editing `Player.gd` if possible (e.g. `EventBus` emission from `PlayerStaminaController` is forbidden to edit — use existing `EventBus` patterns or minimal new autoload-free HUD poll documented in D5-02B)
- **Risk:** If no signal exists, D5-02B may add **one** thin seam — document first.

### 3. Poop bag count

- **Owner:** HUD small label (`x3` style)
- **Data:** `GameState.poop_bag_count` / inventory dict (read-only from HUD `_process` or signal if present)

### 4. Compact control hint

- **Owner:** Either HUD one line **or** keep `ControlsOverlay` minimized — **not** both verbose
- **Scroll:** N/A for one line

### 5. Debug toggle interaction

- **F9/F10** Iso panel; **F11** sprint overlay; **F1** controls — document in `docs/` or `README` snippet for D5-02B branch
- **No new `project.godot` actions** unless unavoidable

## Acceptance (D5-02B)

- No new always-on `CanvasLayer` debug in corners.
- HUD additions use layout containers + `custom_minimum_size` caps.
- Pause remains scroll-safe.

## Files to avoid

`Player.gd`, `PlayerStaminaController.gd`, `IsoMissionBase.gd`, Taco/Hideout scenes, `project.godot` (unless HUD scene path requires export only — prefer not).
