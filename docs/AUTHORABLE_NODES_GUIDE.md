# Authorable Nodes Guide

This guide explains how to place and configure mission authorable nodes in the Godot editor.

For security beams, cameras, guard spawns, patrol routes, and area triggers, see [SECURITY_AUTHORABLES_GUIDE.md](SECURITY_AUTHORABLES_GUIDE.md).

Authorables are hand-placed editor nodes that the mission runtime converts into working Phase0J-style interactables. They are meant to make future isometric/2.5D missions authorable by dragging nodes into a scene instead of writing a one-off script for every pickup.

## Current Authorables

Supported now:

- `PoopBagAuthor`: countable poop bag collectible.
- `CaseCashAuthor`: mission currency that commits to HideoutHub Case Cash on mission success.
- `PolaroidAuthor`: one-shot polaroid shelf unlock.
- `TinyIconAuthor`: one-shot tiny icon unlock.
- `GlowGuyAuthor`: one-shot Glow Guy shelf unlock.
- `ClueAuthor`: one-shot clue/evidence corkboard unlock.

Legacy compatibility:

- `MoneyPickupAuthor` is deprecated. It now acts as a compatibility alias for Case Cash. Use `CaseCashAuthor` for all new mission currency placements.

## Templates

Starter templates live here:

```text
scenes/missions_iso/authoring_templates/
```

Available templates:

- `PoopBagAuthorTemplate.tscn`
- `CaseCashAuthorTemplate.tscn`
- `ClueAuthorTemplate.tscn`
- `GlowGuyAuthorTemplate.tscn`

These are drag/drop starter scenes. They intentionally use placeholder IDs. After placing one, change its IDs before running the scene.

## How To Place An Authorable

1. Open the mission scene in Godot.
2. Drag a template scene from `scenes/missions_iso/authoring_templates/` into the mission's authoring/proof area.
3. Move the node to the desired pickup/interact position.
4. Rename the node clearly, such as `PoopBagBackHall01` or `CaseCashRegister01`.
5. Set a unique `collectible_id`.
6. Set any type-specific ID fields, such as `clue_id` or `glow_guy_id`.
7. Set display text, amount, and hideout fields where relevant.
8. Run the static validator before playtesting.
9. Play the scene and verify F10 pending counts/logs.

## Copying And Multiple Instances

You can place multiple authorables of the same type in one level.

Safe duplication workflow:

1. Duplicate an existing authorable node or drag a fresh template.
2. Move it to the new location.
3. Immediately change all ID fields.
4. For Case Cash, set a positive amount.
5. Run the D6-07B validator.

Do not copy a node and leave the same IDs. Duplicate IDs are blocked/skipped at runtime and flagged by the validator because they can break persistence or replay behavior.

## ID Rules

Every placed authorable needs a stable unique ID.

Required ID fields:

- All authorables: `collectible_id`
- `PolaroidAuthor`: `polaroid_id`
- `TinyIconAuthor`: `icon_id`
- `GlowGuyAuthor`: `glow_guy_id`
- `ClueAuthor`: `clue_id`
- `CaseCashAuthor`: `collectible_id` plus a positive `case_cash_amount`

Use readable, mission-scoped IDs:

```text
taco_poop_back_hall_01
taco_case_cash_register_01
taco_clue_sauce_packet
taco_glow_guy_freezer_01
```

Avoid:

- Empty IDs.
- `CHANGE_ME_UNIQUE_ID`.
- `TODO_ID`.
- Reusing the same ID for different placements.
- Random runtime-generated IDs for persistent pickups.

## One-Shot Vs Countable

Unique one-shot unlocks:

- `polaroid`
- `tiny_icon`
- `glow_guy`
- `clue`

These unlock a specific hideout display or persistent flag. Each unique item should have its own unique ID.

Countable or amount-based authorables:

- `poop_bag`
- `case_cash`

These can be placed multiple times and can add counts/amounts, but each placed instance still needs a unique ID for replay/idempotency.

## Case Cash Rules

Use `CaseCashAuthor` for mission currency.

Important fields:

- `collectible_id`: unique placement ID.
- `case_cash_amount`: amount added on successful mission completion.
- `display_name`: optional label shown in debug/interact context.

Case Cash is pending during the mission and commits only on mission success. Failure/restart should not add funds. Replay should not double-grant one-shot Case Cash pickups unless a future authorable explicitly supports repeatable grants.

Do not use `MoneyPickupAuthor` for new work. It remains only so old scene nodes keep working as Case Cash aliases.

## Clue Rules

Use `ClueAuthor` for evidence/corkboard entries.

Important fields:

- `collectible_id`: unique placement ID.
- `clue_id`: stable clue/corkboard ID.
- `clue_title`: readable title.
- `clue_text`: optional clue body.
- `case_id`: case grouping if the clue system uses it.
- `hideout_collection_key`: optional explicit hideout flag/key.

Clues should appear in F10 as pending during the mission and commit to the clue/corkboard state after mission success.

## Glow Guy Rules

Use `GlowGuyAuthor` for Glow Guy shelf unlocks.

Important fields:

- `collectible_id`: unique placement ID.
- `glow_guy_id`: stable Glow Guy ID.
- `hideout_collection_key`: optional explicit shelf/display key.

Glow Guys should appear in F10 as pending during the mission and commit to the Glow Guy shelf state after mission success.

## Poop Bag Rules

Use `PoopBagAuthor` for poop bag pickups.

Important fields:

- `collectible_id`: unique placement ID.
- `poop_count`: usually `1`, but can be higher if intentionally authored.

Multiple poop bags are supported. Give each one a unique ID.

## Polaroid And Tiny Icon Rules

Use `PolaroidAuthor` and `TinyIconAuthor` for one-shot display unlocks.

Important fields:

- `PolaroidAuthor.collectible_id` and `polaroid_id`.
- `TinyIconAuthor.collectible_id` and `icon_id`.
- Optional display/title fields where exposed.

These should be unique per display unlock.

## Validation

Run the D6-07B validator after placing or duplicating authorables:

```powershell
python src/tools/editor/d6_07b_authorable_standardization/phase0md6_07b_static_validator.py
```

The validator checks for:

- Missing IDs.
- Duplicate IDs.
- Placeholder IDs like `CHANGE_ME_UNIQUE_ID` or `TODO_ID`.
- Invalid Case Cash amounts.
- Deprecated/forward-looking money usage.
- Expected template/proof authorable coverage.

If the validator fails, fix the scene data before playtesting.

## Runtime Test Checklist

After adding authorables:

1. Run the mission scene.
2. Collect each new authorable with normal player interaction.
3. Open F10 and confirm pending counts/amounts update.
4. Complete the mission through the normal completion path.
5. Return to HideoutHub.
6. Confirm displays/funds update where relevant.
7. Replay the mission if needed and confirm one-shot items do not duplicate.
8. Test failure/restart when relevant and confirm pending items do not commit.

## What Not To Do

- Do not leave placeholder IDs in a mission scene.
- Do not duplicate a node without changing IDs.
- Do not use `MoneyPickupAuthor` for new placements.
- Do not create a second currency/wallet system.
- Do not create a parallel clue database or Glow Guy manager.
- Do not rely on random IDs generated at runtime.
- Do not use duplicated one-shot IDs to represent multiple pickups.

## Future Authorable Categories

Planned next categories are not standardized yet:

- Objective authorables: bag, key, code, document, tool, stolen object, handoff item.
- Route/assist authorables: Louis secret route, Bentley vent route, alternate route unlocks, assist triggers, route hints.
- Interactable prop authorables: drawers, shelves, lockers, registers, computers, doors, buttons, keypads.
- Inspectable authorables: flavor objects, lore objects, readable notes, environmental clues, optional inspect prompts.

Use the current collectible authorables as the pattern: stable IDs, validator coverage, generated-runtime interactables, F10 visibility, success-only commit where appropriate, and no duplicate systems.
