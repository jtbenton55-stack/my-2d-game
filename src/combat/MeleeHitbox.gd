extends Area2D
## Active only during attacks; reports hits once per swing via body_entered.

var damage: float = 0.0
var _hit_targets: Array[Node] = []
var _damage_source: Node2D

func _ready() -> void:
	monitoring = false
	body_entered.connect(_on_body_entered)


func setup_damage_source(source: Node2D) -> void:
	_damage_source = source


func begin_swing() -> void:
	_hit_targets.clear()
	monitoring = true


func end_swing() -> void:
	monitoring = false


func _on_body_entered(body: Node) -> void:
	if body == null or body in _hit_targets:
		return
	if _damage_source and body == _damage_source:
		return
	if not body.is_in_group("enemy"):
		return
	if not body.has_method("take_damage"):
		return
	_hit_targets.append(body)
	var src: Node = _damage_source if _damage_source else get_parent()
	body.take_damage(int(round(damage)), src)
