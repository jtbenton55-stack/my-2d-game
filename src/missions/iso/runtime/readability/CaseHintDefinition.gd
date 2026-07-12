@tool
class_name CaseHintDefinition
extends Resource

@export var requirements: RequirementSet
@export var anchor_path: NodePath
@export var max_distance: float = 0.0
@export var priority: int = 0
@export_multiline var text: String = ""
@export var speaker: String = ""
@export var cooldown: float = 0.0
