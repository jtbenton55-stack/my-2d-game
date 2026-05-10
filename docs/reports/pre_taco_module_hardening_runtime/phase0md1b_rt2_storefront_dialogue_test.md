# 0M-D1B-RT2 — C1 storefront + C3 portrait dialogue (Phase 9)

## Runtime

Not executed in the surviving GRB window after the pause-tree experiment ended the session early.

## Code paths (for manual follow-up)

`HideoutManager.open_station` routes:

- `store_terminal` → storefront panel (`_open_storefront`)
- Character IDs `jake`, `mere`, `parmida`, `bentley`, `louis` → portrait `DialogueBox` flow (`_open_character_portrait_dialogue`)

No changes were required in those systems for RT2.
