# Phase 4 — Implementation

- `HUD.gd`: mission compact refresh, `EventBus.game_state_changed`, objective sanitization, optional control hint export.
- `hud.tscn`: `MissionHudStrip` (VBox) with stamina caption, bar, poop label, control hint; `ObjectiveLabel` anchors widened with margins + wrap/clip.
