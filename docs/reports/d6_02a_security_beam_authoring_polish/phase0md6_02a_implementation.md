# PHASE 0M-D6-02A — Security Beam Authoring Polish

## Changes

- `SecurityBeamAuthor.gd`: Inspector groups, `@export_range`, live editor preview via signature `_process`, clamped helpers, trigger height `visual_height + trigger_extra_height * 2`, configuration warnings, validation status in runtime config.
- `IsoMissionBase.gd`: Extended `d6_02_*` F10/runtime summary fields (visual width, trigger dimensions, validation status).
- `IsoMissionDebugPanel.gd`: F10 shows visual/trigger dimensions and validation status.
- `TacoBellIso_Editable_RedesignTest.tscn`: AMBUSH author default `visual_height = 340`.

## Trigger formula

`trigger_height = visual_height + trigger_extra_height * 2.0`

## Default AMBUSH size

- visual_height: 340px
- visual_width: 32px
- trigger_width: 72px
- trigger_extra_height: 16px → trigger height 372px
