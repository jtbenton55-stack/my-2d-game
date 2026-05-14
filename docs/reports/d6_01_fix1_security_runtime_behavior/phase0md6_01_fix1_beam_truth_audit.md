# Beam truth audit

**Exists**  
- Runtime **Area2D** alarm under `GameplayRoot/RuntimeSystems/AlarmZones`, named like `AlarmZone_garage_entry_beam`, id **`garage_entry_beam`**.

**Reporting**  
- `MissionAlertController` maps sources containing `garage_entry_beam` to adapter kind **`beam_trip`**.  
- Same-frame dedupe + attempt-local counters in `MissionSecurityEventAdapter`.

**Player-facing visibility**  
- No dedicated VFX beam mesh in code audited; detection is zone-based. F10 documents a **hint line** for manual navigation.

**No redesign**  
- No new art or beam mesh added this pass.
