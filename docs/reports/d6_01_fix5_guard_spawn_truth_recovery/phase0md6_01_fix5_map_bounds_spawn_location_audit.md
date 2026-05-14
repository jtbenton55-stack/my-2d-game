# Map bounds / valid spawn location audit

- Bounds source: _floor_world_bounds() with guard margin via _get_playable_world_bounds().
- User-reported x=-3046 is outside practical floor bounds for active Taco play lanes.
- FIX5 strategy: derive preferred source position from camera/source, then choose safe candidate near player (190-260 px) and validate against bounds.
- If no sane point -> reject spawn without consuming cap.
