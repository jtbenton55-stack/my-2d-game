extends Node

## Phase 0M-C1 storefront test harness.
## Opens the Neon Nook panel with real HideoutStoreController and
## HideoutStateController instances so icon loading, category filtering,
## Case Cash display, buy buttons, owned state, and insufficient-funds
## feedback can be tested without running the full HideoutHub scene.

const HideoutStoreControllerScript = preload("res://src/hideout/HideoutStoreController.gd")
const HideoutStateControllerScript = preload("res://src/hideout/HideoutStateController.gd")

@onready var _panel := get_node_or_null("UI/HideoutStorefrontPanel")

var _store: Node = null
var _state: Node = null

func _ready() -> void:
	_store = HideoutStoreControllerScript.new()
	_store.name = "HideoutStoreController"
	add_child(_store)
	_state = HideoutStateControllerScript.new()
	_state.name = "HideoutStateController"
	add_child(_state)
	if _state.has_method("apply_debug_state"):
		_state.apply_debug_state("fresh")
	if _panel != null and _panel.has_method("set_store_context"):
		_panel.set_store_context(_store, _state)
	if _panel != null and _panel.has_method("open_store"):
		_panel.open_store()
