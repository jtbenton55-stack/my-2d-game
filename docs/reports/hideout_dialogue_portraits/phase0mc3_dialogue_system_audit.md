# Phase 0M-C3 — Hideout Dialogue System Audit

This audit was performed before any code changes were made. It captures the
state of the dialogue and character interaction systems so the portrait pass
can be wired in without breakage.

## Existing dialogue plumbing

| Concern | Path |
|---|---|
| Dialogue manager (autoload) | `res://src/autoload/DialogueManager.gd` |
| Dialogue UI scene | `res://scenes/ui/DialogueBox.tscn` |
| Dialogue UI script | `res://src/ui/DialogueBox.gd` |
| Dialogue resource type | `res://src/dialogue/DialogueResource.gd` |
| Branching dialogue trigger | `res://src/dialogue/branching_dialogue_trigger.gd` |
| Hideout dialogue bank (existing) | `res://src/hideout/HideoutDialogueBank.gd` |
| Hideout character controller | `res://src/hideout/HideoutCharacterController.gd` |
| Hideout interactable script | `res://src/hideout/HideoutInteractable.gd` |
| Legacy hideout level script | `res://src/levels/Hideout.gd` |
| Event bus | `res://src/utils/EventBus.gd` |

## Trigger paths

The hideout has two ways to talk to characters today.

1. **Production hideout (`scenes/hideout/HideoutHub.tscn`)** —
   `HideoutManager._build_stations()` reads `HideoutStationCatalog.STATIONS`
   and creates `HideoutInteractable` Area2D children for each station,
   including the four character stations `jake`, `mere`, `bentley`, and
   `louis`. When the player presses E, the interactable calls
   `HideoutManager.open_station(station_id, …)`, which currently routes
   character interactions through the `ScrollableStationPanel` UI via
   `HideoutCharacterController.get_panel_data()` /
   `dialogue_for(character_id)`.

2. **Legacy hideout level (`scenes/levels/Hideout.tscn`)** —
   `Hideout.gd._show_crew_dialogue(crew_id)` calls
   `DialogueManager.start_simple_dialogue([{speaker, text}, …])`. Crew nodes
   are `CrewMere`, `CrewJake`, `CrewLouis`, `CrewDom`, `CrewYordano`, and
   `Bentley`.

## Dialogue payload shape

`DialogueManager.start_simple_dialogue(lines: Array)` accepts either:

- `Array[Dictionary]` of `{ "speaker": String, "text": String, ... }`, or
- `Array[String]` (treated as anonymous lines).

It emits two signals through `EventBus`:

- `dialogue_started(lines)` — once when a sequence begins.
- `dialogue_line_changed(speaker, text)` — every advance.
- `dialogue_ended` — once when the sequence finishes.

`DialogueBox.gd` only reads `speaker` and `text`. There is **no portrait
support today**: the existing scene has a `PortraitContainer/PortraitRect`
that is just a `ColorRect` placeholder.

## Character interactables that exist today

| Anchor | Production hideout | Legacy level |
|---|---|---|
| Jake | `Stations/Jake` (HideoutInteractable, station_id=`jake`) | `CrewJake` Node2D with meta `interaction=jake` |
| Parmida / Mere | `Stations/Mere` (station_id=`mere`) | `CrewMere` Node2D with meta `interaction=mere` |
| Bentley | `Stations/Bentley` (station_id=`bentley`) | dedicated `Bentley` node |
| Louis | `Stations/Louis` (station_id=`louis`, hidden until `louis_unlocked`) | `CrewLouis` Node2D, meta `interaction=louis` |

There is **no Parmida-named interactable** — the project uses `mere` as the
station id for the same character. The portrait registry must therefore
support both `parmida` and `mere`, mapping to the same image.

## Risks identified

1. Replacing `DialogueBox.tscn` wholesale is risky because `LevelBase`,
   `Hideout.gd`, and `CityHub.gd` all instance it via `preload("res://scenes/ui/DialogueBox.tscn")`. Solution: keep the same UID and root
   node name, only edit the inside of the panel.
2. Some callers pass plain strings via `start_simple_dialogue(["Hi"])`.
   The new portrait code must tolerate empty / missing portrait_id fields.
3. Existing `dialogue_line_changed(speaker, text)` listeners must keep
   working. We added a parallel signal `dialogue_line_changed_full` with
   the portrait_id rather than changing the original signature.
4. Louis is hidden until `louis_unlocked` in the production hideout.
   Wiring his dialogue must not bypass that gating. Solution: route
   through `HideoutManager.open_station(...)` exactly as before — the
   gating already happens at the interactable layer.

## Conclusion

The system is healthy and self-contained. The portrait pass is implemented
by:

- emitting an additional signal carrying `portrait_id` from
  `DialogueManager`,
- reading that signal in `DialogueBox.gd` and showing a `TextureRect`
  resolved through `DialoguePortraitRegistry`,
- adding `HideoutCharacterDialogueBank` with 12+ funny/clever/heartfelt
  lines per anchor character,
- having `HideoutManager.open_station()` route character station ids to
  `DialogueManager.start_simple_dialogue(...)` with portrait-tagged lines,
- updating `Hideout.gd._show_crew_dialogue()` to prefer the new bank when
  the speaker matches one of the four anchors.

No Taco Bell scenes are touched. No gameplay scripts are rewritten. The
station catalog and 18-station scaffolding are untouched.
