# D6-05 Runtime Validation

## Scene

`TacoBellIso_Editable_RedesignTest.tscn`

## Router listeners

| Event | Listeners |
|-------|-----------|
| `test_camera_alarm` | 3 (guard spawn, lockdown, node toggle) |
| `ambush_beam_tripped` | 2 (guard spawn, objective) |

## `test_camera_alarm` dispatch

- called: 3, handled: 3
- guard spawn: **spawned**
- lockdown: **alerted**
- proof marker visible: **true**
- last effect: `node_toggle` / `camera_proof_toggle` / `shown`

## `ambush_beam_tripped` dispatch

- handled: true, listeners handled: 2

## Static validator

PASS

## Screenshot

`user://d6_05_downstream_effects_validation.png`
