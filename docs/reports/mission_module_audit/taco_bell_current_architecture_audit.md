# Taco Bell current architecture audit

Static inspection of both Taco Bell iso scenes and their referenced scripts/resources. **Not runtime-tested** in this audit-only pass.

## Scene comparison

| Scene | Root script | Extra stack |
|-------|-------------|-------------|
| `TacoBellIso_Editable.tscn` | `IsoMissionBase.gd` | Standard iso runtime (alert controller, markers, HUD, test pause menu, dog) |
| `TacoBellIso_Editable_RedesignTest.tscn` | `IsoMissionBase.gd` | Same `taco_bell_iso_blockout_definition.tres` plus **Phase0J** (interaction bridge, code gate UI, adapters) and **Phase0K** (completion, Louis exit, spawners, wrong-code guard) |

## Flow (inferred)

1. `IsoMissionBase._ready` ensures `GameplayRoot` / `ArtRoot` / `EntityRoot`, applies blockout, reads `mission_definition`, calls `GameState.start_mission`, generates layout/runtime.
2. `LevelBase._ready` (super) spawns player, dog, connects `EventBus.player_died`, sets `QuestManager` objective string, ensures common UI.
3. Runtime systems under `GameplayRoot/RuntimeSystems` hold guards, cameras, alarms, routes, transitions.
4. Exit / return-to-hideout ultimately goes through `LevelBase.complete_level` / `fail_level` → `GameState` + `SceneManager` (autoloads not modified in audit).

## Must-not-forget checklist

See `taco_bell_current_architecture_audit.json` → `must_not_forget` for evidence strings and risk per item.

## Reusable vs Taco-specific boundary (proposal)

- **Keep Taco-specific:** `TacoBellDialogue.gd`, Louis flavor props, Taco-tuned hint tiers, mission copy.
- **Extract to reusable modules:** one-shot alarm behavior, route-access card rules, code-gate barrier spawn pattern, attempt runtime dictionary lifecycle, poop decoy placement API.
- **Replace duplication:** choose **one** of Editable vs RedesignTest controller stacks for production Taco; keep the other as sandbox or merge adapters into `IsoMissionBase` children incrementally.

## Hard assertions

JSON field `assertions` all `true`.
