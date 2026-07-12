class_name EnemyAction
extends Node

enum Type {CONDITIONAL, CHANCE_BASED}

@export var intent: Intent
@export var sound: AudioStream
@export var type: Type
@export_range(0.0, 10.0) var chance_weight := 0.0
@export_range(1, 10) var max_consecutive_uses := 2

@onready var accumulated_weight := 0.0

var enemy: Enemy
var target: Node2D
var _completion_enemy_id := 0


func is_performable() -> bool:
	return false


func perform_action() -> void:
	pass


func update_intent_text() -> void:
	intent.current_text = intent.base_text


func complete_action_when_tween_finishes(tween: Tween) -> void:
	if not tween or not enemy:
		return
	_completion_enemy_id = enemy.get_instance_id()
	tween.finished.connect(_emit_completed_for_stored_enemy)


func complete_action_after_delay(delay: float) -> void:
	if not enemy:
		return
	_completion_enemy_id = enemy.get_instance_id()
	get_tree().create_timer(delay, false).timeout.connect(_emit_completed_for_stored_enemy)


func _emit_completed_for_stored_enemy() -> void:
	var acting_enemy := instance_from_id(_completion_enemy_id) as Enemy
	if is_instance_valid(acting_enemy):
		Events.enemy_action_completed.emit(acting_enemy)
