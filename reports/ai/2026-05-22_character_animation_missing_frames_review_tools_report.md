# Character Animation Missing Frames + Review Tools Report

**Date:** 2026-05-22
**Goal:** Safely append 7 high-confidence missing Parmida animations to the reviewed map, then add lightweight Manual Mapping QA tools for suspicious/incomplete groups and unassigned frame inspection.

## Files changed

- `resources/character_animation_maps/character__working_manual_map.json` — appended 7 animations only
- `resources/character_animation_maps/character__working_manual_map_before_high_confidence_missing_add_20260606_203856.json` — timestamped backup
- `resources/character_animation_maps/character__working_manual_map_review_todo.json` — review todo artifact
- `addons/character_animation_mapper/CharacterAnimationMapperHelpers.gd` — QA/unassigned frame computation helpers
- `addons/character_animation_mapper/CharacterAnimationManualMappingWindow.gd` — Mapping QA / Review section
- `addons/character_animation_mapper/CharacterAnimationUnassignedFramesViewer.gd` — read-only unassigned ranges pop-out
- `src/tools/editor/CharacterAnimationMapperValidator.gd` — static checks for QA tooling

## Files intentionally left untouched

- `project.godot`
- Production player scenes, Taco scenes, autoloads
- Raw spritesheet PNG
- Runtime player animation assignment
- Existing animation entries (no rewrites/removals)
- JSON schema top-level fields (`schema_version`, grid size, `source_sheet`, etc.)

## Backup map path

`res://resources/character_animation_maps/character__working_manual_map_before_high_confidence_missing_add_20260606_203856.json`

## High-confidence animations added (7)

| Animation | Frames | FPS | Loop | Review status |
|---|---:|---:|---|---|
| `eating_away_right_01` | 501..503 | 6.1 | false | needs_review |
| `sit_away_01` | 513..515 | 6.1 | true | needs_review |
| `death_toward_01` | 744..748 | 8.1 | false | needs_review |
| `death_right_01` | 754..758 | 8.1 | false | needs_review |
| `land_away_left_01` | 935..937 | 12.0 | false | needs_review |
| `punch_away_right_02` | 1013..1015 | 12.1 | false | needs_review |
| `punch_down_toward_right_01` | 1186..1188 | 12.0 | false | needs_review |

All notes include: `auto_added=high_confidence_missing_direction; source=frame_gap_audit; requires_visual_review=true`

**Skipped (already existed):** none

## Map counts

| Metric | Before | After |
|---|---:|---:|
| Animation count | 392 | 399 |
| Covered frames | 1587 | 1609 |
| Unassigned frames | 913 | 891 |

Grid confirmed: **50 × 50**
Source sheet confirmed: Parmida manual 5-pack sheet path

## Updated unassigned frame ranges

After adding the 7 high-confidence entries:

1. `986..991` (6 frames)
2. `1040..1064` (25 frames)
3. `1216..1479` (264 frames)
4. `1544..1583` (40 frames)
5. `1632..1863` (232 frames)
6. `1928..2119` (192 frames)
7. `2144..2271` (128 frames)
8. `2496..2499` (4 frames)

Removed from unassigned by this pass: `501..503`, `513..515`, `744..748`, `754..758`, `935..937`, `1013..1015`, `1186..1188`

## Suspicious visual review items (not auto-added)

1. **crouch_04** — present: toward/right/away_left/left; missing: toward_right/away_right/away/toward_left; frames `968..979`; inspect nearby `986..991`
2. **crouch_05** — present: toward/away_left only; frames `980..985`
3. **idle_11 / idle_12** — variant/naming suspicion around `896..897`, `1128..1167`

## Duplicate frame warnings

1. `896..897` — `idle_toward_11` + `dodge_toward_01`
2. `1904` — `punch_away_right_03` + `kick_toward_01`

## QA / Review UI behavior

Collapsible **Mapping QA / Review** section in Manual Animation Mapping window:

- **Refresh QA From Current Map** — recomputes from dock in-memory animations
- **Previous / Next Review Item** — cycles combined list
- **Focus Review Item** — scrolls grid to item frame range
- **Select Review Frames** — selects frames on grid without mutating map
- **Show Unassigned Frames** — opens read-only viewer
- Read-only: no JSON save, no add/update/delete from QA section
- QA refreshes after Add/Update/Delete in manual window

List includes: known suspicious groups, duplicate warnings, and live unassigned ranges.

## Unassigned frame viewer behavior

`CharacterAnimationUnassignedFramesViewer` pop-out:

- Lists contiguous unassigned ranges with frame count and row/col span
- Shows up to 12 thumbnails per selected range
- **Focus Range** / **Select Range** focus or select on main grid via signal callback
- Recomputed from current in-memory map when opened/refreshed
- Read-only — does not create animations

## Validation results

| Check | Result |
|---|---|
| Git status before/after | Recorded; no commits |
| Backup exists and parses | PASS |
| Updated map parses | PASS |
| Schema unchanged except appended entries | PASS |
| Exactly 7 animations added | PASS |
| No existing entries modified | PASS (0 changed) |
| 7 frame ranges covered correctly | PASS |
| Review todo artifact parses | PASS |
| Unassigned ranges recomputed | PASS |
| Godot LSP diagnostics (3 edited scripts) | PASS (0 issues) |
| Godot MCP Pro `validate_script` | **Not run** — editor offline |
| In-editor manual QA walkthrough | **Not run** — editor offline |

## Kimi K2.6 MCP usage

Not used. Local inspection was sufficient; no ambiguity requiring advisory review.

## Safety confirmation

- Stayed inside repository
- No git commit/push/stage
- No production scene/autoload/`project.godot`/spritesheet edits
- Timestamped backup created before map edit
- Only appended 7 high-confidence animations; no suspicious groups auto-added
- QA tooling is visual-review only

## Known limitations

- QA suspicious items for crouch/idle are static curated entries (not auto-detected incomplete direction sets)
- Unassigned viewer thumbnails capped at 12 frames per range for performance
- Unassigned + duplicate lists recompute from in-memory dock state; disk JSON is not auto-written from QA section
- Godot editor manual test not performed this session

## Suggested next step

1. Open Godot → Character Animation Mapper dock → load Parmida sheet + `character__working_manual_map.json`
2. Open Manual Mapping window → expand **Mapping QA / Review**
3. Visually confirm the 7 `needs_review` additions, then mark reviewed after Save Reviewed Map JSON
4. Walk suspicious items (`crouch_04`, `crouch_05`, idle overlap) using Focus/Select
5. Use **Show Unassigned Frames** to inspect `986..991` and larger gaps before mapping more clips
