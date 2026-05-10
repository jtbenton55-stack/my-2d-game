# Phase 0M-C2A-FIX2 — Resource inventory

Inventory covers pre-FIX2 / FIX1 outputs, FIX2 rebuilt outputs, the sandbox scene pair, and key prior C2A reports.

## Sandbox primary (FIX2)

- `res://assets/characters/generated_player_visuals/c2a_animation/fix2_rebuilt/parmida_player_spriteframes_0mc2a_fix2.tres`
- Atlas: `res://assets/characters/generated_player_visuals/c2a_animation/fix2_rebuilt/parmida_player_composite_sheet_0mc2a_fix2.png`

## Legacy / diagnostic (not sandbox primary)

| Resource | Role |
|----------|------|
| `parmida_player_composite_sheet_0mc2a.png` | Older composite used by FIX1 atlas |
| `parmida_player_spriteframes_0mc2a.tres` | Original invalid Godot 4 text layout |
| `parmida_player_spriteframes_0mc2a_fix1.tres` | FIX1 valid format; **glitchy** playback |
| `parmida_player_animation_metadata.json` | Earlier compositor metadata |

## FIX2 rebuild folder

- `fix2_rebuilt/frames/idle_000.png` … `idle_009.png` (10 frames, **100×200** each)
- No `walk_*.png` when walk is rejected (stale walk files removed on pipeline re-run)
- `parmida_player_animation_metadata_0mc2a_fix2.json`

## Reports and tooling

- Prior: `phase0mc2a_spriteframes_report.md`, `phase0mc2a_layer_alignment_matrix.md`, other `phase0mc2a_*.md` in this folder
- FIX2: `phase0mc2a_fix2_*` (this inventory, diagnosis, contact sheets, validation, final repair summary)

## SpriteFrames static notes

- **FIX1:** Godot 4–style top-level `animations = [ ... ]`; animations `idle`, `walk`; atlas regions tied to **legacy** composite semantics → **WRONG_ROW_SELECTED** class symptoms in sandbox.
- **FIX2:** Same serialization pattern; **idle only** in current export; `Rect2(n*100, 0, 100, 200)` for n = 0..9 on composite width **1000**, height **200**.

Machine-readable rows: `phase0mc2a_fix2_resource_inventory.json`.
