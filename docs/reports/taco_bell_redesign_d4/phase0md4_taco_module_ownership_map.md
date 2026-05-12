# 0M-D4 — Taco Bell module ownership map

This map ties **mission fantasy** to **actual files** discovered in the repo. D5 should implement new behavior only by extending the **owner** column — not by growing unrelated singletons.

## Principles

1. **Framework owns repetition** (routing, pause payload shape, attempt counter dictionary, bridges).
2. **Taco owns flavor and layout-specific routing** (Louis lines, bypass IDs, which alarm attaches to which room).
3. **Player owns input**; **IsoMissionBase** owns tool-surface reactions for iso missions unless a thinner `MissionRuntimeContext` is introduced later.

## Table

Full machine-readable rows: `phase0md4_taco_module_ownership_map.json`.

### Critical seam (D5 priority)

| Problem | Owners involved | D5 direction |
| --- | --- | --- |
| Objective text desync | `IsoMissionBase`, `Phase0KMissionCompletionController`, `QuestManager`, `MissionObjectiveBridge` | Pick **one writer** for player-facing primary objective transitions; others subscribe. |
| Louis bypass not gameplay-complete | `Phase0JMechanicRouter`, scene markers | Add **small Taco adapter** that listens to route access Area2D and sets runtime flags / disables beam penalty path — do not stuff into Player. |

## Anti-patterns (explicit)

- Pause menu → direct `Phase0K` node path lookup: **forbidden**; use `MissionPauseDataProvider` + optional `mission_node` context parameter if needed.
- `GameState` fields for per-attempt beam fired: **forbidden**; use `_attempt_runtime_state` or dedicated runtime node group.

Assertions: map created; no unowned major mechanic from audit set; boundary clear.
