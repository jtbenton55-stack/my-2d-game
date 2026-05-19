# Mission Iso Scenes

This folder contains playable, legacy, bake-output, test, and authoring-template scenes. Do not infer runtime status from file name alone.

## Current Playable Scene

- `TacoBellIso_Editable_RedesignTest.tscn`

`MissionSceneResolver.gd` currently resolves `taco_bell_drop` to this scene for playable Taco mission flow.

## Legacy / Dev / Bake Scenes

- `TacoBellIso_Editable.tscn`: legacy bake-output scene; still referenced by bake helpers and older validators/docs.
- `TacoBellIso_Editable_Test.tscn`: hand-edit/test scene referenced by older bake/test workflows.
- `TacoBellIso_Editable2.tscn`: legacy/dev variant.
- `TacoBellIsoBlockout.tscn`: blockout/source-era mission scene.
- `TacoBellIsoHandEditTest.tscn`: hand-edit validation scene.

Do not delete or move these variants until bake helpers, validators, docs, and runtime references are fully retired or redirected.

## Authoring Templates

- `authoring_templates/`: collectible/interactable author templates.
- `security_authoring_templates/`: security author templates.

These templates are intentionally separate from playable scenes. When authoring becomes mission-agnostic, consider moving shared templates to a broader path such as `scenes/templates/mission_authoring/`.
