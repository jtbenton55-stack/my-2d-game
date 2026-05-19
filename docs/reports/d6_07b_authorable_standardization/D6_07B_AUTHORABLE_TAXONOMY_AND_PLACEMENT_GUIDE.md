# D6-07B Authorable Taxonomy and Placement Guide

## Current supported authorables

- `poop_bag`
- `polaroid`
- `tiny_icon`
- `glow_guy`
- `clue` / `evidence_clue`
- `case_cash`

## Currency rule

- Forward-looking mission currency authoring is **Case Cash only**.
- `MoneyPickupAuthor` is a **legacy compatibility alias** that emits `case_cash`.
- Use `CaseCashAuthor` for new placements.

## One-shot vs countable

- **Unique one-shot unlocks (must use unique IDs):**
  - `polaroid`
  - `tiny_icon`
  - `glow_guy`
  - `clue`
- **Countable/amount-based (still require unique placement IDs):**
  - `poop_bag`
  - `case_cash`

## Multi-instance placement rules

- You can place multiple instances of the same type in one level.
- Every instance must have a stable unique `collectible_id` (and type-specific ID if exposed).
- Do not leave placeholder IDs (`CHANGE_ME_UNIQUE_ID`, `TODO_ID`, empty IDs).
- Duplicate IDs are blocked by runtime builder (later duplicate skipped) and flagged by static validator.

## Safe duplicate/copy workflow

1. Duplicate an author node or instantiate a template scene.
2. Immediately update:
   - `collectible_id`
   - type-specific id (`clue_id`, `glow_guy_id`, etc.)
   - amount/title/text where relevant
3. Run static validator before playtesting.
4. Verify in F10 debug that pending/author counts match expectation.

## Drag/drop templates

Available templates in `scenes/missions_iso/authoring_templates/`:

- `PoopBagAuthorTemplate.tscn`
- `CaseCashAuthorTemplate.tscn`
- `ClueAuthorTemplate.tscn`
- `GlowGuyAuthorTemplate.tscn`

These are starter nodes with placeholder IDs and must be edited before runtime use.

## Planned future categories (not implemented in D6-07B)

1. Objective authorables (bag/key/code/document/tool/handoff items)
2. Route/assist authorables (route unlocks, assist triggers, hint markers)
3. Interactable prop authorables (drawers/lockers/registers/computers/keypads)
4. Inspectable authorables (lore/readables/flavor objects)

## What not to do

- Do not create a second mission currency path.
- Do not use random runtime-generated IDs for persistent pickups.
- Do not ship scenes with placeholder IDs.
- Do not rely on duplicate IDs for multiple instances.
