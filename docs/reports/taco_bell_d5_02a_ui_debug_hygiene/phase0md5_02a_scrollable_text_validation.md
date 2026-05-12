# 0M-D5-02A — Phase 5: Scrollable text validation

## Modified panels

| Panel | Bounded box | Scroll | Notes |
|-------|---------------|--------|------|
| Pause Objectives / Scheme / Clues / Controls | `Panel` + `ScrollContainer` + `RichTextLabel` | Vertical scroll via RTL + min height | `_fit_pause_info_scroll` after open |
| Controls overlay (F1) | `Panel` + `ScrollContainer` + `RichTextLabel` | Yes | `_fit_controls_text_height` |
| Sprint debug (F11) | `PanelContainer` + `ScrollContainer` + `RichTextLabel` | Yes | Hidden by default |
| IsoMissionDebugPanel details | Existing `RichTextLabel` | Already `scroll_active` | Unchanged behavior |
| IsoMissionDebugPanel compact status | `ScrollContainer` + `Label` | Yes | Autowrap + dynamic min height |
| Phase0JDebugHUD | `Panel` + `ScrollContainer` + labels | Yes | Column scroll |

## Remaining overflow risks

- **HUD `ObjectiveLabel`** (if mission strings are huge) — not modified; **D5-02B** should use ticker with max width + ellipsis.
- **DialogueBox / Scheme / Evidence** long copy — **DEFER**.
- **RichTextLabel** height fit uses `get_content_height()` — edge case at first frame before layout; **manual** resize check.

## GRB

Pause scroll interaction **not** fully automated (paused tree); **manual** checklist required.
