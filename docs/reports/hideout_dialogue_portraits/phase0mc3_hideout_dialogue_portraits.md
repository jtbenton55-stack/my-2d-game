# Phase 0M-C3 — Hideout Portrait Sheet Slicing + Birthday Dialogue Polish

**Status: PASS**

This pass adds left-side portraits to the existing dialogue UI, slices the
top-level portrait sheets in `res://assets/portraits/` into individual
usable assets, ships funny / clever / heartfelt birthday dialogue for the
four anchor characters, and wires the dialogue safely into the existing
hideout interactions. No Taco Bell scenes, gameplay scripts, collision,
store/decor systems, or source portrait sheets were modified.

## Audit summary

| Concern | Path |
|---|---|
| Dialogue manager | `res://src/autoload/DialogueManager.gd` |
| Dialogue UI scene | `res://scenes/ui/DialogueBox.tscn` |
| Dialogue UI script | `res://src/ui/DialogueBox.gd` |
| Portrait registry | `res://src/dialogue/DialoguePortraitRegistry.gd` |
| Portrait registry data | `res://data/dialogue/dialogue_portraits.json` |
| Character dialogue bank | `res://src/dialogue/HideoutCharacterDialogueBank.gd` |
| Hideout entry point | `res://src/hideout/HideoutManager.gd` |
| Legacy hideout level | `res://src/levels/Hideout.gd` |
| Existing hideout dialogue bank | `res://src/hideout/HideoutDialogueBank.gd` |

## Portrait pipeline

- **Source folder:** `res://assets/portraits/` (5 top-level sheets).
- **Slice output:** `res://assets/portraits/generated_slices/` — 40 cropped
  PNGs at 364x408 each, plus the `portrait_bentley_placeholder.png` and
  `portrait_fallback_silhouette.png` cards (42 PNGs total).
- **AtlasTextures:** `res://assets/portraits/generated_slices/atlas_textures/`
  — 40 `.tres` files referencing the original sheets via `region` rectangles.
- **Contact sheet:** `res://docs/reports/hideout_dialogue_portraits/portrait_slices_contact_sheet.png`.
  Marked clearly as "Generated review sheet only — do not use this contact
  sheet as source art."

All five top-level sheets are `1456 x 816`, sliced as the canonical
`4 columns x 2 rows` layout. The "Don't like" subfolder is intentionally
skipped. The original PNG sheets were not modified.

## Character portrait assignments

| Speaker | Portrait | Notes |
|---|---|---|
| Jake | `portrait_..._069c08a9-..._eff15256_r0_c2` | Brown-haired suited guy with stubble — tired but heroic. |
| Parmida | `portrait_..._069c08a9-..._54c76689_r0_c1` | Hooded woman with kind pink eyes, soft strength. |
| Mere | (same as Parmida) | Mere and Parmida deliberately share the portrait. |
| Bentley | `portrait_bentley_placeholder.png` | No dog portrait exists in the source pack. Placeholder card generated; documented as known limitation. |
| Louis | `portrait_..._069c08a9-..._eff15256_r1_c0` | Bald guy with shades and a dapper jacket — delivery driver swagger. |
| Fallback | `portrait_fallback_silhouette.png` | Used by the registry whenever a `speaker_id` does not resolve. |

`DialoguePortraitRegistry.has_portrait(speaker_id)` returns true for all
six keys above. Both `parmida` and `mere` resolve to the exact same
texture, satisfying the dual-key requirement.

## Dialogue UI changes

`DialogueBox.tscn` now contains:

- a `PanelContainer` (cyber-noir frame with a soft neon-blue border)
  named `PortraitContainer`, fixed at `176 x 196`, on the **left** of the
  HBox,
- a `TextureRect` named `PortraitRect` inside that frame
  (`expand_mode = 1`, `stretch_mode = 5`) so portraits keep their aspect
  ratio,
- the existing `ContentContainer` on the right with `SpeakerLabel`,
  `TextLabel` (autowrap), `ChoicesContainer`, and `NextIndicator`.

The scene UID `dialoguebox_v2` is preserved so every `preload("res://scenes/ui/DialogueBox.tscn")` callsite continues to work.

`DialogueBox.gd`:

- listens to a new signal `EventBus.dialogue_line_changed_full(speaker, text, portrait_id, line_data)` that carries the portrait id,
- still listens to the legacy `dialogue_line_changed(speaker, text)` so
  callers that pass plain strings (no portrait_id) keep working,
- resolves the portrait through `DialoguePortraitRegistry.get_portrait_texture(...)`,
- hides the portrait frame entirely if no texture is available (so legacy
  dialogue without portraits looks the same as before).

## Dialogue content

Line counts (target: 12 each, achieved: 15 each):

- Jake — 15 lines (motifs hit: tired resident, forgetfulness, poop bags,
  sweet tooth, adoration of Parmida, safety worry, birthday surprise).
- Parmida / Mere — 15 lines (motifs hit: kindness, gentle teasing,
  noticing Jake's effort, love for Bentley, birthday warmth, soft
  strength).
- Bentley — 15 lines (motifs hit: bark translation, self-importance,
  loyalty to Mom/Parmida, suspicion of Louis, snack motivation, paw-
  related drama, judging Jake on poop bags).
- Louis — 15 lines (motifs hit: delivery wisdom, Taco Bell comic relief,
  absurd confidence, fear/respect of Bentley, sauce, route shenanigans).

The bank exposes `get_random_line(speaker_id)` and `build_short_sequence(speaker_id, count)` so the production hideout grabs a fresh
3-line burst every interaction.

## Hideout wiring

`HideoutManager.open_station(station_id, ...)` now intercepts
`jake`, `mere`, `parmida`, `bentley`, and `louis` and routes them to
`DialogueManager.start_simple_dialogue([{speaker, text, portrait_id}, ...])`. All other station ids go through the legacy
`ScrollableStationPanel` flow exactly as before.

`Hideout.gd._show_crew_dialogue(crew_id)` (legacy `Hideout.tscn` level)
prefers the new bank for the four anchors and falls back to the legacy
crew dialogue for everyone else (Dom, Yordano, etc).

Louis's gating is preserved — his interactable is still hidden until the
state controller flips to `louis_unlocked`. We changed only the body
of his dialogue, not the gating logic.

## Files created

- `src/dialogue/DialoguePortraitRegistry.gd`
- `src/dialogue/HideoutCharacterDialogueBank.gd`
- `src/tools/editor/hideout_dialogue_portrait_builder.py`
- `src/tools/editor/hideout_dialogue_portrait_static_validator.py`
- `src/tools/editor/HideoutDialoguePortraitTestRunner.gd`
- `src/tools/editor/HideoutDialoguePortraitValidator.gd`
- `scenes/hideout/tools/HideoutDialoguePortraitTest.tscn`
- `data/dialogue/dialogue_portraits.json`
- `assets/portraits/generated_slices/portrait_*.png` (40 sliced + 2 placeholders)
- `assets/portraits/generated_slices/atlas_textures/portrait_*.tres` (40 AtlasTextures)
- `docs/reports/hideout_dialogue_portraits/phase0mc3_dialogue_system_audit.{md,json}`
- `docs/reports/hideout_dialogue_portraits/phase0mc3_portrait_sheet_scan.{md,json}`
- `docs/reports/hideout_dialogue_portraits/phase0mc3_portrait_slice_catalog.{md,json,csv}`
- `docs/reports/hideout_dialogue_portraits/phase0mc3_portrait_assignment_report.{md,json}`
- `docs/reports/hideout_dialogue_portraits/portrait_slices_contact_sheet.png`
- `docs/reports/hideout_dialogue_portraits/phase0mc3_static_validator.json`
- `docs/reports/hideout_dialogue_portraits/phase0mc3_hideout_dialogue_portraits.{md,json}`

## Files modified

- `src/utils/EventBus.gd` — added `dialogue_line_changed_full` signal.
- `src/autoload/DialogueManager.gd` — emits the new signal alongside
  the legacy one.
- `src/ui/DialogueBox.gd` — listens to the new signal, resolves and
  applies the portrait.
- `scenes/ui/DialogueBox.tscn` — replaced the `ColorRect` placeholder
  with a real `TextureRect` portrait inside a small neon-trimmed
  panel container; preserved the scene UID.
- `src/hideout/HideoutManager.gd` — routes character station ids to
  the portrait dialogue path.
- `src/levels/Hideout.gd` — uses the new bank for anchor crew.

## Backups created

- `scenes/hideout/HideoutHub.phase0mc3_portrait_dialogue_backup.20260509_065454.tscn`
- `scenes/ui/DialogueBox.phase0mc3_portrait_dialogue_backup.20260509_065454.tscn`

## Risks / limitations

1. **Bentley still uses a placeholder portrait card.** No dog art exists
   in the source pack. The placeholder is clearly labeled. A future
   pass should replace it with real Shiba art (or one of the B9 dog
   icons if a suitable one is curated).
2. **Legacy dialogue tests** that listen only to
   `dialogue_line_changed(speaker, text)` are still supported and
   unchanged. Anything that wants portraits should subscribe to the
   new `dialogue_line_changed_full` signal.
3. The Godot CLI is unavailable in this environment, so the editor-side
   `HideoutDialoguePortraitValidator.gd` was not auto-run. The static
   Python validator at
   `src/tools/editor/hideout_dialogue_portrait_static_validator.py`
   ran successfully (60/60 checks pass) and the `.gd` validator is
   ready for the next time the editor is opened.
4. The portrait registry caches Texture2D resources after first load.
   This is intentional; if you swap a portrait png on disk, restart
   the dialogue or call the registry again to force a fresh load.

## Manual test checklist

1. Open `res://docs/reports/hideout_dialogue_portraits/portrait_slices_contact_sheet.png` and confirm slices look correct.
2. Open `res://scenes/hideout/HideoutHub.tscn` in the editor.
3. Run the scene.
4. Walk to **Jake** and press E. Confirm the new dialogue panel shows
   Jake's portrait on the left, his name, and at least one tired-resident /
   poop-bag / sweet-tooth / Parmida-loving line.
5. Press E to advance through Jake's 3-line short sequence.
6. Walk to **Mere/Parmida** and press E. Confirm her portrait, and a
   kind, intelligent, birthday-warm line.
7. Walk to **Bentley** and press E. Confirm Bentley's placeholder
   portrait card and a dramatic loyal-Shiba line.
8. Use the debug state controller to switch to `louis_unlocked`,
   walk to **Louis** and press E. Confirm Louis's portrait and a
   delivery-comedy line.
9. Confirm the portrait does not overlap text and no line overflows
   off the panel.
10. Confirm pressing E with the dialogue closed does NOT trigger the
    dialogue.
11. Open the **Mission Board** station and confirm the legacy panel UI
    still works (no portrait, no behavior change).
12. Launch a Taco Bell mission from the mission board.
13. Pause and exit; confirm you return to the HideoutHub.
14. Confirm the 18 stations still show prompts and open their panels
    (Polaroid Wall, Glow Guy Shelf, Tiny Icon Shelf, Care Station,
    Greenhouse Alcove, Open Decor Zone, Loot Crate Drop Zone,
    Evidence Board, Planning Table, Store Terminal, Poop Bag Display,
    Heat Scanner, etc).
15. Confirm Taco Bell scene files were not modified (mtime predates
    this pass).
16. Optional: open `res://scenes/hideout/tools/HideoutDialoguePortraitTest.tscn` and click each button to dry-run the portrait
    UI without the full hideout.

## Recommended next step

The biggest visible gap is **Bentley** — replace the placeholder card with
real Shiba art (or curate one of the B9 dog icons). The dialogue and
registry are already wired; only the PNG path under
`portraits.bentley.png_path` needs to point at the new file.
