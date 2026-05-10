# Dialogue boundary (0M-D1B)

`IsoMissionBase.gd` no longer preloads `TacoBellDialogue.gd`. Dialogue for scheme-card completion lines resolves through:

- `MissionDialogueProvider` (fallback-only default)
- `TacoBellDialogueProvider` (wraps existing `TacoBellDialogue.line` JSON) when `mission_id` contains `taco`

`DialogueManager` / `DialogueBox` unchanged.

Placeholder/runtime scripts under `src/missions/iso/**` may still preload `TacoBellDialogue` for now; they are mission-runtime scripts, not the generic iso base.
