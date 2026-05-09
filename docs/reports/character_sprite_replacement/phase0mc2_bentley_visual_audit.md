# 0M-C2 Bentley Visual Audit

Bentley exists as a generated hideout station/interactable (`station_id=bentley`) rather than a dedicated persistent map sprite node.
Dialogue path: `HideoutInteractable -> HideoutManager.open_station("bentley") -> DialogueManager`.
Existing Bentley portrait is separate UI portrait data and remains preserved.
No safe dedicated black Shiba/isometric dog map sprite was found. Bentley map visual replacement skipped to avoid forcing portrait/icon art into world gameplay.
