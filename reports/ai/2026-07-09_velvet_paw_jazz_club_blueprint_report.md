# Velvet Paw Jazz Club — Level Blueprint Report

**Date:** 2026-07-09  
**Mission ID:** `velvet_paw_jazz_club`  
**Act:** 1 Mission 2 (friend Yordano)  
**Target playtime:** ~30 minutes  

## Deliverables

| File | Purpose |
|------|---------|
| `docs/blueprints/velvet_paw_jazz_club.blueprint.json` | Authoring overlay spec (4480×3200 canvas, 36 regions, 68 mechanic slots) |
| `docs/blueprints/velvet_paw_jazz_club.build_guide.md` | Auto-generated placement checklist for Mission Dock |
| `scenes/dev/mission_authoring/VelvetPawBlueprintProofRoom.tscn` | Dev-only overlay preview scene |

## Story alignment (MISSION_BIBLE + CREATIVE_DIRECTION v2)

- **Premise:** Nightlife blackmail heist — Sterling's encoded setlist hides ledger routing in the performance systems.
- **Social stealth core:** Bar cover, VIP protocol, floor inspection, professionalism meter.
- **Music puzzle:** Dual-clue setlist reorder (album arc + release timeline) → service hatch → backstage.
- **Backstage chain:** Green room → bathroom stash → basement vault → ledger shard.
- **Hostile pivot:** Shard upstairs triggers `velvet_paw_club_hostile`; optional keycard silent route.
- **Owner confrontation:** Suite stairs → briefcase → optional shelf-goblin secret → extraction.
- **Sterling clue:** `jazz_club_encoded_setlist` on setlist success (`connects_to: Rewrite Room`).
- **GameState flags wired in notes:** `velvet_paw_basement_shard_collected`, `velvet_paw_basement_keycard_collected`, `velvet_paw_club_hostile`, `secret_velvet_collectible`.

## Pacing bands (~30 min)

| Phase | Minutes | Blueprint regions |
|-------|---------|-------------------|
| Street / alley approach | 3–4 | `street_alley`, entrance locks |
| Club floor social stealth | 8–10 | `club_floor`, `vip_lounge`, bar/VIP tasks |
| Setlist puzzle + stage | 5–6 | `stage`, `green_room` clues |
| Backstage + basement | 6–8 | `backstage`, `bathroom`, `basement` |
| Hostile + owner suite | 5–7 | `owner_suite`, extraction |

## Mechanic coverage (68 slots, 46 unique types)

Highlights: `SocialStealthZone`, `ProfessionalismMeterNode`, `TerminalHackNode` (setlist), `PowerPuzzleNode`, `PaperTrailNode`, `WitnessNode`, `EncounterSpawnNode`, `ExtractionZone`, side jobs (sound check, poop bag), optional polaroid + heat sink.

## Fixes applied this session

1. Renamed `black_card` → `basement_keycard` with correct GameState flag notes.
2. Updated `setlist_terminal` note for `jazz_club_encoded_setlist` Sterling clue.
3. Updated `ledger_shard` note for basement shard flag vs. encoded-setlist distinction.
4. Added `professionalism_meter`, `hidden_polaroid`, `shelf_goblin_secret`, `heat_sink` slots.
5. Regenerated build guide; validator PASS.

## How to use

1. Open your Velvet Paw iso mission scene (or `VelvetPawBlueprintProofRoom.tscn` for preview).
2. Add `AuthoringBlueprintLayer` under `GameplayRoot/LayoutRoot` at `(0,0)`.
3. Set `blueprint_path` = `res://docs/blueprints/velvet_paw_jazz_club.blueprint.json`.
4. In Mission Dock → **Place From Blueprint** → Refresh slots → place mechanics in order.
5. Use `velvet_paw_jazz_club.build_guide.md` as the step-by-step checklist.
6. Overlay self-strips at runtime via `Phase0JRuntimeAuthoringHider`.

## Validation

- `level_blueprint_validator.py` — **PASS** (no failures/warnings)
- Build guide regenerated successfully

## Risks / follow-ups

- Legacy `JazzClubMission.tscn` is LevelBase, not iso — this blueprint targets the plug-and-play iso authoring path.
- Polaroid beats use `SideObjectiveNode` + `SearchZone` placeholders; wire to hideout gallery IDs when scene is built.
- Jake should toggle Mission Dock plugin if Place From Blueprint UI is stale after reload.

## Grouped-milestone mode

N/A — authoring-data deliverable only; no runtime code changes.
