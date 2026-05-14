# 0M-D6-00 — Bentley / scent / case-the-joint audit

## Case the joint (implemented)

- **Input:** `case_the_joint` action — validated by `MissionBlockoutValidator` (expects action exists); shown in pause menu / controls overlay as **Q**.
- **Handler:** `Player.gd` `_try_case_the_joint()` — cooldown (`case_joint_cooldown`), duration timer, clears prior highlights.
- **Effect:** collects nodes in groups `interactable`, `enemy`, `iso_security_camera` within `case_joint_range`, applies temporary **modulate highlight** (gold tint) to `CanvasItem` nodes (cap 12), light **screen shake**, updates objective string with count.
- **Overlap with “Bentley sniff”:** functionally a **tactical pulse / POI reveal**, not dog-pathfinding, not scent-trail solver by itself.

## Bentley as character / companion

- **`DogCompanion.gd`** — follows player; not audited line-by-line here; no replacement for case pulse.
- **Hideout** — Bentley stations, care wipe paws (**cosmetic hideout care**, not mission sniff).
- **Shadow / arena** — Bentley spectator dialogue snippets.

## Scheme card text

- `HideoutStationCatalog` / scheme starter **`bentley_sniff_pass`** — *“Reveals nearby scent trails for a short duration.”* — **design/catalog text**; not proven as iso runtime effect in this audit.

## Scent trails (iso)

- Markers and placeholders (`MissionScentTrailPlaceholder`, layout docs in Taco tooling) — **wrong trail penalties** already tie into attempt counters / performance.

## Minimap

- **No minimap system** found in audit scope; case pulse is **not** a minimap.

## Assertions

| Assertion | Value |
|-----------|--------|
| bentley_sniff_audit_completed | true |
| q_key_case_the_joint_status_recorded | true |
| sniff_keep_defer_or_remove_recommendation_created | true (see design decision doc) |
