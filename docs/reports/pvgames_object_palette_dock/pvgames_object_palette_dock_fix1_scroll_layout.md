# PVGames Object Palette Dock FIX1 - Scroll Layout

Status: PASS

## Layout Diagnosis

Before this fix, `PVGamesObjectPaletteDock.gd` added all UI controls directly to the dock root `VBoxContainer`. There was no `ScrollContainer`, so the result list, preview/details panel, and placement controls could push the action buttons below the visible dock area.

After this fix, the dock keeps the title/status at the top and places the main UI inside a script-created `MainScroll` `ScrollContainer` with a `ContentVBox`.

Sections now appear in this order:

- Search / Filters
- Results
- Selected Object
- Placement
- Actions

## Results

- Dock scene modified: yes
- Dock script modified: yes
- ScrollContainer added: yes, via `MainScroll`
- Action buttons grouped: yes
- Result list height controlled: yes
- Details/source path overflow handled: yes
- No objects stamped: yes
- HideoutHub modified: no
- Taco Bell scenes modified: no
- Gameplay scripts modified: no
- Source PNGs modified: no
- TileSets modified: no

## Validation

Static validation passed. Godot CLI was not available on PATH in prior B8/B8A/B8B checks or this fix, so manual Godot dock verification is still required.

## Manual Test

1. Enable or re-enable `PVGames Object Palette`.
2. Open the dock in a short/narrow editor layout.
3. Search for `wall`.
4. Filter to `OccludableObjects`.
5. Select one result.
6. Scroll down to `Actions`.
7. Confirm `Dry Run Stamp` and stamp buttons are reachable.
8. Click `Dry Run Stamp` and confirm no object is stamped.
