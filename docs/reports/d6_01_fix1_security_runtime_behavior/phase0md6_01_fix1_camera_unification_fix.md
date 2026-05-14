# Camera unification fix

- **Spawner parent** `EntityRoot/Cameras` so all runtime cameras share the same branch as alert wiring expects.
- **LOS** optional; default **false** so cones are not universally blind through iso walls.
- **Reinforcement** gated by **per-source cooldown** in `MissionAlertController` (not global single timestamp).
- **Adapter** still dedupes same-frame identical events.
