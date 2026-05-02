# Jazz Club multi-floor — deferred gameplay & polish

## Phase 2 (done) vs still stubbed

**Implemented (Phase 2):** Basement visuals under `BasementVisuals` (origin `y=3072`), `BasementDoorTrigger` / `BasementArrivalMarker` / `BasementReturnTrigger`, `Floor1_BasementReturnMarker`, `BasementStairsMarker` at tile (16,4), shard + keycard pickups, Yordano `[E]` interact (`yordano_basement_interact.gd`), `GameState` flags `velvet_paw_club_hostile`, `velvet_paw_basement_shard_collected`, `velvet_paw_basement_keycard_collected`, `velvet_paw_stealth_run_broken`, camera/world height `4224`, perimeter walls extended.

**Still visual / gameplay stubs (expand later):**

- **LightUpDanceFloor**: Spec calls for a 2×2 panel wave grid in bass room — only flat `BassRoomFloor` is placed; add animated panels + wave pattern.
- **Crowd silhouettes (15–18)** with glow sticks: not spawned; add when performance budget allows.
- **Strobe zones / bass-drop stun zones**: `ColorRect` placeholders only; no pulsing shader or stun volumes.
- **30-second countdown / perfect escape / `PerfectEscapeZone`**: not in scene yet; wire to `jazz_club_perfect_bass_blackout` when designed.
- **Escape ladder traversal**: `EscapeLadderLine` is decorative only (Floor 1 endpoint ↔ basement).
- **Bouncer patrol Line2D**: still solid red; optional dashed texture (Phase 4 R9 will hide this line when hostile).
- **Bartender side-quest**: `BartenderInteract` remains a disabled `Area2D` placeholder.
- **Floor 2 / Phase 3** *(layout done)*: `Floor2Visuals` at `y=1664` (dressing rooms, sound booth, VIP balcony, vent/service markers); backstage gameplay nodes moved to Floor 2 (`BackstageArea` ~`(912,2080)`, rig stairs ~`(928,1888)`, briefcase `LedgerBriefcaseMarker` / `LedgerZone` on balcony ~`(1536,2480)`). **`floor2_access_unlocked`** (Phase 4) still gates hostile-suite access in script.
- **Mission completion**: `complete_level()` still requires legacy `ledger_collected` (balcony briefcase). Basement shard + hostile club flow needs end-to-end objective/escape integration in a later phase.

## Phase 4+ prep

- **VIP balcony / vent stubs**: unchanged from earlier notes.
- **`StairsWayfinding` / `StairsBlocker`**: Unblock still tied to `floor2_access_unlocked` or `club_owner_defeated` (resume from arena); tread art parented at Floor 2 origin `(0,1664)` with local offsets ~880–1048 × ~104–228.
- **`VelvetShelfGoblinPickup`**: Optional polaroid backstage (not bathroom Glow Guy). **`BathroomGlowGuyPickup`** = `velvet_bathroom_glow_guy`.
- **`YordanoTinyIconPickup`**: Now at basement DJ shelf tile ~(11,3); catalog id remains **`yordano_tiny_icon_headphones`** (do not rename reward id).
- **Polaroid / hidden stage**: unchanged.

## Resolved / notes

- **Setlist alarm safe spots**: `body_entered` now uses a lambda so `spot_name` binds correctly (fixes prior `StringName` / `Object` order bug).
- **Ledger decoy teleport**: Uses `LedgerBriefcaseMarker` when present.

## Security cameras (Phase 4)

- Confirm `EnemyBase` / `Guard` / `vision_cone.gd` support for a stationary **SecurityCamera** before implementing Phase 4; choose subclass vs standalone script per pre-flight.
