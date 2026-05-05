# Taco Bell Iso QA Baseline Notes

This pass keeps `scenes/missions_iso/TacoBellIso_Editable.tscn` as the playable baseline in `hybrid` authoring mode.

## Debug Controls

- `F10`: toggle compact mission HUD.
- `F9`: toggle debug details panel.

Compact HUD fields:

- heat / attempts
- garage code
- tiny icons / glow guys / polaroids / clues / poop bags
- alert / alarms / wrong code / guards / cameras

## Dialogue Editing

Taco Bell mission dialogue entries now live in:

- `assets/dialogue/taco_bell_dialogue.json`

Each entry includes:

- `dialogue_id`
- `speaker`
- `text`
- `trigger`
- `mission_step`
- optional `tags`
- optional `notes`

To edit dialogue, update the `text` value for the desired `dialogue_id`, then run the mission scene again.

## Route / Code Gate Notes

- Code gate wrong-code thresholds are heat-aware (`2` at base, stricter at high heat).
- The code gate now has a physical runtime blocker that opens on correct code.
- Route return transitions with `route_*` ids auto-trigger on entry.
