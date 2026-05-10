# 0M-D1B-RT2 — Runtime smoke test (Phase 12)

## Verdict: **PARTIAL**

GRB was **recovered and used** for real in-engine checks (scene loads, node queries, programmatic scene changes). The full interactive checklist from the phase brief was **not** completed because synthetic input did not move the player and pausing the tree dropped the bridge.

## What passed (automation)

- Godot **4.6.2-stable** runtime via MCP `grb_launch` / `grb_reset` (**tier 2**)
- **HideoutHub** loaded
- **MissionBoard** panel opened (`MissionBoardPanel.visible == true`)
- **Canonical** `TacoBellIso_Editable.tscn` loaded; **Player** node present in scene tree
- **Static** D1B + RT + RT2 validators — **PASS**
- **Routing fix:** hideout catalog + mission board controller now launch **canonical** Taco (constants updated)

## What failed or was not completed

- **Player movement** — not observed (position/velocity unchanged after GRB input)
- **Pause menu + tabs** — live test stalled MCP (`get_tree().paused`)
- **Poop/tool, beam, reset, exit, C1, C3** — not playtested in this session

## Next pass

Manual playtest with normal input, or GRB configuration that avoids full-tree pause during MCP control.
